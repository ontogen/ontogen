defmodule Ontogen.Commit do
  use Grax.Schema

  alias Ontogen.{Proposition, SpeechAct, Config}
  alias Ontogen.Commit.{Id, Changeset}
  alias Ontogen.NS.Og
  alias RDF.Graph

  import Ontogen.Changeset.Helper, only: [copy_to_proposition_struct: 2]

  schema Og.Commit do
    link parent: Og.parentCommit(), type: Ontogen.Commit, depth: 0

    link speech_act: Og.speechAct(), type: SpeechAct, required: true, depth: +1

    link add: Og.committedAdd(), type: Proposition, depth: +1
    link update: Og.committedUpdate(), type: Proposition, depth: +1
    link replace: Og.committedReplace(), type: Proposition, depth: +1
    link remove: Og.committedRemove(), type: Proposition, depth: +1
    link overwrite: Og.committedOverwrite(), type: Proposition, depth: +1

    link committer: Og.committer(),
         type: Ontogen.Agent,
         required: true,
         depth: +1,
         on_missing_description: :use_rdf_node

    property time: PROV.endedAtTime(), type: :date_time, required: true
    property message: Og.commitMessage(), type: :string
  end

  def new(%Changeset{} = changeset, args) do
    args =
      args
      |> Keyword.put_new_lazy(:committer, fn -> Config.agent() end)
      |> Keyword.put_new_lazy(:time, fn -> DateTime.utc_now() end)

    with {:ok, commit} <- build(RDF.bnode(:tmp), args) do
      changeset
      |> copy_to_proposition_struct(commit)
      |> Grax.reset_id(Id.generate(commit))
      |> validate()
    end
  end

  def new(args) do
    with {:ok, changeset, args} <- Changeset.extract(args) do
      new(changeset, args)
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, commit} -> commit
      {:error, error} -> raise error
    end
  end

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
