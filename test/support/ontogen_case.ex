defmodule Ontogen.Test.Case do
  @moduledoc """
  Common `ExUnit.CaseTemplate` for Ontogen tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use RDF

      alias RDF.{IRI, BlankNode, Literal, Graph}
      alias Ontogen.TestData
      alias Ontogen.NS.Og

      import unquote(__MODULE__)
      import RDF, only: [iri: 1, literal: 1, bnode: 1]
      import Ontogen.TestFactories

      alias Ontogen.TestNamespaces.EX
      @compile {:no_warn_undefined, Ontogen.TestNamespaces.EX}
    end
  end
end
