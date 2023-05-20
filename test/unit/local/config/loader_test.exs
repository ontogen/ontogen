defmodule Ontogen.Local.Config.LoaderTest do
  use Ontogen.Test.Case

  doctest Ontogen.Local.Config.Loader

  alias Ontogen.Local.Config.Loader

  describe "load_config/1" do
    test "single config file" do
      assert TestData.local_config("single_config.ttl")
             |> Loader.load_config() ==
               {:ok, local_config(store: store(~B"LocalOxigraph"))}
    end

    test "multiple config files" do
      assert [
               TestData.local_config("agent_config.ttl"),
               TestData.local_config("store_config.ttl")
             ]
             |> Loader.load_config() ==
               {:ok, local_config(store: store(~B"LocalOxigraph"))}
    end
  end
end
