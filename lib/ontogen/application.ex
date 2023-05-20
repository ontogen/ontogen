defmodule Ontogen.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, args) do
    children = [
      {Ontogen.Local.Config, local_config_load_paths(args)}
    ]

    opts = [strategy: :one_for_one, name: Ontogen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def local_config_load_paths(args) do
    Keyword.get(args, :config_load_paths) ||
      Application.get_env(:ontogen, :config_load_paths) ||
      Ontogen.Local.Config.default_load_paths()
  end
end
