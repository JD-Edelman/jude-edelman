# String Manipulation: Mathematical Derivation

## Symbols

| Symbol | Meaning |
|--------|---------|
| A, B | String patterns (regular expressions) |
| A\|B | Union: the set of strings matching A or B |
| A* | Kleene star: zero or more repetitions of A |
| A+ | One or more repetitions of A; shorthand for AA* |
| A? | Zero or one occurrence of A |
| A{n} | Exactly n repetitions of A |
| A{n,m} | Between n and m repetitions of A |
| [abc] | Character class: matches any one of a, b, or c |
| \d | Digit shorthand: [0-9] |
| \w | Word character shorthand: [a-zA-Z0-9_] |
| \s | Whitespace shorthand: space, tab, newline |
| s, t | Input strings for edit distance computation |
| n, m | Lengths of strings s and t, respectively |
| sᵢ | The i-th character of string s |
| tⱼ | The j-th character of string t |
| d(i,j) | Edit distance between the first i characters of s and the first j characters of t |
| S | Finite set of distinct string values a categorical variable takes |
| K | Number of distinct values in S |
| Dₖ | Binary dummy variable for the k-th category |

---

## Part A — Regular Expression Formal Grammar

**In practice:** When your data contains address fields, open-ended survey responses, or ID codes, you need a principled way to describe which strings count as valid and extract substrings of interest. Regular expressions give you that precision. Regex is worth learning when you need to apply the same pattern to thousands of strings; for one-off cleaning of three values, str.replace() is faster to write.

### The Five Base Operations

A **regular expression** defines a formal language: the set of all strings that match the pattern. Every regex pattern is built by recursively combining five operations on an alphabet (the set of allowed characters).

**1. Concatenation**

If A and B are patterns, then AB matches any string formed by joining a string from A directly with a string from B.

```
L(AB) = { xy : x ∈ L(A), y ∈ L(B) }
```

The pattern `cat` is the concatenation of the single-character patterns `c`, `a`, and `t`; it matches only the string "cat." Order matters: `ca` and `ac` define different sets.

**2. Union (Alternation)**

`A|B` matches any string that matches A or any string that matches B.

```
L(A|B) = L(A) ∪ L(B)
```

The pattern `grey|gray` matches "grey" and "gray" and nothing else. Enclosing in parentheses, `(grey|gray)scale`, applies union only to that part, matching "greyscale" or "grayscale."

**3. Kleene Star**

`A*` matches zero or more consecutive repetitions of A. The empty string always belongs to L(A*).

```
L(A*) = { ε } ∪ L(A) ∪ L(AA) ∪ L(AAA) ∪ ...
```

The pattern `ab*c` matches "ac" (zero b's), "abc" (one b), "abbc" (two b's), and so on. The star applies only to the immediately preceding element unless you use parentheses.

**4. Grouping with Parentheses**

Parentheses scope which sub-pattern an operator applies to. `(AB)*` means zero or more repetitions of the two-character sequence AB together.

```
L((AB)*) ≠ L(A*B*)
```

The pattern `(ab)*c` matches "c", "abc", "ababc", but not "aabbc." Without grouping, `ab*c` means a, then zero or more b's, then c.

**5. Character Classes**

`[abc]` matches any single character in the listed set. `[a-z]` is shorthand for all 26 lowercase letters. `[^abc]` matches any character not in the set.

```
L([abc]) = { "a", "b", "c" }
L([a-z]) = { "a", "b", ..., "z" }
```

Common shorthands derived from character classes:

```
\d  =  [0-9]
\w  =  [a-zA-Z0-9_]
\s  =  [ \t\n\r]
.   =  any character except newline
```

Quantifiers derived from the base operations:

```
A+    =  AA*          (one or more)
A?    =  (A|ε)        (zero or one)
A{n}  =  A applied n times exactly
A{n,m} = A applied between n and m times
```

### Worked Example: Matching a Date String

**In practice:** Date fields are a constant pain point in survey data: some respondents write "05-20-2020," others write "5/20/20." The pattern below locks in one format and flags everything else as non-conforming before merging files.

The pattern `\d{2}-\d{2}-\d{4}` encodes the format MM-DD-YYYY with zero-padded month and day.

Breaking it down operation by operation:

