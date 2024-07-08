defmodule Ontogen.Agent do
  use Grax.Schema
  use Ontogen.Bog.Referencable

  alias Ontogen.NS.Og
  alias RDF.IRI

  require Logger

  schema Og.Agent do
    property name: FOAF.name(), type: :string, required: true
    property email: Og.email(), type: :iri, required: true
  end

  def on_load(%{email: nil} = agent, _graph, _opts) do
    mbox =
      agent
      |> Grax.additional_statements()
      |> FOAF.mbox()
      |> case do
        [email] ->
          email

        [email | _] ->
          Logger.warning(
            "No unique foaf:mbox found for agent #{agent.__id__}: selected #{email} randomly"
          )

          email

        nil ->
          nil
      end

    {:ok, %__MODULE__{agent | email: mbox}}
  end

  def on_load(agent, _, _), do: {:ok, agent}

  @doc """
  Returns the email of an Ontogen agent.

  ## Example

      iex> Ontogen.Agent.build!(EX.Agent, email: ~I<mailto:agent@example.com>)
      ...> |> Ontogen.Agent.email()
      "agent@example.com"

      iex> Ontogen.Agent.build!(EX.Agent)
      ...> |> Ontogen.Agent.email()
      nil

  """
  @spec email(t()) :: String.t() | nil
  def email(%{email: %IRI{value: "mailto:" <> email}}), do: email
  def email(_), do: nil
end
