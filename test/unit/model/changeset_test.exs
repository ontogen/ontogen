defmodule Ontogen.ChangesetTest do
  use Ontogen.Test.Case

  doctest Ontogen.Changeset

  alias Ontogen.{Changeset, Expression, InvalidChangesetError}

  @statement_forms [
    {EX.S, EX.p(), EX.O},
    [{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}],
    EX.S |> EX.p(EX.O),
    graph()
  ]

  describe "new/1" do
    test ":insert statements in various forms" do
      Enum.each(@statement_forms, fn statements ->
        assert Changeset.new(insert: statements) ==
                 {:ok, %Changeset{insertion: statements |> RDF.graph() |> Expression.new!()}}
      end)
    end

    test ":delete statements in various forms" do
      Enum.each(@statement_forms, fn statements ->
        assert Changeset.new(delete: statements) ==
                 {:ok, %Changeset{deletion: statements |> RDF.graph() |> Expression.new!()}}
      end)
    end

    test "multiple :delete statements" do
      other_delete = EX.Foo |> EX.bar(42)

      Enum.each(@statement_forms, fn statements ->
        assert Changeset.new(delete: statements, delete: other_delete) ==
                 {:ok,
                  %Changeset{
                    deletion: [
                      statements |> RDF.graph() |> Expression.new!(),
                      Expression.new!(other_delete)
                    ]
                  }}
      end)
    end

    test "empty :deletes" do
      assert Changeset.new(update: graph(), delete: nil, delete: nil) ==
               {:ok, %Changeset{update: Expression.new!(graph()), deletion: nil}}

      assert Changeset.new(delete: nil, delete: nil, delete: graph()) ==
               {:ok, %Changeset{deletion: Expression.new!(graph())}}
    end

    test ":update statements in various forms" do
      Enum.each(@statement_forms, fn statements ->
        assert Changeset.new(update: statements) ==
                 {:ok, %Changeset{update: statements |> RDF.graph() |> Expression.new!()}}
      end)
    end

    test ":replace statements in various forms" do
      Enum.each(@statement_forms, fn statements ->
        assert Changeset.new(replace: statements) ==
                 {:ok, %Changeset{replacement: statements |> RDF.graph() |> Expression.new!()}}
      end)
    end

    test ":insert and :delete statements" do
      assert Changeset.new(insert: graph(), delete: EX.S |> EX.p(EX.O)) ==
               {:ok,
                %Changeset{
                  insertion: Expression.new!(graph()),
                  deletion: Expression.new!(EX.S |> EX.p(EX.O))
                }}
    end

    test ":insert, :delete, :update and replace statements" do
      delete = EX.S |> EX.p(EX.O)
      update = EX.Foo1 |> EX.bar1(42)
      replace = EX.Foo2 |> EX.bar2("baz")

      assert Changeset.new(insert: graph(), delete: delete, update: update, replace: replace) ==
               {:ok,
                %Changeset{
                  insertion: Expression.new!(graph()),
                  deletion: Expression.new!(delete),
                  update: Expression.new!(update),
                  replacement: Expression.new!(replace)
                }}
    end

    test "without statements" do
      assert Changeset.new(insert: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(delete: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(insert: []) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(delete: []) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end

    test "with a utterance" do
      assert Changeset.new(utterance()) ==
               {:ok, %Changeset{insertion: Expression.new!(graph())}}
    end

    test "with a changeset" do
      assert Changeset.new(changeset()) == {:ok, changeset()}
    end

    test "overlapping insertion and deletion statements" do
      shared_statements = [{EX.s(), EX.p(), EX.o()}]

      assert Changeset.new(
               insert: graph() |> Graph.add(shared_statements),
               delete: shared_statements
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
                )}

      assert Changeset.new(
               update: graph() |> Graph.add(shared_statements),
               delete: shared_statements
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
                )}

      assert Changeset.new(
               replace: graph() |> Graph.add(shared_statements),
               delete: shared_statements
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
                )}
    end

    test "overlapping insertion and deletion statements when multiple deletions" do
      shared_statements = [{EX.s(), EX.p(), EX.o()}]
      other_delete = EX.Foo1 |> EX.bar1(42)

      assert Changeset.new(
               insert: graph() |> Graph.add(shared_statements),
               delete: shared_statements,
               delete: other_delete
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
                )}

      assert Changeset.new(
               insert: graph() |> Graph.add(shared_statements),
               delete: other_delete,
               delete: shared_statements
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
                )}
    end

    test "overlapping insertion statements" do
      shared_statements = [{EX.s(), EX.p(), EX.o()}]

      assert Changeset.new(
               insert: graph() |> Graph.add(shared_statements),
               update: shared_statements
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in multiple insertions: #{inspect(shared_statements)}"
                )}

      assert Changeset.new(
               insert: shared_statements,
               replace: graph() |> Graph.add(shared_statements)
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in multiple insertions: #{inspect(shared_statements)}"
                )}

      assert Changeset.new(
               update: graph() |> Graph.add(shared_statements),
               replace: shared_statements
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in multiple insertions: #{inspect(shared_statements)}"
                )}
    end

    test "overlapping insertion patterns" do
      insert1 = {EX.s(), EX.p(), EX.o1()}
      insert2 = {EX.s(), EX.p(), EX.o2()}

      assert Changeset.new(
               replace: graph() |> Graph.add(insert1),
               update: insert2
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following update statements overlap with replace overwrites: #{inspect([insert2])}"
                )}

      assert Changeset.new(
               insert: graph() |> Graph.add(insert1),
               replace: insert2
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following insert statements overlap with replace overwrites: #{inspect([insert1])}"
                )}

      assert Changeset.new(
               insert: graph() |> Graph.add(insert1),
               update: insert2
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following insert statements overlap with update overwrites: #{inspect([insert1])}"
                )}

      assert Changeset.new(
               update: graph() |> Graph.add(insert1),
               insert: insert2
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following insert statements overlap with update overwrites: #{inspect([insert2])}"
                )}

      assert {:ok, %Changeset{}} =
               Changeset.new(
                 insert: graph() |> Graph.add(insert1),
                 update: {EX.s(), EX.p2(), EX.o2()}
               )

      assert {:ok, %Changeset{}} =
               Changeset.new(
                 update: graph() |> Graph.add(insert1),
                 insert: {EX.s(), EX.p2(), EX.o2()}
               )
    end
  end
end
