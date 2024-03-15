defmodule Ontogen.Operations.EffectiveChangesetQueryTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Operations.EffectiveChangesetQuery

  alias Ontogen.Commit.Changeset

  setup do
    init_commit_history()

    :ok
  end

  describe "adds" do
    test "fully effective (when none of the added statements already exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Ontogen.effective_changeset!(add: statements) ==
               Changeset.new!(add: statements)
    end

    test "partially effective (when some of the added statements already exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      add = [new_statement | Enum.take(graph(), 1)]

      assert Ontogen.effective_changeset!(add: add) ==
               Changeset.new!(add: new_statement)
    end

    test "ineffective (when all of the added statements already exist)" do
      assert Ontogen.effective_changeset!(add: graph()) == :no_effective_changes
    end
  end

  describe "removes" do
    test "fully effective (when all of the removed statements actually exist)" do
      assert Ontogen.effective_changeset!(remove: graph()) ==
               Changeset.new!(remove: graph())
    end

    test "partially effective (when some of the removed statements actually exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      existing_statements = Enum.take(graph(), 1)
      remove = [new_statement | existing_statements]

      assert Ontogen.effective_changeset!(remove: remove) ==
               Changeset.new!(remove: existing_statements)
    end

    test "ineffective (when none of the removed statements actually exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Ontogen.effective_changeset!(remove: statements) ==
               :no_effective_changes
    end
  end

  describe "updates" do
    test "fully effective (when none of the updated statements already exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Ontogen.effective_changeset!(update: statements) ==
               Changeset.new!(update: statements)
    end

    test "partially effective (when some of the updated statements already exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      update = [new_statement, EX.S1 |> EX.p1(EX.O1)]

      assert Ontogen.effective_changeset!(update: update) ==
               Changeset.new!(update: new_statement)
    end

    test "ineffective (when all of the updated statements already exist)" do
      assert Ontogen.effective_changeset!(update: graph()) == :no_effective_changes
    end

    test "removes existing statements to the same subject-predicate" do
      statements = [
        # this statement should lead to an overwrite
        EX.S1 |> EX.p1(EX.O2),
        # this statement should NOT lead to an overwrite
        EX.S2 |> EX.p3("Foo")
      ]

      overwritten = EX.S1 |> EX.p1(EX.O1)

      assert Ontogen.effective_changeset!(update: statements) ==
               Changeset.new!(update: statements, overwrite: overwritten)
    end

    test "when the updated statements are ineffective, the other statements are still replaced" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      update = [new_statement, EX.S2 |> EX.p2(42)]

      assert Ontogen.effective_changeset!(update: update) ==
               Changeset.new!(
                 update: new_statement,
                 overwrite: EX.S2 |> EX.p2("Foo")
               )
    end
  end

  describe "replaces" do
    test "fully effective (when none of the replaced statements already exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Ontogen.effective_changeset!(replace: statements) ==
               Changeset.new!(replace: statements)
    end

    test "partially effective (when some of the replaced statements already exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      replace = [new_statement | Enum.take(graph(), 1)]

      assert Ontogen.effective_changeset!(replace: replace) ==
               Changeset.new!(replace: new_statement)
    end

    test "ineffective (when all of the replaced statements already exist)" do
      assert Ontogen.effective_changeset!(replace: graph()) == :no_effective_changes
    end

    test "removes existing statements to the same subject" do
      statements = [
        EX.S1 |> EX.p1(EX.O2),
        EX.S2 |> EX.p3("Foo")
      ]

      assert Ontogen.effective_changeset!(replace: statements) ==
               Changeset.new!(
                 replace: statements,
                 overwrite: graph()
               )
    end

    test "when the replaced statements are ineffective, the other statements are still replaced" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      replace = [new_statement, EX.S2 |> EX.p2(42)]

      assert Ontogen.effective_changeset!(replace: replace) ==
               Changeset.new!(
                 replace: new_statement,
                 overwrite: EX.S2 |> EX.p2("Foo")
               )
    end

    test "when overwritten statements are removed explicitly" do
      assert Ontogen.effective_changeset!(
               replace: EX.S2 |> EX.p3("Foo"),
               remove: EX.S2 |> EX.p2(42)
             ) ==
               Changeset.new!(
                 replace: EX.S2 |> EX.p3("Foo"),
                 remove: EX.S2 |> EX.p2(42),
                 overwrite: EX.S2 |> EX.p2("Foo")
               )
    end
  end

  describe "combined adds and removes" do
    test "fully effective" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Ontogen.effective_changeset!(add: statements, remove: graph()) ==
               Changeset.new!(add: statements, remove: graph())
    end

    test "partially effective" do
      non_existing_statements = EX.Foo |> EX.bar(EX.Baz1)
      new_statement = EX.Foo |> EX.bar(EX.Baz2)
      existing_statements = Enum.take(graph(), 1)
      add = [new_statement | existing_statements]
      existing_remove_statements = Graph.delete(graph(), existing_statements)
      remove = [non_existing_statements, existing_remove_statements]

      assert Ontogen.effective_changeset!(add: add, remove: remove) ==
               Changeset.new!(
                 add: new_statement,
                 remove: existing_remove_statements
               )
    end

    test "ineffective" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Ontogen.effective_changeset!(add: graph(), remove: statements) ==
               :no_effective_changes
    end
  end
end
