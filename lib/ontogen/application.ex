defmodule Ontogen.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = children(Ontogen.env())

    opts = [strategy: :one_for_one, name: Ontogen.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children(:test), do: []
  defp children(_), do: [Ontogen]
end
