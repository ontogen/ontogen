defmodule Ontogen.Commit do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Changeset, Proposition, SpeechAct, Diff}
  alias Ontogen.Commit.Id
  alias RDF.Graph

  schema Og.Commit do
    link parent: Og.parentCommit(), type: Ontogen.Commit, depth: 0

    link speech_act: Og.speechAct(), type: SpeechAct, required: true, depth: +1

    link insert: Og.committedInsert(), type: Proposition, depth: +1
    link delete: Og.committedDelete(), type: Proposition, depth: +1
    link update: Og.committedUpdate(), type: Proposition, depth: +1
    link replace: Og.committedReplace(), type: Proposition, depth: +1
    link overwrite: Og.committedOverwrite(), type: Proposition, depth: +1

    link committer: Og.committer(), type: Ontogen.Agent, required: true, depth: +1
    property time: PROV.endedAtTime(), type: :date_time, required: true
    property message: Og.commitMessage(), type: :string
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
      {:ok, commit} -> commit
      {:error, error} -> raise error
    end
  end

  defp set_changes(commit, %Changeset{} = changeset) do
    struct(commit, Map.from_struct(changeset))
  end

  def validate(commit) do
    Grax.validate(commit)
  end

  def root?(%__MODULE__{parent: nil}), do: true
  def root?(%__MODULE__{}), do: false

  defdelegate merge(commits), to: Diff, as: :merge_commits
  defdelegate merge(commit1, commit2), to: Diff, as: :merge_commits

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.Commit})
    }
  end
end
