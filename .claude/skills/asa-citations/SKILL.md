---
name: asa-citations
description: "Check and fix citations in American Sociological Association (ASA) style (7th ed.): in-text author-date format, reference list formatting, and — most importantly — the cross-check that every in-text citation has a reference entry and every reference is cited, with matching years and spellings. Also converts from APA, Chicago, or a Zotero/BibTeX export. Use whenever the user asks to check, format, or fix citations or references, prepare a manuscript for a sociology journal, or mentions ASA style, bibliography, works cited, or reference list — even if they don't name the style but are writing for a sociology venue."
---

# ASA citations

The most damaging citation errors aren't formatting: they're a cited work missing from the references, a year that differs between text and list, or a misspelled author name. Reviewers notice these and read them as carelessness about the literature. Check those first, then formatting.

## Step 1: cross-check (always do this first)

Extract every in-text citation and every reference entry. Produce three lists:
1. **Cited but not in references**
2. **In references but never cited** (ASA lists only cited works)
3. **Mismatches**: year, spelling, or coauthor differences between text and list (e.g., "Wacquant 2009" in text, "Wacquant 2008" in the list — also check this is not a translation vs. original issue)

Report these before touching formatting.

## Step 2: in-text format (ASA 7th)

- Author-date, no comma: (Roberts 2002). Page numbers with colon, no space: (Roberts 2002:45).
- Two authors: (Bourdieu and Wacquant 1992). Three or more: first author plus "et al." from the first citation onward in ASA 7th (Karlson et al. 2012). The 6th edition spelled out three authors on first mention, so check which edition the journal follows. The reference list names every author.
- Multiple works: semicolons, order chosen by the author (alphabetical or chronological, consistent): (Roberts 2002; Wacquant 2009).
- Same author, same year: 2002a, 2002b.
- Name in sentence: Roberts (2002) argues….
- Reprints/translations: (Du Bois [1899] 1996).

## Step 3: reference list format

Hanging indent, alphabetical by first author surname. Full first names as published. Title case for titles. Journal article:

> Roberts, Dorothy E. 2002. *Shattered Bonds: The Color of Child Welfare*. New York: Basic Books.
>
> Karlson, Kristian Bernt, Anders Holm, and Richard Breen. 2012. "Comparing Regression Coefficients between Same-Sample Nested Models Using Logit and Probit: A New Method." *Sociological Methodology* 42(1):286–313.

Key features: year after author names; article title in quotation marks; journal italic; volume(issue):pages with no spaces; only the first author inverted; "and" before the last author; DOI at the end as `https://doi.org/…` where available.

Chapter in edited volume:

> Author, First. Year. "Chapter Title." Pp. 1–20 in *Book Title*, edited by First Editor and Second Editor. City: Publisher.

Reprint: `Du Bois, W. E. B. [1899] 1996. *The Philadelphia Negro: A Social Study*. Philadelphia: University of Pennsylvania Press.`

Journal-specific house styles override ASA (e.g., *Research in Social Stratification and Mobility* is an Elsevier journal and may use its own author-date variant). If the user names a target journal, check its author guidelines and say where they differ.

## Step 4: verify, don't invent

When a reference is incomplete (missing pages, DOI, publisher), look it up (Undermind `lookup_papers_by_metadata`, or web search) rather than guessing. Mark anything you could not verify with [CHECK] instead of filling plausible-looking details — fabricated page numbers or DOIs are worse than missing ones.

## Output

The cross-check report, then the corrected reference list, then a list of in-text fixes with their location. If the manuscript is a .docx, make edits with the docx skill (tracked changes if the user wants to review them).
