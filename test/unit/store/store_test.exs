defmodule Ontogen.StoreTest do
  use Ontogen.StoreCase

  doctest Ontogen.Store

  alias Ontogen.{Store, Config}

  describe "repository/2" do
    test "when a repository with the given id exists" do
      repository = repository()
      :ok = Store.insert_data(Config.store(), repository.__id__, Grax.to_rdf!(repository))

      assert Store.repository(Config.store(), repository.__id__) ==
               {:ok, repository}
    end

    test "when no repository with the given id exists" do
      assert Store.repository(Config.store(), id(:repository)) ==
               {:error, :repo_not_found}
    end
  end
end
