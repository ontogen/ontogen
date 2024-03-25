defmodule Ontogen.Config.LoaderTest do
  use OntogenCase

  doctest Ontogen.Config.Loader

  alias Ontogen.Config.Loader

  describe "load_config/1" do
    test "single config file" do
      assert TestData.local_config("single_config.ttl")
             |> Loader.load_config() ==
               {:ok, local_config(store: store(~B"LocalOxigraph"))}
    end

    test "multiple config files" do
      assert [
               # This uses foaf:mbox instead of og:email
               TestData.local_config("user_config.ttl"),
               TestData.local_config("store_config.ttl")
             ]
             |> Loader.load_config() ==
               {:ok,
                local_config(
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
