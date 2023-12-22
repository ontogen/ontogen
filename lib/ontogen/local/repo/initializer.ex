defmodule Ontogen.Local.Repo.Initializer do
  alias Ontogen.Local
  alias Ontogen.Local.Repo.IdFile
  alias Ontogen.Commands.{CreateRepo, FetchRepoInfo}

  def create_repo(store, repo_spec, opts \\ []) do
    with {:ok, repository} <- CreateRepo.call(store, repo_spec) do
      IdFile.create(repository, opts)

      {:ok, repository}
    end
  end

  def repository(opts) do
    with {:ok, repo_id} <- repo_id(opts) do
      FetchRepoInfo.call(store(opts), repo_id, depth: 1)
    end
  end

  def repo_id(opts) do
    cond do
      repo_id = Keyword.get(opts, :repo) -> {:ok, RDF.iri(repo_id)}
      repo_id = IdFile.read() -> {:ok, RDF.iri(repo_id)}
      repo_id = Application.get_env(:ontogen, :repo) -> {:ok, RDF.iri(repo_id)}
      true -> {:error, :repo_not_defined}
    end
  end

  def store(opts), do: Keyword.get(opts, :store, Local.store())
end
