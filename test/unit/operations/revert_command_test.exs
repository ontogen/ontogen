defmodule Ontogen.Operations.RevertCommandTest do
  use Ontogen.ServiceCase, async: false

  doctest Ontogen.Operations.RevertCommand

  alias Ontogen.{
    Commit,
    Config,
    InvalidChangesetError,
    InvalidCommitRangeError,
    EmptyRepositoryError
  }

  import Ontogen.IdUtils

  describe "Ontogen.revert/1" do
    test "when no commits specified" do
      assert Ontogen.revert(foo: :bar) ==
               {:error, EmptyRepositoryError.exception(repository: Ontogen.repository!())}
    end

    test "when nothing to revert" do
      [head, _third, _second, first] = init_history()

      assert Ontogen.revert(to: head) == {:error, "no commits to revert"}
      assert Ontogen.revert(range: {first, first}) == {:error, "no commits to revert"}
    end

    test "when nothing to revert effectively" do
      [_fourth, third, _second, _first] = init_history()

      assert {:ok, %Commit{}} = Ontogen.revert(to: third)

      assert Ontogen.revert(to: third) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end

    # TODO: This is a flaky test on Oxigraph due to this issue: https://github.com/oxigraph/oxigraph/issues/524
    test "head-relative" do
      [fourth, third, second, first] = history = init_history()
      original_dataset = Ontogen.dataset!()

      message = "Revert commit 1"

      assert {:ok, %Commit{} = revert1} =
               Ontogen.revert(
                 to: third,
                 committer: agent(),
                 message: message,
                 time: datetime(1)
               )

      assert revert1.committer == agent()
      assert revert1.time == datetime(1)
      assert revert1.message == message
      assert revert1.reverted_base_commit == third.__id__
      assert revert1.reverted_target_commit == fourth.__id__
      refute revert1.speech_act

      # updates the head in the dataset of the repo
      assert Ontogen.head() == revert1

      # updates the repo graph in the store
      assert Ontogen.repository!(stored: true) == Ontogen.repository!() |> flatten_property(:head)

      # inserts the uttered statements
      assert Ontogen.dataset() ==
               {:ok,
                RDF.graph([
                  EX.S2 |> EX.p2(42, "Foo"),
                  {EX.S3, EX.p3(), "foo"},
                  {EX.S4, EX.p4(), EX.O4}
                ])}

      # inserts the provenance
      assert Ontogen.log() ==
               {:ok, [revert1 | history]}

      ############# another revert (with defaults) ################

      assert {:ok, %Commit{} = revert2} = Ontogen.revert(to: first)

      assert revert2.committer == Config.user!()
      assert DateTime.diff(DateTime.utc_now(), revert2.time, :second) <= 1
      assert revert2.reverted_base_commit == first.__id__
      assert revert2.reverted_target_commit == revert1.__id__

      assert revert2.message ==
               """
               Revert of commits:

               - #{hash_from_iri(second.__id__)}
               - #{hash_from_iri(third.__id__)}
               - #{hash_from_iri(fourth.__id__)}
               - #{hash_from_iri(revert1.__id__)}
               """

      # updates the head in the dataset of the repo
      assert Ontogen.head() == revert2

      # inserts the uttered statements
      assert Ontogen.dataset() ==
               {:ok,
                RDF.graph([
                  EX.S1 |> EX.p1(EX.O1),
                  EX.S2 |> EX.p2(42, "Foo")
                ])}

      # inserts the provenance
      assert Ontogen.log() ==
               {:ok, [revert2, revert1 | history]}

      ############# another revert: reverting other reverts ################

      assert {:ok, %Commit{} = revert3} = Ontogen.revert(to: fourth)

      assert revert3.reverted_base_commit == fourth.__id__
      assert revert3.reverted_target_commit == revert2.__id__

      assert revert3.message ==
               """
               Revert of commits:

               - #{hash_from_iri(revert1.__id__)}
               - #{hash_from_iri(revert2.__id__)}
               """

      # updates the head in the dataset of the repo
      assert Ontogen.head() == revert3

      # inserts the uttered statements
      assert Ontogen.dataset!() == original_dataset

      # inserts the provenance
      assert Ontogen.log() ==
               {:ok, [revert3, revert2, revert1 | history]}

      ############# another revert: revert all ################

      assert {:ok, %Commit{} = revert4} = Ontogen.revert(to: :root)

      assert revert4.reverted_base_commit == Commit.root()
      assert revert4.reverted_target_commit == revert3.__id__

      # updates the head in the dataset of the repo
      assert Ontogen.head() == revert4

      # inserts the uttered statements
      assert Ontogen.dataset() == {:ok, RDF.graph()}

      # inserts the provenance
      assert Ontogen.log() ==
               {:ok, [revert4, revert3, revert2, revert1 | history]}
    end

    test "a non-head relative range" do
      [_fourth, third, second, first] = history = init_history()

      assert {:ok, %Commit{} = revert1} =
               Ontogen.revert(
                 range: {first, third},
                 time: datetime(1)
               )

      assert revert1.committer == Config.user!()
      assert revert1.time == datetime(1)
      assert revert1.reverted_base_commit == first.__id__
      assert revert1.reverted_target_commit == third.__id__
      refute revert1.speech_act

      assert revert1.message ==
               """
               Revert of commits:

               - #{hash_from_iri(second.__id__)}
               - #{hash_from_iri(third.__id__)}
               """

      # updates the head in the dataset of the repo
      assert Ontogen.head() == revert1

      # updates the repo graph in the store
      assert Ontogen.repository!(stored: true) == Ontogen.repository!() |> flatten_property(:head)

      # inserts the uttered statements
      assert Ontogen.dataset() ==
               {:ok,
                RDF.graph([
                  EX.S1 |> EX.p1(EX.O1),
                  EX.S2 |> EX.p2(42, "Foo"),
                  {EX.S5, EX.p5(), EX.O5}
                ])}

      # inserts the provenance
      assert Ontogen.log() ==
               {:ok, [revert1 | history]}
    end

    test "a range ending at the head" do
      [fourth, third, _second, _first] = init_history()

      assert {:ok, %Commit{} = revert} =
               Ontogen.revert(range: {third, fourth}, time: datetime(1))

      assert revert.reverted_base_commit == third.__id__
      assert revert.reverted_target_commit == fourth.__id__
    end

    test "base-relative range" do
      [fourth, third, _second, _first] = history = init_history()

      assert {:ok, %Commit{} = revert1} =
               Ontogen.revert(
                 to: 1,
                 time: datetime(1)
               )

      assert revert1.reverted_base_commit == third.__id__
      assert revert1.reverted_target_commit == fourth.__id__

      assert {:ok, %Commit{} = revert2} =
               Ontogen.revert(
                 to: 5,
                 time: datetime(2)
               )

      assert revert2.reverted_base_commit == Commit.root()
      assert revert2.reverted_target_commit == revert1.__id__

      assert {:ok, %Commit{} = revert3} =
               Ontogen.revert(
                 to: 3,
                 time: datetime(3)
               )

      assert revert3.reverted_base_commit == third.__id__
      assert revert3.reverted_target_commit == revert2.__id__

      assert revert3.message ==
               """
               Revert of commits:

               - #{hash_from_iri(fourth.__id__)}
               - #{hash_from_iri(revert1.__id__)}
               - #{hash_from_iri(revert2.__id__)}
               """

      assert Ontogen.log() ==
               {:ok, [revert3, revert2, revert1 | history]}
    end

    test "a directly given commit" do
      [_fourth, third, second, _first] = init_history()
      original_dataset = Ontogen.dataset!()

      assert {:ok, %Commit{} = revert1} = Ontogen.revert(commit: third)

      assert revert1.reverted_base_commit == second.__id__
      assert revert1.reverted_target_commit == third.__id__

      assert {:ok, %Commit{} = revert2} = Ontogen.revert(commit: revert1.__id__)

      assert revert2.reverted_base_commit == revert1.parent
      assert revert2.reverted_target_commit == revert1.__id__

      assert Ontogen.dataset!() == original_dataset
    end

    test "with commit not part of the history" do
      history = init_history()
      independent_commit = commit()

      refute independent_commit in history

      assert Ontogen.revert(commit: independent_commit) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}

      assert Ontogen.revert(to: independent_commit) ==
               {:error, %InvalidCommitRangeError{reason: :out_of_range}}
    end

    test "nil is not allowed as base" do
      init_history()

      assert Ontogen.revert(to: nil) ==
               {:error, %InvalidCommitRangeError{reason: "nil is not a valid value for base"}}

      assert Ontogen.revert(base: nil) ==
               {:error, %InvalidCommitRangeError{reason: "nil is not a valid value for base"}}
    end

    defp init_history do
      graph = [
        EX.S1 |> EX.p1(EX.O1),
        EX.S2 |> EX.p2(42, "Foo")
      ]

      init_commit_history([
        [
          add: graph,
          message: "Initial commit"
        ],
        [
          # this leads to a different effective change
          add: [{EX.S3, EX.p3(), "foo"}],
          remove: EX.S1 |> EX.p1(EX.O1),
          committer: agent(:agent_jane),
          message: "Second commit"
        ],
        [
          # this leads to a different effective change
          add: [{EX.S4, EX.p4(), EX.O4}, {EX.S3, EX.p3(), "foo"}],
          message: "Third commit"
        ],
        [
          # this leads to a different effective change
          update: [{EX.S5, EX.p5(), EX.O5}, graph],
          message: "Fourth commit"
        ]
      ])
    end
  end
end
