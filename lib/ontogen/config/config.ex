defmodule Ontogen.Config do
  @local_config_dir Mix.Project.project_file() |> Path.dirname() |> Path.join("config")

  @local_path Application.compile_env(
                :ontogen,
                :local_config_path,
                "#{@local_config_dir}/#{Mix.env()}.ttl"
              )

  @paths [
    system: "/etc/ontogen_config.ttl",
    global: "~/.ontogen_config.ttl",
    local: @local_path
  ]

  @default_load_paths Keyword.keys(@paths)

  use Grax.Schema

  alias Ontogen.NS.Ogc

  schema Ogc.Config do
    link :user, Ogc.user(), type: Ontogen.Agent, required: true
    link :store, Ogc.store(), type: Ontogen.Store, required: true
  end

  use Agent

  alias Ontogen.Config.Loader

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
