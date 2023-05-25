defmodule Ontogen.Store.Test.Case do
  use ExUnit.CaseTemplate

  alias Ontogen.{Local, Store}

  using do
    quote do
      use Ontogen.Test.Case, async: false

      alias Ontogen.{Local, Store}

      import unquote(__MODULE__)

      setup :clean_store!
    end
  end

  def clean_store!(_) do
    Local.store() |> Store.drop(:all)
  end
end
