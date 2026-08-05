/*==============================================================================
   MODULE 7: MERGE AND APPEND
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Teach the two most common data-combination operations in Stata.

   MERGE  = join two datasets horizontally (add variables / columns)
            Two datasets share a common ID variable; you match rows by ID.
            Think: Excel VLOOKUP, SQL JOIN.

   APPEND = stack two datasets vertically (add observations / rows)
            Both datasets have the same variables; you add rows.
            Think: stacking two spreadsheets, SQL UNION ALL.

   We demonstrate both using pieces of the CES data split into thematic files:
     ces_demographics.dta  — respondent ID + demographic vars
     ces_attitudes.dta     — respondent ID + policy attitude vars
     ces_vote.dta          — respondent ID + turnout + vote choice vars
     ces_northeast.dta     — Northeast respondents only
     ces_south.dta         — South respondents only
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: SPLIT THE FULL DATASET INTO THEMATIC FILES
*==============================================================================

/*
   We create the split files from the clean data so this module is
   self-contained. In real life these would be pre-existing files —
   e.g., administrative records matched to survey data.
*/

* --- File 1: Demographics ---
preserve
keep caseid age sex education race_eth hispanic_id white_nh ///
     college birth_year census_region state_fips wt_post
save "ces_demographics.dta", replace
restore

* --- File 2: Policy Attitudes ---
preserve
keep caseid ideology5 party_id3 party_id7 dem rep ///
     imm_restrict pol_daca pol_border_patrol pol_wall pol_legal_status pol_deportation ///
     pol_assault_ban pol_concealed_carry pol_background_check ///
     pol_climate_epa pol_climate_paris pol_climate_renewables pol_climate_carbon_tax ///
     econ_retro hh_income_change approve_trump approve_congress approve_scotus
save "ces_attitudes.dta", replace
restore

* --- File 3: Vote Behavior ---
preserve
keep caseid voted voted_2020 pres_vote biden_voter
save "ces_vote.dta", replace
restore

* --- File 4 & 5: Regional subsets (for append demo) ---
preserve
keep if census_region == 1   /* Northeast */
save "ces_northeast.dta", replace
restore

preserve
keep if census_region == 3   /* South */
save "ces_south.dta", replace
restore

di "Split files created."


*==============================================================================
* SECTION 2: UNDERSTANDING MERGE TYPES
*==============================================================================

/*
   Stata has three merge types based on the cardinality of the match:

   1:1   — each observation in master matches at most one in using
           (both datasets have one row per ID)

   m:1   — many rows in master match one row in using
           (e.g., respondents merged to state-level data where many
            respondents share the same state)

   1:m   — one row in master matches many rows in using
           (e.g., one parent matched to multiple children)

   CES thematic files all have one row per caseid → use 1:1.

   After merge, Stata creates _merge:
     1 = master only (ID in demographics but not attitudes)
     2 = using only  (ID in attitudes but not demographics)
     3 = matched     (ID in both)
*/


*==============================================================================
* SECTION 3: 1:1 MERGE — DEMOGRAPHICS + ATTITUDES
*==============================================================================

* Start with demographics as the master dataset
use "ces_demographics.dta", clear

* Sort on the key variable before merging
sort caseid

* Merge in attitudes
merge 1:1 caseid using "ces_attitudes.dta"

/*
   Check the merge result — ALWAYS tabulate _merge after every merge.
   Any code != 3 means something unexpected happened.
*/

tab _merge

/*
   For a clean within-dataset split like this, all should be _merge==3.
   In real data, mismatches are common and must be investigated.
*/

* Drop the indicator now that we've checked it
drop _merge

* Spot-check: confirm variables from both files are present
describe caseid age ideology5 party_id7 imm_restrict

di "Demographics + Attitudes merged successfully."
save "ces_dem_att.dta", replace


*==============================================================================
* SECTION 4: 1:1 MERGE — ADD VOTE DATA
*==============================================================================

use "ces_dem_att.dta", clear
sort caseid

merge 1:1 caseid using "ces_vote.dta"
tab _merge
drop _merge

describe caseid age ideology5 voted biden_voter

save "ces_full_rebuilt.dta", replace
di "Full dataset rebuilt from thematic files."


*==============================================================================
* SECTION 5: MERGE WITH MISMATCHES — REALISTIC SCENARIO
*==============================================================================

/*
   In real research you often merge survey data to external files
   (e.g., state-level unemployment rates, county FIPS demographics).
   These frequently have non-matching records.

   We simulate this by creating a fake state-level file that is missing
   a few states, then merging and handling the mismatches.
*/

* Create a fake state-level economic indicator
clear
input state_fips state_unemp
    1  3.5
    4  5.2
    6  7.1
    8  3.9
    9  4.4
   10  4.1
   12  4.7
   13  3.8
   17  4.5
   18  3.3
end
save "state_economics.dta", replace

* Merge respondents to state-level data (many respondents per state → m:1)
use "ces_full_rebuilt.dta", clear
sort state_fips

merge m:1 state_fips using "state_economics.dta"

tab _merge
/*
   _merge == 1: respondents whose state is NOT in our economic file
   _merge == 2: states in the economic file with no respondents
   _merge == 3: matched
*/

* Investigate mismatches
list state_fips if _merge == 1 in 1/20   /* which states are unmatched? */

