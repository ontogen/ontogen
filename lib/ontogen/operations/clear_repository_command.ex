defmodule Ontogen.Operations.ClearRepositoryCommand do
  @moduledoc """
  This commands clears all contents of the current `Ontogen.Repository` and reinitializes it again.

  > #### Caution {: .error}
  >
  > This command is only for test environments.
  > Do not use this in production, unless you're really sure!
  > It will delete everything: the dataset, the history, the repo!

  """

  use Ontogen.Command

  alias Ontogen.{Store, Repository}
  alias Ontogen.Operations.CreateRepositoryCommand

  def new, do: {:ok, new!()}
  def new!, do: %__MODULE__{}

  @impl true
  def call(%__MODULE__{}, store, repository) do
    delete_repo(store, repository)

    with {:ok, repository} <- Repository.set_head(repository, nil),
         {:ok, command} = CreateRepositoryCommand.new(repository) do
      CreateRepositoryCommand.call(command, store)
    end
  end

  def delete_repo(store, _repository) do
    Store.drop(store, :all)
  end
end
