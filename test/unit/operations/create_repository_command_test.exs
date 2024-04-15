defmodule Ontogen.Operations.CreateRepositoryCommandTest do
  use Ontogen.StoreCase

  doctest Ontogen.Operations.CreateRepositoryCommand

  alias Ontogen.Operations.CreateRepositoryCommand
  alias Ontogen.{Dataset, ProvGraph, Store, Config}

  setup do
    on_exit(fn -> File.rm(Config.Repository.IdFile.path()) end)
  end

  test "creates graphs for the given repo" do
    assert Store.repository(Config.store(), id(:repository)) ==
             {:error, :repo_not_found}

    assert {:ok, %CreateRepositoryCommand{} = command} =
             CreateRepositoryCommand.new(repository())

    assert CreateRepositoryCommand.call(command, Config.store()) ==
             {:ok, repository()}

    assert Store.repository(Config.store(), id(:repository)) == {:ok, repository()}
  end

  @tag :tmp_dir
  test "creates a repo id file", %{tmp_dir: tmp_dir} do
    File.cd!(tmp_dir, fn ->
      repo_id_file = Config.Repository.IdFile.path() |> Path.expand()
      refute File.exists?(repo_id_file)

      assert {:ok, %CreateRepositoryCommand{} = command} =
               CreateRepositoryCommand.new(repository())

      assert {:ok, _} =
               CreateRepositoryCommand.call(command, Config.store())

      assert File.exists?(repo_id_file)
    end)
  after
    File.rm_rf(tmp_dir)
  end

  test "creates graphs with the specified custom ids" do
    base_uri = "http://example.com/test"
    repo_id = base_uri <> "/custom_repo_id"

    assert Store.repository(Config.store(), repo_id) == {:error, :repo_not_found}

    expected_repo =
      Ontogen.Repository.new!(repo_id,
        dataset: Dataset.build!(base_uri <> "/custom_dataset_id"),
        prov_graph: ProvGraph.build!(base_uri <> "/custom_prov_graph_id")
      )

    assert {:ok, %CreateRepositoryCommand{} = command} =
             CreateRepositoryCommand.new(
               repo: repo_id,
               dataset: base_uri <> "/custom_dataset_id",
               prov_graph: base_uri <> "/custom_prov_graph_id"
             )

    assert CreateRepositoryCommand.call(command, Config.store()) ==
             {:ok, expected_repo}

    assert Store.repository(Config.store(), repo_id) == {:ok, expected_repo}
  end

  test "when the repo already exists" do
    assert {:ok, %CreateRepositoryCommand{} = command} =
             CreateRepositoryCommand.new(repository())

    assert CreateRepositoryCommand.call(command, Config.store()) ==
             {:ok, repository()}

    assert CreateRepositoryCommand.call(command, Config.store()) ==
             {:error, :repo_already_exists}
  end
end