* Options for handling mismatches:
* (a) Keep only matched: keep if _merge == 3
* (b) Keep all respondents, set state_unemp to missing for unmatched: leave as-is
* (c) Investigate and fix the source file

* Here: option (b) — keep all respondents
drop if _merge == 2   /* drop state-level rows with no survey match */
drop _merge

* Confirm: state_unemp is missing for unmatched respondents
count if missing(state_unemp)

drop state_unemp   /* clean up fake variable */


*==============================================================================
* SECTION 6: ASSERT CLEAN MERGE (BEST PRACTICE)
*==============================================================================

/*
   Use assert after merge to catch unexpected mismatches in production code.
   If the assertion fails, Stata throws an error and stops — much better
   than silently proceeding with missing data.
*/

use "ces_demographics.dta", clear
sort caseid
merge 1:1 caseid using "ces_vote.dta"

* This should be true for a clean within-dataset split:
assert _merge == 3
drop _merge

di "Assert passed — all records matched."


*==============================================================================
* SECTION 7: KEEPUSING — MERGE ONLY SELECTED VARIABLES
*==============================================================================

/*
   keepusing(varlist) imports only the listed variables from the using file.
   Saves memory when the using file has hundreds of variables but you only
   need a few.
*/

use "ces_demographics.dta", clear
sort caseid

merge 1:1 caseid using "ces_attitudes.dta", ///
    keepusing(ideology5 party_id3 imm_restrict approve_trump)

tab _merge
drop _merge

describe   /* confirm only selected attitude vars imported */


*==============================================================================
* SECTION 8: APPEND — STACK REGIONAL DATASETS
*==============================================================================

/*
   append adds rows (observations) from a second file below the current data.
   Both files must have the same variable names (extra vars from either file
   are filled with missing for the other file's rows).

   Syntax: append using "second_file.dta"

   We stack Northeast and South respondents into one regional subset file.
*/

use "ces_northeast.dta", clear
di "Northeast N = `=_N'"

append using "ces_south.dta"
di "After append N = `=_N'"

* Confirm both regions present
tab census_region, missing

save "ces_ne_south.dta", replace
di "Northeast and South appended."


*==============================================================================
* SECTION 9: APPEND MULTIPLE FILES IN A LOOP
*==============================================================================

/*
   When you have many files to stack (e.g., 50 state files, or yearly panels),
   a foreach loop over filenames is the cleanest approach.

   We simulate four regional files and stack them.
*/

* Create the other two regional files for the demo
use "CES2020_clean.dta", clear
keep if census_region == 2
save "ces_midwest.dta", replace

use "CES2020_clean.dta", clear
keep if census_region == 4
save "ces_west.dta", replace

* --- Append all four regions in a loop ---
* Load the first file, then append the remaining three.
* (The tempfile pattern is fragile — use explicit load + append instead.)

use "ces_northeast.dta", clear

foreach region in midwest south west {
    append using "ces_`region'.dta"
}

save "ces_all_regions.dta", replace
di "All four regional files stacked. N = `=_N'"

* Confirm
tab census_region


*==============================================================================
* SECTION 10: CHECKING FOR DUPLICATE IDs AFTER MERGE/APPEND
*==============================================================================

/*
   After any data combination step, check for duplicate IDs.
   Duplicates in a 1:1 merge key cause Stata to throw an error —
   but after append, IDs can legitimately duplicate (same person
   appearing in multiple files should NOT happen in a cross-sectional survey).
*/

use "ces_all_regions.dta", clear

* Check for duplicates on caseid
duplicates report caseid

/*
   If you see duplicates here, it means a respondent appeared in more than one
   regional file — likely a data error in how the splits were created.
*/

duplicates tag caseid, gen(dup_flag)
count if dup_flag > 0
drop dup_flag


*==============================================================================
* SECTION 11: MANY-TO-ONE MERGE — REAL EXAMPLE
*==============================================================================

/*
   m:1 merge: many survey respondents share a state → merge to state data.
   The using file has ONE row per state.
   The master file has MANY rows per state (one per respondent).
*/

* Create a real-ish state characteristic file using CES state codes
* (population density quintile — made up for illustration)
use "CES2020_clean.dta", clear

* Compute mean ideology by state as a "state-level" variable
collapse (mean) state_mean_ideo = ideology5 (count) n_respondents = caseid, ///
    by(state_fips)

save "state_characteristics.dta", replace

* Now merge back to individual-level data
use "CES2020_clean.dta", clear
sort state_fips

merge m:1 state_fips using "state_characteristics.dta", ///
    keepusing(state_mean_ideo n_respondents)

tab _merge
drop _merge

* Now each respondent has their state's mean ideology attached
summarize state_mean_ideo
corr ideology5 state_mean_ideo   /* individual ideology correlated with state mean */


*==============================================================================
* SECTION 12: CLEANUP
*==============================================================================

* List all the split files we created
di "Files created in this module:"
di "  ces_demographics.dta"
di "  ces_attitudes.dta"
di "  ces_vote.dta"
di "  ces_northeast.dta  ces_midwest.dta  ces_south.dta  ces_west.dta"
di "  ces_dem_att.dta"
di "  ces_full_rebuilt.dta"
di "  ces_ne_south.dta"
di "  ces_all_regions.dta"
di "  state_economics.dta  state_characteristics.dta"

di "Module 7 complete."
