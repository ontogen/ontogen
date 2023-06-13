defmodule Ontogen.CommitTest do
  use Ontogen.Test.Case

  doctest Ontogen.Commit

  alias Ontogen.{Commit, InvalidChangesetError}

  describe "new/1" do
    test "with all required attributes" do
      message = "Initial commit"

      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 insert: expression(),
                 committer: agent(),
                 message: message,
                 time: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = commit.__id__

      assert commit.insertion == expression()
      assert commit.committer == agent()
      assert commit.message == message
      assert commit.time == datetime()
      refute commit.parent
      assert Commit.root?(commit)
    end

    test "implicit expression creation" do
      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 insert: EX.S1 |> EX.p1(EX.O1),
                 delete: {EX.S2, EX.P2, EX.O2},
                 committer: agent(),
                 message: "Some commit",
                 time: datetime()
               )

      assert commit.insertion == expression(EX.S1 |> EX.p1(EX.O1))
      assert commit.deletion == expression({EX.S2, EX.P2, EX.O2})
    end

    test "shared insertion and deletion statement" do
      shared_statements = [{EX.s(), EX.p(), EX.o()}]

      assert Commit.new(
               insert: graph() |> Graph.add(shared_statements),
               delete: shared_statements,
               committer: agent(),
               message: "Inserted and deleted statement",
               time: datetime()
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
                )}
    end

    test "without statements" do
      assert Commit.new(
               committer: agent(),
               message: "without inserted and deleted statements",
               time: datetime()
             ) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end
  end
end
