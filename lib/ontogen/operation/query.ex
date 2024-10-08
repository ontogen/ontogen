defmodule Ontogen.Operation.Query do
  alias Ontogen.Service

  @type t :: struct

  @callback call(operation :: t, service :: Service.t()) :: {:ok, any} | {:error, any}

  defmacro __using__(opts) do
    opts = Keyword.put(opts, :params, [{:type, __MODULE__} | Keyword.get(opts, :params, [])])

    quote do
      use Ontogen.Operation, unquote(opts)
      @behaviour Ontogen.Operation.Query
    end
  end
end
