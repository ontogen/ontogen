defmodule Ontogen.MudCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use OntogenCase, async: false

      import unquote(__MODULE__)

      setup :clean_index!
      setup :clean_seeds!
    end
  end

  @adapters_with_extra_prefixes [Gno.Store.Adapters.GraphDB]

  alias RDF.Graph

  def clean_index!(_context) do
    :ok = Mud.Identity.Index.clear()
  end

  def clean_seeds!(_context) do
    seed_path = "tmp/test/data/" <> _ = Mud.Seed.Directory.path()

    File.rm_rf!(seed_path)

    Mud.Seed.Directory.setup()

    :ok
  end

  def configured_store_adapter do
    "config/ontogen/test/service.ttl"
    |> RDF.read_file!()
    |> Graph.query([
      {:_service, Gno.serviceStore(), :_store},
      {:_store, Mud.this(), :store_adapter_class?}
    ])
    |> case do
      [%{store_adapter_class: store_adapter_class}] ->
        Grax.schema(store_adapter_class)
    end
  end

  @doc """
  Asserts RDF graph equality, normalizing prefix maps for store adapters
  that add extra namespace prefixes to CONSTRUCT responses (e.g. GraphDB).

  For other adapters, this performs a strict `==` comparison.
  """
  defmacro assert_graph_equal(left, right) do
    if configured_store_adapter() in @adapters_with_extra_prefixes do
      quote do
        assert Ontogen.MudCase.normalize_prefixes(unquote(left)) ==
                 Ontogen.MudCase.normalize_prefixes(unquote(right))
      end
    else
      quote do
        assert unquote(left) == unquote(right)
      end
    end
  end

  def normalize_prefixes({:ok, value}), do: {:ok, normalize_prefixes(value)}
  def normalize_prefixes({:error, _} = error), do: error

  def normalize_prefixes(%RDF.Graph{} = graph) do
    graph
    |> RDF.Graph.clear_prefixes()
    |> RDF.Graph.add_prefixes(RDF.standard_prefixes())
    |> RDF.Graph.add_prefixes(Ontogen.NS.prefixes())
  end

  def normalize_prefixes(other), do: other
end
