---
magma_type: Concept
magma_matter_type: Project
magma_matter_name: Ontogen
created_at: 2023-12-07 14:16:03
tags: [magma-vault]
aliases: [Ontogen project, Ontogen-project]
---
# Ontogen project

## Description

Ontogen is a PROV- and DCAT-based versioning system for RDF triple stores. It

- stores a version history of the statements in an RDF dataset in a dedicated named graph of this dataset (similar to the `.git` directory of a Git repo) 
- provides an API to control access to the contents of a triple store, in particular to implement write access in such a way, that it produces provenance metadata for the changes, recording them in a provenance history.  

Ontogen is like a Git for RDF data. Unlike Git, it is not a [[Source-Control-Management]] (SCM) solution, but a [[Data-Control-Management]] solution (DCM) and in its first versions, even more specific, a [[Data-Control-Management]] solution for [[RDF]] data only, i.e. the triples in the graphs of a [[SPARQL]] triple store.

While on the one hand, we have narrowed down the subject of version control to very specific type - RDF data, we take a very general stance within this realm, on the other hand. RDF itself, as being the fundamental data model for the semantic web, already has a fairly universal approach, but instead of limiting our point of view only on the syntactical and semantical level, we like to take all semiotic/linguistic layers into account and incorporate also the pragmatic layer.

Ontogen achieves this by incorporating the concept of the utterance of RDF statements into the model. In other words, when, by whom, in what context, under what conditions, etc. an RDF statement was made.

We achieve this by reifying the utterances of statements to dedicated resources via the RTC vocabulary. In other words, we introduce a new class of RDF resources that represent the utterances of RDF statements and can thus be used as the subject of RDF descriptions in order to be able to make metadata statements about these RDF descriptions and thus form the basis of the provenance history of graphs of an RDF dataset.

Based on this concept of utterance, a model is defined as a specialization of the PROV and DCAT models towards RDF data as `prov:Entity`s resp. `dcat:Dataset`s and attempts to integrate them as far as possible for the purpose 


# Context knowledge


# Artefacts

## Readme

- Prompt: [[Prompt for README]]
- Final version: [[README]]

### Readme prompt task

Generate a README for project 'Ontogen' according to its description and the following information:

-   Hex package name: ontogen
-   Repo URL: https://github.com/github_username/repo_name
-   Documentation URL: https://hexdocs.pm/ontogen/
-   Homepage URL:
-   Demo URL:
-   Logo path: logo.jpg
-   Screenshot path:
-   License: MIT License
-   Contact: Your Name - [@twitter_handle](https://twitter.com/twitter_handle) - your@email.com
-   Acknowledgments:

("n/a" means not applicable and should result in a removal of the respective parts)
