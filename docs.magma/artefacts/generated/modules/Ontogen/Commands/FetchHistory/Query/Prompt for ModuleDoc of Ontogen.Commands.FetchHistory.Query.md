---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.FetchHistory.Query]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.FetchHistory.Query]]

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

# Prompt for ModuleDoc of Ontogen.Commands.FetchHistory.Query

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

##### `Ontogen.Commands.FetchHistory` ![[Ontogen.Commands.FetchHistory#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Ontogen.Commands.FetchHistory.Query#Context knowledge|]]


## Request

![[Ontogen.Commands.FetchHistory.Query#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.FetchHistory.Query` ![[Ontogen.Commands.FetchHistory.Query#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.FetchHistory.Query do
  alias Ontogen.Repository
  alias Ontogen.NS.Og

  import Ontogen.QueryUtils

  def build(repository, subject, opts \\ [])

  def build(repository, {:dataset, _dataset_id}, opts) do
    do_build(repository, nil, opts)
  end

  def build(repository, {:resource, resource}, opts) do
    do_build(repository, resource, opts)
  end

  def build(repository, {:statement, statement}, opts) do
    do_build(repository, statement, opts)
  end

  defp do_build(repository, subject, opts) do
    with {:ok, from_commit} <- from_commit(repository, opts) do
      {:ok, query(subject, from_commit, to_commit(opts))}
    end
  end

  defp from_commit(repository, opts) do
    if commit = Keyword.get(opts, :from_commit, Repository.head_id(repository)) do
      {:ok, commit}
    else
      {:error, :no_head}
    end
  end

  defp to_commit(opts) do
    Keyword.get(opts, :to_commit)
  end

  defp query(subject, from_commit, to_commit) do
    # TODO: use prefix helper
    """
    PREFIX og: <#{Og.__base_iri__()}>
    PREFIX rtc: <#{RTC.__base_iri__()}>
    CONSTRUCT { #{commit_statements_construct_pattern()} }
    WHERE {
      <#{from_commit}> og:parentCommit* ?commit .
      #{filter_commits(to_commit)}
      #{commit_statements_query_pattern(subject)}
    }
    """
  end

  defp filter_commits(nil), do: ""

  defp filter_commits(to_commit) do
    "MINUS { <#{to_commit}> og:parentCommit* ?commit . }"
  end

  defp commit_statements_construct_pattern do
    """
    ?commit ?commit_p ?commit_o .
    ?committed_insertion ?committed_insertion_p ?committed_insertion_o .
    ?committed_deletion ?committed_deletion_p ?committed_deletion_o .
    ?committed_update ?committed_update_p ?committed_update_o .
    ?committed_replacement ?committed_replacement_p ?committed_replacement_o .
    ?committed_overwrite ?committed_overwrite_p ?committed_overwrite_o .
    ?committer ?committer_p ?committer_o .
    ?speech_act ?speech_act_p ?speech_act_o .
    ?speaker ?speaker_p ?speaker_o .
    ?insertion ?insertion_p ?insertion_o .
    ?deletion ?deletion_p ?deletion_o .
    ?update ?update_p ?update_o .
    ?replacement ?replacement_p ?replacement_o .
    """
  end

  defp commit_statements_query_pattern(subject) do
    """
    ?commit
        ?commit_p ?commit_o ;
        og:committer ?committer ;
        og:speechAct ?speech_act .

      ?committer ?committer_p ?committer_o .

      {
        {
          ?commit og:committedInsertion ?committed_insertion .
          #{statement_filter("?committed_insertion", subject)}
        }
        UNION
        {
          ?commit og:committedDeletion ?committed_deletion .
          #{statement_filter("?committed_deletion", subject)}
        }
        UNION
        {
          ?commit og:committedUpdate ?committed_update .
          #{statement_filter("?committed_update", subject)}
        }
        UNION
        {
          ?commit og:committedReplacement ?committed_replacement .
          #{statement_filter("?committed_replacement", subject)}
        }
        UNION
        {
          ?commit og:committedOverwrite ?committed_overwrite .
          #{statement_filter("?committed_overwrite", subject)}
        }
      }

      OPTIONAL {
        ?commit og:committedInsertion ?committed_insertion .
        ?committed_insertion ?committed_insertion_p ?committed_insertion_o .
      }
      OPTIONAL {
        ?commit og:committedDeletion ?committed_deletion .
        ?committed_deletion ?committed_deletion_p ?committed_deletion_o .
      }
      OPTIONAL {
        ?commit og:committedUpdate ?committed_update .
        ?committed_update ?committed_update_p ?committed_update_o .
      }
      OPTIONAL {
        ?commit og:committedReplacement ?committed_replacement .
        ?committed_replacement ?committed_replacement_p ?committed_replacement_o .
      }
      OPTIONAL {
        ?commit og:committedOverwrite ?committed_overwrite .
        ?committed_overwrite ?committed_overwrite_p ?committed_overwrite_o .
      }

      ?speech_act
        ?speech_act_p ?speech_act_o ;
        og:speaker ?speaker .

      ?speaker ?speaker_p ?speaker_o .

      OPTIONAL {
        ?speech_act og:insertion ?insertion .
        ?insertion ?insertion_p ?insertion_o .
      }
      OPTIONAL {
        ?speech_act og:deletion ?deletion .
        ?deletion ?deletion_p ?deletion_o .
      }
      OPTIONAL {
        ?speech_act og:update ?update .
        ?update ?update_p ?update_o .
      }
      OPTIONAL {
        ?speech_act og:replacement ?replacement .
        ?replacement ?replacement_p ?replacement_o .
      }
    """
  end

  defp statement_filter(_, nil), do: ""

  defp statement_filter(proposition, {s, p, o}) do
    "#{proposition} rtc:elements << #{to_term(s)} #{to_term(p)} #{to_term(o)} >> ."
  end

  defp statement_filter(proposition, {s, p}) do
    "#{proposition} rtc:elements << #{to_term(s)} #{to_term(p)} ?resource_o >> ."
  end

  defp statement_filter(proposition, resource) do
    "#{proposition} rtc:elements << #{to_term(resource)} ?resource_p ?resource_o >> ."
  end
end

```
