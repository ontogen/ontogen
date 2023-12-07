---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.CreateRepo]]"
magma_generation_type: OpenAI
magma_generation_params: {"model":"gpt-4","temperature":0.6}
created_at: 2023-12-07 14:16:14
tags: [magma-vault]
aliases: []
---

**Generated results**

```dataview
TABLE
	tags AS Tags,
	magma_generation_type AS Generator,
	magma_generation_params AS Params
WHERE magma_prompt = [[]]
```

Final version: [[ModuleDoc of Ontogen.Commands.CreateRepo]]

**Actions**

```button
name Execute
type command
action Shell commands: Execute: magma.prompt.exec
color blue
```
```button
name Execute manually
type command
action Shell commands: Execute: magma.prompt.exec-manual
color blue
```
```button
name Copy to clipboard
type command
action Shell commands: Execute: magma.prompt.copy
color default
```
```button
name Update
type command
action Shell commands: Execute: magma.prompt.update
color default
```

# Prompt for ModuleDoc of Ontogen.Commands.CreateRepo

## System prompt

![[Magma.system.config#Persona|]]

![[ModuleDoc.artefact.config#System prompt|]]

### Context knowledge

The following sections contain background knowledge you need to be aware of, but which should NOT necessarily be covered in your response as it is documented elsewhere. Only mention absolutely necessary facts from it. Use a reference to the source if necessary.

![[Magma.system.config#Context knowledge|]]

#### Description of the Ontogen project ![[Project#Description|]]

![[Module.matter.config#Context knowledge|]]

#### Peripherally relevant modules

##### `Ontogen` ![[Ontogen#Description|]]

##### `Ontogen.Commands` ![[Ontogen.Commands#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commands.CreateRepo#Context knowledge|]]


## Request

![[Ontogen.Commands.CreateRepo#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.CreateRepo` ![[Ontogen.Commands.CreateRepo#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.CreateRepo do
  alias Ontogen.{Repository, Dataset, ProvGraph, Store, InvalidRepoSpecError}
  alias RDF.IRI

  # TODO: Do we want this short-form or explicitly enforce the specification of the store?
  #  def call(repo_spec), do: call(Ontogen.Local.store(), repo_spec)

  def call(store, %Repository{} = repository) do
    with :ok <- check_not_exists(store, repository),
         :ok <- init_repo_store(store, repository) do
      {:ok, repository}
    end
  end

  def call(store, repo_spec) do
    with {:ok, dataset} <- dataset(repo_spec),
         {:ok, prov_graph} <- prov_graph(repo_spec),
         {:ok, repository} <- repository(repo_spec, dataset, prov_graph) do
      call(store, repository)
    end
  end

  defp dataset(repo_spec) do
    case Keyword.get(repo_spec, :dataset) do
      %Dataset{} = dataset -> Grax.validate(dataset)
      # TODO: try to build id from base id
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
      # TODO: try to build id from base id
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
      # TODO: try to build id from base id
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
      # TODO: the dataset should include a backlink to the repository
      |> Keyword.put(:dataset, dataset)
      |> Keyword.put(:prov_graph, prov_graph)

    # TODO: when no repo id is specified, but an og:repository on the dataset use this one ...
    case Keyword.pop(spec, :id) do
      {nil, spec} -> Repository.build(spec)
      {id, spec} -> Repository.build(id, spec)
    end
  end

  defp check_not_exists(store, repository) do
    # TODO: Find a faster way. We don't need to fetch the complete repo ...
    case Ontogen.Commands.RepoInfo.call(store, repository.__id__) do
      {:error, :repo_not_found} -> :ok
      {:ok, _} -> {:error, :repo_already_exists}
      other -> other
    end
  end

  defp init_repo_store(store, repo) do
    Store.insert_data(store, Repository.graph_id(repo), Grax.to_rdf!(repo))
  end
end

```
