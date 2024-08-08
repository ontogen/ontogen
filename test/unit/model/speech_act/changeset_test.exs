defmodule Ontogen.SpeechAct.ChangesetTest do
  use Ontogen.BogCase

  doctest Ontogen.SpeechAct.Changeset

  alias Ontogen.SpeechAct.Changeset
  alias Ontogen.InvalidChangesetError

  describe "new/1" do
    test "with a keyword list" do
      assert Changeset.new(
               add: statement(1),
               update: statement(2),
               replace: statement(3),
               remove: statement(4)
             ) ==
               {:ok,
                %Changeset{
                  add: graph([1]),
                  update: graph([2]),
                  replace: graph([3]),
                  remove: graph([4])
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

    test "with a speech act" do
      assert Changeset.new(speech_act()) == {:ok, %Changeset{add: graph()}}
    end

    test "without statements" do
      assert Changeset.new(add: nil) ==
               {:error, InvalidChangesetError.exception(reason: :empty)}

      assert Changeset.new(allow_empty: true) ==
               {:ok, Changeset.empty()}

      assert Changeset.new([add: nil], allow_empty: true) ==
               {:ok, Changeset.empty()}

      assert Changeset.new([changeset: []], allow_empty: true) ==
               {:ok, Changeset.empty()}
    end

    test "validates the changeset" do
      assert {:error, %InvalidChangesetError{}} =
               Changeset.new(add: statement(1), remove: statement(1))
    end
  end

  describe "update/2" do
    test "single action" do
      assert [
               add: statements([1, 6]),
               update: statement(2),
               replace: statements([3, 8]),
               remove: statements([4, 5])
             ]
             |> Changeset.update(add: statements([1, 2, 3, 4, 7])) ==
               Changeset.new!(
                 add: graph([1, 2, 3, 4, 6, 7]),
                 update: nil,
                 replace: graph([8]),
                 remove: graph([5])
               )

      assert [
               add: statements([1, 6]),
               update: statements([2, 8]),
               replace: statement(3),
               remove: statements([4, 5])
             ]
             |> Changeset.update(remove: statements([1, 2, 3, 4, 7])) ==
               Changeset.new!(
                 add: graph([6]),
                 update: graph([8]),
                 replace: nil,
                 remove: graph([1, 2, 3, 4, 5, 7])
               )
    end

    test "disjunctive changesets" do
      assert [
               add: statement(:S1_1),
               update: statement(:S2_1),
               replace: statement(:S3_1),
               remove: statement(:S4_1)
             ]
             |> Changeset.update(
               add: statement(:S1_2),
               update: statement(:S2_2),
               replace: statement(:S3_2),
               remove: statement(:S4_2)
             ) ==
               Changeset.new!(
                 add: graph([:S1_1, :S1_2]),
                 update: graph([:S2_1, :S2_2]),
                 replace: graph([:S3_1, :S3_2]),
                 remove: graph([:S4_1, :S4_2])
               )
    end

    test "equal changesets" do
      changeset =
        [
          add: graph([1]),
          update: graph([2]),
          replace: graph([3]),
          remove: graph([4])
        ]

      assert Changeset.update(changeset, changeset) ==
               Changeset.new!(changeset)
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

  test "to_rdf/1" do
    assert Changeset.new!(
             add: statement(1),
             update: statement(2),
             replace: statement(3),
             remove: statement(4)
           )
           |> Changeset.to_rdf() ==
             RDF.Dataset.new()
             |> RDF.Dataset.add(statement(1), graph: Og.Addition)
             |> RDF.Dataset.add(statement(2), graph: Og.Update)
             |> RDF.Dataset.add(statement(3), graph: Og.Replacement)
             |> RDF.Dataset.add(statement(4), graph: Og.Removal)
             |> RDF.Dataset.add(Graph.new(prefixes: [og: Og]))

    assert Changeset.new!(add: statement(1))
           |> Changeset.to_rdf() ==
             RDF.Dataset.new()
             |> RDF.Dataset.add(statement(1), graph: Og.Addition)
             |> RDF.Dataset.add(Graph.new(prefixes: [og: Og]))
  end

  test "to_rdf/2" do
    assert Changeset.new!(add: statement(1))
           |> Changeset.to_rdf(prefixes: [ex: EX]) ==
             RDF.Dataset.new()
             |> RDF.Dataset.add(statement(1), graph: Og.Addition)
             |> RDF.Dataset.add(Graph.new(prefixes: [og: Og, ex: EX]))
  end

  test "from_rdf/1" do
    assert RDF.Dataset.new()
           |> RDF.Dataset.add(statement(1), graph: Og.Addition)
           |> RDF.Dataset.add(statement(2), graph: Og.Update)
           |> RDF.Dataset.add(statement(3), graph: Og.Replacement)
           |> RDF.Dataset.add(statement(4), graph: Og.Removal)
           |> Changeset.from_rdf() ==
             Changeset.new!(
               add: statement(1),
               update: statement(2),
               replace: statement(3),
               remove: statement(4)
             )

    assert RDF.Dataset.new()
           |> RDF.Dataset.add(statement(1), graph: Og.Addition)
           |> Changeset.from_rdf() ==
             Changeset.new!(add: statement(1))
  end
end
