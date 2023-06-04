defmodule Ontogen.Repository do
  use Grax.Schema

  alias Ontogen.NS.Og
  alias Ontogen.{Dataset, ProvGraph}

  schema Og.Repository do
    link dataset: Og.dataset(), type: Dataset, required: true
    link prov_graph: Og.provGraph(), type: ProvGraph, required: true
  end

  def set_head(%__MODULE__{} = repo, commit) do
    with {:ok, dataset} <- Dataset.set_head(repo.dataset, commit) do
      Grax.put(repo, :dataset, dataset)
    end
  end
end
