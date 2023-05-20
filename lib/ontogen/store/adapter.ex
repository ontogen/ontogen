defmodule Ontogen.Store.Adapter do
  @moduledoc """
  A behaviour for SPARQL triple stores hosting an `Ontogen.Repo`.
  """

  alias Ontogen.Store
  alias RDF.Graph

  @type query :: String.t()
  @type update :: String.t()

  @callback query(Store.t(), query(), Keyword.t()) ::
              {:ok, SPARQL.Query.Result.t()} | {:error, any}

  @callback construct(Store.t(), query(), Keyword.t()) ::
              {:ok, Graph.t()} | {:error, any}

  @callback ask(Store.t(), query(), Keyword.t()) ::
              {:ok, boolean} | {:error, any}

  @callback describe(Store.t(), query(), Keyword.t()) ::
              {:ok, Graph.t()} | {:error, any}

  @callback insert(Store.t(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback delete(Store.t(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback update(Store.t(), update(), Keyword.t()) ::
              :ok | {:error, any}

  @callback insert_data(Store.t(), Graph.t(), Keyword.t()) ::
              :ok | {:error, any}

  @callback delete_data(Store.t(), Graph.t(), Keyword.t()) ::
              :ok | {:error, any}
end
