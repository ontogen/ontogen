defmodule Ontogen.Commit.ChangesetTest do
  use OntogenCase

  doctest Ontogen.Commit.Changeset

  alias Ontogen.Commit.Changeset
  alias Ontogen.InvalidChangesetError

  @statement_forms [
    {EX.S, EX.p(), EX.O},
    [{EX.S1, EX.p1(), EX.O1}, {EX.S2, EX.p2(), EX.O2}],
    EX.S |> EX.p(EX.O),
    graph()
  ]

  describe "new/1" do
    test "with a keyword list" do
      assert Changeset.new(
               add: statement(1),
               update: statement(2),
               replace: statement(3),
               remove: statement(4),
               overwrite: statement(5)
             ) ==
               {:ok,
                %Changeset{
                  add: graph([1]),
                  update: graph([2]),
                  replace: graph([3]),
                  remove: graph([4]),
                  overwrite: graph([5])
                }}
    end

    test "with an action map" do
      assert Changeset.new(%{add: graph([1]), remove: statement(2)}) ==
               {:ok,
                %Changeset{
                  add: graph([1]),
                  remove: graph([2])
                }}
    end

    test "with a commit" do
      assert Changeset.new(commit(add: statement(1))) ==
               {:ok, %Changeset{add: graph([1])}}
    end

    test "with a speech act" do
      assert Changeset.new(speech_act()) ==
               {:ok, %Changeset{add: graph()}}
    end

    test "with a changeset" do
      assert Changeset.new(commit_changeset()) == {:ok, commit_changeset()}
    end

    test "statements in various forms" do
      Enum.each(@statement_forms, fn statements ->
        assert Changeset.new(add: statements) ==
                 {:ok, %Changeset{add: RDF.graph(statements)}}

        assert Changeset.new(remove: statements) ==
                 {:ok, %Changeset{remove: RDF.graph(statements)}}

        assert Changeset.new(update: statements) ==
                 {:ok, %Changeset{update: RDF.graph(statements)}}

        assert Changeset.new(replace: statements) ==
                 {:ok, %Changeset{replace: RDF.graph(statements)}}
      end)
    end

    test "without statements" do
      assert Changeset.new(add: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(remove: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(update: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(replace: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end

    test "validates the changeset" do
      assert {:error, %InvalidChangesetError{}} =
               Changeset.new(add: statement(1), remove: statement(1))
    end
  end

  describe "extract/1" do
    test "with direct action keys" do
      assert Changeset.extract(add: graph([1]), remove: statement(2), foo: :bar) ==
               {:ok,
                %Changeset{
                  add: graph([1]),
                  remove: graph([2])
                }, [foo: :bar]}
    end

    test "with a :changeset value and no direct action keys" do
      assert Changeset.extract(changeset: [add: graph([1]), remove: statement(2)], foo: :bar) ==
               {:ok,
                %Changeset{
                  add: graph([1]),
                  remove: graph([2])
                }, [foo: :bar]}
    end

    test "with a :changeset value and direct action keys" do
      assert Changeset.extract(changeset: [add: graph([1])], remove: statement(2), foo: :bar) ==
               {
                 :error,
                 InvalidChangesetError.exception(
                   reason: ":changeset can not be used along additional changes"
                 )
               }
    end
  end

  describe "merge/2" do
    test "single add" do
      assert [
               add: statement(1),
               remove: statements([2, 6]),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(add: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 add: graph([1, 2, 5]),
                 remove: graph([6]),
                 update: graph([3]),
                 replace: graph([4]),
                 overwrite: nil
               )
    end

    test "single update" do
      assert [
               add: statements([1, 6]),
               remove: statement(2),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(update: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 add: graph([6]),
                 remove: nil,
                 update: graph([1, 2, 3, 5]),
                 replace: graph([4]),
                 overwrite: nil
               )
    end

    test "single replace" do
      assert [
               add: statement(1),
               remove: statement(2),
               update: statements([3, 6]),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(replace: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 add: nil,
                 remove: nil,
                 update: graph([6]),
                 replace: graph([1, 2, 3, 4, 5]),
                 overwrite: nil
               )
    end

    test "single remove" do
      assert [
               add: statements([1, 6]),
               remove: statement(2),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(remove: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 add: graph([6]),
                 remove: graph([1, 2, 5, 3, 4]),
                 update: nil,
                 replace: nil,
                 overwrite: nil
               )
    end

    test "single overwrite" do
      assert [
               add: statement(1),
               remove: statement(2),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(overwrite: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 add: nil,
                 remove: nil,
                 update: nil,
                 replace: nil,
                 overwrite: graph([1, 2, 5, 3, 4])
               )
    end

    test "disjunctive changesets" do
      assert [
               add: statement(:S1_1),
               update: statement(:S2_1),
               replace: statement(:S3_1),
               remove: statement(:S4_1),
               overwrite: statement(:S5_1)
             ]
             |> Changeset.merge(
               add: statement(:S1_2),
               update: statement(:S2_2),
               replace: statement(:S3_2),
               remove: statement(:S4_2),
               overwrite: statement(:S5_2)
             ) ==
               Changeset.new!(
                 add: graph([:S1_1, :S1_2]),
                 update: graph([:S2_1, :S2_2]),
                 replace: graph([:S3_1, :S3_2]),
                 remove: graph([:S4_1, :S4_2]),
                 overwrite: graph([:S5_1, :S5_2])
               )
    end

    test "equal changesets" do
      changeset =
        [
          add: graph([1]),
          update: graph([2]),
          replace: graph([3]),
          remove: graph([4]),
          overwrite: graph([5])
        ]

      assert Changeset.merge(changeset, changeset) ==
               Changeset.new!(changeset)
    end

    test "add overlap resolution" do
      assert [
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.add_remove_overlap(), EX.p(), EX.o()},
                 {EX.add_update_overlap(), EX.p(), EX.o()},
                 {EX.add_replace_overlap(), EX.p(), EX.o()},
                 {EX.add_overwrite_overlap(), EX.p(), EX.o()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s(), EX.remove_add_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s(), EX.p(), EX.update_add_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_add_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s(), EX.p(), EX.overwrite_add_overlap()}
               ]
             ]
             |> Changeset.merge(
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s(), EX.remove_add_overlap(), EX.o()},
                 {EX.s(), EX.p(), EX.update_add_overlap()},
                 {EX.replace_add_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.p(), EX.overwrite_add_overlap()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.add_remove_overlap(), EX.p(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.add_update_overlap(), EX.p(), EX.o()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.add_replace_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                 {EX.add_overwrite_overlap(), EX.p(), EX.o()}
               ]
             ) ==
               %Changeset{
                 add:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s(), EX.remove_add_overlap(), EX.o()},
                     {EX.s(), EX.p(), EX.overwrite_add_overlap()}
                   ]),
                 remove:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.add_remove_overlap(), EX.p(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.add_update_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.update_add_overlap()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.add_replace_overlap(), EX.p(), EX.o()},
                     {EX.replace_add_overlap(), EX.p(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.add_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               }
    end

    test "update overlap resolution" do
      assert [
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.add_update_overlap(), EX.p(), EX.o()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2(), EX.remove_update_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s1(), EX.p1(), EX.update_add_overlap()},
                 {EX.s2(), EX.p2(), EX.update_remove_overlap()},
                 {EX.s4(), EX.p4(), EX.update_replace_overlap()},
                 {EX.s5(), EX.p5(), EX.update_overwrite_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_update_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
               ]
             ]
             |> Changeset.merge(
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s1(), EX.p1(), EX.update_add_overlap()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.s2(), EX.p2(), EX.update_remove_overlap()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.add_update_overlap(), EX.p(), EX.o()},
                 {EX.s2(), EX.remove_update_overlap(), EX.o()},
                 {EX.replace_update_overlap(), EX.p(), EX.o()},
                 {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.s4(), EX.p4(), EX.update_replace_overlap()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                 {EX.s5(), EX.p5(), EX.update_overwrite_overlap()}
               ]
             ) ==
               Changeset.new!(
                 add:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()}
                   ]),
                 remove:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.s2(), EX.p2(), EX.update_remove_overlap()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.add_update_overlap(), EX.p(), EX.o()},
                     {EX.s2(), EX.remove_update_overlap(), EX.o()},
                     {EX.s3(), EX.p3(), EX.overwrite_update_overlap()},
                     {EX.s1(), EX.p1(), EX.update_add_overlap()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.s4(), EX.p4(), EX.update_replace_overlap()},
                     {EX.replace_update_overlap(), EX.p(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.s5(), EX.p5(), EX.update_overwrite_overlap()}
                   ])
               )
    end

    test "replace overlap resolution" do
      assert [
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.add_replace_overlap(), EX.p(), EX.o()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s(), EX.remove_replace_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s(), EX.p(), EX.update_replace_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_add_overlap(), EX.p(), EX.o()},
                 {EX.replace_remove_overlap(), EX.p(), EX.o()},
                 {EX.replace_update_overlap(), EX.p(), EX.o()},
                 {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s(), EX.p(), EX.overwrite_replace_overlap()}
               ]
             ]
             |> Changeset.merge(
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.replace_add_overlap(), EX.p(), EX.o()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.replace_remove_overlap(), EX.p(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.replace_update_overlap(), EX.p(), EX.o()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.add_replace_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.remove_replace_overlap(), EX.o()},
                 {EX.s(), EX.p(), EX.update_replace_overlap()},
                 {EX.s(), EX.p(), EX.overwrite_replace_overlap()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                 {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
               ]
             ) ==
               Changeset.new!(
                 add:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()}
                   ]),
                 remove:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.replace_remove_overlap(), EX.p(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.add_replace_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.remove_replace_overlap(), EX.o()},
                     {EX.s(), EX.p(), EX.update_replace_overlap()},
                     {EX.s(), EX.p(), EX.overwrite_replace_overlap()},
                     {EX.replace_add_overlap(), EX.p(), EX.o()},
                     {EX.replace_update_overlap(), EX.p(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               )
    end

    test "remove overlap resolution" do
      assert [
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.add_remove_overlap(), EX.p(), EX.o()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s1(), EX.remove_add_overlap(), EX.o()},
                 {EX.s3(), EX.remove_update_overlap(), EX.o()},
                 {EX.s4(), EX.remove_replace_overlap(), EX.o()},
                 {EX.s5(), EX.remove_overwrite_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s(), EX.p(), EX.update_remove_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_remove_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s(), EX.p(), EX.overwrite_remove_overlap()}
               ]
             ]
             |> Changeset.merge(
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s1(), EX.remove_add_overlap(), EX.o()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.add_remove_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.p(), EX.update_remove_overlap()},
                 {EX.replace_remove_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.p(), EX.overwrite_remove_overlap()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.s3(), EX.remove_update_overlap(), EX.o()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.s4(), EX.remove_replace_overlap(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                 {EX.s5(), EX.remove_overwrite_overlap(), EX.o()}
               ]
             ) ==
               Changeset.new!(
                 add:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s1(), EX.remove_add_overlap(), EX.o()}
                   ]),
                 remove:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.add_remove_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.update_remove_overlap()},
                     {EX.replace_remove_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.overwrite_remove_overlap()}
                     #                     {EX.s5(), EX.remove_overwrite_overlap(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.s3(), EX.remove_update_overlap(), EX.o()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.s4(), EX.remove_replace_overlap(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.s5(), EX.remove_overwrite_overlap(), EX.o()}
                   ])
               )
    end

    test "overwrite overlap resolution" do
      assert [
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.add_overwrite_overlap(), EX.p(), EX.o()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2(), EX.remove_overwrite_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3(), EX.p3(), EX.update_overwrite_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s1(), EX.p1(), EX.overwrite_add_overlap()},
                 {EX.s2(), EX.p2(), EX.overwrite_remove_overlap()},
                 {EX.s3(), EX.p3(), EX.overwrite_update_overlap()},
                 {EX.s4(), EX.p4(), EX.overwrite_replace_overlap()}
               ]
             ]
             |> Changeset.merge(
               add: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s1(), EX.p1(), EX.overwrite_add_overlap()}
               ],
               remove: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.s2(), EX.p2(), EX.overwrite_remove_overlap()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.s4(), EX.p4(), EX.overwrite_replace_overlap()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                 {EX.add_overwrite_overlap(), EX.p(), EX.o()},
                 {EX.s2(), EX.remove_overwrite_overlap(), EX.o()},
                 {EX.s3(), EX.p3(), EX.update_overwrite_overlap()},
                 {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
               ]
             ) ==
               Changeset.new!(
                 add:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s1(), EX.p1(), EX.overwrite_add_overlap()}
                   ]),
                 remove:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.s2(), EX.p2(), EX.overwrite_remove_overlap()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.s3(), EX.p3(), EX.overwrite_update_overlap()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.s4(), EX.p4(), EX.overwrite_replace_overlap()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.add_overwrite_overlap(), EX.p(), EX.o()},
                     {EX.s2(), EX.remove_overwrite_overlap(), EX.o()},
                     {EX.s3(), EX.p3(), EX.update_overwrite_overlap()},
                     {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               )
    end

    test "empty elements in commits" do
      assert [add: statement(1)]
             |> Changeset.merge(remove: statement(1)) ==
               Changeset.new!(remove: statement(1))

      assert [remove: statement(1)]
             |> Changeset.merge(add: statement(1)) ==
               Changeset.new!(add: statement(1))
    end
  end

  describe "merge/1" do
    test "one element list" do
      assert Changeset.merge([commit(add: statement(1))]) ==
               Changeset.new!(add: statement(1))
    end

    test "two element list" do
      assert Changeset.merge([
               [add: statement(1)],
               [remove: statement(2)]
             ]) ==
               [add: statement(1)]
               |> Changeset.merge(remove: statement(2))
    end

    test "three element list" do
      assert Changeset.merge([
               [add: statement(1)],
               [remove: statement(1)],
               [add: statement(1)]
             ]) ==
               Changeset.new!(add: statement(1))
    end
  end
end
