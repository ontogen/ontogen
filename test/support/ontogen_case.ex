defmodule OntogenCase do
  @moduledoc """
  Common `ExUnit.CaseTemplate` for Ontogen tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use RDF

      alias Ontogen.{Service, Repository, Dataset, Manifest}
      alias RDF.{IRI, BlankNode, Literal, Graph}
      alias Ontogen.TestData
      alias Ontogen.NS.{Og, OgA}

      import unquote(__MODULE__)
      import RDF, only: [iri: 1, literal: 1, bnode: 1]
      import Ontogen.TestFactories
      import Ontogen.TestUtils
      import Ontogen.IdUtils
      import Ontogen.Utils

      alias Ontogen.TestNamespaces.EX
      @compile {:no_warn_undefined, Ontogen.TestNamespaces.EX}

      setup :clean_manifest_cache
    end
  end

  def clean_manifest_cache(_) do
    DCATR.Manifest.Cache.clear()
  end
end
