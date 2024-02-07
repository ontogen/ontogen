defmodule Ontogen.StoreCase do
  use ExUnit.CaseTemplate

  alias Ontogen.Store

  using do
    quote do
      use OntogenCase, async: false

      alias Ontogen.Store

      import unquote(__MODULE__)

      setup :clean_store!
    end
  end

  def clean_store!(_) do
    Ontogen.Config.store() |> Store.drop(:all)
  end
end
