defmodule Ontogen.Repository do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Dataset, ProvGraph, Commit}

  import Ontogen.Utils, only: [bang!: 2]
  schema Og.Repository do
    link dataset: Og.dataset(), type: Dataset, required: true
    link prov_graph: Og.provGraph(), type: ProvGraph, required: true

    link head: Og.head(),
         type: Commit,
         required: true,
         on_missing_description: :use_rdf_node
  end

  def new(id, attrs) do
    attrs = Keyword.put_new(attrs, :head, Commit.root())

    build(id, attrs)
  end

  def new!(id, attrs), do: bang!(&new/2, [id, attrs])

  def head_id(%__MODULE__{head: %Commit{__id__: id}}), do: id
  def head_id(%__MODULE__{head: head}), do: head

  def set_head(%__MODULE__{} = repository, :root), do: set_head(repository, Commit.root())

  def set_head(%__MODULE__{} = repository, commit) do
    Grax.put(repository, :head, commit)
  end

  def graph_id(%__MODULE__{} = repository), do: repository.__id__
  def dataset_graph_id(%__MODULE__{dataset: dataset}), do: dataset.__id__
  def prov_graph_id(%__MODULE__{prov_graph: prov_graph}), do: prov_graph.__id__
end
