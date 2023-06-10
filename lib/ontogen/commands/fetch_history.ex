defmodule Ontogen.Commands.FetchHistory do
  alias Ontogen.{Store, Repository, HistoryType}
  alias Ontogen.Commands.FetchHistory.Query
  alias RDF.{Triple, Statement}

  import RDF.Guards

  def dataset(store, repository, opts \\ []) do
    call(store, repository, {:dataset, Repository.dataset_graph_id(repository)}, opts)
  end

  def resource(store, repository, resource, opts \\ []) do
    call(store, repository, {:resource, normalize_resource(resource)}, opts)
  end

  def statement(store, repository, statement, opts \\ []) do
    call(store, repository, {:statement, normalize_statement(statement)}, opts)
  end

  def call(store, repository, subject, opts \\ []) do
    with {:ok, query} <- Query.build(repository, subject, opts),
         {:ok, history_graph} <-
           Store.construct(store, Repository.prov_graph_id(repository), query, raw_mode: true) do
      HistoryType.history(history_graph, subject, opts)
    end
  end

  defp normalize_resource(resource) when is_rdf_resource(resource), do: resource
  defp normalize_resource(resource), do: RDF.iri(resource)

  defp normalize_statement({_, _, _} = triple), do: Triple.new(triple)

  defp normalize_statement({s, p}),
    do: {Statement.coerce_subject(s), Statement.coerce_predicate(p)}
end
