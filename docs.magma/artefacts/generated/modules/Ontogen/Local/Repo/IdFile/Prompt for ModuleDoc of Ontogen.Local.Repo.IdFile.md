---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Local.Repo.IdFile]]"
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

Final version: [[ModuleDoc of Ontogen.Local.Repo.IdFile]]

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

# Prompt for ModuleDoc of Ontogen.Local.Repo.IdFile

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

![[Ontogen.Local.Repo.IdFile#Context knowledge|]]


## Request

![[Ontogen.Local.Repo.IdFile#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Local.Repo.IdFile` ![[Ontogen.Local.Repo.IdFile#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Local.Repo.IdFile do
  @repo_id_filename ".ontogen_repo"
  @env_repo_id_filename "#{@repo_id_filename}_#{Mix.env()}"
  @repo_id_filenames [@env_repo_id_filename, @repo_id_filename]

  @create_repo_id_file Application.compile_env(:ontogen, :create_repo_id_file, true)

  def create(repository, opts) when is_list(opts) do
    opts
    |> Keyword.get(:create_repo_id_file, @create_repo_id_file)
    |> do_create_repo_id_file(repository.__id__)
  end

  defp do_create_repo_id_file(nil, _), do: :skipped
  defp do_create_repo_id_file(false, _), do: :skipped

  defp do_create_repo_id_file(true, repo_id),
    do: do_create_repo_id_file(@repo_id_filename, repo_id)

  defp do_create_repo_id_file(:env, repo_id),
    do: do_create_repo_id_file(@env_repo_id_filename, repo_id)

  defp do_create_repo_id_file(filename, repo_id) do
    File.write!(filename, to_string(repo_id))
  end

  def read do
    Enum.find_value(@repo_id_filenames, fn filename ->
      if File.exists?(filename) do
        filename
        |> File.read!()
        |> String.trim()
      end
    end)
  end
end

```
