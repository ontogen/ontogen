defmodule Ontogen.Config.Loader do
  @moduledoc false

  alias Ontogen.{Bog, ConfigError}
  alias RDF.{Graph, Turtle}

  @system_path Application.compile_env(:ontogen, :system_config_path, "/etc/ontogen.conf.bog.ttl")
  @global_path Application.compile_env(:ontogen, :global_config_path, "~/.ontogen.conf.bog.ttl")

  @default_local_config_path Path.join([
                               Path.dirname(Mix.Project.project_file()),
                               "config",
                               "ontogen"
                             ])
  @local_path Application.compile_env(:ontogen, :local_config_path, @default_local_config_path)

  @named_paths [
    system: @system_path,
    global: @global_path,
    local: @local_path
  ]

  @default_load_paths Keyword.keys(@named_paths)

  def local_path, do: @local_path

  @doc """
  The list of paths from which the configuration is iteratively built.

  #{Enum.map_join(@default_load_paths, "\n", &"- `#{inspect(&1)}`")}
  """
  def default_load_paths, do: @default_load_paths

  def env(opts \\ []) do
    Keyword.get(
      opts,
      :env,
      System.get_env("OG_ENV") || System.get_env("MIX_ENV") || Ontogen.env()
    )
  end

  defp named_path(name), do: @named_paths[name]

  def load_paths(opts \\ []) do
    Keyword.get(
      opts,
      :load_path,
      Application.get_env(:ontogen, :config_load_paths, @default_load_paths)
    )
  end

  # the og:serviceStore must be set manually to a Store adapter or the generic [ :this og:Store ]
  @service_structure """
                     #{RDF.turtle_prefixes(og: Ontogen.NS.Og, "": Ontogen.NS.Bog)}

                     [ :this og:Service
                         ; og:serviceRepository [ :this og:Repository
                             ; og:repositoryDataset [ :this og:Dataset ]
                             ; og:repositoryProvGraph [ :this og:ProvGraph ]
                         ]

                         ; og:serviceOperator :I
                     ] .
                     """
                     |> Turtle.read_string!(
                       bnode_gen: RDF.BlankNode.Generator.Random.new(prefix: "bog")
                     )
  def service_structure, do: @service_structure

  def load_graph(opts \\ []) do
    load_paths = opts |> load_paths() |> List.wrap()
    env = env(opts)

    with {:ok, service_structure} <- Bog.precompile(@service_structure) do
      case do_load_config_graphs(load_paths, env, nil) do
        nil -> {:ok, service_structure}
        %Graph{} = graph -> {:ok, Graph.add(graph, service_structure)}
        error -> error
      end
    end
  end

  defp do_load_config_graphs(load_paths, env, acc \\ nil)
  defp do_load_config_graphs([], _env, acc), do: acc

  defp do_load_config_graphs([path | rest], env, acc) do
    case do_load_config_graph(path, env) do
      {:ok, nil} -> do_load_config_graphs(rest, env, acc)
      {:ok, graph} when is_nil(acc) -> do_load_config_graphs(rest, env, graph)
      {:ok, graph} -> do_load_config_graphs(rest, env, Graph.put_properties(acc, graph))
      {:error, _} = error -> error
    end
  end

  defp do_load_config_graph(nil, _), do: {:ok, nil}

  defp do_load_config_graph(path, env) when is_atom(path) do
    case path |> named_path() |> do_load_config_graph(env) do
      {:ok, _} = ok -> ok
      {:error, %ConfigError{reason: :missing}} when path in [:system, :global] -> {:ok, nil}
      {:error, _} = error -> error
    end
  end

  defp do_load_config_graph(path, env) when is_binary(path) do
    path = Path.expand(path)

    cond do
      File.dir?(path) ->
        do_load_config_directory(path, env)

      File.exists?(path) ->
        case RDF.read_file(path) do
          {:ok, graph} -> Bog.precompile(graph)
          {:error, error} -> {:error, ConfigError.exception(file: path, reason: error)}
        end

      true ->
        {:error, ConfigError.exception(reason: :missing, file: path)}
    end
  end

  @environments ~w[prod dev test]a
  @conf_file_pattern "**/*.bog.ttl"
  @local_env_file_patterns Map.new(@environments, &{&1, "**/*.#{&1}.bog.ttl"})
  @local_env_directory_pattern Map.new(@environments, &{&1, "#{&1}/**/*.bog.ttl"})

  defp do_load_config_directory(path, env) do
    {general_files, environment_specific_files} = directory_files(path, env)

    general_graph = do_load_config_graphs(general_files, env)
    environment_specific_graph = do_load_config_graphs(environment_specific_files, env)

    graph =
      cond do
        general_graph && environment_specific_graph ->
          Graph.put_properties(general_graph, environment_specific_graph)

        general_graph ->
          general_graph

        environment_specific_graph ->
          environment_specific_graph
      end

    {:ok, graph}
  end

  defp directory_files(path, env) do
    {this_environment_specific_files, other_environment_specific_files} =
      @environments
      |> Enum.map(fn environment ->
        {environment,
         (path |> Path.join(@local_env_file_patterns[environment]) |> Path.wildcard()) ++
           (path |> Path.join(@local_env_directory_pattern[environment]) |> Path.wildcard())}
      end)
      |> Keyword.pop(env)

    general_files =
      path
      |> Path.join(@conf_file_pattern)
      |> Path.wildcard()
      |> Kernel.--(this_environment_specific_files)
      |> Kernel.--(other_environment_specific_files |> Keyword.values() |> List.flatten())

    {without_excluded(general_files), without_excluded(this_environment_specific_files)}
  end

  defp without_excluded(files) do
    Enum.reject(files, &(&1 |> Path.basename() |> String.starts_with?("_")))
  end
end
