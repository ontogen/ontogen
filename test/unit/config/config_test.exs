defmodule Ontogen.ConfigTest do
  use Ontogen.BogCase

  doctest Ontogen.Config

  alias Ontogen.Config
  alias Ontogen.{Service, Store, Repository, Dataset, ProvGraph, Agent}
  alias Ontogen.Store.Adapters.{Oxigraph, Fuseki, GraphDB}

  @configured_store_adapter configured_store_adapter()

  test "agent/0" do
    assert {:ok,
            %Agent{
              name: "Jane Doe",
              email: ~I<mailto:jane.doe@example.com>
            }} =
             Config.agent()

    assert Config.agent("agent") == Config.agent()
    assert Config.user() == Config.agent()
  end

  test "service/0" do
    assert {:ok,
            %Service{
              repository: %Repository{
                dataset: %Dataset{
                  title: "test dataset",
                  creators: [%FOAF.Agent{name: "Jane Doe"}],
                  publishers: [%FOAF.Agent{name: "Jane Doe"}]
                }
              },
              store: %@configured_store_adapter{}
            }} =
             Config.service()

    assert Config.service("service") == Config.service()
  end

  test "repository/0" do
    assert {:ok,
            %Repository{
              dataset: %Dataset{
                title: "test dataset",
                creators: [%FOAF.Agent{name: "Jane Doe"}],
                publishers: [%FOAF.Agent{name: "Jane Doe"}]
              }
            }} =
             Config.repository()

    assert Config.repository("repository") == Config.repository()
  end

  test "dataset/0" do
    assert {:ok,
            %Dataset{
              title: "test dataset",
              creators: [%FOAF.Agent{name: "Jane Doe"}],
              publishers: [%FOAF.Agent{name: "Jane Doe"}]
            }} =
             Config.dataset()

    assert Config.dataset("dataset") == Config.dataset()
  end

  test "prov_graph/0" do
    assert {:ok, %ProvGraph{}} = Config.prov_graph()
    assert Config.prov_graph("provGraph") == Config.prov_graph()
  end

  case @configured_store_adapter do
    Store ->
      test "store/0 with generic store" do
        assert {:ok, %Store{}} = Config.store()
        assert Config.store() == Config.store("store")
      end

    Fuseki ->
      test "store/0 with Fuseki adapter" do
        assert {:ok,
                %Fuseki{
                  port: 3030,
                  dataset: "ontogen-test-dataset"
                }} =
                 Config.store()
      end

    Oxigraph ->
      test "store/0 with Oxigraph adapter" do
        assert {:ok, %Oxigraph{port: 7879}} = Config.store()
      end

    GraphDB ->
      test "store/0 with GraphDB adapter" do
        assert {:ok, %GraphDB{port: 7200}} = Config.store()
      end
  end
end
