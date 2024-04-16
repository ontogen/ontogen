defmodule Ontogen.CommitTest do
  use OntogenCase

  doctest Ontogen.Commit

  alias Ontogen.{Commit, Proposition, Config, InvalidChangesetError}

  test "id stability" do
    assert {:ok,
            %Commit{
              __id__: %IRI{
                value:
                  "urn:hash::sha256:0db70c636f5b2e0a8271fc94ad9319ae5e2645fc68008a3d1cd6436a0126efd5"
              }
            }} =
             Commit.new(
               speech_act: speech_act(),
               add: proposition(1),
               update: proposition(2),
               replace: proposition(3),
               remove: proposition(4),
               overwrite: proposition(5),
               committer: agent(),
               message: "Initial commit",
               time: datetime()
             )

    assert {:ok,
            %Commit{
              __id__: %IRI{
                value:
                  "urn:hash::sha256:c6fa7aecf65d0b862552e61c5987c13eb9c1ee552698801b28051808d6a405d9"
              }
            }} =
             Commit.new(
               speech_act: speech_act(),
               add: proposition(1),
               committer: agent(),
               message: "Initial commit",
               time: datetime()
             )

    assert {:ok,
            %Commit{
              __id__: %IRI{
                value:
                  "urn:hash::sha256:f2a583167b850ea127fd0628d5b18445b51879bf2481e9a1590b7937dfeb4c4d"
              }
            }} =
             Commit.new(
               parent: commit(),
               speech_act: speech_act(),
               add: proposition(1),
               update: proposition(2),
               replace: proposition(3),
               remove: proposition(4),
               overwrite: proposition(5),
               committer: agent(),
               message: "Initial commit",
               time: datetime()
             )
  end

  describe "new/1" do
    test "with all required attributes" do
      message = "Initial commit"

      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 speech_act: speech_act(),
                 add: proposition(),
                 committer: agent(),
                 message: message,
                 time: datetime()
               )

      assert %IRI{value: "urn:hash::sha256:" <> _} = commit.__id__

      assert commit.add == proposition()
      assert commit.speech_act == speech_act()
      assert commit.committer == agent()
      assert commit.message == message
      assert commit.time == datetime()
      assert commit.parent == Commit.root()
      assert Commit.root?(commit)
    end

    test "uses proper defaults" do
      assert {:ok, %Commit{} = commit} = Commit.new(add: graph(), speech_act: speech_act())

      assert commit.add == proposition()
      assert DateTime.diff(DateTime.utc_now(), commit.time, :second) <= 1
      assert commit.committer == Config.user()
    end

    test "implicit proposition creation" do
      assert {:ok, %Commit{} = commit} =
               Commit.new(
                 speech_act: speech_act(),
                 add: EX.S1 |> EX.p1(EX.O1),
                 remove: {EX.S2, EX.P2, EX.O2},
                 committer: agent(),
                 message: "Some commit",
                 time: datetime()
               )

      assert commit.add == proposition(EX.S1 |> EX.p1(EX.O1))
      assert commit.remove == proposition({EX.S2, EX.P2, EX.O2})
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

      assert commit.add == commit_changeset().add |> Proposition.new!()
      assert commit.remove == commit_changeset().remove |> Proposition.new!()
      assert commit.update == commit_changeset().update
      assert commit.replace == commit_changeset().replace
      assert commit.speech_act == speech_act()
    end

    test "shared add and remove statement" do
      shared_statements = [{EX.s(), EX.p(), EX.o()}]

      assert Commit.new(
               speech_act: speech_act(),
               add: graph() |> Graph.add(shared_statements),
               remove: shared_statements,
               committer: agent(),
               message: "Inserted and removed statement",
               time: datetime()
             ) ==
               {:error,
                InvalidChangesetError.exception(
                  reason:
                    "the following statements are in both add and remove: #{inspect(shared_statements)}"
                )}
    end

    test "without statements" do
      assert Commit.new(
               speech_act: speech_act(),
               committer: agent(),
               message: "without added and removed statements",
               time: datetime()
             ) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end

    test "without speech act" do
      assert {:error, "missing speech_act in commit" <> _} =
               Commit.new(
                 add: graph(),
                 committer: agent(),
                 message: "without speech act",
                 time: datetime()
               )
    end
  end
end
