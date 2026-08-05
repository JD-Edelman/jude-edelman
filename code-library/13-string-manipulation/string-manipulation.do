/*==============================================================================
   MODULE 13: STRING MANIPULATION & REGULAR EXPRESSIONS
   Dataset: CES 2020 Common Content (cleaned from Module 1)
            + Simulated string variables

   Purpose: Work with string data in Stata — cleaning text fields,
   extracting substrings, pattern matching, and converting between
   string and numeric formats.

   Stata string functions work on str# (fixed-length) and strL (long-string)
   variables. Most operate left-to-right; all are case-sensitive by default.
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: CREATE EXAMPLE STRING VARIABLES
*==============================================================================

/*
   CES doesn't have many raw string variables (it's well-coded), but
   string data appears constantly in administrative records, open-ended
   surveys, and merged datasets. We simulate common messy cases.
*/

* Simulate messy state names (as you might get from a CSV merge)
gen state_name = ""
replace state_name = "  Florida  "   if state_fips == 12
replace state_name = "GEORGIA"       if state_fips == 13
replace state_name = "New York"      if state_fips == 36
replace state_name = "texas"         if state_fips == 48
replace state_name = "California "   if state_fips == 6
replace state_name = "Pennsylvania"  if state_fips == 42
replace state_name = "ohio"          if state_fips == 39
replace state_name = "MICHIGAN"      if state_fips == 26
replace state_name = " North Carolina" if state_fips == 37
replace state_name = "Arizona"       if state_fips == 4

* Simulate a name variable with inconsistent formatting
gen respondent_name = "Smith, John A." in 1
replace respondent_name = "jones, mary" in 2
replace respondent_name = "BROWN, JAMES" in 3
replace respondent_name = "Williams, Sue" in 4

* Simulate a messy date string
gen survey_date = ""
replace survey_date = "10/01/2020" in 1
replace survey_date = "2020-10-02" in 2
replace survey_date = "Oct 03, 2020" in 3
replace survey_date = "10-04-2020" in 4


*==============================================================================
* SECTION 2: BASIC STRING FUNCTIONS
*==============================================================================

/*
   Key Stata string functions:
   lower(s)       → lowercase
   upper(s)       → uppercase
   proper(s)      → Title Case
   trim(s)        → remove leading and trailing spaces
   ltrim(s)       → remove leading spaces only
   rtrim(s)       → remove trailing spaces only
   strlen(s)      → length of string
   substr(s,n,k)  → k characters starting at position n
   subinstr(s,f,r,n) → replace first n occurrences of f with r in s
   strpos(s,sub)  → position of sub in s (0 if not found)
   strtrim(s)     → same as trim (alias)
*/

* Standardize state names: trim whitespace, then proper case
gen state_clean = proper(trim(state_name))
list state_name state_clean in 1/10, clean

* All caps
gen state_upper = upper(trim(state_name))

* All lower
gen state_lower = lower(trim(state_name))

* String length
gen state_len = strlen(trim(state_name))
tab state_len

* Check if state name contains "New"
gen has_new = strpos(state_name, "New") > 0
tab has_new

* Replace abbreviation
gen state_corrected = subinstr(state_clean, "N. Carolina", "North Carolina", 1)


*==============================================================================
* SECTION 3: EXTRACTING SUBSTRINGS
*==============================================================================

/*
   substr(string, start, length)
   Negative start counts from the END of the string.
   If length is longer than the string, Stata returns what exists.
*/

* Extract first 5 characters of state name
gen state_abbrev5 = substr(state_clean, 1, 5)
list state_clean state_abbrev5 in 1/10, clean

* Extract last 5 characters (useful for zip code suffixes, etc.)
gen state_last5 = substr(state_clean, -5, 5)

* Extract middle characters (e.g., year from "10/01/2020")
gen year_str = substr(survey_date, 7, 4) if strpos(survey_date, "/") > 0
destring year_str, gen(year_num) force

* Extract first word (before first space)
gen first_word = substr(state_clean, 1, strpos(state_clean+" ", " ")-1)
list state_clean first_word in 1/10, clean


*==============================================================================
* SECTION 4: SPLITTING STRINGS
*==============================================================================

/*
   split varname, parse(delimiter)
   Splits a string on a delimiter into multiple new variables.
   The new variables are named varname1, varname2, etc.
*/

* Split survey_date on "/" → month, day, year
gen date_slash = survey_date if strpos(survey_date, "/") > 0
split date_slash, parse(/) gen(date_part)
rename date_part1 survey_month
rename date_part2 survey_day
rename date_part3 survey_year_str

destring survey_month survey_day survey_year_str, replace force

* Split respondent_name on "," → last name, first name
split respondent_name, parse(,) gen(name_part)
rename name_part1 last_name
rename name_part2 first_name

* Clean up first name (has leading space)
replace first_name = ltrim(first_name)
replace last_name  = proper(trim(last_name))
replace first_name = proper(trim(first_name))

list respondent_name last_name first_name in 1/4, clean


*==============================================================================
* SECTION 5: REGULAR EXPRESSIONS
*==============================================================================

/*
   Regular expressions (regex) are powerful patterns for matching and
   extracting complex string content.

   Key Stata regex functions:
   regexm(s, pattern)          → 1 if s matches pattern, 0 otherwise
   regexs(n)                   → nth captured group after regexm
   regexr(s, pattern, replace) → replace first match with replace string
   ustrregexm, ustrregexs      → Unicode versions (for non-ASCII text)

   Regex syntax:
   .       = any single character
   *       = zero or more of preceding
   +       = one or more of preceding
   ?       = zero or one of preceding
   [abc]   = any of a, b, c
   [0-9]   = any digit
   [A-Z]   = any uppercase letter
   ^       = start of string
   $       = end of string
   \d      = digit (use [0-9] in Stata's basic regex)
   ()      = capture group (accessible via regexs())
*/

