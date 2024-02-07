defmodule Ontogen.Query do
  alias Ontogen.{Repository, Store}

  @type t :: struct

  @callback call(
              operation :: t,
              repository :: Repository.t(),
              store :: Store.t()
            ) ::
              {:ok, any} | {:error, any}

  defmacro __using__(opts) do
    opts = Keyword.put(opts, :params, [{:type, __MODULE__} | Keyword.get(opts, :params, [])])

    quote do
      use Ontogen.Operation, unquote(opts)
      @behaviour Ontogen.Query
    end
  end
end
