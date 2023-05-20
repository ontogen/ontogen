defmodule Ontogen.Local.Config.Loader do
  @moduledoc false

  alias Ontogen.Local.Config
  alias RDF.Graph

  @node RDF.bnode("_LocalConfig")
  def node, do: @node

  def load_config(load_paths) do
    with {:ok, graph} <- load_config_graphs(load_paths) do
      Config.load(graph, @node)
    end
  end

  defp load_config_graphs(load_paths) do
    case do_load_config_graphs(List.wrap(load_paths), nil) do
      nil -> {:error, "no config files found"}
      %Graph{} = graph -> {:ok, graph}
      error -> error
    end
  end

  defp do_load_config_graphs([], acc), do: acc

  defp do_load_config_graphs([path | rest], acc) do
    if File.exists?(path) do
      case RDF.read_file(path) do
        {:ok, graph} when is_nil(acc) -> do_load_config_graphs(rest, graph)
        {:ok, graph} -> do_load_config_graphs(rest, Graph.put_properties(acc, graph))
        {:error, error} -> {:error, "error reading config file #{path}: #{error}"}
      end
    else
      do_load_config_graphs(rest, acc)
    end
  end
end
