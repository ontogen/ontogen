---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Local.Repo.Initializer]]"
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

Final version: [[ModuleDoc of Ontogen.Local.Repo.Initializer]]

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

# Prompt for ModuleDoc of Ontogen.Local.Repo.Initializer

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

##### `Ontogen.Local` ![[Ontogen.Local#Description|]]

##### `Ontogen.Local.Repo` ![[Ontogen.Local.Repo#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Local.Repo.Initializer#Context knowledge|]]


## Request

![[Ontogen.Local.Repo.Initializer#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Local.Repo.Initializer` ![[Ontogen.Local.Repo.Initializer#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Local.Repo.Initializer do
  alias Ontogen.{Local, Commands}
  alias Ontogen.Local.Repo.IdFile

  def create_repo(store, repo_spec, opts \\ []) do
    with {:ok, repository} <- Commands.CreateRepo.call(store, repo_spec) do
      IdFile.create(repository, opts)

      {:ok, repository}
    end
  end

  def repository(opts) do
    with {:ok, repo_id} <- repo_id(opts) do
      # TODO: How can get rid of this depth: 1 limitation, which is needed since the agent can't be preloaded?
      Commands.RepoInfo.call(store(opts), repo_id, depth: 1)
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

```
