defmodule Ontogen.Store.SPARQL.Operation do
  defstruct [:name, :type, :update_type, :payload, :opts]

  @type query :: String.t()
  @type update :: String.t()
  @type data :: RDF.Data.t()
  @type payload :: query() | update() | data() | nil

  @type type :: :query | :update
  @type update_type :: :query | :data | :graph_store
  @type name :: atom

  @type t() :: %__MODULE__{
          type: type(),
          update_type: update_type(),
          name: name(),
          payload: payload(),
          opts: keyword
        }

  import Ontogen.Utils, only: [bang!: 2]

  def new(name, payload, opts \\ []) do
    with {:ok, name, type, update_type} <- typed_name(name) do
      {:ok,
       %__MODULE__{
         name: name,
         type: type,
         update_type: update_type,
         payload: payload,
         opts: opts
       }}
    end
  end

  def new!(name, payload, opts \\ []), do: bang!(&new/3, [name, payload, opts])

  defp typed_name(:select), do: {:ok, :select, :query, nil}
  defp typed_name(:construct), do: {:ok, :construct, :query, nil}
  defp typed_name(:ask), do: {:ok, :ask, :query, nil}
  defp typed_name(:describe), do: {:ok, :describe, :query, nil}

  defp typed_name(:insert_data), do: {:ok, :insert_data, :update, :data}
  defp typed_name(:delete_data), do: {:ok, :delete_data, :update, :data}

  defp typed_name(:insert), do: {:ok, :insert, :update, :query}
  defp typed_name(:delete), do: {:ok, :delete, :update, :query}
  defp typed_name(:update), do: {:ok, :update, :update, :query}

  defp typed_name(:load), do: {:ok, :load, :update, :graph_store}
  defp typed_name(:clear), do: {:ok, :clear, :update, :graph_store}

  defp typed_name(:drop), do: {:ok, :drop, :update, :graph_store}
  defp typed_name(:create), do: {:ok, :create, :update, :graph_store}
  defp typed_name(:add), do: {:ok, :add, :update, :graph_store}
  defp typed_name(:copy), do: {:ok, :copy, :update, :graph_store}
  defp typed_name(:move), do: {:ok, :move, :update, :graph_store}

  defp typed_name(invalid),
    do:
      {:error,
       Ontogen.InvalidSPARQLOperationError.exception(
         "invalid SPARQL operation type: #{inspect(invalid)}"
       )}

  def select(query, opts \\ []), do: new(:select, query, opts)
  def select!(query, opts \\ []), do: new!(:select, query, opts)
  def construct(query, opts \\ []), do: new(:construct, query, opts)
  def construct!(query, opts \\ []), do: new!(:construct, query, opts)
  def ask(query, opts \\ []), do: new(:ask, query, opts)
  def ask!(query, opts \\ []), do: new!(:ask, query, opts)
  def describe(query, opts \\ []), do: new(:describe, query, opts)
  def describe!(query, opts \\ []), do: new!(:describe, query, opts)

  def insert(update, opts \\ []), do: new(:insert, update, opts)
  def insert!(update, opts \\ []), do: new!(:insert, update, opts)
  def delete(update, opts \\ []), do: new(:delete, update, opts)
  def delete!(update, opts \\ []), do: new!(:delete, update, opts)
  def update(update, opts \\ []), do: new(:update, update, opts)
  def update!(update, opts \\ []), do: new!(:update, update, opts)

  def insert_data(data, opts \\ []), do: new(:insert_data, data, opts)
  def insert_data!(data, opts \\ []), do: new!(:insert_data, data, opts)
  def delete_data(data, opts \\ []), do: new(:delete_data, data, opts)
  def delete_data!(data, opts \\ []), do: new!(:delete_data, data, opts)

  def load(query, opts \\ []), do: new(:load, query, opts)
  def load!(query, opts \\ []), do: new!(:load, query, opts)

  def clear(opts \\ []), do: new(:clear, nil, opts)
  def clear!(opts \\ []), do: new!(:clear, nil, opts)
  def drop(opts \\ []), do: new(:drop, nil, opts)
  def drop!(opts \\ []), do: new!(:drop, nil, opts)
  def create(opts \\ []), do: new(:create, nil, opts)
  def create!(opts \\ []), do: new!(:create, nil, opts)
end
