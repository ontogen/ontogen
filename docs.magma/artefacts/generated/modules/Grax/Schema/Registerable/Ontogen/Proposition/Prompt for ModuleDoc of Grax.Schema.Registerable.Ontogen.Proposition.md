---
magma_type: Artefact.Prompt
magma_artefact: ModuleDoc
magma_concept: "[[Grax.Schema.Registerable.Ontogen.Proposition]]"
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

Final version: [[ModuleDoc of Grax.Schema.Registerable.Ontogen.Proposition]]

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

# Prompt for ModuleDoc of Grax.Schema.Registerable.Ontogen.Proposition

## System prompt

![[Magma.system.config#Persona|]]

![[ModuleDoc.artefact.config#System prompt|]]

### Context knowledge

The following sections contain background knowledge you need to be aware of, but which should NOT necessarily be covered in your response as it is documented elsewhere. Only mention absolutely necessary facts from it. Use a reference to the source if necessary.

![[Magma.system.config#Context knowledge|]]

#### Description of the Ontogen project ![[Project#Description|]]

![[Module.matter.config#Context knowledge|]]

#### Peripherally relevant modules

##### `Grax` ![[Grax#Description|]]

##### `Grax.Schema` ![[Grax.Schema#Description|]]

##### `Grax.Schema.Registerable` ![[Grax.Schema.Registerable#Description|]]

##### `Grax.Schema.Registerable.Ontogen` ![[Grax.Schema.Registerable.Ontogen#Description|]]

![[ModuleDoc.artefact.config#Context knowledge|]]

![[Grax.Schema.Registerable.Ontogen.Proposition#Context knowledge|]]


## Request

![[Grax.Schema.Registerable.Ontogen.Proposition#ModuleDoc prompt task|]]

### Description of the module `Grax.Schema.Registerable.Ontogen.Proposition` ![[Grax.Schema.Registerable.Ontogen.Proposition#Description|]]

### Module code

This is the code of the module to be documented. Ignore commented out code.

```elixir
defmodule Ontogen.Proposition do
  #  Magma.moduledoc(
  #    "Represents abstract sets of utterance-independent statements in a canonical form and with content-hashed identifiers."
  #  )
  use Magma

  #  @moduledoc """
  #  Represents abstract sets of utterance-independent statements in a canonical form and with content-hashed identifiers.
  #
  #  #{Magma.module_doc(__MODULE__)}
  #  """

  use Grax.Schema

  alias Ontogen.NS.Og

  alias RTC.Compound
  alias RDF.Graph

  import Ontogen.IdUtils

  # TODO:  < PROV.Entity?
  schema Og.Proposition do
    field :statements
  end

  @doc """
  Generates a new `Ontogen.Proposition` from a given RDF graph.

  This function serves as an interface for creating an `Ontogen.Proposition`. It takes an RDF graph as input and wraps it in an `RTC.Compound` internally. This approach provides the benefits of `RTC.Compound` within the `Ontogen.Proposition` structure while ensuring that the unique characteristics of `Ontogen.Proposition` are maintained.

  Once the `RTC.Compound` is created from the input graph, it's embedded into the `Ontogen.Proposition`. This compound represents the same resource - the set of RDF statements - and is identified within the `Ontogen.Proposition` by the `:statements` field.

  By creating a SHA256-URN from the RDF Dataset Canonicalization hash of the graph, a unique identifier is generated for the `Ontogen.Proposition`. This identifier is not only unique but also consistent across different RDF stores for the same set of statements.

  The resulting `Ontogen.Proposition` thus represents a normalized RDF graph with a content-hashed identifier, encapsulating the same RDF statements as the input graph in a format compatible with Ontogen's requirements.

  ## Parameters

  - `statements`: The RDF graph to be converted into an `Ontogen.Proposition`.

  ## Examples

      # TODO: update so we have final ids
      iex> Ontogen.Proposition.new([{EX.S1, EX.P1, EX.O1}, EX.S2 |> EX.p2(EX.O2)])
      {:ok,
        %Ontogen.Proposition{
         __additional_statements__: %{
           ~I<http://www.w3.org/1999/02/22-rdf-syntax-ns#type> => %{
             ~I<https://w3id.org/ontogen#Proposition> => nil
           }
         },
         __id__: ~I<urn:hash::sha256:fcf4ddfdb01c46782658052f16c9715e5180332ea68cf620c2bb131ac894681a>,
         statements: #RTC.Compound<id: ~I<urn:hash::sha256:fcf4ddfdb01c46782658052f16c9715e5180332ea68cf620c2bb131ac894681a>, graph_name: nil
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix rtc: <https://w3id.org/rtc#> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .

        <urn:hash::sha256:fcf4ddfdb01c46782658052f16c9715e5180332ea68cf620c2bb131ac894681a>
            rtc:elements << <http://example.com/S1> <http://example.com/P1> <http://example.com/O1> >>, << <http://example.com/S2> <http://example.com/p2> <http://example.com/O2> >> .
        >
        }
      }

    iex> Ontogen.Proposition.new!([{EX.S1, EX.P1, ~B"foo"}]) ==
    ...>   Ontogen.Proposition.new!([{EX.S1, EX.P1, ~B"bar"}])
    true


  ## Returns

  - `{:ok, %Ontogen.Proposition{}}` on successful creation of an `Ontogen.Proposition`.
  - `{:error, reason}` on failure, where `reason` is a term explaining why the creation of the `Ontogen.Proposition` failed.

  """
  def new(statements) do
    with {:ok, id} <- dataset_hash_iri(statements) do
      build(id,
        # TODO: statements should be added canonicalized to an Ontogen.Proposition
        statements:
          Compound.new(statements, id,
            name: nil,
            assertion_mode: :unasserted
          )
      )
    end
  end

  def new!(statements) do
    case new(statements) do
      {:ok, proposition} -> proposition
      {:error, error} -> raise error
    end
  end

  def on_load(%{} = proposition, graph, _opts) do
    {
      :ok,
      %{
        proposition
        | statements:
            graph
            # TODO: is this correct
            |> Graph.take([proposition.__id__], [RTC.elements()])
            |> Compound.from_rdf(proposition.__id__)
            |> Compound.change_graph_name(nil)
      }
      |> Grax.delete_additional_predicates(RTC.elements())
    }
  end

  def on_to_rdf(%{__id__: id, statements: compound}, graph, _opts) do
    {
      :ok,
      graph
      |> Graph.add(Compound.to_rdf(compound, element_style: :elements))
      # TODO: use RDF typing opt-out of Grax when available
      |> Graph.delete({id, RDF.type(), Og.Proposition})
    }
  end

  def graph(nil), do: nil
  def graph([]), do: nil
  def graph(%Graph{} = graph), do: graph
  def graph(%{statements: compound}), do: Compound.graph(compound)
end

```
