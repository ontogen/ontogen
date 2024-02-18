defmodule Ontogen.CommitTest do
  use OntogenCase

  doctest Ontogen.Commit

  alias Ontogen.{Commit, Proposition, InvalidChangesetError}

  describe "new/1" do
    test "with all required attributes" do
      message = "Initial commit"

      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 speech_act: speech_act(),
                 insert: proposition(),
                 committer: agent(),
                 message: message,
                 time: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = commit.__id__

      assert commit.insert == proposition()
      assert commit.speech_act == speech_act()
      assert commit.committer == agent()
      assert commit.message == message
      assert commit.time == datetime()
      refute commit.parent
      assert Commit.root?(commit)
    end

    test "implicit proposition creation" do
      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 speech_act: speech_act(),
                 insert: EX.S1 |> EX.p1(EX.O1),
                 delete: {EX.S2, EX.P2, EX.O2},
                 committer: agent(),
                 message: "Some commit",
                 time: datetime()
               )

      assert commit.insert == proposition(EX.S1 |> EX.p1(EX.O1))
      assert commit.delete == proposition({EX.S2, EX.P2, EX.O2})
      assert commit.speech_act == speech_act()
    end

    test "with changeset" do
      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 speech_act: speech_act(),
                 changeset: commit_changeset(),
                 committer: agent(),
                 message: "Some commit",
                 time: datetime()
               )

      assert commit.insert == commit_changeset().insert |> Proposition.new!()
      assert commit.delete == commit_changeset().delete |> Proposition.new!()
      assert commit.update == commit_changeset().update
      assert commit.replace == commit_changeset().replace
      assert commit.speech_act == speech_act()
    end

    test "shared insert and delete statement" do
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
                    "the following statements are in both insert and delete: #{inspect(shared_statements)}"
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
