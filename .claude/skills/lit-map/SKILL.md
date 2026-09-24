---
name: lit-map
description: "Map the literature on a research question: run a structured search (Undermind deep search when connected), sort what comes back into the debates it actually belongs to, and write a synthesis organized by argument rather than by paper, ending in a defensible gap statement. Use whenever the user asks for a literature review, 'what has been written on', 'who works on', a lit search, an annotated bibliography, background for a paper or prospectus, or wants to know where a project sits in existing scholarship — even if they only name a topic."
---

# Literature map

A literature review that walks through papers one at a time ("Smith (2019) found… Jones (2021) found…") shows that reading happened. It does not show what the field thinks, where it disagrees, or where a new paper fits. This skill builds the second kind: a map of positions, with papers as evidence for positions.

## Step 1: pin the question

Before searching, write the question in one sentence with its parts named: the outcome, the population or site, the mechanism or explanation under dispute, and the scope (country, period). If the user gave only a topic ("foster care privatization"), draft the question yourself and state it back with your assumptions, then proceed — do not stall for confirmation on something the search will sharpen anyway.

Note which disciplines plausibly hold the answer. For stratification, child welfare, and education questions this is rarely sociology alone: social work, public policy, economics, demography, and legal scholarship often hold key pieces, and a map that stays inside one discipline will report a gap that another field closed years ago.

## Step 2: search

If the Undermind connector is available, call `get_orientation` first, then launch a deep search with the full question sentence (not keywords — Undermind reasons over the sentence). Save results into a workspace folder named for the project so the user can return to them. Supplement with targeted `search_papers` calls for:

- The two or three most-cited anchor works (check that they are actually in the results; if not, find them by author).
- Recent work (last 3 years), which deep searches can underweight.
- Critical or dissenting work, searched for explicitly ("critiques of…", "limits of…"), because consensus-shaped queries return consensus.

Without Undermind, use web search and say that coverage is thinner.

Read abstracts at minimum; read full text (via `read_pdfs`) for anchor works and any paper whose claim the synthesis will lean on. Never characterize a paper's findings from its title.

## Step 3: sort into debates

Group papers by the claim they make, not by method or date. For each group write:

- **The position** in one sentence, stated as its proponents would state it.
- **Key works** (3–6), with a phrase on what each contributes.
- **Evidence base**: data sources, methods, settings. Note when a whole position rests on one dataset or one country.
- **Where it runs into another group**: the specific point of contradiction.

Usually 3–5 groups. If everything lands in one group, the question is too narrow or the search too consensus-shaped; go back to step 2.

## Step 4: find the gap honestly

A gap is only a gap if you checked. Before stating one, search specifically for work that would fill it. Distinguish:

- **Unstudied**: no one has looked (rare; be suspicious).
- **Understudied in this setting**: studied elsewhere, not here (common and legitimate — say where it was studied).
- **Contested**: studied, with conflicting findings the user's project could adjudicate (often the strongest framing).
- **Mismeasured**: studied, but with a measure or design that cannot answer the question.

Say which kind it is. "Contested" and "mismeasured" gaps make stronger papers than "unstudied" ones.

## Step 5: write it up

Use this structure:

```
# Literature map: <question>

## The question
## Positions in the literature
### <Position 1 name>
### <Position 2 name>
...
## Where they conflict
## The gap (type: unstudied / understudied here / contested / mismeasured)
## Where the user's project fits
## Annotated bibliography
  Author (Year). Title. Venue. — one to two sentences: claim, data, why it matters here.
## Search record
  Queries run, date, databases, and what was deliberately excluded.
```

Citations in ASA style (the `asa-citations` skill has the rules). The search record matters: it lets the user rerun or extend the search later and defend its scope to a committee.

## Limits to state

Say plainly which relevant literatures you could not reach (paywalled books, non-English work, grey literature such as agency reports — which matters a lot for child welfare). A map is only as complete as its search, and the user should know where the edges are.
