---
magma_type: Artefact.Version
magma_artefact: TableOfContents
magma_concept: "[[Ontogen User Guide]]"
magma_draft: "[[Generated Ontogen User Guide ToC (2023-12-15T05:26:06)]]"
created_at: 2023-12-15 05:41:41
tags: [magma-vault]
aliases: []
---

>[!info]
>The sections were already assembled. If you want to reassemble, please use the following Mix task:
>
>```sh
>mix magma.text.assemble "Ontogen User Guide ToC"
>```
>
>It will ask you to confirm any overwrites of files with user-provided content.

# Ontogen User Guide ToC

## Introduction

Abstract: An overview of Ontogen, describing its role as a Data-Control-Management solution for RDF data. This section highlights how Ontogen differs from traditional SCM tools and focuses on its capabilities in managing RDF datasets and generating provenance metadata.

## Basics

Abstract: This section explains the core concepts behind Ontogen, including RDF-star, RTC, and the provenance and versioning model. It provides essential knowledge for understanding how Ontogen handles RDF data management and versioning.

## Creating Repositories

Abstract: Details the process of creating and managing repositories within Ontogen. It describes the structure of these repositories and their role in the management of RDF datasets, akin to the `.git` directory in Git.

## Operations

Abstract: Covers the various operations available in Ontogen for managing and manipulating RDF datasets. 

- the `commit` command to add changes to RDF datasets, including examples and best practices for committing changes.
- the `changes` command to review modifications made to a dataset since the last commit
- the `history` command to review the version history of a dataset, offering insights into the dataset's chronological development.
- the `revert` command, for returning to previous versions of a dataset.

## Limitations and Future Developments

Abstract: Discusses the current limitations of the initial MVP version of Ontogen and outlines the projected roadmap for future development. This section gives users insight into upcoming features and enhancements.
