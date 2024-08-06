defmodule Ontogen.Operation do
  @type t :: struct

  # We don't want an operation to fail because of a timeout, when the query on
  # the store is still running and maybe finishing successfully.
  @default_timeout :infinity

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
      import Ontogen.Utils, only: [bang!: 2]
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
      import Ontogen.Utils, only: [bang!: 2]
      unquote(api_block)
    end
  end
end
