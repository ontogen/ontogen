defmodule Ontogen.CommitTest do
  use Ontogen.Test.Case

  doctest Ontogen.Commit

  alias Ontogen.{Commit, InvalidCommitError}

  describe "new/1" do
    test "with all required attributes" do
      message = "Initial commit"

      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 insertion: expression(),
                 committer: agent(),
                 message: message,
                 ended_at: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = commit.__id__

      assert commit.insertion == expression()
      assert commit.committer == agent()
      assert commit.message == message
      assert commit.ended_at == datetime()
      refute commit.parent
      assert Commit.root?(commit)
    end

    test "implicit expression creation" do
      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 insertion: EX.S1 |> EX.p1(EX.O1),
                 deletion: {EX.S2, EX.P2, EX.O2},
                 committer: agent(),
                 message: "Some commit",
                 ended_at: datetime()
               )

      assert commit.insertion == expression(EX.S1 |> EX.p1(EX.O1))
      assert commit.deletion == expression({EX.S2, EX.P2, EX.O2})
    end

    test "shared insertion and deletion statement" do
      shared_statements = [{EX.s(), EX.p(), EX.o()}]

      assert Commit.new(
               insertion: graph() |> Graph.add(shared_statements),
               deletion: shared_statements,
               committer: agent(),
               message: "Inserted and deleted statement",
               ended_at: datetime()
             ) ==
               {:error,
                InvalidCommitError.exception(
                  reason:
                    "the following statements are in both insertion and deletions: #{inspect(shared_statements)}"
                )}
    end
  end
end
