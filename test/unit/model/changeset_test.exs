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

    test ":insert and :delete statements" do
      assert Changeset.new(insert: graph(), delete: EX.S |> EX.p(EX.O)) ==
               {:ok,
                %Changeset{
                  insertion: Expression.new!(graph()),
                  deletion: Expression.new!(EX.S |> EX.p(EX.O))
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

    test "shared insertion and deletion statement" do
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
    end
  end
end
