---
name: reviewer-response
description: "Plan and draft a revise-and-resubmit: parse editor and reviewer comments into a numbered action list, triage each (do it, partially do it, respectfully decline), draft the response letter in the standard comment/response/change format, and track every change to its location in the manuscript. Use whenever the user has an R&R, reviewer reports, a decision letter, a desk reject with comments, or feedback from an advisor or committee they need to answer point by point."
---

# Reviewer response

An R&R is won or lost on two things: whether the editor can see that every concern was taken seriously, and whether the changes actually address what the reviewer was worried about (which is not always what they literally asked for). This skill handles both.

## Step 1: read the decision letter first

The editor's letter sets the priorities. Editors often say which reviewer concerns are essential ("in particular, address R2's concern about selection"). Those points get the most effort and are named first in the cover letter. If the editor flags nothing, infer priorities from overlap: a concern raised by two reviewers is essential.

## Step 2: parse into atomic comments

Split every report into single, answerable comments and number them R1.1, R1.2, R2.1… One reviewer paragraph often holds three separate requests; split them, because a response that answers one of three reads as evasive.

For each comment record:
- **Quote** (verbatim, short)
- **What they actually want** — the underlying worry. "Add a table of descriptives" might really be "I don't trust your sample." Answering the worry is what moves a reviewer.
- **Type**: framing/theory, literature, data/measurement, method/specification, interpretation, writing/clarity, scope.
- **Effort**: small / medium / large.

## Step 3: triage

Decide for each: **Do**, **Partly do**, or **Decline**. Decline is legitimate when a request would change the paper into a different paper, contradicts another reviewer, or is infeasible with the data. A good decline:
- thanks the reviewer and restates the concern fairly,
- gives the specific reason,
- offers something (a footnote, a robustness check in an appendix, an acknowledged limitation).

When reviewers contradict each other, say so in both responses, name which way you went, and why. Editors expect this and resolve it in the author's favor when the reasoning is clear.

Present the triage table to the user before drafting — the choices here are theirs, and it's much cheaper to change a plan than a letter.

## Step 4: draft the letter

```
Dear Dr. <Editor>,

<Thanks; one paragraph summarizing the major changes, keyed to the editor's priorities.>

Below we respond to each comment. Reviewer comments are in italics; page numbers
refer to the revised manuscript.

REVIEWER 1
R1.1  *<quoted comment>*
Response: <what we did and why, in 1–4 sentences>.
Change: <section, page, or table where it is — or "No change; see explanation">.
```

Tone: grateful without groveling, direct, never defensive. Don't open every reply with "We thank the reviewer for this excellent point" — do it once per reviewer at the top. Quote the new manuscript text for changes to key claims so the reviewer need not hunt for it.

## Step 5: track changes to the manuscript

Keep a change log mapping each comment ID to the manuscript location. Before finalizing, verify every "Change:" line points to text that exists — mismatched page references are the most common reason an R&R reads as sloppy. If the manuscript is a .docx, use the docx skill to read it and to produce a tracked-changes version if the journal wants one.

## Output

Deliver: (1) the triage table, (2) the response letter as a .docx, (3) the change log. For advisor or committee feedback, same process, shorter letter — often a table is enough.
