defmodule Ontogen.Changeset.ValidationTest do
  use OntogenCase

  alias Ontogen.Changeset.Validation
  alias Ontogen.InvalidChangesetError
  alias Ontogen.Commit

  doctest Ontogen.Changeset.Validation

  test "valid changeset" do
    assert Validation.validate(commit_changeset()) == {:ok, commit_changeset()}
  end

  test "overlapping insert and delete statements" do
    shared_statements = graph([1])

    assert %Commit.Changeset{
             insert: graph() |> Graph.add(shared_statements),
             delete: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in both insert and delete: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             update: graph() |> Graph.add(shared_statements),
             delete: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in both insert and delete: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             replace: graph() |> Graph.add(shared_statements),
             delete: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in both insert and delete: #{inspect(Graph.triples(shared_statements))}"
              )}
  end

  test "overlapping insert statements" do
    shared_statements = graph([1])

    assert %Commit.Changeset{
             insert: graph() |> Graph.add(shared_statements),
             update: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in multiple inserts: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             insert: shared_statements,
             replace: graph() |> Graph.add(shared_statements)
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in multiple inserts: #{inspect(Graph.triples(shared_statements))}"
              )}

    assert %Commit.Changeset{
             update: graph() |> Graph.add(shared_statements),
             replace: shared_statements
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following statements are in multiple inserts: #{inspect(Graph.triples(shared_statements))}"
              )}
  end

  test "overlapping insert patterns" do
    insert1 = {EX.s(), EX.p(), EX.o1()}
    insert2 = {EX.s(), EX.p(), EX.o2()}

    assert %Commit.Changeset{
             replace: graph() |> Graph.add(insert1),
             update: RDF.graph([insert2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following update statements overlap with replace overwrites: #{inspect([insert2])}"
              )}

    assert %Commit.Changeset{
             insert: graph() |> Graph.add(insert1),
             replace: RDF.graph([insert2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following insert statements overlap with replace overwrites: #{inspect([insert1])}"
              )}

    assert %Commit.Changeset{
             insert: graph() |> Graph.add(insert1),
             update: RDF.graph([insert2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following insert statements overlap with update overwrites: #{inspect([insert1])}"
              )}

    assert %Commit.Changeset{
             update: graph() |> Graph.add(insert1),
             insert: RDF.graph([insert2])
           }
           |> Validation.validate() ==
             {:error,
              InvalidChangesetError.exception(
                reason:
                  "the following insert statements overlap with update overwrites: #{inspect([insert2])}"
              )}

    assert {:ok, _} =
             %Commit.Changeset{
               insert: graph() |> Graph.add(insert1),
               update: RDF.graph({EX.s(), EX.p2(), EX.o2()})
             }
             |> Validation.validate()

    assert {:ok, _} =
             %Commit.Changeset{
               update: graph() |> Graph.add(insert1),
               insert: RDF.graph({EX.s(), EX.p2(), EX.o2()})
             }
             |> Validation.validate()
  end
end
