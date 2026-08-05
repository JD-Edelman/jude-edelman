# Merge and Append: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| L | Left table (the "base" or analysis table) |
| R | Right table (the table being merged in) |
| n_L | Number of rows in L |
| n_R | Number of rows in R |
| A | Multiset of key values in L |
| B | Multiset of key values in R |
| A ∩ B | Set of key values present in both L and R (intersection) |
| A ∪ B | Set of key values present in either L or R (union) |
| A \ B | Set of key values in A but not in B (set difference) |
| \|A\| | Number of distinct key values in A |
| c_L(k) | Number of times key value k appears in L |
| c_R(k) | Number of times key value k appears in R |
| D | Total number of rows with a given key column |
| U | Number of distinct values of a given key column |
| C_L | Set of column names in L |
| C_R | Set of column names in R |
| K | Key column used for joining |
| (K₁, K₂, ..., Kₚ) | Composite key: a tuple of columns that together are unique |

---

## Part A — Set Theory of Joins

**In practice:** Before you merge two datasets, you should be able to state precisely which rows you expect in the result. The set-theory framing gives you that precision. It also forces you to confront, before running the code, how many rows you will lose in an inner join.

### Inner Join

The **inner join** returns all rows from L matched with all rows from R where the key values agree.

Result key set:

```
A ∩ B
```

For a 1:1 join (key is unique in both tables):

```
Row count = |A ∩ B| ≤ min(|A|, |B|)
```

Equality holds when A ⊆ B or B ⊆ A. The lost rows are those in A \ B (keys in L with no match in R) and B \ A (keys in R with no match in L).

The proportion of rows dropped from L is:

```
Drop rate_L = |A \ B| / |A| = (|A| - |A ∩ B|) / |A|
```

If your left table has state-level data for 50 states and the right table has crime statistics for 48 states (two states missing), the inner join returns 48 rows. Those two states vanish silently unless you check.

### Left Join

The **left join** returns all rows of L, matched with R where a match exists, and NULL for right-side columns where no match exists.

```
Result key set: A    (all keys in L)
Row count (1:1 case): n_L
```

For rows in A ∩ B: right-side columns are populated. For rows in A \ B: right-side columns are NULL.

The left join is the safe default when you want to keep all your analysis units and accept NAs for unmatched covariates. You never lose left-table rows; you learn which rows lack matches by looking at which right-side columns are missing.

### Full Outer Join

The **full outer join** returns all rows from both L and R.

```
Result key set: A ∪ B
Row count (1:1 case): |A ∪ B| = |A| + |B| - |A ∩ B|
```

This is the **inclusion-exclusion principle**: the size of the union equals the sum of the individual sizes minus the size of the intersection (to avoid double-counting matched keys). For rows in A ∩ B, columns from both tables are populated. For rows in A \ B, right-side columns are NULL. For rows in B \ A, left-side columns are NULL.

### Cross Join (Cartesian Product)

The **cross join** matches every row of L with every row of R regardless of key.

```
Row count: n_L × n_R
```

No key is required. This is rarely the intended operation, but it is what you get in a many-to-many merge where the key is not unique in either table (for matching keys).

---

## Part B — Cardinality and Row Counts

**In practice:** Cardinality determines whether your merge is safe. Getting the cardinality wrong is one of the most common data-pipeline bugs in survey research, and it is silent: R and Stata will produce a result either way.

### Cardinality Notation

- **1:1** — each key value appears at most once in both L and R.
- **m:1** (many-to-one) — a key value may appear multiple times in L, but at most once in R. Example: multiple survey respondents in the same congressional district; the district-characteristics file has one row per district.
- **1:m** — the mirror of m:1. Rare in applied use; usually a matter of which table is called "left."
- **m:m** (many-to-many) — a key value may appear multiple times in both L and R.

### Row Count in a Many-to-Many Join

For a single key value k that appears c_L(k) times in L and c_R(k) times in R, the inner join produces c_L(k) × c_R(k) rows for that key value.

The total row count of a many-to-many inner join is:

```
Row count = Σ_{k ∈ A∩B} c_L(k) · c_R(k)
```

In the worst case, when all n_L rows share one key value and all n_R rows share the same key value:

```
Maximum row count = n_L × n_R
```

