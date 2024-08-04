defmodule Ontogen.HistoryType do
  alias __MODULE__
  alias RDF.{IRI, Statement, Graph}

  @type subject_type :: :dataset | :graph | :resource | :statement
  @type subject :: IRI.t() | Statement.t()

  @callback history(history_graph :: Graph.t(), subject_type, subject, opts :: keyword) ::
              {:ok, list} | {:error, any}

  @default_history_type HistoryType.Raw

  def history(history_graph, subject_type, subject, opts \\ []) do
    with {:ok, history_type, opts} <- history_type(opts) do
      history_type.history(history_graph, subject_type, subject, opts)
    end
  end

  def history_type(opts) do
    has_format? = Keyword.has_key?(opts, :format)

    case Keyword.pop(opts, :type) do
      {nil, opts} when has_format? -> {:ok, HistoryType.Formatter, opts}
      {nil, opts} -> {:ok, @default_history_type, opts}
      {:log, opts} -> {:ok, HistoryType.Native, opts}
      {:native, opts} -> {:ok, HistoryType.Native, opts}
      {:raw, opts} -> {:ok, HistoryType.Raw, opts}
      {:formatted, opts} -> {:ok, HistoryType.Formatter, opts}
      {history_type, opts} when is_atom(history_type) -> {:ok, history_type, opts}
      {invalid, _} -> {:error, "invalid history type: #{inspect(invalid)}"}
    end
  end
end
