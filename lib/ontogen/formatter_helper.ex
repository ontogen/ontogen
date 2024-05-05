defmodule Ontogen.FormatterHelper do
  @moduledoc false

  alias Ontogen.{Changeset, Commit, SpeechAct, Agent}
  alias RDF.IRI

  import Ontogen.IdUtils

  @hash_formats ~w[short full iri]a
  def hash_formats, do: @hash_formats

  def changes(changeset, change_formats, opts) do
    change_formats
    |> Enum.map(&Changeset.Formatter.format(changeset, &1, opts))
    |> Enum.intersperse("\n\n")
  end

  def hash(%Commit{__id__: iri}, format), do: hash(iri, format)
  def hash(%SpeechAct{__id__: iri}, format), do: hash(iri, format)
  def hash(%IRI{} = iri, :iri), do: to_string(iri)
  def hash(%IRI{} = iri, :full), do: hash_from_iri(iri)
  def hash(%IRI{} = iri, :short), do: short_hash_from_iri(iri)

  def agent(agent, email_with_brackets \\ true)
  def agent(%IRI{} = iri, false), do: to_string(iri)
  def agent(%IRI{} = iri, true), do: ["<", to_string(iri), ">"]

  def agent(%Agent{name: nil, email: nil} = agent, false),
    do: ["??? ", to_string(agent.__id__)]

  def agent(%Agent{name: nil, email: nil} = agent, true),
    do: ["??? <", to_string(agent.__id__), ">"]

  def agent(%Agent{} = agent, false),
    do: [agent.name || "???", " ", Agent.email(agent) || "???"]

  def agent(%Agent{} = agent, true),
    do: [agent.name || "???", " <", Agent.email(agent) || "???", ">"]

  def author_or_source(%SpeechAct{speaker: speaker}) when not is_nil(speaker),
    do: ["Author: ", agent(speaker), "\n"]

  def author_or_source(%SpeechAct{data_source: source}) when not is_nil(source),
    do: ["Source: <", to_id(source), ">\n"]

  def time(datetime), do: Calendar.strftime(datetime, "%a %b %d %X %Y %z")
end
