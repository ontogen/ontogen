defmodule Ontogen.Command do
  alias Ontogen.{Repository, Store}

  @type t :: struct

  @callback call(
              command :: t,
              repository :: Repository.t(),
              store :: Store.t()
            ) ::
              {:ok, Repository.t(), any} | {:ok, Repository.t()} | {:error, any}

  defmacro __using__(opts) do
    opts = Keyword.put(opts, :params, [{:type, __MODULE__} | Keyword.get(opts, :params, [])])

    quote do
      use Ontogen.Operation, unquote(opts)
      @behaviour Ontogen.Command
    end
  end
end
