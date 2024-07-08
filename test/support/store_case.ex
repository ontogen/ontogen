defmodule Ontogen.StoreCase do
  use ExUnit.CaseTemplate

  alias Ontogen.Store
  alias Ontogen.Store.SPARQL.Operation

  using do
    quote do
      use Ontogen.BogCase, async: false

      alias Ontogen.Store

      import unquote(__MODULE__)
      import Ontogen.TestFixtures

      setup :clean_store!
    end
  end

  def clean_store!(_) do
    :ok = Store.handle_sparql(Operation.drop!(), Ontogen.Config.store!(), :all)
  end
end
