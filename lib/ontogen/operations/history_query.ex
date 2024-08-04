defmodule Ontogen.Operations.HistoryQuery do
  use Ontogen.Query,
    params: [
      subject_type: nil,
      subject: nil,
      range: nil,
      history_type: nil,
      history_type_opts: nil,
      direct_execution: false
    ]

  alias Ontogen.Operations.HistoryQuery.Query
  alias Ontogen.{Commit, HistoryType, Service}
  alias RDF.{Triple, Statement}

  import Ontogen.QueryUtils, only: [graph_query: 0]
  import RDF.Guards

  @full_history_range Commit.Range.new!(:root, :head)

  api do
    def history(args \\ []) do
      case HistoryQuery.new(args) do
        # We're not performing the store access inside of the GenServer (by using __do_call__/1)
        # when direct_execution is set (when we're querying the full history of a dataset),
        # because we don't want to block it for this potentially large read access.
        # Also, we don't want to pass the potentially large data structure between processes.
        {:ok, %HistoryQuery{direct_execution: true} = query} ->
          HistoryQuery.call(query, service())

        query ->
          HistoryQuery.__do_call__(query)
      end
    end

    def history!(args \\ []), do: bang!(&history/1, [args])

    def log(args \\ []) do
      if Keyword.has_key?(args, :format) do
        history(args)
      else
        args |> Keyword.put(:type, :log) |> history()
      end
    end

    def log!(args \\ []), do: bang!(&log/1, [args])
  end

  def new(args \\ []) do
    with {:ok, subject_type, subject, args} <- extract_subject(args),
         {:ok, range, args} <- Commit.Range.extract(args),
         {:ok, history_type, _} <- HistoryType.history_type(args) do
      {:ok,
       %__MODULE__{
         subject_type: subject_type,
         subject: subject,
         range: range,
         history_type: history_type,
         history_type_opts: args
       }
       |> set_execution_mode()}
    end
  end

  def new!(args \\ []), do: bang!(&new/1, [args])

  defp extract_subject(args) do
    {resource, args} = Keyword.pop(args, :resource)
    {statement, args} = Keyword.pop(args, :statement)

    cond do
      resource && statement -> {:error, ":resource and :statement can't be used together"}
      resource -> {:ok, :resource, normalize_resource(resource), args}
      statement -> {:ok, :statement, normalize_statement(statement), args}
      true -> {:ok, :dataset, nil, args}
    end
  end

  defp normalize_resource(resource) when is_rdf_resource(resource), do: resource
  defp normalize_resource(resource), do: RDF.iri(resource)

  defp normalize_statement({_, _, _} = triple), do: Triple.new(triple)

  defp normalize_statement({s, p}),
    do: {Statement.coerce_subject(s), Statement.coerce_predicate(p)}

  defp set_execution_mode(%__MODULE__{subject_type: :dataset, range: @full_history_range} = query) do
    %__MODULE__{query | direct_execution: true}
  end

  defp set_execution_mode(query), do: query

  @impl true
  def call(%__MODULE__{subject_type: :dataset, range: @full_history_range} = operation, service) do
    with {:ok, graph} <- Service.handle_sparql(graph_query(), service, :history),
         {:ok, operation} <-
           (if operation.history_type == HistoryType.Raw do
              {:ok, operation}
            else
              fetch_range(operation, service)
            end) do
      as_history_type(graph, operation)
    end
  end

  def call(%__MODULE__{range: %Commit.Range{commit_ids: nil}} = operation, service) do
    # Attention: Besides fetching the commit chain for ordering the result, this has
    # the side-effect of validating the requested range, which is important because we
    # need to protect against one problem: when a base commit is specified that is not
    # part of the history, the filter_commits clause in our query misses the mark
    # and we get the whole history back to the root, leading to a complete revert of
    # everything in case of the revert use case.
    with {:ok, operation} <- fetch_range(operation, service) do
      call(operation, service)
    end
  end

  # empty range, return an empty history
  def call(%__MODULE__{range: %Commit.Range{commit_ids: []}} = operation, _) do
    as_history_type(RDF.graph(), operation)
  end

  def call(%__MODULE__{} = operation, service) do
    with {:ok, operation} <- with_absolute_range(operation),
         {:ok, query} <- Query.build(operation),
         {:ok, history_graph} <- Service.handle_sparql(query, service, :history) do
      as_history_type(history_graph, operation)
    end
  end

  defp fetch_range(%__MODULE__{} = operation, service) do
    with {:ok, range} <- Commit.Range.fetch(operation.range, service) do
      {:ok, %__MODULE__{operation | range: range}}
    end
  end

  defp as_history_type(history_graph, operation) do
    HistoryType.history(
      history_graph,
      operation.subject_type,
      operation.subject,
      history_order(operation.history_type_opts, operation.range.commit_ids)
    )
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
