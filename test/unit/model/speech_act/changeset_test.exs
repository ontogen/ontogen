defmodule Ontogen.SpeechAct.ChangesetTest do
  use OntogenCase

  doctest Ontogen.SpeechAct.Changeset

  alias Ontogen.SpeechAct.Changeset
  alias Ontogen.InvalidChangesetError

  describe "new/1" do
    test "with a keyword list" do
      assert Changeset.new(
               insert: statement(1),
               update: statement(2),
               replace: statement(3),
               delete: statement(4)
             ) ==
               {:ok,
                %Changeset{
                  insert: graph([1]),
                  update: graph([2]),
                  replace: graph([3]),
                  delete: graph([4])
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

    test "with a speech act" do
      assert Changeset.new(speech_act()) == {:ok, %Changeset{insert: graph()}}
    end

    test "without statements" do
      assert Changeset.new(insert: nil) ==
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
end
