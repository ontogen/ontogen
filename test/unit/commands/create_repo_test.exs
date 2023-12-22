defmodule Ontogen.Commands.CreateRepoTest do
  use Ontogen.Store.Test.Case

  doctest Ontogen.Commands.CreateRepo

  alias Ontogen.{Dataset, ProvGraph}
  alias Ontogen.Commands.{CreateRepo, FetchRepoInfo}

  test "creates graphs for the given repo" do
    assert FetchRepoInfo.call(Local.store(), id(:repository)) == {:error, :repo_not_found}

    assert CreateRepo.call(Local.store(), repository()) ==
             {:ok, repository()}

    assert FetchRepoInfo.call(Local.store(), id(:repository)) == {:ok, repository()}
  end

  test "creates graphs with the specified custom ids" do
    base_uri = "http://example.com/test"
    repo_id = base_uri <> "/custom_repo_id"

    assert FetchRepoInfo.call(Local.store(), repo_id) == {:error, :repo_not_found}

    expected_repo =
      Ontogen.Repository.build!(repo_id,
        dataset: Dataset.build!(base_uri <> "/custom_dataset_id"),
        prov_graph: ProvGraph.build!(base_uri <> "/custom_prov_graph_id")
      )

    assert CreateRepo.call(Local.store(),
             repo: repo_id,
             dataset: base_uri <> "/custom_dataset_id",
             prov_graph: base_uri <> "/custom_prov_graph_id"
           ) ==
             {:ok, expected_repo}

    assert FetchRepoInfo.call(Local.store(), repo_id) == {:ok, expected_repo}
  end

  test "when the repo already exists" do
    assert CreateRepo.call(Local.store(), repository()) ==
             {:ok, repository()}

    assert CreateRepo.call(Local.store(), repository()) ==
             {:error, :repo_already_exists}
  end
end
