---
magma_type: Artefact.Prompt
magma_artefact: Article
magma_concept: "[[Ontogen User Guide - Basics]]"
magma_generation_type: OpenAI
magma_generation_params: {"model":"gpt-4-1106-preview","temperature":0.6}
created_at: 2023-12-15 07:29:04
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

Final version: [[Ontogen User Guide - Basics (article section)]]

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

# Prompt for Ontogen User Guide - Basics (article section)

## System prompt

![[Magma.system.config#Persona|]]

![[UserGuide.text_type.config#System prompt|]]

### Context knowledge

The following sections contain background knowledge you need to be aware of, but which should NOT necessarily be covered in your response as it is documented elsewhere. Only mention absolutely necessary facts from it. Use a reference to the source if necessary.

![[Magma.system.config#Context knowledge|]]

#### Description of the Ontogen project ![[Project#Description|]]

![[Text.Section.matter.config#Context knowledge|]]

![[UserGuide.text_type.config#Context knowledge|]]

#### Outline of the 'Ontogen User Guide' content ![[Ontogen User Guide ToC#Ontogen User Guide ToC|]]



![[Article.artefact.config#Context knowledge|]]

![[Ontogen User Guide - Basics#Context knowledge|]]


## Request

![[Ontogen User Guide - Basics#Article prompt task|]]

### Description of the intended content of the 'Basics' section ![[Ontogen User Guide - Basics#Description|]]
