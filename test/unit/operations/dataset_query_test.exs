defmodule Ontogen.Operations.DatasetQueryTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.DatasetQuery

  setup do
    init_commit_history()

    :ok
  end

  test "returns the dataset" do
    assert Ontogen.dataset() == {:ok, graph()}
  end
end
