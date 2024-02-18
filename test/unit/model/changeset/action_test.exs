defmodule Ontogen.Changeset.ActionTest do
  use OntogenCase

  import Ontogen.Changeset.Action

  doctest Ontogen.Changeset.Action

  test "sort_changes/1" do
    assert sort_changes(
             insert: statement(1),
             delete: statement(2),
             update: statement(3),
             replace: statement(4),
             overwrite: statement(5)
           ) ==
             [
               overwrite: statement(5),
               delete: statement(2),
               replace: statement(4),
               update: statement(3),
               insert: statement(1)
             ]
  end
end
