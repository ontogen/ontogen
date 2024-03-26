defmodule Ontogen.Application do
  @moduledoc false

  use Application

  @mix_env Mix.env()

  @impl true
  def start(_type, args) do
    @mix_env
    |> children(args)
    |> Supervisor.start_link(strategy: :one_for_one, name: Ontogen.Supervisor)
  end

  defp children(:test, args) do
    [
      {Ontogen.Config, config_load_paths(args)}
    ]
  end

  defp children(_, args) do
    [
      {Ontogen.Config, config_load_paths(args)},
      {Ontogen, Keyword.get(args, :repo_args, [])}
    ]
  end

  defp config_load_paths(args) do
    Keyword.get(args, :config_load_paths) ||
      Application.get_env(:ontogen, :config_load_paths) ||
      Ontogen.Config.default_load_paths()
  end
end
