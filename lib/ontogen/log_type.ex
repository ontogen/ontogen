defmodule Ontogen.LogType do
  alias RDF.{IRI, Statement, Graph}

  @type subject_type :: :dataset | :graph | :resource | :statement
  @type subject ::
          {:dataset, IRI.t()}
          | {:graph, IRI.t()}
          | {:resource, IRI.t()}
          | {:statement, Statement.t()}

  @callback log(history_graph :: Graph.t(), subject, opts :: keyword) ::
              {:ok, list} | {:error, any}

  @default_log_type Ontogen.LogType.Native

  def log(history_graph, subject, opts \\ []) do
    with {:ok, log_type, opts} <- log_type(opts) do
      log_type.log(history_graph, subject, opts)
    end
  end

  defp log_type(opts) do
    case Keyword.pop(opts, :type) do
      {nil, opts} -> {:ok, @default_log_type, opts}
      {:native, opts} -> {:ok, Ontogen.LogType.Native, opts}
      {:raw, opts} -> {:ok, Ontogen.LogType.Raw, opts}
      {log_type, opts} when is_atom(log_type) -> {:ok, log_type, opts}
      {invalid, _} -> {:error, "invalid log type: #{inspect(invalid)}"}
    end
  end
end
