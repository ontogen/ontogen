defmodule Ontogen.Command do
  alias Ontogen.Service

  @type t :: struct

  @callback call(operation :: t, service :: Service.t()) ::
              {:ok, Service.t(), any} | {:ok, Service.t()} | {:error, any}

  defmacro __using__(opts) do
    opts = Keyword.put(opts, :params, [{:type, __MODULE__} | Keyword.get(opts, :params, [])])

    quote do
      use Ontogen.Operation, unquote(opts)
      @behaviour Ontogen.Command
    end
  end
end
