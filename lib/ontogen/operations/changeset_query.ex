defmodule Ontogen.Operations.ChangesetQuery do
  use Ontogen.Query,
    params: [
      history_query: nil
    ]

  alias Ontogen.Operations.HistoryQuery
  alias Ontogen.Commit

  api do
    def dataset_changes(args \\ []), do: changeset_query(:dataset, args)
    def resource_changes(resource, args \\ []), do: changeset_query({:resource, resource}, args)

    def dataset_changes!(args \\ []), do: bang!(&dataset_changes/1, [args])
    def resource_changes!(resource, args \\ []), do: bang!(&resource_changes/2, [resource, args])

    defp changeset_query(subject, args) do
      subject
      |> ChangesetQuery.new(args)
      |> ChangesetQuery.__do_call__()
    end
  end

  def new(subject, opts \\ []) do
    with {:ok, history_query} <- history_query(subject, opts) do
      {:ok, %__MODULE__{history_query: history_query}}
    end
  end

  def history_query(subject, opts) do
    history_opts =
      opts
      |> Keyword.put(:type, :native)
      |> Keyword.put(:order, :asc)

    with {:ok, history_query} <- HistoryQuery.new(subject, history_opts) do
      validate_history_query(history_query)
    end
  end

  defp validate_history_query(%HistoryQuery{subject_type: subject_type})
       when subject_type not in [:dataset, :resource] do
    {:error, "invalid subject type: #{inspect(subject_type)}"}
  end

  defp validate_history_query(%HistoryQuery{} = history_query), do: {:ok, history_query}

  @impl true
  def call(%__MODULE__{} = operation, store, repository) do
    with {:ok, history} <- HistoryQuery.call(operation.history_query, store, repository) do
      changeset(history, operation.history_query.subject_type, operation.history_query.subject)
    end
  end

  defp changeset([], _, _), do: {:ok, nil}

  defp changeset(history, subject_type, subject) do
    changeset =
      history
      |> Enum.map(
        &(&1
          |> Commit.Changeset.new!()
          |> Commit.Changeset.limit(subject_type, subject))
      )
      |> Commit.Changeset.merge()

    {:ok, changeset}
  end
end
