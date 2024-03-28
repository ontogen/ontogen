defmodule Ontogen.Config.Loader do
  @moduledoc false

  alias Ontogen.{Config, ConfigError}
  alias RDF.Graph

  def load_config(load_paths) do
    with {:ok, graph} <- load_config_graphs(load_paths) do
      case Config.load(graph, Ontogen.Config.id()) do
        {:ok, _} = ok -> ok
        {:error, error} -> {:error, ConfigError.exception(reason: error)}
      end
    end
  end

  defp load_config_graphs(load_paths) do
    case do_load_config_graphs(List.wrap(load_paths), nil) do
      nil -> {:error, ConfigError.exception(reason: :missing)}
      %Graph{} = graph -> {:ok, graph}
      error -> error
    end
  end

  defp do_load_config_graphs([], acc), do: acc

  defp do_load_config_graphs([path | rest], acc) do
    case do_load_config_graph(path) do
      {:ok, nil} ->
        do_load_config_graphs(rest, acc)

      {:ok, graph} ->
        do_load_config_graphs(
          rest,
          if(acc, do: Graph.put_properties(acc, graph), else: graph)
        )

      {:error, _} = error ->
        error
    end
  end

  defp do_load_config_graph(nil), do: {:ok, nil}

  defp do_load_config_graph(path) when is_atom(path) do
    path |> Config.path() |> do_load_config_graph()
  end

  defp do_load_config_graph(path) when is_binary(path) do
    path = Path.expand(path)

    if File.exists?(path) do
      case RDF.read_file(path) do
        {:ok, _} = ok_graph -> ok_graph
        {:error, error} -> {:error, ConfigError.exception(file: path, reason: error)}
      end
    else
      {:ok, nil}
    end
  end
end
