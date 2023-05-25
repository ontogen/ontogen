defmodule Ontogen.Application do
  @moduledoc false

  use Application

  alias Ontogen.Local

  @mix_env Mix.env()

  @impl true
  def start(_type, args) do
    @mix_env
    |> children(args)
    |> Supervisor.start_link(strategy: :one_for_one, name: Ontogen.Supervisor)
  end

  defp children(:test, args) do
    [
      {Local.Config, local_config_load_paths(args)}
    ]
  end

  defp children(_, args) do
    [
      {Local.Config, local_config_load_paths(args)},
      {Local.Repo, Keyword.get(args, :repo_args, [])}
    ]
  end

  defp local_config_load_paths(args) do
    Keyword.get(args, :config_load_paths) ||
      Application.get_env(:ontogen, :config_load_paths) ||
      Local.Config.default_load_paths()
  end
end
