defmodule Ontogen.Operations.HistoryQuery do
  use Ontogen.Query,
    params: [
      subject_type: nil,
      subject: nil,
      from_commit: nil,
      to_commit: nil,
      history_type_opts: nil
    ]

  alias Ontogen.Operations.HistoryQuery.Query
  alias Ontogen.{Store, Repository, HistoryType}
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
    {from_commit, args} = Keyword.pop(args, :from_commit)
    {to_commit, args} = Keyword.pop(args, :to_commit)

    with {:ok, subject_type, subject} <- normalize_subject(subject) do
      {:ok,
       %__MODULE__{
         subject_type: subject_type,
         subject: subject,
         from_commit: from_commit,
         to_commit: to_commit,
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
  def call(%__MODULE__{} = operation, store, repository) do
    with {:ok, operation} <- finish_range(operation, repository),
         {:ok, query} <- Query.build(operation),
         {:ok, history_graph} <-
           Store.construct(store, Repository.prov_graph_id(repository), query, raw_mode: true) do
      HistoryType.history(
        history_graph,
        operation.subject_type,
        operation.subject,
        operation.history_type_opts
      )
    end
  end

  defp finish_range(%__MODULE__{from_commit: nil} = operation, repository) do
    if commit = Repository.head_id(repository) do
      {:ok, %__MODULE__{operation | from_commit: commit}}
    else
      {:error, :no_head}
    end
  end

  defp finish_range(%__MODULE__{} = operation, _), do: {:ok, operation}
end
