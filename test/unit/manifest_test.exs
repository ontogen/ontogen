defmodule Ontogen.ManifestTest do
  use Ontogen.MudCase

  doctest Ontogen.Manifest

  alias Ontogen.Manifest
  alias Ontogen.{Service, Repository, Dataset, History, Agent}
  alias Gno.Store.Adapters.{Oxigraph, Fuseki, GraphDB}

  import RDF.Sigils

  @configured_store_adapter configured_store_adapter()

  test "manifest/0" do
    assert {:ok,
            %Manifest{
              graph: %Graph{},
              load_path: _,
              agent: %Agent{
                name: "Jane Doe",
                email: ~I<mailto:jane.doe@example.com>
              },
              service: %Service{
                repository: %Repository{
                  dataset: %Dataset{}
                },
                store: %@configured_store_adapter{}
              }
            }} =
             Manifest.manifest()
  end

  test "agent/0" do
    assert {:ok,
            %Agent{
              name: "Jane Doe",
              email: ~I<mailto:jane.doe@example.com>
            }} =
             Manifest.agent()
  end

  test "agent/1 with ref" do
    assert Manifest.agent(ref: "agent") == Manifest.agent()
    assert Manifest.agent(ref: :this) == Manifest.agent()
    assert Manifest.user() == Manifest.agent()
  end

  test "service/0" do
    assert {:ok,
            %Service{
              repository: %Repository{
                dataset: %Dataset{}
              },
              store: %@configured_store_adapter{}
            }} =
             Manifest.service()
  end

  test "service/1 with ref" do
    assert Manifest.service(ref: "service") == Manifest.service()
    assert Manifest.service(ref: :this) == Manifest.service()
  end

  test "repository/0" do
    assert {:ok, %Repository{dataset: %Dataset{}}} =
             Manifest.repository()
  end

  test "repository/1 with ref" do
    assert Manifest.repository(ref: "repository") == Manifest.repository()
    assert Manifest.repository(ref: :this) == Manifest.repository()
  end

  test "dataset/0" do
    assert {:ok,
            %Dataset{
              __additional_statements__: %{
                ~I<http://purl.org/dc/terms/title> => %{~L"test dataset" => nil}
              }
            }} =
             Manifest.dataset()
  end

  test "dataset/1 with ref" do
    assert Manifest.dataset(ref: "dataset") == Manifest.dataset()
    assert Manifest.dataset(ref: :this) == Manifest.dataset()
  end

  test "history/0" do
    assert {:ok, %History{}} = Manifest.history()
  end

  test "history/1 with ref" do
    assert Manifest.history(ref: "history") == Manifest.history()
    assert Manifest.history(ref: :this) == Manifest.history()
  end

  case @configured_store_adapter do
    Gno.Store ->
      test "store/0 with generic store" do
        assert {:ok, %Store{}} = Manifest.store()
      end

      test "store/1 with ref" do
        assert Manifest.store(ref: "store") == Manifest.store()
        assert Manifest.store(ref: :this) == Manifest.store()
      end

    Fuseki ->
      test "store/0 with Fuseki adapter" do
        assert {:ok,
                %Fuseki{
                  port: 3030,
                  dataset: "ontogen-test-dataset"
                }} =
                 Manifest.store()
      end

    Oxigraph ->
      test "store/0 with Oxigraph adapter" do
        assert {:ok, %Oxigraph{port: 7879}} = Manifest.store()
      end

    GraphDB ->
      test "store/0 with GraphDB adapter" do
        assert {:ok, %GraphDB{port: 7200}} = Manifest.store()
      end
  end

  describe "generate/2" do
    @moduletag :tmp_dir

    setup context do
      project_dir = context.tmp_dir
      manifest_dir = Path.join(project_dir, "config/ontogen")
      on_exit(fn -> File.rm_rf!(context.tmp_dir) end)
      {:ok, project_dir: project_dir, manifest_dir: manifest_dir}
    end

    test "generates default manifest", %{project_dir: project_dir, manifest_dir: manifest_dir} do
      assert :ok = Manifest.generate(project_dir)

      assert %Manifest{
               service: %Service{
                 __id__: %RDF.IRI{value: "urn:uuid:" <> _},
                 repository: %Repository{
                   dataset: %Dataset{}
                 },
                 store: %Gno.Store{}
               },
               agent: %Agent{name: "Your name"}
             } = Manifest.manifest!(load_path: manifest_dir)

      assert File.exists?(Path.join(project_dir, Mud.Seed.Directory.path()))
    end

    test "generates manifest with custom store adapter", %{
      project_dir: project_dir,
      manifest_dir: manifest_dir
    } do
      assert :ok = Manifest.generate(project_dir, adapter: Fuseki)

      assert {:ok, %Manifest{service: %Service{store: %Fuseki{}}}} =
               Manifest.manifest(load_path: manifest_dir)

      File.rm_rf!(manifest_dir)

      assert :ok = Manifest.generate(project_dir, adapter: "Oxigraph")

      assert {:ok, %Manifest{service: %Service{store: %Oxigraph{}}}} =
               Manifest.manifest(load_path: manifest_dir)
    end

    test "fails with unknown adapter", %{project_dir: project_dir} do
      assert {:error, %Gno.Manifest.GeneratorError{}} =
               Manifest.generate(project_dir, adapter: :unknown)
    end

    test "supports custom template directories", %{
      project_dir: project_dir,
      manifest_dir: manifest_dir
    } do
      custom_template_dir = Path.join(project_dir, "custom_template")
      File.mkdir_p!(custom_template_dir)
      File.write!(Path.join(custom_template_dir, "custom.ttl.eex"), "<%= @custom_value %>")

      assert :ok =
               Manifest.generate(
                 project_dir,
                 template: custom_template_dir,
                 adapter: Fuseki,
                 assigns: [custom_value: "Test"]
               )

      content = File.read!(Path.join(manifest_dir, "custom.ttl"))
      assert content == "Test"
    end
  end
end
