defmodule Ontogen.TestData do
  @moduledoc """
  Functions for accessing test data.
  """

  @dir Path.join(File.cwd!(), "test/data/")
  def dir, do: @dir

  def path(name) do
    path = Path.join(@dir, name)

    if File.exists?(path) do
      path
    else
      raise "test data file '#{path}' not found"
    end
  end

  def local_config(name), do: "local_config" |> Path.join(name) |> path
end
