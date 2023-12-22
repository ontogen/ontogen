defmodule Ontogen.Commands.FetchRepoInfoTest do
  use Ontogen.Store.Test.Case

  doctest Ontogen.Commands.FetchRepoInfo

  alias Ontogen.Commands.FetchRepoInfo

  test "when repo exists" do
    repository = repository()
    :ok = Store.insert_data(Local.store(), repository.__id__, Grax.to_rdf!(repository))

    assert FetchRepoInfo.call(Local.store(), repository.__id__) == {:ok, repository}
  end

  test "when repo not exists" do
    assert FetchRepoInfo.call(Local.store(), id(:repository)) == {:error, :repo_not_found}
  end
end
