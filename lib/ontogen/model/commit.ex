defmodule Ontogen.Commit do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Expression, Changeset}
  alias Ontogen.Commit.Id
  alias RDF.Graph

  schema Og.Commit do
    link parent: Og.parentCommit(), type: Ontogen.Commit, depth: 0

    link insertion: Og.committedInsertion(), type: Expression
    link deletion: Og.committedDeletion(), type: Expression

    link committer: Og.committer(), type: Ontogen.Agent, required: true

    property message: Og.commitMessage(), type: :string

    property time: PROV.endedAtTime(), type: :date_time, required: true
  end

  def new(args) do
    with {:ok, changeset, args} <- Changeset.extract(args),
         {:ok, commit} <- build(RDF.bnode(:tmp), args),
         commit = set_changes(commit, changeset),
         {:ok, id} <- Id.generate(commit) do
      commit
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  def effective(%__MODULE__{}, :no_effective_changes), do: {:ok, :no_effective_changes}

  def effective(%__MODULE__{} = origin, effective_changeset) do
    effective_commit = set_changes(origin, effective_changeset)

    with {:ok, id} <- Id.generate(effective_commit) do
      effective_commit
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  defp set_changes(commit, %Changeset{} = changeset),
    do: struct(commit, Map.from_struct(changeset))

  def validate(commit) do
    Grax.validate(commit)
  end

  def root?(%__MODULE__{parent: nil}), do: true
  def root?(%__MODULE__{}), do: false

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.Commit})
    }
  end
end
