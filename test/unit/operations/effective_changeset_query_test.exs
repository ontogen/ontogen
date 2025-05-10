defmodule Ontogen.Operations.EffectiveChangesetQueryTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.EffectiveChangesetQuery

  alias Gno.{Changeset, EffectiveChangeset, NoEffectiveChanges}

  setup do
    init_commit_history()

    :ok
  end

  test "with changeset arguments" do
    assert Ontogen.effective_changeset!(add: statement(1)) ==
             EffectiveChangeset.new!(add: statement(1))
  end

  test "with Gno.Changeset" do
    assert Ontogen.effective_changeset(Changeset.new!(add: statement(1))) ==
             {:ok, EffectiveChangeset.new!(add: statement(1))}
  end

  test "handles NoEffectiveChanges correctly" do
    assert Ontogen.effective_changeset!(add: graph()) == %NoEffectiveChanges{}
  end
end
