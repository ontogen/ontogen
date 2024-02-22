defmodule Ontogen.Changeset.ActionTest do
  use OntogenCase

  import Ontogen.Changeset.Action

  doctest Ontogen.Changeset.Action

  test "sort_changes/1" do
    assert sort_changes(
             add: statement(1),
             remove: statement(2),
             update: statement(3),
             replace: statement(4),
             overwrite: statement(5)
           ) ==
             [
               overwrite: statement(5),
               remove: statement(2),
               replace: statement(4),
               update: statement(3),
               add: statement(1)
             ]
  end
end
