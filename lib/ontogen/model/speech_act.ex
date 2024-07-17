defmodule Ontogen.SpeechAct do
  use Grax.Schema

  alias Ontogen.{Proposition, Changeset, Config, Utils, InvalidSpeechActError}
  alias Ontogen.Changeset.Action
  alias Ontogen.SpeechAct.{Id, Changeset}
  alias Ontogen.NS.Og
  alias RDF.Graph

  import Ontogen.Changeset.Helper, only: [copy_to_proposition_struct: 2]
  import Ontogen.Utils, only: [bang!: 2]

  @args_keys Action.fields() ++ [:speaker, :speech_act_time, :data_source]
  @shared_args [:time, :committer]

  schema Og.SpeechAct do
    link add: Og.add(), type: Proposition, depth: +1
    link update: Og.update(), type: Proposition, depth: +1
    link replace: Og.replace(), type: Proposition, depth: +1
    link remove: Og.remove(), type: Proposition, depth: +1

    property time: PROV.endedAtTime(), type: :date_time, required: true
    link speaker: Og.speaker(),
         type: Ontogen.Agent,
         depth: +1,
         on_missing_description: :use_rdf_node

    property data_source: Og.dataSource(), type: :iri
  end

  def new(%Changeset{} = changeset, args) do
    {commit_args, args} = Utils.extract_args(args, @shared_args)
    {speech_act_time, args} = Keyword.pop(args, :speech_act_time)

    args =
      args
      |> Keyword.put_new(
        :speaker,
        Keyword.get_lazy(commit_args, :committer, fn -> Config.user!() end)
      )
      |> Keyword.put(
        :time,
        speech_act_time || Keyword.get_lazy(commit_args, :time, fn -> DateTime.utc_now() end)
      )

    with {:ok, speech_act} <- build(RDF.bnode(:tmp), args) do
      update_changeset(speech_act, changeset)
    end
  end

  def new(args) do
    with {:ok, changeset, args} <- Changeset.extract(args) do
      new(changeset, args)
    end
  end

  def new!(args), do: bang!(&new/1, [args])
  def new!(changeset, args), do: bang!(&new/2, [changeset, args])

  def extract(args) do
    {speech_act_args, args} = extract_args(args)

    with {:ok, speech_act} <- new(speech_act_args) do
      {:ok, speech_act, args}
    end
  end

  defp extract_args(args) do
    Utils.extract_args(args, @args_keys, @shared_args)
  end

  def update_changeset(%__MODULE__{} = speech_act, %Changeset{} = changeset) do
    speech_act = copy_to_proposition_struct(changeset, speech_act)

    speech_act
    |> Grax.reset_id(Id.generate(speech_act))
    |> validate()
  end

  def validate(speech_act) do
    with {:ok, speech_act} <- Grax.validate(speech_act) do
      if origin(speech_act) do
        {:ok, speech_act}
      else
        {:error, InvalidSpeechActError.exception(reason: "origin missing")}
      end
    end
  end

  def origin(%__MODULE__{} = speech_act) do
    speech_act.speaker || speech_act.data_source
  end

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.SpeechAct})
    }
  end
end
