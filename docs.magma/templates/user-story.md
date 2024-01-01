---
magma_type: Concept
magma_matter_type: UserStory
status: Not started
card-type: story
effort: 1
complexity: 1
for-version: v0.1
priority:
aliases: []
created_at: {{date}} {{time}}
tags: [magma-vault]
---

day:: [[{{date}}]]
project::
version:: [[Ontogen v0.1]]
subsystem::
follow_up_of:: 
dependencies::
tags:: 

---
type:: #user-story  
part_of:: 
# {{title}}

> [!check] 
> **"An Ontogen user can/must/... do \[action], to reach \[goal]."**
> 
> -- [[User Story]]

```table-of-contents
```

## Description


## TODO

- [ ] 

### Open Questions and Problems

```dataview
TABLE 
	type    AS Type,
	tags    AS Tags,
  status  AS Status
	
FROM [[]] and #open and (#question or #problem) and -#daily and -#weekly and -#monthly and -#yearly
```
## Analysis & Design

### Requirements

- 

```dataview
TABLE 
	type    AS Type,
	tags    AS Tags,
  status  AS Status
	
FROM [[]] and #requirement and -#daily and -#weekly and -#monthly and -#yearly
```

### Domain Analysis

### Acceptance Criteria

### Deliverables

### Effort Estimation


## Implementation notes

### Toolset (Tech-Stack)



# Context knowledge



# Artefacts

## Roadmap-Entries for the User Guide page on the Future roadmap

## NLnet-MoU-Addendum

i.e. LibreOffice-Templates

## Bounty page


## Sunsama task

- Prompt: [[Prompt for ModuleDoc of Ontogen.Changeset]]
- Final version: [[ModuleDoc of Ontogen.Changeset]]

### "Sunsama task" prompt task

Generate documentation for module `Ontogen.Changeset` according to its description and code in the knowledge base below.

## GitHub Issue and/or PR

- GitHub discussions?
- Linear issues (via Linear Github Sync?)?


## Changelog entry





# References
### Follow-ups
```dataview
LIST WHERE follow_up_of = [[]] SORT file.created_at
```

## Concepts
```dataview
TABLE 
	type    AS Type,
	tagline AS Tagline,
	tags    AS Tags,
  status  AS Status
	
FROM [[]] and -#zettel and -#story and -#daily and -#weekly and -#monthly and -#yearly
```
## Documents
```dataview
TABLE 
	type    AS Type,
	tagline AS Tagline,
	tags    AS Tags,
  status  AS Status

FROM #zettel and [[]]
```

