defmodule Ontogen.Utils do
  @moduledoc false

  def bang!(fun, args) do
    case apply(fun, args) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end

  def extract_args(args, keys, shared \\ []) do
    shared_args = Keyword.take(args, shared)

    Enum.reduce(keys, {shared_args, args}, fn key, {extracted, args} ->
      case Keyword.pop_first(args, key) do
        {nil, args} -> {extracted, args}
        {value, args} -> {Keyword.put(extracted, key, value), args}
      end
    end)
  end

  def first_line(string) do
    string
    |> String.split("\n", parts: 2)
    |> List.first()
  end

  @doc """
  Formats a given `DateTime` relative to the current UTC time.
  """
  def human_relative_time(time) do
    Timex.format!(time, "{relative}", :relative)
  end

  @formats [
    "{ISO:Extended}",
    "{ISO:Basic}",
    "{RFC3339}",
    "{YYYY}-{MM}-{DD}",
    "{YYYY}-{M}-{D}",
    "{YYYY}-{0M}-{0D}",
    "{YYYY}-{0M}-{0D} {h24}:{m}:{s}",
    "{YYYY}-{0M}-{0D}T{h24}:{m}:{s}{Z:}",
    "{0D}.{0M}.{YYYY}",
    "{0M}/{0D}/{YYYY}",
    "{YYYY}/{0M}/{0D}",
    "{D} {Mfull} {YYYY}",
    "{D} {Mshort} {YYYY}",
    "{Mfull} {D}, {YYYY}",
    "{WDfull}, {D} {Mfull} {YYYY}",
    "{h24}:{m}:{s} {D}/{0M}/{YYYY}",
    "{AM} {h12}:{m} {D}/{0M}/{YYYY}"
  ]

  @doc """
  Parses various formats of date and time strings into `DateTime` structs.
  """
  def parse_time(string) do
    Enum.find_value(@formats, {:error, "failed to parse #{string}"}, fn format ->
      case Timex.parse(string, format) do
        {:ok, datetime} -> {:ok, datetime}
        _ -> nil
      end
    end)
  end

  def parse_time!(string), do: bang!(&parse_time/1, [string])
end
