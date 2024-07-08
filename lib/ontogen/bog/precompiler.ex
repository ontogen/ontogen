defmodule Ontogen.Bog.Precompiler do
  use RDF
  alias RDF.{Graph, Description, BlankNode}
  alias Ontogen.Bog.Referencable
  alias Ontogen.NS.{Bog}

  @i_agent_class Ontogen.NS.Og.Agent

  @spec precompile(Graph.t(), keyword) :: {:ok, Graph.t()} | {:error, any}
  def precompile(%Graph{} = graph, opts \\ []) do
    graph
    |> resolve_indexicals(opts)
    |> resolve_referencables(opts)
  end

  defp resolve_indexicals(graph, opts) do
    graph
    |> resolve_me_indexical(opts)
    |> resolve_this_indexical(opts)
  end

  defp resolve_me_indexical(graph, _opts) do
    me_bnode = RDF.bnode()

    graph =
      case Graph.pop(graph, Bog.I) do
        {%Description{} = user, graph} ->
          Graph.add(
            graph,
            user
            |> Description.change_subject(me_bnode)
            |> me_as_referencable()
          )

        {nil, graph} ->
          graph
      end

    graph
    |> Graph.query({:s?, :p?, Bog.I})
    |> Enum.reduce(graph, fn %{s: s, p: p}, graph ->
      graph
      |> Graph.delete({s, p, Bog.I})
      |> Graph.add({s, p, me_bnode})
      |> Graph.add(me_as_referencable(me_bnode))
    end)
  end

  defp me_as_referencable(me) do
    me
    |> RDF.type(@i_agent_class)
    |> Bog.ref("agent")
  end

  defp resolve_this_indexical(graph, _opts) do
    graph
    |> Graph.query({:subject?, Bog.this(), :class?})
    |> Enum.reduce(graph, fn %{subject: subject, class: class}, graph ->
      graph
      |> Graph.delete({subject, Bog.this(), class})
      |> Graph.add(subject |> RDF.type(class) |> Bog.ref(Referencable.this_ref(class)))
    end)
  end

  defp resolve_referencables(graph, opts) do
    with {:ok, precompiled_resources} <-
           graph
           |> Graph.query({:subject?, Bog.ref(), :ref?})
           |> RDF.Utils.map_while_ok(fn %{subject: subject, ref: _ref} ->
             with {:ok, referencable} <- Referencable.load_from_rdf(graph, subject),
                  {:ok, resolved_referencable} <- resolve_referencable(referencable, opts) do
               {:ok, {subject, resolved_referencable}}
             end
           end) do
      with_precompiled_subjects =
        Enum.reduce(precompiled_resources, graph, fn
          {resource, resolved_referencable}, precompiled_graph ->
            precompiled_graph
            |> Graph.add(Grax.to_rdf!(resolved_referencable, prefixes: []))
            |> Graph.delete_descriptions(resource)
        end)

      precompiled_graph =
        Enum.reduce(precompiled_resources, with_precompiled_subjects, fn
          {resource, resolved_referencable}, precompiled_graph ->
            rename(precompiled_graph, resource, resolved_referencable.__id__)
        end)

      {:ok, precompiled_graph}
    end
  end

  # We don't have to deal with non-referencable blank nodes, because these were filtered out already
  defp resolve_referencable(%Referencable{__id__: %BlankNode{}} = anonymous_referencable, opts) do
    anonymous_referencable
    |> Referencable.Id.generate(Keyword.put(opts, :mint, true))
  end

  defp rename(graph, old_id, new_id) do
    Graph.rename_resource(graph, old_id, new_id)
  end
end
