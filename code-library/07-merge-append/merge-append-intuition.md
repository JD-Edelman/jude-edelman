# Merge and Append — Intuition

## 1. What Problem Does This Solve?

Real social science data is almost never contained in a single rectangular file. The CES 2020 survey, for example, might be distributed across a main respondent file, a validated vote file released months later, and a district-level contextual file containing legislative district characteristics. These three sources describe the same units (or related units) but were created by different teams, at different times, with different granularities.

Merging and appending are the operations that combine these separate files into a single analysis dataset. They are not exotic transformations; they are routine data infrastructure. But they are a major source of analytic errors: silent row loss, silent row duplication, and mismatched keys that produce garbage without warning. Understanding the logic precisely prevents those errors.

## 2. When Would a Researcher Reach for It — and When Not?

**Use a merge (adding columns from a second file) when:**

- You want to add variables from a different level of analysis to your main file (e.g., county-level unemployment rate to a person-level survey file).
- Two files cover the same units (respondents, counties, years) and you want all their variables in one place.
- You are linking a follow-up survey wave to a baseline file on a shared respondent ID.

**Use an append (stacking rows from a second file) when:**

- Two files have the same variables but cover different observations (e.g., CES data from two different years, or respondents split across two files for processing reasons).
- You are building a pooled panel by combining annual cross-sections.

**Do not merge when you should append, and vice versa.** The signal that you are in the wrong operation: if after merging you have more rows than you started with (and you were not expecting that), you have created row duplicates. If after appending you have the same number of rows but variables are all missing for one file's observations, you have misidentified variable alignment.

## 3. How the Mechanism Works in Plain Language

### The Key Variable

Before any join, identify the key: the column (or combination of columns) that uniquely identifies each row in each file. For a person-level file, that might be a respondent ID. For a county-year file, it might be (FIPS code, year). The key is what the merge algorithm uses to decide which rows to connect.

A critical check before merging: confirm that the key is actually unique in each file. If respondent ID 10042 appears twice in your left file, every row in the right file that matches ID 10042 will be paired with both copies. Your row count will silently balloon.

### Join Types in Plain Language

**Inner join**: keep only the rows where the key appears in both files. If a respondent is in your CES file but not in the validated vote file (because they were not matched), they disappear. This is often what you want if you only care about respondents with complete data, but it is silent data loss, not filtered data. Know how many rows you drop.

**Left join**: keep all rows from the left file. Rows whose key does not appear in the right file get missing values for the right-side columns. Use this when your primary file defines the analysis sample and the right-side file provides supplementary variables that may not cover everyone.

**Right join**: the mirror of a left join. Rarely used explicitly; analysts just swap which file is "left."

**Full outer join**: keep all rows from both files, filling in missing values wherever a row appears in only one file. Use this when both files are authoritative and you want to see the full universe of keys across both.

### The Merge Indicator

After merging, always inspect the merge indicator (called `_merge` in Stata). It takes three values:
- 1 = row came from left file only (right-side key had no match)
- 2 = row came from right file only (left-side key had no match)
- 3 = row matched in both files

A merge indicator full of 3s means a clean merge. Any 1s or 2s are mismatches. Some are expected (not everyone has a validated vote record). Many unexpected 1s or 2s suggest a key mismatch: possibly a string/numeric type discrepancy, leading/trailing whitespace, inconsistent capitalization ("TX" vs. "tx"), or a coding difference between files.

### Common Key Mismatch Problems

- **Type mismatch**: one file stores the respondent ID as a string ("00142"), the other as a numeric (142). They look like the same value but do not match.
- **Leading zeros**: a numeric ID converted to string may drop leading zeros. "00142" becomes "142."
- **Whitespace**: a state abbreviation imported from a CSV might be stored as " TX" (with a space). It will not match "TX." `trim()` functions fix this.
- **Case sensitivity**: "Democrat" vs. "democrat" vs. "DEMOCRAT" will all fail to match in a case-sensitive join.
- **Encoding differences**: rare in modern workflows but still appears when combining files from different sources or operating systems.

### When Append Is Right Instead

Appending stacks rows vertically. Two files with the same columns but covering different years of respondents get combined into one file with more rows and the same columns. The key thing to know: software aligns columns by name, not by position. If the 2019 file has variables in order (id, age, income) and the 2020 file has them in order (id, income, age), the append will correctly align them as long as the column names match. If a variable exists in one file but not the other, that variable gets missing values for all rows from the file that lacks it.

## 4. Honest Strengths vs. Weaknesses

**Strengths:**

- Enables multi-level and longitudinal analysis by linking data across levels and time.
- Preserves the original files (non-destructive: you create a new combined file).
- With proper key checks and merge indicator inspection, errors are detectable before they corrupt results.

**Weaknesses and honest caveats:**

- Silent errors are the main risk. An inner join that drops 30% of your sample is not an error message; it is a smaller dataset. You have to notice it.
- Many-to-many merges (where the key is not unique in either file) produce a Cartesian product of matching rows. This is almost always wrong for analysis purposes. The row count can explode without warning.
- Key quality degrades in practice. IDs get transcribed incorrectly, string formats drift between data vintages, and external data sources (Census, administrative records) use different coding schemes than your survey. Budget time for key cleaning before merging.
- Merging multiple files in sequence compounds errors. A mismatched key in the second merge may be invisible because the first merge already silently dropped the relevant rows.
