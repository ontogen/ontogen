---
created_at: 2023-07-03 20:18
tags:
  - grax
---
# Grax

## Description

Grax is a library designed to facilitate the translation of RDF graph data into Elixir data structures. It functions by mapping RDF data originating from RDF.ex structures into Elixir structs that conform to a defined schema. 

The Grax schema is defined as an Elixir struct, bearing some resemblance to `Ecto.Schema`, but with distinct features. Each `Grax.Schema` struct contains a unique internal identifier, labeled `__id__`, as well as an `__additional_statements__` field for storing statements that falls outside of the Grax schema.

In Grax, the elements of the `Grax.Schema` struct are termed properties, and these correspond to RDF properties. These properties are defined in the body of a `schema/1` block using the `property/3` macro, and their associated RDF property URIs are embedded within the Grax schema struct.

## with more technical details

Grax is a library designed to facilitate the translation of RDF graph data into Elixir data structures. It functions by mapping RDF data originating from RDF.ex structures into Elixir structs that conform to a defined schema. 

The Grax schema is defined as an Elixir struct, bearing some resemblance to `Ecto.Schema`, but with distinct features. Each `Grax.Schema` struct contains a unique internal identifier, labeled `__id__`, as well as an `__additional_statements__` field for storing statements that falls outside of the Grax schema.

In Grax, the elements of the `Grax.Schema` struct are termed properties, and these correspond to RDF properties. These properties are defined in the body of a `schema/1` block using the `property/3` macro, and their associated RDF property URIs are embedded within the Grax schema struct.

RDF.ex, a key component in Grax's operation, is a fully RDF 1.1 and RDF-star specification compatible implementation of the RDF data model in Elixir. It provides in-memory data structures for RDF descriptions, graphs, and datasets, enabling data to be loaded and stored in various serialization formats.


**Schemas**

Grax uses schemas to map between RDF graphs and Elixir structs. These schemas are Elixir modules that use the `Grax.Schema` behaviour. They must define a `struct/0` function that returns the struct to be used for mapping and a `graph/1` function that returns the RDF graph to be mapped from.

The `struct/0` function should return an Elixir struct. This struct will be used to map the RDF graph data to. The struct should have fields that correspond to the properties of the RDF graph.

The `graph/1` function should return an RDF graph. This graph will be used to map the RDF graph data from. The graph should have properties that correspond to the fields of the Elixir struct.

The `Grax.Schema` behaviour also provides a `map/2` function that can be used to map between the RDF graph and the Elixir struct. This function takes the RDF graph and the Elixir struct as arguments and returns a new Elixir struct with the mapped data.

**API**

The Grax API provides functions to work with Grax schemas and RDF graphs. The main functions are `Grax.load/2`, `Grax.to_rdf/2`, and `Grax.map/3`.

`Grax.load/2` is used to load RDF graph data into an Elixir struct. It takes an RDF graph and a Grax schema as arguments and returns an Elixir struct with the loaded data.

`Grax.to_rdf/2` is used to dump Elixir struct data into an RDF graph. It takes an Elixir struct and a Grax schema as arguments and returns an RDF graph with the struct data and the specified properties.

`Grax.from_/2` is used to dump Elixir struct data into an RDF graph. It takes an Elixir struct and a Grax schema as arguments and returns an RDF graph with the struct data and the specified properties.

Please note that these are high-level summaries of the information provided in the user guide. For more detailed information and examples, you should refer to the [Schemas](https://rdf-elixir.dev/grax/schemas) and [API](https://rdf-elixir.dev/grax/api) sections of the Grax user guide.

