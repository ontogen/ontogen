defmodule Ontogen.SpeechAct do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Proposition, Changeset, Action, Local, Utils}
  alias Ontogen.SpeechAct.Id
  alias RDF.Graph

  @args_keys Action.fields() ++ [:speaker, :speech_act_time, :data_source]
  @shared_args [:time, :committer]

  schema Og.SpeechAct do
    link insert: Og.insert(), type: Proposition, depth: +1
    link delete: Og.delete(), type: Proposition, depth: +1
    link update: Og.update(), type: Proposition, depth: +1
    link replace: Og.replace(), type: Proposition, depth: +1

    property time: PROV.endedAtTime(), type: :date_time, required: true
    link speaker: Og.speaker(), type: Ontogen.Agent, depth: +1
    link data_source: Og.dataSource(), type: DCAT.Dataset, depth: 0
  end

  def new(%Changeset{} = changeset, args) do
    {commit_args, args} = Utils.extract_args(args, @shared_args)
    {speech_act_time, args} = Keyword.pop(args, :speech_act_time)

    args =
      args
      |> Keyword.put_new(
        :speaker,
        Keyword.get_lazy(commit_args, :committer, fn -> Local.agent() end)
      )
      |> Keyword.put(
        :time,
        speech_act_time || Keyword.get_lazy(commit_args, :time, fn -> DateTime.utc_now() end)
      )

    with {:ok, speech_act} <- build(RDF.bnode(:tmp), args),
         speech_act = struct(speech_act, Map.from_struct(changeset)),
         {:ok, id} <- Id.generate(speech_act) do
      speech_act
      |> Grax.reset_id(id)
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
      {:ok, speech_act} -> speech_act
      {:error, error} -> raise error
    end
  end

  def new!(changeset, args) do
    case new(changeset, args) do
      {:ok, speech_act} -> speech_act
      {:error, error} -> raise error
    end
  end

  def extract(args) do
    {speech_act_args, args} = extract_args(args)

    with {:ok, speech_act} <- new(speech_act_args) do
      {:ok, speech_act, args}
    end
  end

  defp extract_args(args) do
    Utils.extract_args(args, @args_keys, @shared_args)
  end

  def validate(speech_act) do
    Grax.validate(speech_act)
  end

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.SpeechAct})
    }
  end
end
