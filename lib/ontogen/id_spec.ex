defmodule Ontogen.IdSpec do
  use Grax.Id.Spec

  import Grax.Id.UUID

  @ontogen_uuid_namespace "d6a16b91-f160-530e-b932-9e25e098581f" =
                            UUID.uuid5(:dns, "ontogen.io")

  @bog_uuid_namespace "30366299-98eb-5325-8561-9096f6673f3d" =
                        UUID.uuid5(@ontogen_uuid_namespace, "bog")

  def ontogen_uuid_namespace, do: @ontogen_uuid_namespace
  def bog_uuid_namespace, do: @bog_uuid_namespace

  urn :uuid do
    uuid5 Ontogen.Bog.Referencable.__hash__(), namespace: @bog_uuid_namespace
  end
end
