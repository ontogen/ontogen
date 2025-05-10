defmodule Ontogen.Operations.EffectiveChangesetQuery do
  use Ontogen.Operation.Query,
    params: [
      changeset: nil
    ]

  api do
    def effective_changeset(args) do
      args
      |> EffectiveChangesetQuery.new()
      |> EffectiveChangesetQuery.__do_call__()
    end

    def effective_changeset!(args), do: bang!(&effective_changeset/1, [args])
  end

  def new(changeset_args) do
    with {:ok, changeset} <- Gno.Changeset.new(changeset_args) do
      {:ok, %__MODULE__{changeset: changeset}}
    end
  end

  def new!(args \\ []), do: bang!(&new/1, [args])

  @impl true
  def call(%__MODULE__{changeset: changeset}, service) do
    Gno.EffectiveChangeset.Query.call(service, changeset)
  end
end
