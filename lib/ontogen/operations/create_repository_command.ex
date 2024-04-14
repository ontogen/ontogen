defmodule Ontogen.Operations.CreateRepositoryCommand do
  use Ontogen.Command,
    params: [
      repository: nil,
      create_repo_id_file: true
    ]

  alias Ontogen.{Repository, Dataset, ProvGraph, Store, Commit, InvalidRepoSpecError}
  alias Ontogen.Config.Repository.IdFile
  alias RDF.IRI

  api do
    def create_repo(repo_spec, opts \\ []) do
      repo_spec
      |> CreateRepositoryCommand.new(opts)
      |> CreateRepositoryCommand.__do_call__()
    end
  end

  def new(repository_spec, opts \\ [])

  def new(%Repository{} = repository, opts) do
    {:ok,
     %__MODULE__{
       repository: repository,
       create_repo_id_file: Keyword.get(opts, :create_repo_id_file, true)
     }}
  end

  def new(repository_spec, []) do
    repo_id_file_opts = Keyword.take(repository_spec, [:create_repo_id_file])
    repository_spec = Keyword.drop(repository_spec, Keyword.keys(repo_id_file_opts))

    with {:ok, dataset} <- dataset(repository_spec),
         {:ok, prov_graph} <- prov_graph(repository_spec),
         {:ok, repository} <- repository(repository_spec, dataset, prov_graph) do
      new(repository, repo_id_file_opts)
    end
  end

  defp dataset(repo_spec) do
    case Keyword.get(repo_spec, :dataset) do
      %Dataset{} = dataset -> Grax.validate(dataset)
      nil -> {:error, InvalidRepoSpecError.exception(reason: "missing dataset spec")}
      spec -> build_dataset(spec)
    end
  end

  defp build_dataset(iri) when is_binary(iri), do: iri |> RDF.iri() |> build_dataset()
  defp build_dataset(%IRI{} = iri), do: build_dataset(id: iri)
  defp build_dataset(spec) when is_map(spec), do: spec |> Keyword.new() |> build_dataset()

  defp build_dataset(spec) when is_list(spec) do
    case Keyword.pop(spec, :id) do
      {nil, spec} -> Dataset.build(spec)
      {id, spec} -> Dataset.build(id, spec)
    end
  end

  defp prov_graph(repo_spec) do
    case Keyword.get(repo_spec, :prov_graph) do
      %ProvGraph{} = prov_graph -> Grax.validate(prov_graph)
      nil -> {:error, InvalidRepoSpecError.exception(reason: "missing prov_graph spec")}
      spec -> build_prov_graph(spec)
    end
  end

  defp build_prov_graph(iri) when is_binary(iri), do: iri |> RDF.iri() |> build_prov_graph()
  defp build_prov_graph(%IRI{} = iri), do: build_prov_graph(id: iri)
  defp build_prov_graph(spec) when is_map(spec), do: spec |> Keyword.new() |> build_prov_graph()

  defp build_prov_graph(spec) when is_list(spec) do
    case Keyword.pop(spec, :id) do
      {nil, spec} -> ProvGraph.build(spec)
      {id, spec} -> ProvGraph.build(id, spec)
    end
  end

  defp repository(repo_spec, dataset, prov_graph) do
    case Keyword.get(repo_spec, :repo) do
      nil -> {:error, InvalidRepoSpecError.exception(reason: "missing repo spec")}
      spec -> build_repo(spec, dataset, prov_graph)
    end
  end

  defp build_repo(iri, dataset, prov_graph) when is_binary(iri),
    do: iri |> RDF.iri() |> build_repo(dataset, prov_graph)

  defp build_repo(%IRI{} = iri, dataset, prov_graph),
    do: build_repo([id: iri], dataset, prov_graph)

  defp build_repo(spec, dataset, prov_graph) when is_map(spec),
    do: spec |> Keyword.new() |> build_repo(dataset, prov_graph)

  defp build_repo(spec, dataset, prov_graph) when is_list(spec) do
    spec =
      spec
      |> Keyword.put(:dataset, dataset)
      |> Keyword.put(:prov_graph, prov_graph)
      |> Keyword.put(:head, Commit.root())

    case Keyword.pop(spec, :id) do
      {nil, spec} -> Repository.build(spec)
      {id, spec} -> Repository.build(id, spec)
    end
  end

  @impl true
  def call(%__MODULE__{repository: repository} = command, store, _ \\ nil) do
    with :ok <- check_not_exists(store, repository),
         :ok <- init_repo_store(store, repository) do
      if command.create_repo_id_file, do: IdFile.create(repository)

      {:ok, repository}
    end
  end

  defp check_not_exists(store, repository) do
    case Store.repository(store, repository.__id__) do
      {:error, :repo_not_found} -> :ok
      {:ok, _} -> {:error, :repo_already_exists}
      other -> other
    end
  end

  defp init_repo_store(store, repo) do
    Store.insert_data(store, Repository.graph_id(repo), Grax.to_rdf!(repo))
  end
end
