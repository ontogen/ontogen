defmodule Ontogen.Store.Adapters.OxigraphTest do
  use OntogenCase, async: true

  doctest Ontogen.Store.Adapters.Oxigraph

  alias Ontogen.Store.Adapters.Oxigraph
  alias Ontogen.Store

  test "endpoint_base/1" do
    assert Store.endpoint_base(%Oxigraph{}) ==
             {:ok, "http://localhost:7878"}

    assert Store.endpoint_base(%Oxigraph{port: 7879}) ==
             {:ok, "http://localhost:7879"}

    assert Store.endpoint_base(%Oxigraph{scheme: "https", host: "example.com", port: nil}) ==
             {:ok, "https://example.com"}
  end

  test "query_endpoint/1" do
    assert Store.query_endpoint(%Oxigraph{}) ==
             {:ok, "http://localhost:7878/query"}

    assert Store.query_endpoint(%Oxigraph{port: 7879}) ==
             {:ok, "http://localhost:7879/query"}

    assert %Oxigraph{scheme: "https", host: "example.com", port: nil}
           |> Store.query_endpoint() ==
             {:ok, "https://example.com/query"}
  end

  test "update_endpoint/1" do
    assert Store.update_endpoint(%Oxigraph{}) ==
             {:ok, "http://localhost:7878/update"}

    assert Store.update_endpoint(%Oxigraph{port: 7879}) ==
             {:ok, "http://localhost:7879/update"}

    assert Store.update_endpoint(%Oxigraph{scheme: "https", host: "example.com", port: nil}) ==
             {:ok, "https://example.com/update"}
  end

  test "graph_store_endpoint/1" do
    assert Store.graph_store_endpoint(%Oxigraph{}) ==
             {:ok, "http://localhost:7878/store"}

    assert Store.graph_store_endpoint(%Oxigraph{port: 7879}) ==
             {:ok, "http://localhost:7879/store"}

    assert Store.graph_store_endpoint(%Oxigraph{scheme: "https", host: "example.com", port: nil}) ==
             {:ok, "https://example.com/store"}
  end

  test "dataset_endpoint_segment/1" do
    assert Store.dataset_endpoint_segment(%Oxigraph{}) == {:ok, ""}
  end

  test "*_endpoint/1 functions when endpoints set directly" do
    assert Store.query_endpoint(%Oxigraph{query_endpoint: EX.query_endpoint()}) ==
             {:ok, to_string(EX.query_endpoint())}

    assert Store.update_endpoint(%Oxigraph{update_endpoint: EX.update_endpoint()}) ==
             {:ok, to_string(EX.update_endpoint())}

    assert Store.graph_store_endpoint(%Oxigraph{graph_store_endpoint: EX.graph_store_endpoint()}) ==
             {:ok, to_string(EX.graph_store_endpoint())}
  end
end
