defmodule Ontogen.Store.Oxigraph do
  @moduledoc """
  `Ontogen.Store.Adapter` implementation for Oxigraph.
  """

  use Grax.Schema

  @behaviour Ontogen.Store.Adapter

  alias Ontogen.NS.Ogc
  alias RDF.{Graph, Description, Dataset}

  schema Ogc.OxigraphStore < Ontogen.Store do
  end

  @impl true
  def query(store, graph, query, opts \\ []),
    do: SPARQL.Client.query(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def construct(store, graph, query, opts \\ []),
    do: SPARQL.Client.construct(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def ask(store, graph, query, opts \\ []),
    do: SPARQL.Client.ask(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def describe(store, graph, query, opts \\ []),
    do: SPARQL.Client.describe(query, query_endpoint(store), query_opts(opts, graph))

  @impl true
  def insert(store, graph, update, opts \\ []),
    do: SPARQL.Client.insert(update, update_endpoint(store), update_opts(opts, graph))

  @impl true
  def update(store, graph, update, opts \\ []),
    do: SPARQL.Client.update(update, update_endpoint(store), update_opts(opts, graph))

  @impl true
  def delete(store, graph, update, opts \\ []),
    do: SPARQL.Client.delete(update, update_endpoint(store), update_opts(opts, graph))

  @impl true
  def insert_data(store, graph, data, opts \\ []),
    do: data |> set_graph(graph) |> SPARQL.Client.insert_data(update_endpoint(store), opts)

  @impl true
  def delete_data(store, graph, data, opts \\ []),
    do: data |> set_graph(graph) |> SPARQL.Client.delete_data(update_endpoint(store), opts)

  @impl true
  def create(store, graph, opts \\ []),
    do: SPARQL.Client.create(update_endpoint(store), Keyword.put(opts, :graph, graph))

  @impl true
  def clear(store, graph, opts \\ []),
    do: SPARQL.Client.clear(update_endpoint(store), Keyword.put(opts, :graph, graph))

  @impl true
  def drop(store, graph, opts \\ []),
    do: SPARQL.Client.drop(update_endpoint(store), Keyword.put(opts, :graph, graph))

  defp query_opts(opts, graph) do
    opts
    |> add_graph_opt(:query, graph)
  end

  defp update_opts(opts, graph) do
    opts
    |> Keyword.put_new(:raw_mode, true)
    |> add_graph_opt(:update, graph)
  end

  defp add_graph_opt(opts, _, nil), do: opts

  defp add_graph_opt(opts, type, graph) do
    {named_graph, opts} = Keyword.pop(opts, :named_graph, false)
    Keyword.put(opts, graph_opt(type, named_graph), graph)
  end

  defp graph_opt(:query, false), do: :default_graph
  defp graph_opt(:query, true), do: :named_graph
  defp graph_opt(:update, false), do: :using_graph
  defp graph_opt(:update, true), do: :using_named_graph

  defp set_graph(data, nil), do: data
  defp set_graph(data, :default), do: data

  defp set_graph(%Graph{} = data, graph_name),
    do: data |> Graph.change_name(graph_name) |> Dataset.new()

  defp set_graph(%Description{} = data, graph_name),
    do: data |> Graph.new(name: graph_name) |> Dataset.new()

  defp query_endpoint(%__MODULE__{query_endpoint: query_endpoint}), do: query_endpoint
  defp update_endpoint(%__MODULE__{update_endpoint: update_endpoint}), do: update_endpoint
end
