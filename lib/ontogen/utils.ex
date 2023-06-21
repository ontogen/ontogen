defmodule Ontogen.Utils do
  def extract_args(args, keys, shared \\ []) do
    shared_args = Keyword.take(args, shared)

    Enum.reduce(keys, {shared_args, args}, fn key, {extracted, args} ->
      case Keyword.pop_first(args, key) do
        {nil, args} -> {extracted, args}
        {value, args} -> {Keyword.put(extracted, key, value), args}
      end
    end)
  end
end
