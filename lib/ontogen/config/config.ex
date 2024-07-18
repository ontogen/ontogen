defmodule Ontogen.Config do
  alias Ontogen.{Agent, Repository, Dataset, History, Service, Store}
  alias Ontogen.Config.Loader

  import Ontogen.Utils, only: [bang!: 2]

  defdelegate graph(opts \\ []), to: Loader, as: :load_graph

  def graph!(opts \\ []), do: bang!(&graph/1, [opts])

  [
    agent: Agent,
    service: Service,
    repository: Repository,
    dataset: Dataset,
    history: History
  ]
  |> Enum.each(fn {name, schema} ->
    bang_name = String.to_atom("#{name}!")

    def unquote(:"#{name}_id")(ref \\ :this) do
      unquote(schema).deref_id!(ref)
    end

    def unquote(name)(ref \\ :this, opts \\ []) do
      with {:ok, graph} <- graph(opts), do: unquote(schema).deref(ref, graph)
    end

    def unquote(bang_name)(ref \\ :this, opts \\ []) do
      unquote(schema).deref!(ref, graph!(opts))
    end
  end)

  defdelegate user(), to: __MODULE__, as: :agent
  defdelegate user!(), to: __MODULE__, as: :agent!

  def store(ref \\ :this, opts \\ [])

  def store(:this, opts) do
    with {:ok, graph} <- graph(opts),
         {:ok, service} <- Service.this(graph),
         do: {:ok, service.store}
  end

  def store(ref, opts) do
    with {:ok, graph} <- graph(opts), do: Store.deref(ref, graph)
  end

  def store!(ref \\ :this, opts \\ [])

  def store!(:this, opts) do
    Service.this!(graph!(opts)).store
  end

  def store!(ref, opts) do
    Store.deref(ref, graph!(opts))
  end
end
