defmodule Ontogen.Commands.CreateRepo do
  alias Ontogen.{Repository, Dataset, ProvGraph, Store, InvalidRepoSpecError}
  alias Ontogen.Commands.FetchRepoInfo
  alias Ontogen.Local.Repo.IdFile
  alias RDF.IRI

  def call(store, repository, opts \\ [])

  def call(store, %Repository{} = repository, opts) do
    with :ok <- check_not_exists(store, repository),
         :ok <- init_repo_store(store, repository) do
      IdFile.create(repository, opts)

      {:ok, repository}
    end
  end

  def call(store, repo_spec, opts) do
    with {:ok, dataset} <- dataset(repo_spec),
         {:ok, prov_graph} <- prov_graph(repo_spec),
         {:ok, repository} <- repository(repo_spec, dataset, prov_graph) do
      call(store, repository, opts)
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

    case Keyword.pop(spec, :id) do
      {nil, spec} -> Repository.build(spec)
      {id, spec} -> Repository.build(id, spec)
    end
  end

  defp check_not_exists(store, repository) do
    case FetchRepoInfo.call(store, repository.__id__) do
      {:error, :repo_not_found} -> :ok
      {:ok, _} -> {:error, :repo_already_exists}
      other -> other
    end
  end

  defp init_repo_store(store, repo) do
    Store.insert_data(store, Repository.graph_id(repo), Grax.to_rdf!(repo))
  end
end
