defmodule Ontogen.Store.Adapter do
  @moduledoc """
  A behaviour for SPARQL triple stores hosting an `Ontogen.Repository`.
  """

  alias Ontogen.Store
  alias RDF.{Graph, IRI}

  @type type :: module

  @type query :: String.t()
  @type update :: String.t()
  @type graph :: IRI.coercible()

  @callback query(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, SPARQL.Query.Result.t()} | {:error, any}

  @callback construct(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, Graph.t()} | {:error, any}

  @callback ask(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, boolean} | {:error, any}

  @callback describe(Store.t(), graph(), query(), Keyword.t()) ::
              {:ok, Graph.t()} | {:error, any}

  @callback insert(Store.t(), graph(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback delete(Store.t(), graph(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback update(Store.t(), graph(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback insert_data(Store.t(), graph(), Graph.t(), Keyword.t()) ::
              :ok | {:error, any}

  @callback delete_data(Store.t(), graph(), Graph.t(), Keyword.t()) ::
              :ok | {:error, any}

  @callback create(Store.t(), graph(), Keyword.t()) ::
              :ok | {:error, any}

  @callback clear(Store.t(), graph() | :all | :default | :named, Keyword.t()) ::
              :ok | {:error, any}

  @callback drop(Store.t(), graph() | :all | :default | :named, Keyword.t()) ::
              :ok | {:error, any}

  @doc """
  Returns the `Ontogen.Store.Adapter` module for the given string.

  ## Example

      iex> Ontogen.Store.Adapter.type("Oxigraph")
      Ontogen.Store.Oxigraph

      iex> Ontogen.Store.Adapter.type("Commit")
      nil

      iex> Ontogen.Store.Adapter.type("NonExisting")
      nil

  """
  @spec type(binary) :: type() | nil
  def type(string) when is_binary(string) do
    module = Module.concat(Ontogen.Store, string)

    if type?(module) do
      module
    end
  end

  @doc """
  Checks if the given `module` is a `Ontogen.Store.Adapter` module.
  """
  @spec type?(module) :: boolean
  def type?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :insert_data, 4)
  end
end