```
\d        matches any character in {0, 1, 2, 3, 4, 5, 6, 7, 8, 9}
\d{2}     matches exactly 2 consecutive digits
-         matches the literal hyphen character
\d{2}-\d{2}-\d{4}  =  (2 digits) concat (-) concat (2 digits) concat (-) concat (4 digits)
```

Test against "05-20-2020":

```
\d{2}  matches "05"   -- check
-      matches "-"    -- check
\d{2}  matches "20"   -- check
-      matches "-"    -- check
\d{4}  matches "2020" -- check
Result: MATCH
```

Test against "5-20-2020":

```
\d{2}  requires 2 digits; only "5" available before the hyphen
Result: NO MATCH
```

This pattern is strict: it rejects unpadded dates. To allow both padded and unpadded, use `\d{1,2}-\d{1,2}-\d{4}`. This small change expands the matched set to include "5-3-2020" and similar forms. The choice of which to use depends on whether your data source guarantees zero-padding.

To match date strings embedded inside longer strings rather than the whole string, use `re.search()` in Python or `regexm()` in Stata rather than anchored match functions; otherwise the pattern only fires when the entire field is the date.

---

## Part B — String Distance (Levenshtein)

**In practice:** In record linkage, the same respondent or organization often appears with slightly different spellings across data sources. Edit distance gives you a single number that quantifies how different two strings are, making automated fuzzy matching possible at scale.

### Definition

The **Levenshtein distance** d(s, t) between strings s and t is the minimum number of single-character operations needed to transform s into t. The three allowed operations are:

```
Insertion:     add one character anywhere in s
Deletion:      remove one character from s
Substitution:  replace one character of s with a different character
```

Each operation costs 1. The distance is the minimum total cost over all possible sequences of operations. For example, d("Florida", "florida") = 1 because one substitution (F to f) suffices.

### Dynamic Programming Recurrence

Computing d(s, t) by brute force (enumerating all edit sequences) is infeasible. The efficient approach uses dynamic programming. Define d(i, j) as the edit distance between the first i characters of s and the first j characters of t.

**Base cases** (transforming to or from an empty string):

```
d(0, j) = j   for j = 0, 1, ..., m    (j insertions needed)
d(i, 0) = i   for i = 0, 1, ..., n    (i deletions needed)
```

**Recurrence** for i >= 1 and j >= 1:

```
d(i, j) = min(
    d(i-1, j)   + 1,              -- delete sᵢ
    d(i, j-1)   + 1,              -- insert tⱼ
    d(i-1, j-1) + [sᵢ ≠ tⱼ]      -- substitute if characters differ; cost 0 if they match
)
```

The indicator [sᵢ ≠ tⱼ] equals 1 when the characters differ (a substitution is needed) and 0 when they match (no operation needed at this position). The algorithm fills the table from top-left to bottom-right; d(n, m) in the bottom-right cell is the answer.

### Worked Example: d("cat", "cut")

n = 3 (s = "cat"), m = 3 (t = "cut"). Build the 4x4 table. Rows index positions in s (0 = empty, 1 = c, 2 = a, 3 = t); columns index positions in t (0 = empty, 1 = c, 2 = u, 3 = t).

**Initialize the borders:**

```
     ""   c    u    t
""    0   1    2    3
c     1   ?    ?    ?
a     2   ?    ?    ?
t     3   ?    ?    ?
```

**Fill d(1,1):** s₁ = 'c', t₁ = 'c'. Characters match, so [sᵢ ≠ tⱼ] = 0.

```
d(1,1) = min(d(0,1)+1, d(1,0)+1, d(0,0)+0) = min(2, 2, 0) = 0
```

**Fill d(1,2):** s₁ = 'c', t₂ = 'u'. Characters differ, cost = 1.

```
d(1,2) = min(d(0,2)+1, d(1,1)+1, d(0,1)+1) = min(3, 1, 2) = 1
```

**Fill d(1,3):** s₁ = 'c', t₃ = 't'. Differ, cost = 1.

```
d(1,3) = min(d(0,3)+1, d(1,2)+1, d(0,2)+1) = min(4, 2, 3) = 2
```

**Fill d(2,1):** s₂ = 'a', t₁ = 'c'. Differ, cost = 1.

```
d(2,1) = min(d(1,1)+1, d(2,0)+1, d(1,0)+1) = min(1, 3, 2) = 1
```

**Fill d(2,2):** s₂ = 'a', t₂ = 'u'. Differ, cost = 1.

