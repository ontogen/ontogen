defmodule Ontogen.Store.Adapters.FusekiTest do
  use OntogenCase, async: true

  doctest Ontogen.Store.Adapters.Fuseki

  alias Ontogen.Store.Adapters.Fuseki
  alias Ontogen.{Store, InvalidStoreEndpointError}

  test "endpoint_base/1" do
    assert Store.endpoint_base(%Fuseki{dataset: "test-dataset"}) ==
             {:ok, "http://localhost:3030/test-dataset"}

    assert Store.endpoint_base(%Fuseki{dataset: "test-dataset", port: 42}) ==
             {:ok, "http://localhost:42/test-dataset"}

    assert %Fuseki{dataset: "example-dataset", scheme: "https", host: "example.com", port: nil}
           |> Store.endpoint_base() ==
             {:ok, "https://example.com/example-dataset"}
  end

  test "query_endpoint/1" do
    assert Store.query_endpoint(%Fuseki{dataset: "test-dataset"}) ==
             {:ok, "http://localhost:3030/test-dataset/query"}

    assert Store.query_endpoint(%Fuseki{dataset: "test-dataset", port: 42}) ==
             {:ok, "http://localhost:42/test-dataset/query"}

    assert %Fuseki{dataset: "example-dataset", scheme: "https", host: "example.com", port: nil}
           |> Store.query_endpoint() ==
             {:ok, "https://example.com/example-dataset/query"}
  end

  test "update_endpoint/1" do
    assert Store.update_endpoint(%Fuseki{dataset: "test-dataset"}) ==
             {:ok, "http://localhost:3030/test-dataset/update"}

    assert Store.update_endpoint(%Fuseki{dataset: "test-dataset", port: 42}) ==
             {:ok, "http://localhost:42/test-dataset/update"}

    assert %Fuseki{dataset: "test-dataset", scheme: "https", host: "example.com", port: nil}
           |> Store.update_endpoint() ==
             {:ok, "https://example.com/test-dataset/update"}
  end

  test "graph_store_endpoint/1" do
    assert Store.graph_store_endpoint(%Fuseki{dataset: "test-dataset"}) ==
             {:ok, "http://localhost:3030/test-dataset/data"}

    assert Store.graph_store_endpoint(%Fuseki{dataset: "test-dataset", port: 42}) ==
             {:ok, "http://localhost:42/test-dataset/data"}

    assert %Fuseki{dataset: "test-dataset", scheme: "https", host: "example.com", port: nil}
           |> Store.graph_store_endpoint() ==
             {:ok, "https://example.com/test-dataset/data"}
  end

  test "dataset_endpoint_segment/1" do
    assert Store.dataset_endpoint_segment(%Fuseki{dataset: "test-dataset"}) ==
             {:ok, "test-dataset"}

    assert Store.dataset_endpoint_segment(%Fuseki{}) ==
             {:error,
              InvalidStoreEndpointError.exception(
                "missing :dataset value for store #{inspect(%Fuseki{})}"
              )}
  end

  test "*_endpoint/1 functions when endpoints set directly" do
    assert Store.query_endpoint(%Fuseki{query_endpoint: EX.query_endpoint()}) ==
             {:ok, to_string(EX.query_endpoint())}

    assert Store.update_endpoint(%Fuseki{update_endpoint: EX.update_endpoint()}) ==
             {:ok, to_string(EX.update_endpoint())}

    assert %Fuseki{graph_store_endpoint: EX.graph_store_endpoint()}
           |> Store.graph_store_endpoint() ==
             {:ok, to_string(EX.graph_store_endpoint())}
  end
end
