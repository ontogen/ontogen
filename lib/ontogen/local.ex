defmodule Ontogen.Local do
  alias Ontogen.Local.Config

  defdelegate config, to: Config
  defdelegate agent, to: Config
  defdelegate store, to: Config
end
