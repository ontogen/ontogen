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
               # an add overlapping with an update never happens effectively
               update: nil,
               # an add overlapping with a replace never happens effectively
               replace: nil,
               remove: statements([2, 4]),
               overwrite: statement(3)
             ]
             |> Changeset.merge(add: statements([2, 3, 5])) ==
               Changeset.new!(
                 add: graph([1, 5]),
                 remove: graph([4]),
                 overwrite: nil
               )
    end

    test "single update" do
      assert [
               # an update overlapping with an add never happens effectively
               add: nil,
               update: statement(1),
               # an update overlapping with a replace never happens effectively
               replace: nil,
               remove: statements([2, 4]),
               overwrite: statement(3)
             ]
             |> Changeset.merge(update: statements([2, 3, 5])) ==
               Changeset.new!(
                 update: graph([1, 5]),
                 remove: graph([4]),
                 overwrite: nil
               )
    end

    test "single replace" do
      assert [
               # a replace overlapping with an add never happens effectively
               add: nil,
               # a replace overlapping with an update never happens effectively
               update: nil,
               replace: statement(1),
               remove: statements([2, 4]),
               overwrite: statement(3)
             ]
             |> Changeset.merge(replace: statements([2, 3, 5])) ==
               Changeset.new!(
                 replace: graph([1, 5]),
                 remove: graph([4]),
                 overwrite: nil
               )
    end

    test "single remove" do
      assert [
               add: statements([1, 5]),
               update: statement(2),
               replace: statement(3),
               remove: statement(4),
               # a remove overlapping with an overwrite never happens effectively
               overwrite: nil
             ]
             |> Changeset.merge(remove: statements([1, 2, 3, 6])) ==
               Changeset.new!(
                 add: graph([5]),
                 update: nil,
                 replace: nil,
                 remove: graph([4, 6])
               )
    end

    test "single overwrite" do
      assert [
               add: statement(1),
               update: statements([2, 5]),
               replace: statements([3, 6]),
               # a remove overlapping with an overwrite never happens effectively
               remove: nil,
               overwrite: nil
             ]
             |> Changeset.merge(overwrite: statements([1, 2, 3])) ==
               Changeset.new!(
                 add: nil,
                 update: graph([5]),
                 replace: graph([6]),
                 overwrite: nil
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

    test "empty results" do
      assert [add: statement(1)]
             |> Changeset.merge(remove: statement(1)) ==
               Changeset.empty()

      assert [remove: statement(1)]
             |> Changeset.merge(add: statement(1)) ==
               Changeset.empty()
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

    test "four element list" do
      assert Changeset.merge([
               [add: EX.S1 |> EX.p1(EX.O1)],
               [remove: EX.S1 |> EX.p1(EX.O1)],
               [add: EX.S1 |> EX.p4(EX.O4)],
               [replace: EX.S1 |> EX.p2(EX.O2), overwrite: EX.S1 |> EX.p4(EX.O4)]
             ]) ==
               Changeset.new!(replace: EX.S1 |> EX.p2(EX.O2))
    end
  end

  test "invert/1" do
    assert Changeset.new!(
             add: statement(1),
             update: statement(2),
             replace: statement(3),
             remove: statement(4),
             overwrite: statement(5)
           )
           |> Changeset.invert() ==
             %Changeset{
               add: graph([4, 5]),
               remove: graph([1, 2, 3])
             }

    assert Changeset.new!(
             replace: statement(1),
             overwrite: statement(2)
           )
           |> Changeset.invert() ==
             %Changeset{
               add: graph([2]),
               remove: graph([1])
             }
  end

  test "limit/3" do
    changeset = %Changeset{
      add: graph([1, {EX.S, EX.p1(), EX.O1}]),
      update: nil,
      replace: graph([1]),
      remove: graph([2, {EX.S, EX.p1(), EX.O2}]),
      overwrite: graph([{EX.S, EX.p2(), EX.O2}])
    }

    assert Changeset.limit(changeset, :resource, RDF.iri(EX.S)) ==
             %Changeset{
               add: graph([{EX.S, EX.p1(), EX.O1}]),
               remove: graph([{EX.S, EX.p1(), EX.O2}]),
               overwrite: graph([{EX.S, EX.p2(), EX.O2}])
             }
  end
end
