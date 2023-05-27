defmodule Ontogen.IdSpec do
  use Grax.Id.Spec

  import Grax.Id.UUID

  urn :uuid do
    uuid4 Ontogen.Utterance
  end
end
