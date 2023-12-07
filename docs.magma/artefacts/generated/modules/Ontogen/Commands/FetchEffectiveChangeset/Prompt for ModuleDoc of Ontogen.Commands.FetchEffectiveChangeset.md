---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Ontogen.Commands.FetchEffectiveChangeset]]"
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

Final version: [[ModuleDoc of Ontogen.Commands.FetchEffectiveChangeset]]

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

# Prompt for ModuleDoc of Ontogen.Commands.FetchEffectiveChangeset

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

![[Ontogen.Commands.FetchEffectiveChangeset#Context knowledge|]]


## Request

![[Ontogen.Commands.FetchEffectiveChangeset#ModuleDoc prompt task|]]

### Description of the module `Ontogen.Commands.FetchEffectiveChangeset` ![[Ontogen.Commands.FetchEffectiveChangeset#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Commands.FetchEffectiveChangeset do
  alias Ontogen.{Changeset, Proposition, Store, Repository}
  alias RDF.{Graph, Description}

  import Ontogen.QueryUtils

  def call(store, repo, %{
        insertion: insertion_proposition,
        deletion: deletion_proposition,
        update: update_proposition,
        replacement: replacement_proposition
      }) do
    insert = Proposition.graph(insertion_proposition)
    delete = Proposition.graph(deletion_proposition)
    update = Proposition.graph(update_proposition)
    replace = Proposition.graph(replacement_proposition)

    dataset = Repository.dataset_graph_id(repo)

    with {:ok, insert_delete_change_graph} <-
           Store.construct(store, dataset, insert_delete_query(insert, delete, update, replace)),
         {:ok, effective_insertion} <- effective_insertion(insert, insert_delete_change_graph),
         {:ok, effective_update} <- effective_insertion(update, insert_delete_change_graph),
         {:ok, effective_replacement} <- effective_insertion(replace, insert_delete_change_graph),
         {:ok, effective_deletion} <- effective_deletion(delete, insert_delete_change_graph),
         {:ok, update_overwrites_graph} <- update_overwrites(store, dataset, update),
         {:ok, replace_overwrites_graph} <- replace_overwrites(store, dataset, replace),
         {:ok, overwrite} = overwrite_deletion(update_overwrites_graph, replace_overwrites_graph) do
      if effective_insertion || effective_deletion || effective_update || effective_replacement ||
           overwrite do
        Changeset.new(
          insert: effective_insertion,
          delete: effective_deletion,
          update: effective_update,
          replace: effective_replacement,
          overwrite: overwrite
        )
      else
        {:ok, :no_effective_changes}
      end
    end
  end

  def call(store, repo, changeset_args) do
    with {:ok, changeset} <- Changeset.new(changeset_args) do
      call(store, repo, changeset)
    end
  end

  defp update_overwrites(_, _, nil), do: {:ok, nil}

  defp update_overwrites(store, dataset, update) do
    with {:ok, update_overwrite_graph} <-
           Store.construct(store, dataset, update_overwrites_query(update)) do
      {:ok, Graph.delete(update_overwrite_graph, update)}
    end
  end

  defp replace_overwrites(_, _, nil), do: {:ok, nil}

  defp replace_overwrites(store, dataset, replace) do
    with {:ok, replace_overwrite_graph} <-
           Store.construct(store, dataset, replace_overwrites_query(replace)) do
      {:ok, Graph.delete(replace_overwrite_graph, replace)}
    end
  end

  defp effective_insertion(nil, _), do: {:ok, nil}

  defp effective_insertion(insert, change_graph) do
    effective_insert =
      Enum.reduce(insert, insert, fn triple, effective_insert ->
        if Graph.include?(change_graph, triple) do
          Graph.delete(effective_insert, triple)
        else
          effective_insert
        end
      end)

    if Graph.empty?(effective_insert) do
      {:ok, nil}
    else
      Proposition.new(effective_insert)
    end
  end

  defp effective_deletion(nil, _), do: {:ok, nil}

  defp effective_deletion(delete, change_graph) do
    effective_delete =
      Enum.reduce(delete, delete, fn triple, effective_delete ->
        if Graph.include?(change_graph, triple) do
          effective_delete
        else
          Graph.delete(effective_delete, triple)
        end
      end)

    if Graph.empty?(effective_delete) do
      {:ok, nil}
    else
      Proposition.new(effective_delete)
    end
  end

  defp overwrite_deletion(update_overwrite, replacement_overwrite) do
    do_overwrite_deletion(
      non_empty_graph(update_overwrite),
      non_empty_graph(replacement_overwrite)
    )
  end

  defp do_overwrite_deletion(nil, nil), do: {:ok, nil}
  defp do_overwrite_deletion(update_overwrite, nil), do: Proposition.new(update_overwrite)

  defp do_overwrite_deletion(nil, replacement_overwrite),
    do: Proposition.new(replacement_overwrite)

  defp do_overwrite_deletion(update_overwrite, replacement_overwrite) do
    update_overwrite |> Graph.add(replacement_overwrite) |> Proposition.new()
  end

  defp non_empty_graph(nil), do: nil
  defp non_empty_graph(graph), do: unless(Graph.empty?(graph), do: graph)

  defp insert_delete_query(insert, delete, update, replace) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s ?p ?o ) {
        #{triples(insert)}
        #{triples(delete)}
        #{triples(update)}
        #{triples(replace)}
      }
      ?s ?p ?o .
    }
    """
  end

  defp triples(nil), do: ""

  defp triples(graph) do
    Enum.map_join(graph, "\n", fn {s, p, o} ->
      "(#{to_term(s)} #{to_term(p)} #{to_term(o)})"
    end)
  end

  defp update_overwrites_query(nil), do: ""

  defp update_overwrites_query(update) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s ?p) {
        #{subject_predicate_pairs(update)}
      }
      ?s ?p ?o .
    }
    """
  end

  defp subject_predicate_pairs(update) do
    update
    |> Graph.descriptions()
    |> Enum.flat_map(fn description ->
      description
      |> Description.predicates()
      |> Enum.map(&{description.subject, &1})
    end)
    |> Enum.map_join("\n", fn {s, p} -> "(#{to_term(s)} #{to_term(p)})" end)
  end

  defp replace_overwrites_query(nil), do: ""

  defp replace_overwrites_query(replace) do
    """
    CONSTRUCT { ?s ?p ?o . }
    WHERE {
      VALUES (?s) {
        #{subjects(replace)}
      }
      ?s ?p ?o .
    }
    """
  end

  defp subjects(replace) do
    replace
    |> Graph.subjects()
    |> Enum.map_join("\n", &"(#{to_term(&1)})")
  end
end

```