```
d(2,2) = min(d(1,2)+1, d(2,1)+1, d(1,1)+1) = min(2, 2, 1) = 1
```

**Fill d(2,3):** s₂ = 'a', t₃ = 't'. Differ, cost = 1.

```
d(2,3) = min(d(1,3)+1, d(2,2)+1, d(1,2)+1) = min(3, 2, 2) = 2
```

**Fill d(3,1):** s₃ = 't', t₁ = 'c'. Differ, cost = 1.

```
d(3,1) = min(d(2,1)+1, d(3,0)+1, d(2,0)+1) = min(2, 4, 3) = 2
```

**Fill d(3,2):** s₃ = 't', t₂ = 'u'. Differ, cost = 1.

```
d(3,2) = min(d(2,2)+1, d(3,1)+1, d(2,1)+1) = min(2, 3, 2) = 2
```

**Fill d(3,3):** s₃ = 't', t₃ = 't'. Match, cost = 0.

```
d(3,3) = min(d(2,3)+1, d(3,2)+1, d(2,2)+0) = min(3, 3, 1) = 1
```

**Completed table:**

```
     ""   c    u    t
""    0   1    2    3
c     1   0    1    2
a     2   1    1    2
t     3   2    2    1
```

**Result: d("cat", "cut") = 1.** One substitution, 'a' to 'u', transforms "cat" into "cut." The table confirms this is the minimum.

Edit distance is the backbone of fuzzy merge tools (fuzzyjoin in R, recordlinkage in Python). A threshold of d <= 2 catches most typos and spacing errors without generating too many false matches. Always pre-standardize strings (trim whitespace, lowercase) before computing edit distance; otherwise "Florida" and "florida" register as d = 1 when they should be treated as identical.

---

## Part C — Encoding Categorical Strings as Dummies

**In practice:** Regression software needs numeric input. When a string variable like "party affiliation" or "region" enters the model, the encoding step converts it to numbers. Getting this wrong (including too many dummies) crashes the model; getting the reference category wrong does not change fitted values but does change how you narrate the results.

### From Strings to Dummies

Suppose a string variable `party` takes values in the set S = {"Democrat", "Republican", "Independent", "Other"}. There are K = |S| = 4 distinct values.

The standard encoding uses K - 1 = 3 **dummy variables**, omitting one category as the **reference category**. With "Democrat" as reference:

```
D_Rep = 1 if party = "Republican",  0 otherwise
D_Ind = 1 if party = "Independent", 0 otherwise
D_Oth = 1 if party = "Other",       0 otherwise
```

A Democrat is encoded as (D_Rep = 0, D_Ind = 0, D_Oth = 0): all dummies off. The regression model is:

```
Y = β₀ + β₁ D_Rep + β₂ D_Ind + β₃ D_Oth + ε
```

Here β₀ is the expected Y for Democrats. Each coefficient β₁, β₂, β₃ is the difference in expected Y between that party and Democrats.

### The Dummy Trap: Why You Cannot Include All K Dummies

Define a fourth dummy for the reference category:

```
D_Dem = 1 if party = "Democrat", 0 otherwise
```

Every observation belongs to exactly one party, so the four dummies satisfy an exact linear constraint:

```
D_Dem + D_Rep + D_Ind + D_Oth = 1   for every observation
```

This means D_Dem = 1 - D_Rep - D_Ind - D_Oth. In matrix form, let the design matrix X have columns [1 | D_Dem | D_Rep | D_Ind | D_Oth]. The constant column (intercept) equals the sum of all four dummy columns:

```
intercept column = D_Dem + D_Rep + D_Ind + D_Oth
```

This is a **perfect multicollinearity**: one column is an exact linear combination of the others. The consequence is:

```
rank(X) < number of columns
=> X'X is singular
=> (X'X)⁻¹ does not exist
=> OLS has no unique solution
```

No unique β exists. Software will either throw an error or silently drop one column, depending on implementation.

The fix is always to drop any one of the K dummies. The choice of which to drop (the reference category) does not change fitted values Y-hat, residuals, R-squared, or any F-test. It only changes the interpretation of the intercept and slope coefficients. If you switch the reference from Democrats to Republicans, β₀ changes (now it represents Republicans) and the other coefficients represent distances from Republicans, but every predicted value for every observation stays the same.

In R, `factor()` and `as.factor()` handle this automatically. In Stata, `i.varname` does the same. Never manually create all K dummies and include them together with an intercept.
