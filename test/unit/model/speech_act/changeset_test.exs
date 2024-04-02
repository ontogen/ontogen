defmodule Ontogen.SpeechAct.ChangesetTest do
  use OntogenCase

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

    assert Changeset.new!(add: statement(1))
           |> Changeset.to_rdf() ==
             RDF.Dataset.new()
             |> RDF.Dataset.add(statement(1), graph: Og.Addition)
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
