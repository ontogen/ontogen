defmodule Ontogen.Changeset.ValidationTest do
  use OntogenCase

  alias Ontogen.Changeset.Validation
  alias Ontogen.InvalidChangesetError
  alias Ontogen.Commit

  doctest Ontogen.Changeset.Validation

  test "valid changeset" do
    assert Validation.validate(commit_changeset()) == {:ok, commit_changeset()}
  end

  test "overlapping add and remove statements" do
    shared_statements = graph([1])

    assert %Commit.Changeset{
             add: graph() |> Graph.add(shared_statements),
             remove: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in both add and remove: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             update: graph() |> Graph.add(shared_statements),
             remove: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in both add and remove: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             replace: graph() |> Graph.add(shared_statements),
             remove: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in both add and remove: #{inspect(Graph.triples(shared_statements))}"
              )}
  end

  test "overlapping add statements" do
    shared_statements = graph([1])

    assert %Commit.Changeset{
             add: graph() |> Graph.add(shared_statements),
             update: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in multiple adds: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             add: shared_statements,
             replace: graph() |> Graph.add(shared_statements)
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in multiple adds: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             update: graph() |> Graph.add(shared_statements),
             replace: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in multiple adds: #{inspect(Graph.triples(shared_statements))}"
              )}
  end

  test "overlapping add patterns" do
    add1 = {EX.s(), EX.p(), EX.o1()}
    add2 = {EX.s(), EX.p(), EX.o2()}

    assert %Commit.Changeset{
             replace: graph() |> Graph.add(add1),
             update: RDF.graph([add2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following update statements overlap with replace overwrites: #{inspect([add2])}"
              )}

    assert %Commit.Changeset{
             add: graph() |> Graph.add(add1),
             replace: RDF.graph([add2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following add statements overlap with replace overwrites: #{inspect([add1])}"
              )}

    assert %Commit.Changeset{
             add: graph() |> Graph.add(add1),
             update: RDF.graph([add2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following add statements overlap with update overwrites: #{inspect([add1])}"
              )}

    assert %Commit.Changeset{
             update: graph() |> Graph.add(add1),
             add: RDF.graph([add2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following add statements overlap with update overwrites: #{inspect([add2])}"
              )}

    assert {:ok, _} =
             %Commit.Changeset{
               add: graph() |> Graph.add(add1),
               update: RDF.graph({EX.s(), EX.p2(), EX.o2()})
             }
             |> Validation.validate()

    assert {:ok, _} =
             %Commit.Changeset{
               update: graph() |> Graph.add(add1),
               add: RDF.graph({EX.s(), EX.p2(), EX.o2()})
             }
             |> Validation.validate()
  end
end
