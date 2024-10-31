defmodule Ontogen.Config.LoaderTest do
  use Ontogen.MudCase

  doctest Ontogen.Config.Loader

  alias Ontogen.{Config, ConfigError}
  alias Ontogen.Config.Loader

  test "no config" do
    assert Loader.load_graph(load_path: nil) == {:ok, service_structure_graph()}
    assert Loader.load_graph(load_path: []) == {:ok, service_structure_graph()}

    assert Loader.load_graph(load_path: TestData.config("empty.og.ttl")) ==
             {:ok, service_structure_graph()}
  end

  test "single config file" do
    assert Loader.load_graph(load_path: TestData.config("single_config.og.ttl")) ==
             {:ok,
              service_structure_graph()
              |> Graph.add_prefixes(oga: OgA)
              |> Graph.add(
                Graph.new([
                  {Config.service_id(), Og.serviceStore(), RDF.bnode("store")},
                  {RDF.bnode("store"), Mud.this(), OgA.Fuseki}
                ])
                |> Mud.process!()
              )}
  end

  test "flat config dir" do
    assert Loader.load_graph(load_path: TestData.config("flat_dir")) ==
             {:ok,
              service_structure_graph()
              |> Graph.add_prefixes(oga: OgA, foaf: FOAF, dcterms: "http://purl.org/dc/terms/")
              |> Graph.add(
                Graph.new([
                  {Config.service_id(), Og.serviceStore(), RDF.bnode("store")},
                  {RDF.bnode("store"), Mud.this(), OgA.Fuseki},
                  {Config.dataset_id(), ~I<http://purl.org/dc/terms/title>, "test dataset"},
                  {Config.agent_id(), FOAF.name(), "Max Mustermann"}
                ])
                |> Mud.process!()
              )}
  end

  test "nested config dir" do
    assert Loader.load_graph(load_path: TestData.config("nested_dir")) ==
             {:ok,
              service_structure_graph()
              |> Graph.add_prefixes(oga: OgA, foaf: FOAF, dcterms: "http://purl.org/dc/terms/")
              |> Graph.add(
                Graph.new([
                  {Config.service_id(), Og.serviceStore(), RDF.bnode("store")},
                  {RDF.bnode("store"), Mud.this(), OgA.Fuseki},
                  {Config.dataset_id(), ~I<http://purl.org/dc/terms/title>, "test dataset"},
                  {Config.repository_id(), ~I<http://purl.org/dc/terms/creator>,
                   Config.agent_id()},
                  {Config.agent_id(), FOAF.name(), "Max Mustermann"}
                ])
                |> Mud.process!()
              )}
  end

  test "environment-specific dir" do
    assert Loader.load_graph(load_path: TestData.config("env_specific")) ==
             {:ok,
              service_structure_graph()
              |> Graph.add_prefixes(oga: OgA, foaf: FOAF, dcterms: "http://purl.org/dc/terms/")
              |> Graph.add(
                Graph.new([
                  {Config.service_id(), Og.serviceStore(), RDF.bnode("store")},
                  {RDF.bnode("store"), Mud.this(), OgA.Fuseki},
                  {RDF.bnode("store"), Og.storeEndpointPort(), 3030},
                  {Config.service_id(), ~I<http://purl.org/dc/terms/title>, "Example service"},
                  {Config.dataset_id(), ~I<http://purl.org/dc/terms/title>, "test dataset"},
                  {Config.repository_id(), ~I<http://purl.org/dc/terms/title>, "test repository"},
                  {Config.repository_id(), ~I<http://purl.org/dc/terms/creator>,
                   Config.agent_id()},
                  {Config.agent_id(), FOAF.name(), "Max Mustermann"},
                  {Config.agent_id(), Og.email(), ~I<mailto:max.mustermann.test@example.com>}
                ])
                |> Mud.process!()
              )}

    assert Loader.load_graph(load_path: TestData.config("env_specific"), env: :test) ==
             Loader.load_graph(load_path: TestData.config("env_specific"))

    assert Loader.load_graph(load_path: TestData.config("env_specific"), env: :dev) ==
             {:ok,
              service_structure_graph()
              |> Graph.add_prefixes(oga: OgA, foaf: FOAF, dcterms: "http://purl.org/dc/terms/")
              |> Graph.add(
                Graph.new([
                  {Config.service_id(), Og.serviceStore(), RDF.bnode("store")},
                  {RDF.bnode("store"), Mud.this(), OgA.Oxigraph},
                  {Config.service_id(), ~I<http://purl.org/dc/terms/title>, "Example service"},
                  {Config.dataset_id(), ~I<http://purl.org/dc/terms/title>, "dev dataset"},
                  {Config.repository_id(), ~I<http://purl.org/dc/terms/title>, "dev repository"},
                  {Config.repository_id(), ~I<http://purl.org/dc/terms/creator>,
                   Config.agent_id()},
                  {Config.agent_id(), FOAF.name(), "Max Mustermann"},
                  {Config.agent_id(), Og.email(), ~I<mailto:max.mustermann@example.com>}
                ])
                |> Mud.process!()
              )}
  end

  test "empty path" do
    assert {:error, %ConfigError{reason: :missing}} =
             Loader.load_graph(load_path: TestData.config("empty"))
  end

  test "config path name" do
    assert Loader.load_graph(load_path: :local) ==
             Loader.load_graph(load_path: "config/ontogen")

    assert Loader.load_graph(load_path: :local) ==
             Loader.load_graph(load_path: "config/ontogen/test")
  end
end
