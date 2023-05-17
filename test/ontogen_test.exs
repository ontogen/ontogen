defmodule OntogenTest do
  use ExUnit.Case
  doctest Ontogen

  test "greets the world" do
    assert Ontogen.hello() == :world
  end
end
