defmodule TestReferencable do
  @moduledoc """
  Test referencable.
  """

  use Grax.Schema
  use Ontogen.Bog.Referencable

  alias Ontogen.TestNamespaces.EX
  @compile {:no_warn_undefined, Ontogen.TestNamespaces.EX}

  schema EX.TestReferencable do
    property foo: EX.foo()
  end
end
