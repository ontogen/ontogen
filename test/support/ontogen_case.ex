defmodule Ontogen.Test.Case do
  @moduledoc """
  Common `ExUnit.CaseTemplate` for Ontogen tests.
  """

  use ExUnit.CaseTemplate

  use RDF.Vocabulary.Namespace
  defvocab EX, base_iri: "http://example.com/", terms: [], strict: false

  using do
    quote do
      use RDF

      alias RDF.{IRI, BlankNode, Literal, Graph}
      alias Ontogen.TestData

      import unquote(__MODULE__)
      import RDF, only: [iri: 1, literal: 1, bnode: 1]
      import Ontogen.TestFactories

      alias unquote(__MODULE__).EX
      @compile {:no_warn_undefined, Ontogen.Test.Case.EX}
    end
  end
end
