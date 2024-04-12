defmodule Ontogen.Operations.HistoryQuery do
  use Ontogen.Query,
    params: [
      subject_type: nil,
      subject: nil,
      range: nil,
      ids_only: false,
      history_type_opts: nil
    ]

  alias Ontogen.Operations.HistoryQuery.Query
  alias Ontogen.{Commit, Store, Repository, HistoryType, CommitIdChain}
  alias RDF.{Triple, Statement}

  import RDF.Guards

  api do
    def dataset_history(args \\ []), do: history(:dataset, args)
    def resource_history(resource, args \\ []), do: history({:resource, resource}, args)
    def statement_history(statement, args \\ []), do: history({:statement, statement}, args)

    defp history(subject, args) do
      subject
      |> HistoryQuery.new(args)
      |> HistoryQuery.__do_call__()
    end
  end

  def new(subject, args \\ []) do
    {ids_only, args} = Keyword.pop(args, :ids_only, false)

    with {:ok, subject_type, subject} <- normalize_subject(subject),
         {:ok, range, args} <- Commit.Range.extract(args) do
      {:ok,
       %__MODULE__{
         subject_type: subject_type,
         subject: subject,
         range: range,
         ids_only: ids_only,
         history_type_opts: args
       }}
    end
  end

  defp normalize_subject(:dataset),
    do: {:ok, :dataset, nil}

  defp normalize_subject({:resource, resource}),
    do: {:ok, :resource, normalize_resource(resource)}

  defp normalize_subject({:statement, statement}),
    do: {:ok, :statement, normalize_statement(statement)}

  defp normalize_subject(invalid),
    do: {:error, "invalid history subject: #{inspect(invalid)}"}

  defp normalize_resource(resource) when is_rdf_resource(resource), do: resource
  defp normalize_resource(resource), do: RDF.iri(resource)

  defp normalize_statement({_, _, _} = triple), do: Triple.new(triple)

  defp normalize_statement({s, p}),
    do: {Statement.coerce_subject(s), Statement.coerce_predicate(p)}

  @impl true
  def call(%__MODULE__{ids_only: ids_only?} = operation, store, repository) do
    with {:ok, operation} <- finish_range(operation, repository),
         # Attention: Besides fetching the commit chain for ordering the result, this has the
         # side-effect of validating the requested range, which is important because we
         # need to protect against one problem in particular: when a base commit is specified
         # that is not part of the history, the filter_commits clause in our query misses the mark
         # and we get the whole history back to the root, leading to a complete revert of everything
         # in case of the revert use case.
         {:ok, commit_id_chain} when not ids_only? <-
           CommitIdChain.fetch(operation.range, store, repository),
         {:ok, query} <- Query.build(operation),
         {:ok, history_graph} <-
           Store.construct(store, Repository.prov_graph_id(repository), query, raw_mode: true) do
      HistoryType.history(
        history_graph,
        operation.subject_type,
        operation.subject,
        history_order(operation.history_type_opts, commit_id_chain)
      )
    end
  end

  defp finish_range(%__MODULE__{} = operation, repository) do
    with {:ok, absolute_range} <- Commit.Range.absolute(operation.range, repository) do
      {:ok, %__MODULE__{operation | range: absolute_range}}
    end
  end

  defp history_order(opts, commit_id_chain) do
    Keyword.update(opts, :order, {:desc, :parent, commit_id_chain}, fn
      :asc -> {:asc, :parent, commit_id_chain}
      :desc -> {:desc, :parent, commit_id_chain}
      other -> other
    end)
  end
end