* Does the state name contain a digit? (shouldn't — flag anomalies)
gen has_digit = regexm(state_name, "[0-9]")
count if has_digit == 1

* Extract 4-digit year from any date format using regex
gen year_extracted = ""
replace year_extracted = regexs(1) if regexm(survey_date, "([0-9][0-9][0-9][0-9])")
destring year_extracted, gen(year_regex) force

* Validate email format (if you had an email field)
* gen valid_email = regexm(email_var, "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")

* Replace "ohio" or "OHIO" with "Ohio" using case-insensitive matching
* (Stata's regexm is case-sensitive; use lower() first)
gen state_fixed = state_clean
replace state_fixed = "Ohio" if lower(trim(state_name)) == "ohio"

* Remove all spaces from a string
gen state_nospace = subinstr(state_clean, " ", "", .)

list state_clean state_nospace in 1/10, clean


*==============================================================================
* SECTION 6: CONVERTING STRINGS TO NUMERICS
*==============================================================================

/*
   destring: convert a string to numeric, coercing non-numeric to missing
   real():   inline conversion inside an expression
   encode:   convert a string categorical to a Stata labeled numeric
*/

* destring with force (non-numeric → missing)
gen age_str = string(age)
replace age_str = "unknown" in 1/50   /* inject some bad values */

destring age_str, gen(age_from_str) force
count if missing(age_from_str)   /* should equal 50 */
drop age_str age_from_str

* encode: string categories → numeric with value labels
gen party_str = ""
replace party_str = "Democrat"    if party_id3 == 1
replace party_str = "Republican"  if party_id3 == 2
replace party_str = "Independent" if party_id3 == 3

encode party_str, gen(party_encoded)
tab party_encoded   /* numeric with text labels */
describe party_encoded   /* type is byte/int, not str */


*==============================================================================
* SECTION 7: CONVERTING NUMERICS TO STRINGS
*==============================================================================

/*
   string(x): convert numeric to string
   string(x, format): apply a display format first (e.g., %02.0f for zero-padded)
   tostring: convert an entire variable
*/

* Zero-pad state FIPS codes (must be 2 digits, e.g., 01 not 1)
gen state_fips_str = string(state_fips, "%02.0f")
list state_fips state_fips_str in 1/5, clean

* Build a county FIPS code = state FIPS (2 digits) + county FIPS (3 digits)
* (pretend we have a county variable)
gen county_fips_fake = runiformint(1, 900)   /* integer uniform draw, Stata 14+ */
gen county_fips_str  = string(county_fips_fake, "%03.0f")
gen full_fips = state_fips_str + county_fips_str
list state_fips_str county_fips_str full_fips in 1/5, clean

drop county_fips_fake county_fips_str full_fips


*==============================================================================
* SECTION 8: STRING VARIABLES IN MERGE KEYS
*==============================================================================

/*
   Merging on string keys requires EXACT character-by-character matches.
   A single trailing space will prevent a match. Always:
   1. trim() both sides
   2. lower() both sides (or upper() — pick one)
   3. Verify N matches after merge
*/

* Simulate a lookup table keyed on lower-trimmed state names
preserve
collapse (first) state_fips, by(state_name)
gen merge_key = lower(trim(state_name))
drop if missing(merge_key) | merge_key == ""
save "state_lookup.dta", replace
restore

* Main data: create standardized key
gen merge_key = lower(trim(state_name))

* state_fips already exists in master — use a different name in the lookup file
* or drop it from keepusing (we only need the key for matching here)
merge m:1 merge_key using "state_lookup.dta", keepusing()
tab _merge
drop _merge merge_key


*==============================================================================
* SECTION 9: CLEANING OPEN-ENDED TEXT (WORD COUNT, CONTAINS)
*==============================================================================

/*
   If you have open-ended survey responses, common tasks are:
   - Count words
   - Check if a response contains a keyword
   - Standardize casing
*/

* Simulate an open-ended "describe your economic situation" field
gen econ_text = ""
replace econ_text = "Things are getting worse every year" in 1
replace econ_text = "I feel pretty secure financially" in 2
replace econ_text = "very worried about job loss" in 3
replace econ_text = "stable but not great" in 4

* Word count (count spaces + 1, for non-empty strings)
gen word_count = wordcount(econ_text) if econ_text != ""

* Does response mention "job" or "work"?
gen mentions_job = regexm(lower(econ_text), "job|work|employ")
tab mentions_job

* Does response mention economic decline?
gen mentions_decline = regexm(lower(econ_text), "worse|worried|loss|decline|bad")
tab mentions_decline


*==============================================================================
* SECTION 10: CLEANUP
*==============================================================================

drop state_name state_clean state_upper state_lower state_len has_new ///
     state_corrected state_abbrev5 state_last5 state_fixed state_nospace ///
     first_word respondent_name last_name first_name ///
     survey_date date_slash date_part1 date_part2 date_part3 ///
     survey_month survey_day survey_year_str ///
     year_str year_num year_extracted year_regex ///
     has_digit party_str party_encoded state_fips_str ///
     econ_text word_count mentions_job mentions_decline

di "Module 13 complete."
