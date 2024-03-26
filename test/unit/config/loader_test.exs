defmodule Ontogen.Config.LoaderTest do
  use OntogenCase

  doctest Ontogen.Config.Loader

  alias Ontogen.Config.Loader

  describe "load_config/1" do
    test "single config file" do
      assert TestData.config("single_config.ttl")
             |> Loader.load_config() ==
               {:ok, config(store: store(~B"LocalOxigraph"))}
    end

    test "config path name" do
      assert Loader.load_config(:local) ==
               Loader.load_config("config/test.ttl")
    end

    test "multiple config files" do
      assert [
               # This uses foaf:mbox instead of og:email
               TestData.config("user_config.ttl"),
               TestData.config("store_config.ttl")
             ]
             |> Loader.load_config() ==
               {:ok,
                config(
                  store: store(~B"LocalOxigraph"),
                  user:
                    agent()
                    |> Grax.add_additional_statements(
                      {FOAF.mbox(), ~I<mailto:john.doe@example.com>}
                    )
                )}
    end
  end
end
