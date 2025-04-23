defmodule Ontogen.Repository do
  use Grax.Schema
  use Mud.Referencable

  alias Ontogen.NS.Og
  alias Ontogen.{Dataset, History, Commit}

  import Ontogen.Utils, only: [bang!: 2]

  schema Og.Repository < Gno.Repository do
    link dataset: Og.repositoryDataset(), type: Dataset, required: true
    link history: Og.repositoryHistory(), type: History, required: true

    link head: Og.head(), type: Commit, on_missing_description: :use_rdf_node
  end

  def new(id, attrs) do
    attrs = Keyword.put_new(attrs, :head, Commit.root())

    build(id, attrs)
  end

  def new!(id, attrs), do: bang!(&new/2, [id, attrs])

  def head_id(%__MODULE__{head: %Commit{__id__: id}}), do: id
  def head_id(%__MODULE__{head: nil}), do: Commit.root()
  def head_id(%__MODULE__{head: head}), do: head

  def set_head(%__MODULE__{} = repository, :root), do: set_head(repository, Commit.root())

  def set_head(%__MODULE__{} = repository, commit) do
    Grax.put(repository, :head, commit)
  end

  def set_head!(repository, commit), do: bang!(&set_head/2, [repository, commit])

  def history_graph_id(%{history: history}), do: history.__id__

  defdelegate dataset_graph_id(repository), to: Gno.Repository
  defdelegate graph_id(repository), to: Gno.Repository

  def graph_id(repository, :history), do: history_graph_id(repository)
  def graph_id(repository, name), do: Gno.Repository.graph_id(repository, name)
end
