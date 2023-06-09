defmodule Ontogen.Commands.ClearRepo do
  @moduledoc """
  This commands clears all contents of the current `Ontogen.Repo` and reinitializes it again.

  > #### Caution {: .error}
  >
  > This command is only for test environments.
  > Do not use this in production, unless you're really sure!
  > It will delete everything: the dataset, the history, the repo!

  """

  alias Ontogen.{Local, Store, Repository}
  alias Ontogen.Commands.CreateRepo

  def call(store) do
    :ready = Local.Repo.status()

    call(store, Local.Repo.repository())

    Local.Repo.reload()
  end

  def call(store, repository) do
    delete_repo(store, repository)

    with {:ok, repository} <- Repository.set_head(repository, nil) do
      CreateRepo.call(store, repository)
    end
  end

  def delete_repo(store, _repository) do
    Store.drop(store, :all)
  end
end
