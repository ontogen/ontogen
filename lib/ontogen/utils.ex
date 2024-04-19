defmodule Ontogen.Utils do
  @moduledoc false

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
  Truncates a string to a maximum length and appends '...' if necessary.

  ## Examples

      iex> Ontogen.Utils.truncate("Hello World", 5)
      "He..."

      iex> Ontogen.Utils.truncate("Hello", 10)
      "Hello"
  """
  def truncate(string, max_length, trunc_suffix \\ "...") do
    if String.length(string) > max_length do
      String.slice(string, 0, max_length - String.length(trunc_suffix)) <> trunc_suffix
    else
      string
    end
  end

  @doc """
  Formats a given `DateTime` relative to the current UTC time.

  ## Examples

      iex> Ontogen.Utils.human_relative_time(DateTime.utc_now())
      "just now"

      iex> ten_minutes_ago = DateTime.add(DateTime.utc_now(), -600, :second)
      iex> Ontogen.Utils.human_relative_time(ten_minutes_ago)
      "10 minutes ago"

      iex> two_years_one_month_ago = DateTime.add(DateTime.utc_now(), -66225636, :second) # approximately two years and one month
      iex> Ontogen.Utils.human_relative_time(two_years_one_month_ago)
      "2 years, 1 month ago"
  """
  def human_relative_time(time) do
    now = DateTime.utc_now()
    seconds = DateTime.diff(now, time, :second)

    cond do
      seconds < 60 -> "just now"
      seconds < 120 -> "1 minute ago"
      seconds < 3_600 -> "#{div(seconds, 60)} minutes ago"
      seconds < 7_200 -> "1 hour ago"
      seconds < 86_400 -> "#{div(seconds, 3_600)} hours ago"
      seconds < 172_800 -> "1 day ago"
      seconds < 604_800 -> "#{div(seconds, 86_400)} days ago"
      seconds < 1_209_600 -> "1 week ago"
      seconds < 2_592_000 -> "#{div(seconds, 604_800)} weeks ago"
      seconds < 5_184_000 -> "1 month ago"
      seconds < 31_536_000 -> "#{div(seconds, 2_592_000)} months ago"
      seconds < 63_072_000 -> "1 year ago"
      true -> format_years_and_months(now, time)
    end
  end

  defp format_years_and_months(now, past_time) do
    years = now.year - past_time.year
    months = now.month - past_time.month

    if months < 0 do
      {years - 1, months + 12}
    else
      {years, months}
    end
    |> case do
      {years, 0} -> "#{years} years ago"
      {years, months} -> "#{years} years, #{months} month#{if months > 1, do: "s", else: ""} ago"
    end
  end

  @default_terminal_width_fallback 120
  def terminal_width do
    case :io.columns() do
      {:ok, columns} -> columns
      _ -> @default_terminal_width_fallback
    end
  end

  def bang!(fun, args) do
    case apply(fun, args) do
      {:ok, result} -> result
      {:error, error} -> raise error
    end
  end
end
