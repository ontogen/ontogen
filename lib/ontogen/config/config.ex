defmodule Ontogen.Config do
  @system_path Application.compile_env(:ontogen, :system_config_path, "/etc/ontogen_config.ttl")
  @global_path Application.compile_env(:ontogen, :global_config_path, "~/.ontogen_config.ttl")

  @local_config_dir Mix.Project.project_file() |> Path.dirname() |> Path.join("config")

  @local_path Application.compile_env(
                :ontogen,
                :local_config_path,
                "#{@local_config_dir}/#{Mix.env()}.ttl"
              )

  @paths [
    system: @system_path,
    global: @global_path,
    local: @local_path
  ]

  @default_load_paths Keyword.keys(@paths)

  use Grax.Schema
  use Agent

  import RDF.Sigils

  alias Ontogen.NS.Ogc
  alias Ontogen.Config.Loader

  schema Ogc.Config do
    link :user, Ogc.user(), type: Ontogen.Agent, required: true
    link :store, Ogc.store(), type: Ontogen.Store, required: true
  end

  @id ~I<http://localhost/ontogen/config>
  def id, do: @id

  def new(attrs) when is_list(attrs) do
    build(id(), attrs)
  end

  def new!(attrs) when is_list(attrs) do
    build!(id(), attrs)
  end

  @doc """
  The list of paths from which the configuration is iteratively built.

  #{Enum.map_join(@default_load_paths, "\n", &"- `#{inspect(&1)}`")}
  """
  def default_load_paths, do: @default_load_paths

  def path(name), do: @paths[name]

  def start_link(load_paths) do
    with {:ok, config} <- Loader.load_config(load_paths) do
      Agent.start_link(fn -> config end, name: __MODULE__)
    end
  end

  def config do
    Agent.get(__MODULE__, & &1)
  end

  def user do
    Agent.get(__MODULE__, & &1.user)
  end

  def store do
    Agent.get(__MODULE__, & &1.store)
  end

  def reload(load_paths) do
    with {:ok, config} <- Loader.load_config(load_paths) do
      Agent.update(__MODULE__, fn -> config end)
    end
  end
end
