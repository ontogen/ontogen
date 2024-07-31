defmodule Ontogen.Operations.ChangesetQuery do
  use Ontogen.Query,
    params: [
      history_query: nil
    ]

  alias Ontogen.Operations.HistoryQuery
  alias Ontogen.Commit

  api do
    def changeset(args \\ []) do
      args
      |> ChangesetQuery.new()
      |> ChangesetQuery.__do_call__()
    end

    def changeset!(args \\ []), do: bang!(&changeset/1, [args])
  end

  def new(opts \\ []) do
    with {:ok, history_query} <- history_query(opts) do
      {:ok, %__MODULE__{history_query: history_query}}
    end
  end

  def history_query(opts) do
    history_opts =
      opts
      |> Keyword.put(:type, :native)
      |> Keyword.put(:order, :asc)

    with {:ok, history_query} <- HistoryQuery.new(history_opts) do
      validate_history_query(history_query)
    end
  end

  defp validate_history_query(%HistoryQuery{subject_type: subject_type})
       when subject_type not in [:dataset, :resource] do
    {:error, "invalid subject type: #{inspect(subject_type)}"}
  end

  defp validate_history_query(%HistoryQuery{} = history_query), do: {:ok, history_query}

  @impl true
  def call(%__MODULE__{} = operation, service) do
    with {:ok, history} <- HistoryQuery.call(operation.history_query, service) do
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
