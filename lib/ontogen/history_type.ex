defmodule Ontogen.HistoryType do
  alias RDF.{IRI, Statement, Graph}

  @type subject_type :: :dataset | :graph | :resource | :statement
  @type subject :: IRI.t() | Statement.t()

  @callback history(history_graph :: Graph.t(), subject_type, subject, opts :: keyword) ::
              {:ok, list} | {:error, any}

  @default_history_type Ontogen.HistoryType.Native

  def history(history_graph, subject_type, subject, opts \\ []) do
    with {:ok, history_type, opts} <- history_type(opts) do
      history_type.history(history_graph, subject_type, subject, opts)
    end
  end

  defp history_type(opts) do
    case Keyword.pop(opts, :type) do
      {nil, opts} -> {:ok, @default_history_type, opts}
      {:native, opts} -> {:ok, Ontogen.HistoryType.Native, opts}
      {:raw, opts} -> {:ok, Ontogen.HistoryType.Raw, opts}
      {history_type, opts} when is_atom(history_type) -> {:ok, history_type, opts}
      {invalid, _} -> {:error, "invalid history type: #{inspect(invalid)}"}
    end
  end
end
