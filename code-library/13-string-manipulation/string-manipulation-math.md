# Module 13 — String Manipulation: Math

## Symbols Used in This File

| Symbol | Meaning |
|---|---|
| A, B | String patterns (in regex context) |
| A* | Kleene star: zero or more repetitions of A |
| A+ | One or more repetitions of A (A+ = AA*) |
| A? | Zero or one occurrence of A |
| A\|B | Union: matches A or B |
| [abc] | Character class: matches a, b, or c |
| s, t | Input strings for edit distance |
| n, m | Lengths of s and t respectively |
| sᵢ | The i-th character of string s |
| d(i,j) | Edit distance between prefix of s of length i and prefix of t of length j |
| S | Finite set of string values a categorical variable takes |
| K | Number of distinct values in S |
| \d | Regex shorthand for a digit character [0-9] |
| \w | Regex shorthand for a word character [a-zA-Z0-9_] |
| \s | Regex shorthand for a whitespace character |

---

## Part A — Regular Expression Formal Grammar

### What a Regex Defines

A regular expression defines a formal language: the set of all strings that match the pattern. Each pattern is built from five base operations applied recursively to an alphabet (the set of characters you are working with).

### The Five Base Operations

**1. Concatenation**

If A and B are patterns, AB is the concatenation: a string matches AB if it can be split into a prefix that matches A immediately followed by a suffix that matches B.

Example: `cat` is the concatenation of the single-character patterns `c`, `a`, and `t`. It matches exactly the string "cat."

**2. Union (Alternation)**

A|B matches strings that match either A or B (or both, if both are possible).

Example: `cat|dog` matches "cat" or "dog." In a larger pattern, `(grey|gray)` matches either spelling of the color.

**3. Kleene Star**

A* matches zero or more consecutive repetitions of A. The empty string matches A* (zero repetitions).

