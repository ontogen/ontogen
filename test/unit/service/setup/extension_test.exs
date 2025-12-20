defmodule Ontogen.Service.Setup.ExtensionTest do
  use Ontogen.StoreCase

  doctest Ontogen.Service.Setup.Extension

  alias Ontogen.Operations.RepositoryQuery
  alias Ontogen.Manifest
  alias Ontogen.Service.Setup.Extension
  alias Gno.Service.{Setup, SetupError}

  @configured_store_adapter configured_store_adapter()

  defp setup_with_extension(service) do
    Setup.setup(service, extension: Extension)
  end

  describe "Setup.setup/2" do
    test "successfully sets up Ontogen repository with head initialization" do
      service = Manifest.service!()

      assert service.repository.head == nil

      assert {:ok, updated_service} = setup_with_extension(service)

      assert repository_exists?(service)
      assert updated_service.repository.head == RDF.iri(Og.CommitRoot)
      assert {:ok, stored_repo} = RepositoryQuery.call(service)
      assert stored_repo.head == RDF.iri(Og.CommitRoot)
      assert validate_ontogen_structure(service)
    end

    test "fails if repository already exists" do
      service = Manifest.service!()

      assert {:ok, _} = setup_with_extension(service)

      assert {:error, %SetupError{reason: :already_setup}} =
               setup_with_extension(service)
    end
  end

  describe "Setup.teardown/2" do
    setup do
      on_exit(fn ->
        @configured_store_adapter.setup(Manifest.store!())
      end)

      :ok
    end

    test "successfully tears down Ontogen repository" do
      service = Manifest.service!()

      assert {:ok, _} = setup_with_extension(service)
      assert repository_exists?(service)

      assert :ok = Setup.teardown(service, extension: Extension)
    end

    test "removes all Ontogen-specific graphs" do
      service = Manifest.service!()

      assert {:ok, _} = setup_with_extension(service)
      assert validate_ontogen_structure(service)
      Gno.insert_data!(graph(1), service: service, graph: :history)
      assert Gno.ask!("ASK { ?s ?p ?o . }", service: service, graph: :history)

      assert :ok = Setup.teardown(service, extension: Extension)
      refute validate_ontogen_structure(service)

      # Other triple stores don't support when the dataset is deleted
      if @configured_store_adapter == Gno.Store.Adapters.Oxigraph do
        refute Gno.ask!("ASK { ?s ?p ?o . }", service: service, graph: :history)
      end
    end
  end

  describe "Setup.validate/2" do
    test "returns error before setup" do
      service = Manifest.service!()

      assert {:error, _} = Setup.validate(service, extension: Extension)
    end

    test "returns :ok after setup" do
      service = Manifest.service!()

      assert {:ok, _} = setup_with_extension(service)
      assert :ok = Setup.validate(service, extension: Extension)
    end

    test "returns error if the history of the repository is missing" do
      service = Manifest.service!()

      assert {:ok, _} = setup_with_extension(service)

      Gno.delete_data!(
        RDF.graph(
          {service.repository.__id__, Og.repositoryHistory(), service.repository.history.__id__}
        ),
        service: service,
        graph: :repository_manifest
      )

      assert {:error, _} = Setup.validate(service, extension: Extension)
    end
  end

  defp repository_exists?(service) do
    case RepositoryQuery.call(service) do
      {:ok, _} -> true
      {:error, %Grax.ValidationError{}} -> false
      {:error, reason} -> raise "Failed to check repository existence: #{inspect(reason)}"
    end
  end

  defp validate_ontogen_structure(service) do
    case Extension.validate(service, []) do
      :ok -> true
      {:error, _} -> false
    end
  end
end
