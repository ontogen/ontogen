defmodule Ontogen.Utterance do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Proposition, Changeset}
  alias Ontogen.Utterance.Id
  alias RDF.Graph

  schema Og.Utterance do
    link insertion: Og.insertion(), type: Proposition, depth: +1
    link deletion: Og.deletion(), type: Proposition, depth: +1
    link update: Og.update(), type: Proposition, depth: +1
    link replacement: Og.replacement(), type: Proposition, depth: +1

    property time: PROV.endedAtTime(), type: :date_time, required: true
    link speaker: Og.speaker(), type: Ontogen.Agent, depth: +1
    link data_source: Og.dataSource(), type: DCAT.Dataset, depth: 0
  end

  def new(%Changeset{} = changeset, args) do
    with {:ok, utterance} <- build(RDF.bnode(:tmp), args),
         utterance = struct(utterance, Map.from_struct(changeset)),
         {:ok, id} <- Id.generate(utterance) do
      utterance
      |> Grax.reset_id(id)
      |> validate()
    end
  end

  def new!(changeset, args) do
    case new(changeset, args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  def new(args) do
    with {:ok, changeset, args} <- Changeset.extract(args) do
      new(changeset, args)
    end
  end

  def new!(args) do
    case new(args) do
      {:ok, utterance} -> utterance
      {:error, error} -> raise error
    end
  end

  def validate(utterance) do
    Grax.validate(utterance)
  end

  def on_to_rdf(%__MODULE__{__id__: id}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.delete({id, RDF.type(), Og.Utterance})
    }
  end
end
