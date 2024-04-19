defmodule Ontogen.Operation do
  @type t :: struct

  @default_timeout 10_000

  defmacro __using__(opts) do
    params = Keyword.fetch!(opts, :params)
    timeout = Keyword.get(opts, :timeout, @default_timeout)

    quote do
      defstruct unquote(params)

      import unquote(__MODULE__), only: [api: 1]

      def __do_call__(%__MODULE__{} = operation) do
        GenServer.call(Ontogen, operation, unquote(timeout))
      end

      def __do_call__({:ok, operation}), do: __do_call__(operation)
      def __do_call__({:error, _} = error), do: error
    end
  end

  defmacro api(block) do
    quote do
      @api unquote(Macro.escape(block, unquote: true))
      def __api__, do: @api
    end
  end

  defmacro include_api({:__aliases__, _, operation} = module) do
    operation_module = Module.concat(operation)
    api_block = operation_module.__api__()

    quote do
      @external_resource to_string(unquote(module).__info__(:compile)[:source])
      require unquote(module)
      alias unquote(module)
      unquote(api_block)
    end
  end
end
