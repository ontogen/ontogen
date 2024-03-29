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

  api do
    def clear_repository do
      ClearRepositoryCommand.new()
      |> ClearRepositoryCommand.__do_call__()
    end
  end

  def new, do: {:ok, new!()}
  def new!, do: %__MODULE__{}

  @impl true
  def call(%__MODULE__{}, store, repository) do
    delete_repo(store, repository)

    with {:ok, repository} <- Repository.set_head(repository, nil),
         {:ok, command} = CreateRepositoryCommand.new(repository, create_repo_id_file: false) do
      CreateRepositoryCommand.call(command, store)
    end
  end

  def delete_repo(store, _repository) do
    Store.drop(store, :all)
  end
end
