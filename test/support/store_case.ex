defmodule Ontogen.StoreCase do
  use ExUnit.CaseTemplate

  alias Gno.Store
  alias Gno.Store.SPARQL.Operation

  using do
    quote do
      use Ontogen.MudCase, async: false

      alias Ontogen.Store

      import unquote(__MODULE__)
      import Ontogen.TestFixtures

      setup :clean_store!
    end
  end

  def clean_store!(_) do
    store = Ontogen.Manifest.store!()
    :ok = Gno.Store.setup(store)
    :ok = Store.handle_sparql(Operation.drop!(), store, :all)
  end
end
