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
  alias Ontogen.{Commit, Store, Repository, HistoryType}
  alias RDF.{Triple, Statement}

  import RDF.Guards

  api do
    def dataset_history(args \\ []), do: history(:dataset, args)
    def resource_history(resource, args \\ []), do: history({:resource, resource}, args)
    def statement_history(statement, args \\ []), do: history({:statement, statement}, args)

    def dataset_history!(args \\ []), do: bang!(&dataset_history/1, [args])
    def resource_history!(resource, args \\ []), do: bang!(&resource_history/2, [resource, args])

    def statement_history!(statement, args \\ []),
      do: bang!(&statement_history/2, [statement, args])

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
  def call(%__MODULE__{range: %Commit.Range{commit_ids: nil}} = operation, store, repository) do
    # Attention: Besides fetching the commit chain for ordering the result, this has
    # the side-effect of validating the requested range, which is important because we
    # need to protect against one problem: when a base commit is specified that is not
    # part of the history, the filter_commits clause in our query misses the mark
    # and we get the whole history back to the root, leading to a complete revert of
    # everything in case of the revert use case.
    with {:ok, range} <- Commit.Range.fetch(operation.range, store, repository) do
      %__MODULE__{operation | range: range}
      |> call(store, repository)
    end
  end

  # empty range, return an empty history
  def call(%__MODULE__{range: %Commit.Range{commit_ids: []}} = operation, _, _) do
    HistoryType.history(RDF.graph(), operation.subject_type, operation.subject)
  end

  def call(%__MODULE__{} = operation, store, repository) do
    with {:ok, operation} <- with_absolute_range(operation),
         {:ok, query} <- Query.build(operation),
         {:ok, history_graph} <-
           Store.construct(store, Repository.prov_graph_id(repository), query, raw_mode: true) do
      HistoryType.history(
        history_graph,
        operation.subject_type,
        operation.subject,
        history_order(operation.history_type_opts, operation.range.commit_ids)
      )
    end
  end

  def with_absolute_range(%__MODULE__{} = operation) do
    with {:ok, absolute_range} <- Commit.Range.absolute(operation.range) do
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
