# Module 13 — String Manipulation: Intuition

## What Problem Does This Technique Solve?

Survey data, administrative records, and scraped text all contain variables stored as character strings rather than numbers. Names, open-ended responses, geographic identifiers, dates stored as "January 2020," and race/ethnicity categories that vary in phrasing across datasets all arrive as strings. Before you can analyze them, count them, or merge datasets on them, you have to deal with the fact that strings do not behave like numbers.

Numbers have natural ordering, arithmetic, and a unique representation: 42 is exactly 42. The string "Democrat" is not the same as "democrat," "Democrat " (with a trailing space), "Dem.", or "democratic party." All five might represent the same concept, but a computer's equality check returns false for all five pairwise comparisons. Every one of those discrepancies is a potential merge failure or miscounted category.

The CES 2020 is largely pre-coded, but the moment you merge it with an external file (congressional district records, Census geographic identifiers, state names from a policy database), string inconsistencies become a practical problem. Open-ended "other, specify" items are entirely string-based.

---

## Why String Data Is Harder Than Numeric Data

**No arithmetic.** You cannot compute the mean of a list of names or interpolate between "Alaska" and "Alabama." String operations are categorical operations.

**No canonical ordering.** Alphabetic ordering is a convention, not an inherent property. It does not correspond to any sociological ordering.

**Multiple representations of the same value.** This is the central practical problem. Inconsistent capitalization, extra whitespace, abbreviations, alternate spellings, and encoding artifacts (curly quotes vs. straight quotes, em dashes vs. hyphens) all make string equality fail silently. A merge failure because one dataset has "North Carolina" and another has "North Carolina " (one extra space) will produce a blank merged dataset with no error message.

**Encoding issues.** Non-ASCII characters (accented letters, non-Latin scripts) may be stored in different encodings depending on the software that created the file. An accent that displays correctly in one context becomes a garbled character in another, breaking any string comparison that depends on exact matching.

---

## The Most Common Sources of Merge Failures

**Leading and trailing whitespace.** The most common cause of failed string merges. `"Alabama"` and `"Alabama "` (one trailing space) are not equal. Always trim whitespace before any merge.

**Mixed case.** `"Democrat"` is not `"democrat"`. Convert to a single case (usually lowercase) before comparing.

**Numeric-stored-as-string.** A FIPS code stored as the string `"01"` is not the same as the number `1`. If one dataset has string FIPS codes and another has numeric FIPS codes, the merge fails. You need to either convert both to the same type or ensure string formatting is consistent (zero-padded or not, consistently).

**Inconsistent abbreviations.** `"FL"` vs. `"Florida"` vs. `"Fla."` are three representations of the same state. Standardize to one format before merging.

**Encoding artifacts.** Copied-from-PDF text often contains non-breaking spaces (character 160 in ASCII) rather than ordinary spaces (character 32). They look identical on screen but are not equal in string comparison.

---

## Regular Expressions: When and When Not to Use Them

A regular expression (regex) is a pattern language for matching strings. It lets you ask questions like: "Find all strings that start with a two-digit number, then a hyphen, then four letters" or "Find all strings that contain the word 'county' anywhere, case-insensitively."

**Use regex when:**
- You need to find or extract patterns across many strings where the exact string varies but the structure is consistent. Dates in inconsistent formats ("Jan 5, 2020" vs. "1/5/2020") can be captured with separate patterns.
- You need to validate string format (does this look like a valid FIPS code?).
- You need to extract a substring with a consistent structure from a longer, messier string.
- You are working with open-ended text and need to flag responses that mention a key term.

**Do not use regex when:**
- You know the exact string you are looking for. A simple `contains(var, "Florida")` or `== "Florida"` is faster, clearer, and harder to get wrong.
- The pattern is so complex that the regex is unreadable without extensive comments. At that point, parsing in steps is more maintainable.
- You are matching against a lookup table of allowed values. Use a merge or a lookup table, not a long alternation pattern.

Regex is powerful but not always the right tool. A regex that almost works is worse than no regex: it silently misclassifies observations.

---

## The Risk of Over-Cleaning

String cleaning has a failure mode in the opposite direction from under-cleaning: you can strip meaningful variation from the strings.

If you standardize all racial/ethnic category labels to match a lookup table, make sure your lookup table preserves the distinctions you care about. Collapsing "Mexican American," "Puerto Rican," and "Cuban American" into "Hispanic/Latino" for the sake of standardization discards information that may matter for your analysis.

If you strip punctuation to make string comparisons easier, make sure punctuation is not meaningful. Stripping periods from "Dr." vs. "Mr." collapses titles that may be relevant.

The principle: clean just enough to make your specific operation work. Do not apply blanket transformations without checking what gets collapsed.

---

## Why Standardize Before Merging, Never After

String standardization must happen before merges, not after. If you merge two datasets on a string variable that has not been standardized, mismatches create non-merged rows: they disappear from the merged file rather than appearing with merge errors. You will not know they are missing unless you check the merge count against expectations.

If you try to standardize after the merge, you are standardizing a variable that already has missing rows baked into it. The records that did not merge are gone. You cannot recover them by cleaning the string in the merged file.

The workflow: (1) clean and standardize all merge key variables in each source file; (2) verify that values in the key variable have the expected distribution; (3) merge; (4) check the merge count and inspect unmatched rows.

---

## Parsing vs. Matching

**Parsing** extracts structure from within a string. "January 5, 2020" can be parsed into a month, day, and year. A full name "Smith, John A." can be parsed into last name, first name, and middle initial. Parsing imposes a schema on unstructured text.

**Matching** determines whether two strings refer to the same thing. Exact matching requires character-for-character equality. Fuzzy matching (using edit distance or other string similarity metrics) allows for small differences in spelling. Fuzzy matching is appropriate when you expect typos or minor formatting inconsistencies; exact matching is appropriate when strings have been standardized and you expect precision.

The two operations require different tools and different thinking. Parsing is about extracting structure; matching is about asserting identity.

---

## Strengths, Weaknesses, and Alternatives

| | String Manipulation |
|---|---|
| **Strengths** | Enables merges and categorization that would otherwise fail; regular expressions scale to large text data; standardization is reproducible and verifiable |
| **Weaknesses** | Easy to introduce subtle bugs (regex with off-by-one errors; overcleaning that collapses distinct values); requires domain knowledge to know which standardizations are appropriate |
| **Alternatives** | For large-scale text classification (sentiment, topic), machine learning approaches (bag-of-words, embeddings) outperform manual string manipulation. For fuzzy record linkage across datasets, probabilistic record linkage algorithms (Fellegi-Sunter model) are more principled than ad-hoc edit-distance cutoffs. |
