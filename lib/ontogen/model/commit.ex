defmodule Ontogen.Commit do
  use Grax.Schema

  alias Ontogen.{Proposition, SpeechAct, Config}
  alias Ontogen.Commit.{Id, Changeset}
  alias Ontogen.NS.Og
  alias RDF.Graph

  import Ontogen.Changeset.Helper, only: [copy_to_proposition_struct: 2]

  schema Og.Commit do
    link parent: Og.parentCommit(),
         type: Ontogen.Commit,
         required: true,
         depth: 0,
         on_missing_description: :use_rdf_node

    link add: Og.committedAdd(), type: Proposition, depth: +1
    link update: Og.committedUpdate(), type: Proposition, depth: +1
    link replace: Og.committedReplace(), type: Proposition, depth: +1
    link remove: Og.committedRemove(), type: Proposition, depth: +1
    link overwrite: Og.committedOverwrite(), type: Proposition, depth: +1

    link speech_act: Og.speechAct(), type: SpeechAct, depth: +1
    link reverted_base_commit: Og.revertedBaseCommit(), type: __MODULE__, depth: 0
    link reverted_target_commit: Og.revertedTargetCommit(), type: __MODULE__, depth: 0

    link committer: Og.committer(),
         type: Ontogen.Agent,
         required: true,
         depth: +1,
         on_missing_description: :use_rdf_node

    property time: PROV.endedAtTime(), type: :date_time, required: true
    property message: Og.commitMessage(), type: :string
  end

  @root RDF.iri(Og.CommitRoot)
  def root, do: @root

  def new(%Changeset{} = changeset, args) do
    args =
      args
      |> Keyword.put_new(:parent, @root)
      |> Keyword.put_new_lazy(:committer, fn -> Config.user() end)
      |> Keyword.put_new_lazy(:time, fn -> DateTime.utc_now() end)

    with {:ok, commit} <- build(RDF.bnode(:tmp), args) do
      commit
      |> init(changeset)
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

  defp init(commit, changeset) do
    changeset
    |> copy_to_proposition_struct(commit)
    |> Grax.reset_id(Id.generate(commit))
  end

  def validate(commit) do
    if commit.speech_act || commit.reverted_base_commit || commit.reverted_target_commit do
      Grax.validate(commit)
    else
      {:error, "missing speech_act in commit #{commit.__id__}"}
    end
  end

  def root?(%__MODULE__{parent: @root}), do: true
  def root?(%__MODULE__{}), do: false

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.Commit})
    }
  end
end