A many-to-many join between a 10,000-row person file and a 500-row person file (persons appear multiple times in both) can produce millions of rows. This is almost always a bug, not a feature.

**Worked example.** Suppose L has 5 respondents all from county 001, and R has 3 years of county-level data for county 001. The inner join produces 5 × 3 = 15 rows. If you did not intend to create a person-year panel, you have accidentally triplicated your respondent data.

### Safe vs. Unsafe Cardinality

For most analytic purposes:

- **1:1 — safe.** Row count is preserved. Each row gets exactly one match.
- **m:1 — safe.** Each left row gets at most one match (the single right-row for that key). Adding a district-level variable to a person-level file is a clean m:1 merge.
- **1:m or m:m — unsafe** for most analysis. Row counts increase, and each resulting row is not a distinct unit of observation.

Before any merge, assert your expected cardinality. In Stata:

```stata
merge 1:1 caseid using rightfile.dta
```

If Stata finds duplicate keys in either file, it returns an error before doing anything dangerous. This is the correct behavior and a useful safety check.

---

## Part C — Key Uniqueness

**In practice:** You should verify key uniqueness before every merge, not after. Discovering a many-to-many explosion in the result is harder to diagnose than catching duplicate keys before the merge.

### The Uniqueness Condition

A column K is a **key** for table T if and only if all values in K are distinct:

```
∀ i ≠ j in T, Kᵢ ≠ Kⱼ
```

Equivalently: the number of duplicate key values is 0.

### Duplicate Count Formula

Let D = total rows with key K in T. Let U = number of distinct values of K in T. Then:

```
Duplicate count = D - U
```

If D - U = 0, K is a valid key. If D - U > 0, K has duplicates and is not a key; any merge using K may produce unintended row inflation.

In Stata: `duplicates report caseid`. In R: `get_dupes(df, caseid)`. Always run this before a merge.

### Composite Keys

Sometimes no single column uniquely identifies rows. A **composite key** is a tuple of columns (K₁, K₂, ..., Kₚ) that is unique in their combination. In a county-year panel, neither county FIPS code nor year alone is unique, but (FIPS, year) together is.

Checking a composite key in Stata:

```stata
duplicates report fips year
```

Zero duplicates confirms that (fips, year) is a valid composite key. Nonzero means you need to investigate before merging on those columns.

---

## Part D — Append

**In practice:** Append is the operation for pooling survey waves, stacking replicate datasets, or combining files from different geographic regions. It is simpler than merging but has its own pitfalls around column naming and variable coverage.

### Definition

An **append** stacks the rows of two (or more) tables with the same columns:

```
Result row count = n_L + n_R
```

This is exact, not approximate. No keys are involved; rows from L and rows from R simply sit below each other in the result.

Unlike a merge, append never creates NAs from the join itself; all NAs in the result come from variables that exist in one file but not the other.

### Column Alignment by Name, Not Position

If L has columns (id, age, income) and R has columns (id, income, age), the append aligns by column name:

- Column "id" gets values from L's id column stacked above R's id column.
- Column "age" gets values from L's age column stacked above R's age column.
- Column "income" similarly.

The positional order within each file is irrelevant. This contrasts with naive row concatenation in some low-level environments (for example, cbind in R or hstack in NumPy), which would treat column 1 of L as the same as column 1 of R regardless of name.

### Handling Non-Overlapping Columns

If L has a variable X that R does not, the appended result has X for all L rows and missing for all R rows. If R has a variable Z that L does not, the result has Z missing for all L rows.

Formally, let C_L and C_R be the column sets of L and R. The append result has column set C_L ∪ C_R, with:

- Non-missing values for column c in row i if i ∈ L and c ∈ C_L, or i ∈ R and c ∈ C_R.
- Missing values otherwise.

When pooling two survey waves, variable names must match exactly for the variables you intend to stack. A variable called voted_2020 in one wave and vote_2020 in another will appear as two separate columns after appending, both mostly missing. Rename before appending.

### Tracking Source After Appending

Since appending discards information about which file each row came from, create a source indicator before appending:

```stata
gen wave = 2019
save wave2019_tagged.dta, replace

use wave2020.dta
gen wave = 2020
append using wave2019_tagged.dta
```

The row count identity n_L + n_R = N_result can then be verified, and the wave variable allows group-specific analysis or wave fixed effects.