Example: `ab*c` matches "ac" (zero b's), "abc" (one b), "abbc" (two b's), "abbbc" (three b's), and so on.

**4. Grouping with Parentheses**

Parentheses group sub-patterns. (AB)* means zero or more repetitions of the two-character sequence AB together, not zero or more A's followed by zero or more B's.

Example: `(ab)*c` matches "c" (zero ab's), "abc", "ababc", "abababc," but not "ac" (because that would need A to repeat while B stays absent).

**5. Character Classes**

[abc] matches any single character that is one of a, b, or c. [a-z] is shorthand for all lowercase letters. [^abc] matches any character that is not a, b, or c.

Common shorthands:
- \d = [0-9]
- \w = [a-zA-Z0-9_]
- \s = space, tab, newline
- . = any character except newline (in most implementations)

Quantifiers derived from the base operations:
- A+ = AA* (one or more A's)
- A? = (A | empty) (zero or one A)
- A{n} = exactly n repetitions of A
- A{n,m} = between n and m repetitions of A

### Worked Example: Matching a Date String

Pattern: `\d{2}-\d{2}-\d{4}`

Apply the operations step by step:

1. `\d` matches any single digit character.
2. `\d{2}` matches exactly two consecutive digit characters. This matches "01," "12," "09," etc.
3. `-` matches a literal hyphen character.
4. `\d{2}-\d{2}-\d{4}` is the concatenation: (two digits) then (hyphen) then (two digits) then (hyphen) then (four digits).

Match test against "05-20-2020":
- `\d{2}` matches "05." Check.
- `-` matches "-." Check.
- `\d{2}` matches "20." Check.
- `-` matches "-." Check.
- `\d{4}` matches "2020." Check.
- Full match: yes.

Match test against "5-20-2020":
- `\d{2}` requires two digits. "5" is only one digit before the hyphen. Fail.
- This pattern does not match dates without zero-padding.

To handle both padded and unpadded: `\d{1,2}-\d{1,2}-\d{4}`.

### Another Example: Extracting a US State Abbreviation

Pattern: `\b[A-Z]{2}\b`

- `\b` is a word boundary (zero-width assertion: position between a word character and a non-word character).
- `[A-Z]{2}` matches exactly two uppercase letters.
- This matches "FL," "CA," "NY," etc. as standalone tokens.

Limitation: it also matches any two-uppercase-letter token, including "US," "ID," or "OK" used as words. Regular expressions match patterns, not semantics. A regex alone cannot know that "OK" is sometimes a state abbreviation and sometimes a word.

---

## Part B — Levenshtein (Edit) Distance

### Definition

The Levenshtein distance d(s, t) between two strings s and t is the minimum number of single-character edit operations needed to transform s into t. The three allowed operations are:

- Insertion: insert one character anywhere in s.
- Deletion: delete one character from s.
- Substitution: replace one character of s with a different character.

Examples:
- d("kitten", "sitting") = 3 (substitute k→s, substitute e→i, insert g at the end)
- d("Florida", "florida") = 1 (substitute F→f)
- d("", "abc") = 3 (three insertions)

### Dynamic Programming Recurrence

Compute d(s, t) via a dynamic programming table. Let n = |s| (length of s) and m = |t|. Define:

d(i, j) = edit distance between the first i characters of s and the first j characters of t

**Base cases:**

d(0, j) = j   for j = 0, 1, ..., m   (transforming empty string to first j characters of t requires j insertions)
d(i, 0) = i   for i = 0, 1, ..., n   (transforming first i characters of s to empty string requires i deletions)

**Recurrence for i ≥ 1, j ≥ 1:**

d(i, j) = min(
  d(i-1, j) + 1,              [delete s_i: solve subproblem on s[1..i-1] vs t[1..j], then delete]
  d(i, j-1) + 1,              [insert t_j: solve subproblem on s[1..i] vs t[1..j-1], then insert]
  d(i-1, j-1) + cost          [match or substitute: cost = 0 if s_i = t_j, cost = 1 if s_i ≠ t_j]
)

The minimum is taken over these three operations. The cost term encodes: if the i-th character of s already equals the j-th character of t, no operation is needed; otherwise, one substitution is needed.

### Worked Example: d("cat", "bat")

n = 3 (s = "cat"), m = 3 (t = "bat").

Build the table d(i, j) for i = 0..3 and j = 0..3:

Initialize:

|   | "" | b | a | t |
|---|---|---|---|---|
| "" | 0 | 1 | 2 | 3 |
| c | 1 | ? | ? | ? |
| a | 2 | ? | ? | ? |
| t | 3 | ? | ? | ? |

Fill d(1,1): s₁ = 'c', t₁ = 'b'. s₁ ≠ t₁, so cost = 1.
d(1,1) = min(d(0,1)+1, d(1,0)+1, d(0,0)+1) = min(2, 2, 1) = 1

Fill d(1,2): s₁ = 'c', t₂ = 'a'. s₁ ≠ t₂, cost = 1.
d(1,2) = min(d(0,2)+1, d(1,1)+1, d(0,1)+1) = min(3, 2, 2) = 2

Fill d(1,3): s₁ = 'c', t₃ = 't'. s₁ ≠ t₃, cost = 1.
d(1,3) = min(d(0,3)+1, d(1,2)+1, d(0,2)+1) = min(4, 3, 3) = 3

Fill d(2,1): s₂ = 'a', t₁ = 'b'. s₂ ≠ t₁, cost = 1.
d(2,1) = min(d(1,1)+1, d(2,0)+1, d(1,0)+1) = min(2, 3, 2) = 2

Fill d(2,2): s₂ = 'a', t₂ = 'a'. s₂ = t₂, cost = 0.
d(2,2) = min(d(1,2)+1, d(2,1)+1, d(1,1)+0) = min(3, 3, 1) = 1

Fill d(2,3): s₂ = 'a', t₃ = 't'. s₂ ≠ t₃, cost = 1.
d(2,3) = min(d(1,3)+1, d(2,2)+1, d(1,2)+1) = min(4, 2, 3) = 2

Fill d(3,1): s₃ = 't', t₁ = 'b'. s₃ ≠ t₁, cost = 1.
d(3,1) = min(d(2,1)+1, d(3,0)+1, d(2,0)+1) = min(3, 4, 3) = 3

Fill d(3,2): s₃ = 't', t₂ = 'a'. s₃ ≠ t₂, cost = 1.
d(3,2) = min(d(2,2)+1, d(3,1)+1, d(2,1)+1) = min(2, 4, 3) = 2

Fill d(3,3): s₃ = 't', t₃ = 't'. s₃ = t₃, cost = 0.
d(3,3) = min(d(2,3)+1, d(3,2)+1, d(2,2)+0) = min(3, 3, 1) = 1

**Result: d("cat", "bat") = 1.** One substitution (c→b) transforms "cat" into "bat." Correct.

### Practical Use in Fuzzy Matching

In record linkage, you set a threshold δ: two strings are considered a match if d(s, t) ≤ δ. A common default for state names is δ = 1 or δ = 2. The normalized edit distance d(s,t) / max(|s|, |t|) puts the distance on a 0-to-1 scale, making it comparable across string pairs of different lengths.

Caution: fuzzy matching should be used only on pre-standardized strings (trimmed, lowercased). Running fuzzy matching on strings that differ only by case or whitespace inflates the match distance unnecessarily and may cause genuine matches to fall above the threshold.

---

## Part C — Indicator Variables from String Categories

### The Encoding Problem

Suppose a string variable party takes values in the set S = {"Democrat", "Republican", "Independent", "Other"}. K = |S| = 4 distinct values.

To use this variable in a regression, you need numeric codes. The standard approach is K - 1 = 3 binary (dummy) indicator variables, with one category omitted as the reference.

Define:

D_Rep = 1 if party = "Republican," 0 otherwise
D_Ind = 1 if party = "Independent," 0 otherwise
D_Oth = 1 if party = "Other," 0 otherwise

The omitted category is "Democrat," which is encoded as (D_Rep = 0, D_Ind = 0, D_Oth = 0).

A regression model using these dummies:

Y = β₀ + β₁ D_Rep + β₂ D_Ind + β₃ D_Oth + ε

The intercept β₀ is the expected Y for the reference category (Democrats). The coefficients β₁, β₂, β₃ are differences in expected Y relative to Democrats.

### The Dummy Trap: Why You Cannot Include All K Dummies

Define a fourth dummy:

D_Dem = 1 if party = "Democrat," 0 otherwise

Note the exact linear relationship:

D_Dem + D_Rep + D_Ind + D_Oth = 1   (every observation belongs to exactly one category)

This means D_Dem = 1 - D_Rep - D_Ind - D_Oth. In matrix form, if the design matrix X includes a column of ones (the intercept) and all four dummy columns, one column is an exact linear combination of the others. The matrix X'X is singular (non-invertible) and OLS has no unique solution.

**Formally:** let the design matrix be [1 | D_Dem | D_Rep | D_Ind | D_Oth]. The column of ones (intercept) equals the sum of all four dummy columns: 1 = D_Dem + D_Rep + D_Ind + D_Oth. Therefore, the five columns are linearly dependent, rank(X) < 5, and (X'X)⁻¹ does not exist.

The solution is to drop any one of the K categories. The choice of reference category does not affect fitted values, residuals, or model fit. It only changes the interpretation of the intercept and the specific contrasts encoded in the coefficients. A coefficient of 0.15 on D_Rep means Republicans score 0.15 higher than Democrats (the reference). If you changed the reference to Independents, the Republican coefficient would change but the implied predictions for every observation would be identical.

This is the direct analog of numeric dummy coding (Module 01 in this library) applied to strings. The mathematical logic is identical; the only additional step is converting the string categories to numeric indicators before any estimation.
