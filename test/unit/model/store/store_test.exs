defmodule Ontogen.StoreTest do
  use Ontogen.StoreCase

  doctest Ontogen.Store.GenSPARQL

  alias Ontogen.{Store, Repository, Dataset, Config, InvalidStoreEndpointError}
  alias Ontogen.Store.SPARQL.Operation

  # These tests serve as integration tests for
  # - Ontogen.Store
  # - Ontogen.Store.GenSPARQL
  # - all Ontogen.Store.Adapter.handle_sparql/4 implementations
  #   (since this test suite is supposed to be run on the different triple stores in its entirety)

  describe "handle/4" do
    test "default graph" do
      assert {:ok, %SPARQL.Query.Result{results: []}} =
               "SELECT * WHERE { ?s ?p ?o . }"
               |> Operation.select!()
               |> Store.handle_sparql(Config.store!(), nil)

      assert EX.S
             |> EX.p(EX.O)
             |> RDF.graph()
             |> Operation.insert_data!()
             |> Store.handle_sparql(Config.store!(), nil) ==
               :ok

      assert {:ok,
              %SPARQL.Query.Result{
                results: [
                  %{
                    "s" => ~I<http://example.com/S>,
                    "p" => ~I<http://example.com/p>,
                    "o" => ~I<http://example.com/O>
                  }
                ]
              }} =
               "SELECT * WHERE { ?s ?p ?o . }"
               |> Operation.select!()
               |> Store.handle_sparql(Config.store!(), nil)
    end

    test "named graph" do
      assert {:ok, %SPARQL.Query.Result{results: []}} =
               "SELECT * WHERE { ?s ?p ?o . }"
               |> Operation.select!()
               |> Store.handle_sparql(Config.store!(), Dataset.this_id!())

      assert EX.S
             |> EX.p(EX.O)
             |> RDF.graph()
             |> Operation.insert_data!()
             |> Store.handle_sparql(Config.store!(), Dataset.this_id!()) ==
               :ok

      assert {:ok,
              %SPARQL.Query.Result{
                results: [
                  %{
                    "s" => ~I<http://example.com/S>,
                    "p" => ~I<http://example.com/p>,
                    "o" => ~I<http://example.com/O>
                  }
                ]
              }} =
               "SELECT * WHERE { ?s ?p ?o . }"
               |> Operation.select!()
               |> Store.handle_sparql(Config.store!(), Dataset.this_id!())

      graph =
        EX.S2
        |> EX.p(EX.O2)
        |> RDF.graph()

      assert graph
             |> Operation.insert_data!()
             |> Store.handle_sparql(Config.store!(), Repository.this_id!()) ==
               :ok

      assert "CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o . }"
             |> Operation.construct!()
             |> Store.handle_sparql(Config.store!(), Repository.this_id!()) ==
               {:ok, graph}
    end
  end

  test "endpoint_base/1" do
    assert Store.endpoint_base(%Store{}) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "endpoint_base not supported on generic #{inspect(%Store{})}"
              )}

    store = %Store{query_endpoint: EX.query_endpoint()}

    assert Store.endpoint_base(store) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "endpoint_base not supported on generic #{inspect(store)}"
              )}
  end

  test "query_endpoint/1" do
    assert Store.query_endpoint(%Store{}) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "undefined query_endpoint on generic #{inspect(%Store{})}"
              )}

    store = %Store{scheme: "https", host: "example.com", port: nil}

    assert Store.query_endpoint(store) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "undefined query_endpoint on generic #{inspect(store)}"
              )}
  end

  test "update_endpoint/1" do
    assert Store.update_endpoint(%Store{}) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "undefined update_endpoint on generic #{inspect(%Store{})}"
              )}

    store = %Store{scheme: "https", host: "example.com", port: nil}

    assert Store.update_endpoint(store) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "undefined update_endpoint on generic #{inspect(store)}"
              )}
  end

  test "graph_store_endpoint/1" do
    assert Store.graph_store_endpoint(%Store{}) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "undefined graph_store_endpoint on generic #{inspect(%Store{})}"
              )}

    store = %Store{scheme: "https", host: "example.com", port: nil}

    assert Store.graph_store_endpoint(store) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "undefined graph_store_endpoint on generic #{inspect(store)}"
              )}
  end

  test "dataset_endpoint_segment/1" do
    store = %Store{query_endpoint: EX.query_endpoint()}

    assert Store.dataset_endpoint_segment(store) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "dataset_endpoint_segment not supported on generic #{inspect(store)}"
              )}
  end

  test "*_endpoint/1 functions when endpoints set directly" do
    assert %Store{query_endpoint: EX.query_endpoint()} |> Store.query_endpoint() ==
             {:ok, to_string(EX.query_endpoint())}

    assert %Store{update_endpoint: EX.update_endpoint()} |> Store.update_endpoint() ==
             {:ok, to_string(EX.update_endpoint())}

    assert %Store{graph_store_endpoint: EX.graph_store_endpoint()}
           |> Store.graph_store_endpoint() ==
             {:ok, to_string(EX.graph_store_endpoint())}
  end
end
