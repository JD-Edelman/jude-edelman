---
name: replication-package
description: "Audit and assemble a replication package for a quantitative paper in Stata, R, or Python: one master script that runs raw data to every table and figure, relative paths, seeds, logged versions, a data-availability statement, and a README in the Social Science Data Editors template. Use whenever the user is submitting to a journal that requires code/data, preparing materials for a coauthor or advisor, cleaning up an analysis folder, asks 'can someone else run this', or mentions replication, reproducibility, Dataverse, OSF, or ICPSR deposit."
---

# Replication package

A replication package works if a stranger with the data can run one file and get every number in the paper. Most don't, for boring reasons: absolute paths, missing intermediate files, unseeded randomness, and steps done by hand. This skill finds those and fixes them.

## Step 1: inventory

List every file in the project and classify: raw data, intermediate data, code, output (tables/figures/logs), manuscript. Then map each table and figure in the manuscript to the script and line that produces it. Anything in the paper that no script produces is the first finding — it was made by hand and must be scripted or documented.

## Step 2: audit the code

Check for and fix:
- **Absolute paths** (`C:\Users\…`, `/Users/jude/…`). Replace with a single root global set in the master script (Stata `global root`; R `here::here()`; Python `pathlib.Path(__file__)`).
- **Order dependence**: scripts that only work if run after something else unstated. The master script should encode the order.
- **Randomness**: multiple imputation, bootstrap, matching, sampling, and train/test splits need a seed set once, visibly (`set seed`, `set.seed`, `np.random.default_rng(seed)`). Multiple imputation and propensity score matching (modules 10 and 15 in the user's code library) are the usual offenders.
- **Package versions**: Stata `version` statement and a list of `ssc install`s; R `renv` lockfile or `sessionInfo()`; Python `requirements.txt` with pinned versions.
- **Interactive steps**: `browse`, `edit`, `View()`, manual Excel edits. Replace or document.
- **Outputs**: every table/figure written to file by code, not copied from the console.
- **Logs**: the master script writes a log so a replicator can compare.
- **Dead code**: exploratory analyses not in the paper go in an `extra/` folder or get removed.

Report findings as a checklist with file and line, then make the fixes with the user's agreement.

## Step 3: structure

```
project/
├── README.md
├── main.do | main.R | main.py      # runs everything in order
├── code/
│   ├── 01_clean.*
│   ├── 02_analysis.*
│   └── 03_tables_figures.*
├── data/
│   ├── raw/          # untouched; or instructions to obtain
│   └── derived/      # created by code only
└── output/
    ├── tables/
    ├── figures/
    └── logs/
```

## Step 4: data availability

For each dataset: source, citation with DOI, access conditions, and exact file/version used. Restricted data (NCANDS, AFCARS, NSCAW, restricted Add Health, state administrative records) cannot be deposited — say how a replicator would apply for access, and provide the code plus a synthetic or dummy dataset with the same structure so the code can at least be run end to end.

## Step 5: README

Use the Social Science Data Editors template sections: Overview; Data Availability and Provenance; Dataset list; Computational requirements (software, versions, packages, runtime, memory); Description of programs; Instructions to replicators; List of tables and programs (table/figure → script → output file); References. Keep it plain.

## Step 6: test

If possible, run the master script from a clean copy in a fresh session and confirm outputs match the manuscript. If the data isn't available here, at minimum run a syntax/lint pass and check that every referenced file exists. Report what was verified and what wasn't — "runs end to end" should only be claimed if it was actually run.
