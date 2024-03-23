defmodule Ontogen.Operations.RevertCommandTest do
  use Ontogen.RepositoryCase, async: false

  doctest Ontogen.Operations.RevertCommand

  alias Ontogen.{Commit, Config, InvalidChangesetError}
  import Ontogen.IdUtils

  describe "Ontogen.revert/1" do
    test "when no commits specified" do
      assert Ontogen.revert(foo: :bar) == {:error, "no commits to revert specified"}
    end

    test "when nothing to revert" do
      [head, _third, _second, _first] = init_history()

      assert Ontogen.revert(to: head) == {:error, "no commits to revert"}
    end

    test "when nothing to revert effectively" do
      [_fourth, third, _second, _first] = init_history()

      assert {:ok, %Commit{}} = Ontogen.revert(to: third)

      assert Ontogen.revert(to: third) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end

    # TODO: This is a flaky test on Oxigraph due to this issue: https://github.com/oxigraph/oxigraph/issues/524
    test "head-relative" do
      [fourth, third, _second, first] = history = init_history()
      original_dataset = Ontogen.dataset()

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
      refute revert1.reverted_target_commit
      refute revert1.speech_act

      # updates the head in the dataset of the repo
      assert Ontogen.head() == revert1

      # updates the repo graph in the store
      assert Ontogen.repository() |> flatten_property(:head) == stored_repo()

      # inserts the uttered statements
      assert Ontogen.dataset() ==
               {:ok,
                RDF.graph([
                  EX.S2 |> EX.p2(42, "Foo"),
                  {EX.S3, EX.p3(), "foo"},
                  {EX.S4, EX.p4(), EX.O4}
                ])}

      # inserts the provenance
      assert Ontogen.dataset_history() ==
               {:ok, [revert1 | history]}

      ############# another revert (with defaults) ################

      assert {:ok, %Commit{} = revert2} = Ontogen.revert(to: first)

      assert revert2.committer == Config.agent()
      assert DateTime.diff(DateTime.utc_now(), revert2.time, :second) <= 1
      assert revert2.reverted_base_commit == first.__id__
      refute revert2.reverted_target_commit

      assert revert2.message ==
               """
               Revert of commits:

               - 8806b0d970677c1826ab00e6c8d64e96c7039e0a34296b3e81066052490c84b8
               - 8edcb85143fd1adee3f201ed78e0f2dc0437373d7865cce33675c0cc4270ec98
               - 2a78b53e5b0fe4e493776af840a8613bcbe7f37e91092e44ec13ff85f844c286
               - 8855cfb8509d8f4c9519f8163f94d7153c26aa03616f53c19fea32f04447ab7e
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
      assert Ontogen.dataset_history() ==
               {:ok, [revert2, revert1 | history]}

      ############# another revert: reverting other reverts ################

      assert {:ok, %Commit{} = revert3} = Ontogen.revert(to: fourth)

      assert revert3.reverted_base_commit == fourth.__id__
      refute revert3.reverted_target_commit

      assert revert3.message ==
               """
               Revert of commits:

               - #{hash_from_iri(revert1.__id__)}
               - #{hash_from_iri(revert2.__id__)}
               """

      # updates the head in the dataset of the repo
      assert Ontogen.head() == revert3

      # inserts the uttered statements
      assert Ontogen.dataset() == original_dataset

      # inserts the provenance
      assert Ontogen.dataset_history() ==
               {:ok, [revert3, revert2, revert1 | history]}
    end

    test "a non-head relative range" do
      [_fourth, third, second, first] = history = init_history()

      assert {:ok, %Commit{} = revert1} =
               Ontogen.revert(
                 range: {first, third},
                 time: datetime(1)
               )

      assert revert1.committer == Config.agent()
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
      assert Ontogen.repository() |> flatten_property(:head) == stored_repo()

      # inserts the uttered statements
      assert Ontogen.dataset() ==
               {:ok,
                RDF.graph([
                  EX.S1 |> EX.p1(EX.O1),
                  EX.S2 |> EX.p2(42, "Foo"),
                  {EX.S5, EX.p5(), EX.O5}
                ])}

      # inserts the provenance
      assert Ontogen.dataset_history() ==
               {:ok, [revert1 | history]}
    end

    test "a range ending at the head" do
      [fourth, third, _second, _first] = init_history()

      assert {:ok, %Commit{} = revert} =
               Ontogen.revert(range: {third, fourth}, time: datetime(1))

      assert revert.reverted_base_commit == third.__id__
      refute revert.reverted_target_commit
    end

    test "a directly given commit" do
      [_fourth, third, _second, _first] = init_history()
      original_dataset = Ontogen.dataset()

      assert {:ok, %Commit{} = revert1} = Ontogen.revert(commit: third)

      refute revert1.reverted_base_commit
      assert revert1.reverted_target_commit == third.__id__

      assert {:ok, %Commit{} = revert2} = Ontogen.revert(commit: revert1)

      assert revert2.reverted_base_commit == revert1.parent
      refute revert2.reverted_target_commit

      assert Ontogen.dataset() == original_dataset
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
