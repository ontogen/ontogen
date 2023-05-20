defmodule Ontogen.Store.Oxigraph do
  @moduledoc """
  `Ontogen.Store.Adapter` implementation for Oxigraph.
  """

  use Grax.Schema

  @behaviour Ontogen.Store.Adapter

  alias Ontogen.NS.Ogc

  schema Ogc.OxigraphStore < Ontogen.Store do
  end

  @impl true
  def query(store, query, opts \\ []),
    do: SPARQL.Client.query(query, query_endpoint(store), opts)

  @impl true
  def construct(store, query, opts \\ []),
    do: SPARQL.Client.construct(query, query_endpoint(store), opts)

  @impl true
  def ask(store, query, opts \\ []),
    do: SPARQL.Client.ask(query, query_endpoint(store), opts)

  @impl true
  def describe(store, query, opts \\ []),
    do: SPARQL.Client.describe(query, query_endpoint(store), opts)

  @impl true
  def insert(store, update, opts \\ []),
    do: SPARQL.Client.insert(update, update_endpoint(store), update_opts(opts))

  @impl true
  def insert_data(store, update, opts \\ []),
    do: SPARQL.Client.insert_data(update, update_endpoint(store), update_opts(opts))

  @impl true
  def update(store, update, opts \\ []),
    do: SPARQL.Client.update(update, update_endpoint(store), update_opts(opts))

  @impl true
  def delete(store, update, opts \\ []),
    do: SPARQL.Client.delete(update, update_endpoint(store), update_opts(opts))

  @impl true
  def delete_data(store, update, opts \\ []),
    do: SPARQL.Client.delete_data(update, update_endpoint(store), update_opts(opts))

  defp update_opts(opts) do
    opts
    |> Keyword.put_new(:raw_mode, true)
  end

  defp query_endpoint(%__MODULE__{query_endpoint: query_endpoint}), do: query_endpoint
  defp update_endpoint(%__MODULE__{update_endpoint: update_endpoint}), do: update_endpoint
end
