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
               insert: statement(1),
               update: statement(2),
               replace: statement(3),
               delete: statement(4),
               overwrite: statement(5)
             ) ==
               {:ok,
                %Changeset{
                  insert: graph([1]),
                  update: graph([2]),
                  replace: graph([3]),
                  delete: graph([4]),
                  overwrite: graph([5])
                }}
    end

    test "with an action map" do
      assert Changeset.new(%{insert: graph([1]), delete: statement(2)}) ==
               {:ok,
                %Changeset{
                  insert: graph([1]),
                  delete: graph([2])
                }}
    end

    test "with a commit" do
      assert Changeset.new(commit(insert: statement(1))) ==
               {:ok, %Changeset{insert: graph([1])}}
    end

    test "with a speech act" do
      assert Changeset.new(speech_act()) ==
               {:ok, %Changeset{insert: graph()}}
    end

    test "with a changeset" do
      assert Changeset.new(commit_changeset()) == {:ok, commit_changeset()}
    end

    test "statements in various forms" do
      Enum.each(@statement_forms, fn statements ->
        assert Changeset.new(insert: statements) ==
                 {:ok, %Changeset{insert: RDF.graph(statements)}}

        assert Changeset.new(delete: statements) ==
                 {:ok, %Changeset{delete: RDF.graph(statements)}}

        assert Changeset.new(update: statements) ==
                 {:ok, %Changeset{update: RDF.graph(statements)}}

        assert Changeset.new(replace: statements) ==
                 {:ok, %Changeset{replace: RDF.graph(statements)}}
      end)
    end

    test "without statements" do
      assert Changeset.new(insert: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(delete: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(update: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(replace: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}
    end

    test "validates the changeset" do
      assert {:error, %InvalidChangesetError{}} =
               Changeset.new(insert: statement(1), delete: statement(1))
    end
  end

  describe "extract/1" do
    test "with direct action keys" do
      assert Changeset.extract(insert: graph([1]), delete: statement(2), foo: :bar) ==
               {:ok,
                %Changeset{
                  insert: graph([1]),
                  delete: graph([2])
                }, [foo: :bar]}
    end

    test "with a :changeset value and no direct action keys" do
      assert Changeset.extract(changeset: [insert: graph([1]), delete: statement(2)], foo: :bar) ==
               {:ok,
                %Changeset{
                  insert: graph([1]),
                  delete: graph([2])
                }, [foo: :bar]}
    end

    test "with a :changeset value and direct action keys" do
      assert Changeset.extract(changeset: [insert: graph([1])], delete: statement(2), foo: :bar) ==
               {
                 :error,
                 InvalidChangesetError.exception(
                   reason: ":changeset can not be used along additional changes"
                 )
               }
    end
  end

  describe "merge/2" do
    test "single insert" do
      assert [
               insert: statement(1),
               delete: statements([2, 6]),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(insert: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 insert: graph([1, 2, 5]),
                 delete: graph([6]),
                 update: graph([3]),
                 replace: graph([4]),
                 overwrite: nil
               )
    end

    test "single update" do
      assert [
               insert: statements([1, 6]),
               delete: statement(2),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(update: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 insert: graph([6]),
                 delete: nil,
                 update: graph([1, 2, 3, 5]),
                 replace: graph([4]),
                 overwrite: nil
               )
    end

    test "single replace" do
      assert [
               insert: statement(1),
               delete: statement(2),
               update: statements([3, 6]),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(replace: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 insert: nil,
                 delete: nil,
                 update: graph([6]),
                 replace: graph([1, 2, 3, 4, 5]),
                 overwrite: nil
               )
    end

    test "single delete" do
      assert [
               insert: statements([1, 6]),
               delete: statement(2),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(delete: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 insert: graph([6]),
                 delete: graph([1, 2, 5, 3, 4]),
                 update: nil,
                 replace: nil,
                 overwrite: nil
               )
    end

    test "single overwrite" do
      assert [
               insert: statement(1),
               delete: statement(2),
               update: statement(3),
               replace: statement(4),
               overwrite: statement(5)
             ]
             |> Changeset.merge(overwrite: statements([1, 2, 3, 4, 5])) ==
               Changeset.new!(
                 insert: nil,
                 delete: nil,
                 update: nil,
                 replace: nil,
                 overwrite: graph([1, 2, 5, 3, 4])
               )
    end

    test "disjunctive changesets" do
      assert [
               insert: statement(:S1_1),
               update: statement(:S2_1),
               replace: statement(:S3_1),
               delete: statement(:S4_1),
               overwrite: statement(:S5_1)
             ]
             |> Changeset.merge(
               insert: statement(:S1_2),
               update: statement(:S2_2),
               replace: statement(:S3_2),
               delete: statement(:S4_2),
               overwrite: statement(:S5_2)
             ) ==
               Changeset.new!(
                 insert: graph([:S1_1, :S1_2]),
                 update: graph([:S2_1, :S2_2]),
                 replace: graph([:S3_1, :S3_2]),
                 delete: graph([:S4_1, :S4_2]),
                 overwrite: graph([:S5_1, :S5_2])
               )
    end

    test "equal changesets" do
      changeset =
        [
          insert: graph([1]),
          update: graph([2]),
          replace: graph([3]),
          delete: graph([4]),
          overwrite: graph([5])
        ]

      assert Changeset.merge(changeset, changeset) ==
               Changeset.new!(changeset)
    end

    test "insert overlap resolution" do
      assert [
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.insert_delete_overlap(), EX.p(), EX.o()},
                 {EX.insert_update_overlap(), EX.p(), EX.o()},
                 {EX.insert_replace_overlap(), EX.p(), EX.o()},
                 {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s(), EX.delete_insert_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s(), EX.p(), EX.update_insert_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_insert_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s(), EX.p(), EX.overwrite_insert_overlap()}
               ]
             ]
             |> Changeset.merge(
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s(), EX.delete_insert_overlap(), EX.o()},
                 {EX.s(), EX.p(), EX.update_insert_overlap()},
                 {EX.replace_insert_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.p(), EX.overwrite_insert_overlap()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.insert_delete_overlap(), EX.p(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.insert_update_overlap(), EX.p(), EX.o()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.insert_replace_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                 {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
               ]
             ) ==
               %Changeset{
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s(), EX.delete_insert_overlap(), EX.o()},
                     {EX.s(), EX.p(), EX.overwrite_insert_overlap()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.insert_delete_overlap(), EX.p(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.insert_update_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.update_insert_overlap()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.insert_replace_overlap(), EX.p(), EX.o()},
                     {EX.replace_insert_overlap(), EX.p(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               }
    end

    test "update overlap resolution" do
      assert [
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.insert_update_overlap(), EX.p(), EX.o()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2(), EX.delete_update_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s1(), EX.p1(), EX.update_insert_overlap()},
                 {EX.s2(), EX.p2(), EX.update_delete_overlap()},
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
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s1(), EX.p1(), EX.update_insert_overlap()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.s2(), EX.p2(), EX.update_delete_overlap()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.insert_update_overlap(), EX.p(), EX.o()},
                 {EX.s2(), EX.delete_update_overlap(), EX.o()},
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
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.s2(), EX.p2(), EX.update_delete_overlap()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.insert_update_overlap(), EX.p(), EX.o()},
                     {EX.s2(), EX.delete_update_overlap(), EX.o()},
                     {EX.s3(), EX.p3(), EX.overwrite_update_overlap()},
                     {EX.s1(), EX.p1(), EX.update_insert_overlap()}
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
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.insert_replace_overlap(), EX.p(), EX.o()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s(), EX.delete_replace_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s(), EX.p(), EX.update_replace_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_insert_overlap(), EX.p(), EX.o()},
                 {EX.replace_delete_overlap(), EX.p(), EX.o()},
                 {EX.replace_update_overlap(), EX.p(), EX.o()},
                 {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s(), EX.p(), EX.overwrite_replace_overlap()}
               ]
             ]
             |> Changeset.merge(
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.replace_insert_overlap(), EX.p(), EX.o()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.replace_delete_overlap(), EX.p(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.replace_update_overlap(), EX.p(), EX.o()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.insert_replace_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.delete_replace_overlap(), EX.o()},
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
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.replace_delete_overlap(), EX.p(), EX.o()}
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
                     {EX.insert_replace_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.delete_replace_overlap(), EX.o()},
                     {EX.s(), EX.p(), EX.update_replace_overlap()},
                     {EX.s(), EX.p(), EX.overwrite_replace_overlap()},
                     {EX.replace_insert_overlap(), EX.p(), EX.o()},
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

    test "delete overlap resolution" do
      assert [
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.insert_delete_overlap(), EX.p(), EX.o()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s1(), EX.delete_insert_overlap(), EX.o()},
                 {EX.s3(), EX.delete_update_overlap(), EX.o()},
                 {EX.s4(), EX.delete_replace_overlap(), EX.o()},
                 {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s(), EX.p(), EX.update_delete_overlap()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.replace_delete_overlap(), EX.p(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s(), EX.p(), EX.overwrite_delete_overlap()}
               ]
             ]
             |> Changeset.merge(
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s1(), EX.delete_insert_overlap(), EX.o()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.insert_delete_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.p(), EX.update_delete_overlap()},
                 {EX.replace_delete_overlap(), EX.p(), EX.o()},
                 {EX.s(), EX.p(), EX.overwrite_delete_overlap()}
               ],
               update: [
                 {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                 {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                 {EX.s3(), EX.delete_update_overlap(), EX.o()}
               ],
               replace: [
                 {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                 {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                 {EX.s4(), EX.delete_replace_overlap(), EX.o()}
               ],
               overwrite: [
                 {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                 {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                 {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
               ]
             ) ==
               Changeset.new!(
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s1(), EX.delete_insert_overlap(), EX.o()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.insert_delete_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.update_delete_overlap()},
                     {EX.replace_delete_overlap(), EX.p(), EX.o()},
                     {EX.s(), EX.p(), EX.overwrite_delete_overlap()}
                     #                     {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
                   ]),
                 update:
                   RDF.graph([
                     {EX.s3_1(), EX.p3_1(), EX.o3_1()},
                     {EX.s3_2(), EX.p3_2(), EX.o3_2()},
                     {EX.s3(), EX.delete_update_overlap(), EX.o()}
                   ]),
                 replace:
                   RDF.graph([
                     {EX.s4_1(), EX.p4_1(), EX.o4_1()},
                     {EX.s4_2(), EX.p4_2(), EX.o4_2()},
                     {EX.s4(), EX.delete_replace_overlap(), EX.o()}
                   ]),
                 overwrite:
                   RDF.graph([
                     {EX.s5_1(), EX.p5_1(), EX.o5_1()},
                     {EX.s5_2(), EX.p5_2(), EX.o5_2()},
                     {EX.s5(), EX.delete_overwrite_overlap(), EX.o()}
                   ])
               )
    end

    test "overwrite overlap resolution" do
      assert [
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.insert_overwrite_overlap(), EX.p(), EX.o()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2(), EX.delete_overwrite_overlap(), EX.o()}
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
                 {EX.s1(), EX.p1(), EX.overwrite_insert_overlap()},
                 {EX.s2(), EX.p2(), EX.overwrite_delete_overlap()},
                 {EX.s3(), EX.p3(), EX.overwrite_update_overlap()},
                 {EX.s4(), EX.p4(), EX.overwrite_replace_overlap()}
               ]
             ]
             |> Changeset.merge(
               insert: [
                 {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                 {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                 {EX.s1(), EX.p1(), EX.overwrite_insert_overlap()}
               ],
               delete: [
                 {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                 {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                 {EX.s2(), EX.p2(), EX.overwrite_delete_overlap()}
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
                 {EX.insert_overwrite_overlap(), EX.p(), EX.o()},
                 {EX.s2(), EX.delete_overwrite_overlap(), EX.o()},
                 {EX.s3(), EX.p3(), EX.update_overwrite_overlap()},
                 {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
               ]
             ) ==
               Changeset.new!(
                 insert:
                   RDF.graph([
                     {EX.s1_1(), EX.p1_1(), EX.o1_1()},
                     {EX.s1_2(), EX.p1_2(), EX.o1_2()},
                     {EX.s1(), EX.p1(), EX.overwrite_insert_overlap()}
                   ]),
                 delete:
                   RDF.graph([
                     {EX.s2_1(), EX.p2_1(), EX.o2_1()},
                     {EX.s2_2(), EX.p2_2(), EX.o2_2()},
                     {EX.s2(), EX.p2(), EX.overwrite_delete_overlap()}
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
                     {EX.insert_overwrite_overlap(), EX.p(), EX.o()},
                     {EX.s2(), EX.delete_overwrite_overlap(), EX.o()},
                     {EX.s3(), EX.p3(), EX.update_overwrite_overlap()},
                     {EX.replace_overwrite_overlap(), EX.p(), EX.o()}
                   ])
               )
    end

    test "empty elements in commits" do
      assert [insert: statement(1)]
             |> Changeset.merge(delete: statement(1)) ==
               Changeset.new!(delete: statement(1))

      assert [delete: statement(1)]
             |> Changeset.merge(insert: statement(1)) ==
               Changeset.new!(insert: statement(1))
    end
  end

  describe "merge/1" do
    test "one element list" do
      assert Changeset.merge([commit(insert: statement(1))]) ==
               Changeset.new!(insert: statement(1))
    end

    test "two element list" do
      assert Changeset.merge([
               [insert: statement(1)],
               [delete: statement(2)]
             ]) ==
               [insert: statement(1)]
               |> Changeset.merge(delete: statement(2))
    end

    test "three element list" do
      assert Changeset.merge([
               [insert: statement(1)],
               [delete: statement(1)],
               [insert: statement(1)]
             ]) ==
               Changeset.new!(insert: statement(1))
    end
  end
end
