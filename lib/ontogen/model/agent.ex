defmodule Ontogen.Agent do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias RDF.IRI

  schema Og.Agent < [FOAF.Agent, PROV.Agent] do
  end

  @doc """
  Returns the email of an Ontogen agent.

  ## Example

      iex> Ontogen.Agent.build!(EX.Agent, mbox: ~I<mailto:agent@example.com>)
      ...> |> Ontogen.Agent.email()
      "agent@example.com"

      iex> Ontogen.Agent.build!(EX.Agent)
      ...> |> Ontogen.Agent.email()
      nil

  """
  @spec email(t()) :: String.t() | nil
  def email(%{mbox: %IRI{value: "mailto:" <> email}}), do: email
  def email(_), do: nil
end
