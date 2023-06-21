defmodule Ontogen.Commands.FetchEffectiveChangesetTest do
  use Ontogen.Local.Repo.Test.Case, async: false

  doctest Ontogen.Commands.FetchEffectiveChangeset

  setup do
    init_commit_history()

    :ok
  end

  describe "insertions" do
    test "fully effective (when none of the inserted statements already exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Repo.effective_changeset!(insert: statements) ==
               Changeset.new!(insert: statements)
    end

    test "partially effective (when some of the inserted statements already exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      insert = [new_statement | Enum.take(graph(), 1)]

      assert Repo.effective_changeset!(insert: insert) ==
               Changeset.new!(insert: new_statement)
    end

    test "ineffective (when all of the inserted statements already exist)" do
      assert Repo.effective_changeset!(insert: graph()) == :no_effective_changes
    end
  end

  describe "deletions" do
    test "fully effective (when all of the deleted statements actually exist)" do
      assert Repo.effective_changeset!(delete: graph()) ==
               Changeset.new!(delete: graph())
    end

    test "partially effective (when some of the deleted statements actually exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      existing_statements = Enum.take(graph(), 1)
      delete = [new_statement | existing_statements]

      assert Repo.effective_changeset!(delete: delete) ==
               Changeset.new!(delete: existing_statements)
    end

    test "ineffective (when none of the deleted statements actually exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Repo.effective_changeset!(delete: statements) ==
               :no_effective_changes
    end
  end

  describe "updates" do
    test "fully effective (when none of the updated statements already exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Repo.effective_changeset!(update: statements) ==
               Changeset.new!(update: statements)
    end

    test "partially effective (when some of the updated statements already exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      update = [new_statement, EX.S1 |> EX.p1(EX.O1)]

      assert Repo.effective_changeset!(update: update) ==
               Changeset.new!(update: new_statement)
    end

    test "ineffective (when all of the updated statements already exist)" do
      assert Repo.effective_changeset!(update: graph()) == :no_effective_changes
    end

    test "deletes existing statements to the same subject-predicate" do
      statements = [
        # this statement should lead to an overwrite
        EX.S1 |> EX.p1(EX.O2),
        # this statement should NOT lead to an overwrite
        EX.S2 |> EX.p3("Foo")
      ]

      overwritten = EX.S1 |> EX.p1(EX.O1)

      assert Repo.effective_changeset!(update: statements) ==
               Changeset.new!(update: statements, overwrite: overwritten)
    end

    test "when the updated statements are ineffective, the other statements are still replaced" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      update = [new_statement, EX.S2 |> EX.p2(42)]

      assert Repo.effective_changeset!(update: update) ==
               Changeset.new!(
                 update: new_statement,
                 overwrite: EX.S2 |> EX.p2("Foo")
               )
    end
  end

  describe "replacements" do
    test "fully effective (when none of the replaced statements already exist)" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Repo.effective_changeset!(replace: statements) ==
               Changeset.new!(replace: statements)
    end

    test "partially effective (when some of the replaced statements already exist)" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      replace = [new_statement | Enum.take(graph(), 1)]

      assert Repo.effective_changeset!(replace: replace) ==
               Changeset.new!(replace: new_statement)
    end

    test "ineffective (when all of the replaced statements already exist)" do
      assert Repo.effective_changeset!(replace: graph()) == :no_effective_changes
    end

    test "deletes existing statements to the same subject" do
      statements = [
        EX.S1 |> EX.p1(EX.O2),
        EX.S2 |> EX.p3("Foo")
      ]

      assert Repo.effective_changeset!(replace: statements) ==
               Changeset.new!(
                 replace: statements,
                 overwrite: graph()
               )
    end

    test "when the replaced statements are ineffective, the other statements are still replaced" do
      new_statement = EX.Foo |> EX.bar(EX.Baz)
      replace = [new_statement, EX.S2 |> EX.p2(42)]

      assert Repo.effective_changeset!(replace: replace) ==
               Changeset.new!(
                 replace: new_statement,
                 overwrite: EX.S2 |> EX.p2("Foo")
               )
    end
  end

  describe "combined inserts and deletes" do
    test "fully effective" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Repo.effective_changeset!(insert: statements, delete: graph()) ==
               Changeset.new!(insert: statements, delete: graph())
    end

    test "partially effective" do
      non_existing_statements = EX.Foo |> EX.bar(EX.Baz1)
      new_statement = EX.Foo |> EX.bar(EX.Baz2)
      existing_statements = Enum.take(graph(), 1)
      insert = [new_statement | existing_statements]
      existing_delete_statements = Graph.delete(graph(), existing_statements)
      delete = [non_existing_statements, existing_delete_statements]

      assert Repo.effective_changeset!(insert: insert, delete: delete) ==
               Changeset.new!(
                 insert: new_statement,
                 delete: existing_delete_statements
               )
    end

    test "ineffective" do
      statements = EX.Foo |> EX.bar(EX.Baz)

      assert Repo.effective_changeset!(insert: graph(), delete: statements) ==
               :no_effective_changes
    end
  end
end
