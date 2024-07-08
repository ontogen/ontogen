defmodule Ontogen.Store.GenSPARQL do
  alias Ontogen.Store
  alias Ontogen.Store.SPARQL.Operation
  alias RDF.{Graph, Description, Dataset}

  def handle(operation, adapter, graph_name, opts \\ [])

  @doc operation: :query
  def handle(%Operation{type: :query} = operation, adapter, graph_name, opts) do
    with {:ok, endpoint} <- Store.query_endpoint(adapter) do
      apply(SPARQL.Client, operation.name, [
        operation.payload,
        endpoint,
        query_opts(opts, graph_name)
      ])
    end
  end

  @doc operation: :update
  def handle(%Operation{type: :update, update_type: :query} = op, adapter, graph_name, opts) do
    with {:ok, endpoint} <- Store.update_endpoint(adapter) do
      apply(SPARQL.Client, op.name, [
        op.payload,
        endpoint,
        update_opts(opts, graph_name)
      ])
    end
  end

  @doc operation: :update
  def handle(%Operation{type: :update, update_type: :data} = op, adapter, graph_name, opts) do
    with {:ok, endpoint} <- Store.update_endpoint(adapter) do
      apply(SPARQL.Client, op.name, [
        set_graph(op.payload, graph_name),
        endpoint,
        update_opts(opts, graph_name)
      ])
    end
  end

  @doc operation: :update
  def handle(%Operation{type: :update, update_type: :graph_store} = op, adapter, graph_name, opts) do
    with {:ok, endpoint} <- Store.update_endpoint(adapter) do
      apply(SPARQL.Client, op.name, [endpoint, Keyword.put(opts, :graph, graph_name)])
    end
  end

  defp query_opts(opts, graph) do
    opts
    |> general_opts()
    |> add_graph_opt(:query, graph)
  end

  defp update_opts(opts, graph) do
    opts
    |> general_opts()
    |> add_graph_opt(:update, graph)
  end

  defp general_opts(opts) do
    opts
    |> Keyword.put_new(:raw_mode, true)
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
end
