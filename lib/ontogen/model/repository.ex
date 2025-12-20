defmodule Ontogen.Repository do
  use DCATR.Repository.Type
  use Mud.Referencable

  alias Ontogen.NS.Og
  alias Ontogen.{History, Commit}

  import Ontogen.Utils, only: [bang!: 2]

  schema Og.Repository < DCATR.Repository do
    link history: Og.repositoryHistory(), type: History, required: true, depth: +1

    link head: Og.head(), type: Commit, on_missing_description: :use_rdf_node
  end

  def new(id, attrs) do
    attrs = Keyword.put_new(attrs, :head, Commit.root())

    build(id, attrs)
  end

  def new!(id, attrs), do: bang!(&new/2, [id, attrs])

  @impl true
  def resolve_graph_selector(%_{history: history}, :history), do: history
  def resolve_graph_selector(repository, selector), do: super(repository, selector)

  @impl true
  def system_graphs(%_{history: history} = repo), do: [history | super(repo)]

  def head_id(%__MODULE__{head: %Commit{__id__: id}}), do: id
  def head_id(%__MODULE__{head: nil}), do: Commit.root()
  def head_id(%__MODULE__{head: head}), do: head

  def set_head(%__MODULE__{} = repository, :root), do: set_head(repository, Commit.root())

  def set_head(%__MODULE__{} = repository, commit) do
    Grax.put(repository, :head, commit)
  end

  def set_head!(repository, commit), do: bang!(&set_head/2, [repository, commit])
end
