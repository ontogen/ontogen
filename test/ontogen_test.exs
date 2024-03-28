defmodule OntogenTest do
  use Ontogen.StoreCase

  doctest Ontogen

  alias Ontogen.Config
  alias Ontogen.Operations.CreateRepositoryCommand
  alias Ontogen.Repository.NotReadyError
  import ExUnit.CaptureLog

  describe "init" do
    test "when no repo specified" do
      assert capture_log(fn -> start_supervised(Ontogen) end) =~
               "Repo not specified"

      assert Ontogen.status() == :no_repo
      assert Ontogen.repository() == {:error, %NotReadyError{operation: :repository}}
      assert Ontogen.dataset_info() == {:error, %NotReadyError{operation: :dataset_info}}
      assert Ontogen.prov_graph_info() == {:error, %NotReadyError{operation: :prov_graph_info}}
    end

    test "when the repo does not exist" do
      assert capture_log(fn -> start_supervised({Ontogen, [repo: id(:repo)]}) end) =~
               "Repo not found"

      assert Ontogen.status() == :no_repo
      assert Ontogen.repository() == {:error, %NotReadyError{operation: :repository}}
      assert Ontogen.dataset_info() == {:error, %NotReadyError{operation: :dataset_info}}
      assert Ontogen.prov_graph_info() == {:error, %NotReadyError{operation: :prov_graph_info}}
    end

    test "when the repo does exist" do
      {:ok, command} = CreateRepositoryCommand.new(repository())
      {:ok, repository} = CreateRepositoryCommand.call(command, Config.store())

      assert capture_log(fn -> start_supervised({Ontogen, [repo: repository.__id__]}) end) =~
               "Connected to repo #{repository.__id__}"

      assert Ontogen.status() == :ready
      assert Ontogen.repository() == repository
      assert Ontogen.dataset_info() == repository.dataset
      assert Ontogen.prov_graph_info() == repository.prov_graph
    end
  end

  describe "create_repo/3" do
    test "when the repo does not exist" do
      capture_log(fn -> {:ok, _} = start_supervised(Ontogen) end)

      repository = repository()

      assert Ontogen.create_repo(repository) == {:ok, repository}

      assert Ontogen.status() == :ready
      assert Ontogen.repository() == repository
      assert Ontogen.dataset_info() == repository.dataset
      assert Ontogen.prov_graph_info() == repository.prov_graph
    end

    test "when the repo already exists" do
      capture_log(fn -> {:ok, _} = start_supervised({Ontogen, [repo: id(:repository)]}) end)

      {:ok, command} = CreateRepositoryCommand.new(repository())
      {:ok, _} = CreateRepositoryCommand.call(command, Config.store())

      assert Ontogen.create_repo(repository()) == {:error, :repo_already_exists}
    end

    test "when the repo is already connected" do
      {:ok, command} = CreateRepositoryCommand.new(repository())
      {:ok, _} = CreateRepositoryCommand.call(command, Config.store())

      capture_log(fn -> {:ok, _} = start_supervised({Ontogen, [repo: id(:repository)]}) end)

      assert Ontogen.create_repo(repository()) == {:error, :repo_already_connected}
    end
  end
end
