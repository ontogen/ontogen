---
created_at: 2023-07-03 17:16
tags:
  - rtc
---
# RTC

## Description

The RDF Triple Compounds (RTC) specification describes a framework for handling sets of RDF statements within an RDF graph. This is useful in cases where a group of triples needs to be annotated or treated as a unit.

Triple compounds are essentially logical RDF graphs contained within physical RDF graphs. They allow for further nesting of compound structures and can be seen as named sub-graphs within a main graph. These can be useful in many scenarios, such as where named graphs are too coarse-grained or can't be used for other reasons. 

A triple compound is created by assigning a set of triples to a shared node using RDF-star statements and the `rtc:elementOf` property. The triples that form a triple compound must be quoted triples, which can be either asserted or unasserted triples. The specification also introduces an `rtc:elements` property as an inverse of `rtc:elementOf`.

## Description with sub-compounds

The RDF Triple Compounds (RTC) specification describes a framework for handling sets of RDF statements within an RDF graph. This is useful in cases where a group of triples needs to be annotated or treated as a unit.

Triple compounds are essentially logical RDF graphs contained within physical RDF graphs. They allow for further nesting of compound structures and can be seen as named sub-graphs within a main graph. These can be useful in many scenarios, such as where named graphs are too coarse-grained or can't be used for other reasons. This approach also simplifies the process of working with such compounds, as libraries can be created to treat these compounds like normal graphs, handling any required annotations automatically.

A triple compound is created by assigning a set of triples to a shared node using RDF-star statements and the `rtc:elementOf` property. The triples that form a triple compound must be quoted triples, which can be either asserted or unasserted triples. The specification also introduces an `rtc:elements` property as an inverse of `rtc:elementOf`.

The specification defines the concept of sub-compounds, where one triple compound can be a subset of another compound, using the `rtc:subCompoundOf` property. This allows for further structuring and organization of triples. For example, a dedicated compound could be created for all triples from a specific user, and then further sub-compounds could be defined for triples stated on certain dates. An important aspect to note here is that all statements about the super-compound must be interpreted to apply to all of its sub-compounds, except for the `rtc:elements` statements.

The vocabulary introduced in the specification includes the class `Compound` and properties `element of` and `elements`. A `Compound` is a set of triples as an RDF resource, and the `element of` property assigns a triple to a compound as an element.


