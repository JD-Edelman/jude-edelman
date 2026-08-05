/*==============================================================================
   MODULE 1: IMPORT, RENAME, RECODE & GENERATE NEW VARIABLES
   Dataset: Cooperative Election Study (CES) 2020 Common Content

   Download data (CSV, ~188MB):
   https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi%3A10.7910/DVN/E9N6PH

   Codebook/Questionnaire:
   https://cces.gov.harvard.edu/pages/welcome-cooperative-congressional-election-study

   Citation:
   Schaffner, Brian; Ansolabehere, Stephen; Luks, Sam, 2021,
   "Cooperative Election Study Common Content, 2020",
   https://doi.org/10.7910/DVN/E9N6PH, Harvard Dataverse, V4.

   Purpose: This module demonstrates how to import a large CSV into Stata,
   rename variables to plain-English names, use foreach loops with global
   macros as variable "dictionaries" to batch-recode missing values, and
   generate new variables from existing ones.
==============================================================================*/


*==============================================================================
* SECTION 0: SETUP
*==============================================================================

clear all
set more off

* Set your working directory — adjust this path to where your data lives
* cd "C:/Users/YourName/CES2020"

* Log file (optional but recommended — records everything in your session)
* log using "module01_output.log", replace


*==============================================================================
* SECTION 1: IMPORT CSV
*==============================================================================

/*
   insheet and import delimited both work for CSVs.
   import delimited is preferred in modern Stata (v13+).

   bindquote(strict) handles quoted fields correctly.
   case(lower) forces all variable names to lowercase.
*/

import delimited "CES20_Common_OUTPUT_vv.csv", ///
    bindquote(strict) ///
    case(lower) ///
    clear

* Quick check — confirm row/column counts
di "Observations: `=_N'"
di "Variables:    `=c(k)'"


*==============================================================================
* SECTION 2: RENAME VARIABLES
*==============================================================================

/*
   CES uses cryptic variable names (e.g., CC20_401, gender, birthyr).
   Renaming to plain English makes the rest of your code self-documenting.
   You don't have to rename everything — just the variables you'll use.

   Syntax: rename oldname newname
*/

* --- Demographics ---
rename gender         sex
rename birthyr        birth_year
rename educ           education
rename race           race_eth
rename hispanic       hispanic_id
rename votereg        voter_registered
rename region         census_region
rename inputstate     state_fips

* --- Party & ideology (YouGov panel profile variables) ---
rename pid3           party_id3
rename pid7           party_id7
rename ideo5          ideology5

* --- Survey weights ---
rename weight         wt_post
rename weight_cumulative wt_cumulative

* --- Presidential approval ---
rename cc20_320a      approve_trump
rename cc20_320b      approve_congress
rename cc20_320c      approve_scotus

* --- Economy / wellbeing ---
rename cc20_302       econ_retro        /* retrospective national economy  */
rename cc20_303       hh_income_change  /* household income last year      */
rename cc20_307       police_safety     /* feel safe around police         */
rename cc20_309e      self_rated_health

* --- Policy attitudes: healthcare (support/oppose) ---
rename cc20_327a      pol_medicare_expand
rename cc20_327b      pol_drug_prices
rename cc20_327c      pol_aca_repeal
rename cc20_327d      pol_medicaid_work
rename cc20_327e      pol_mandate_repeal
rename cc20_327f      pol_public_option

* --- Policy attitudes: guns ---
rename cc20_330a      pol_assault_ban
rename cc20_330b      pol_concealed_carry
rename cc20_330c      pol_background_check

* --- Policy attitudes: immigration ---
rename cc20_331a      pol_daca
rename cc20_331b      pol_border_patrol
rename cc20_331c      pol_wall
rename cc20_331d      pol_legal_status
rename cc20_331e      pol_deportation

* --- Policy attitudes: abortion ---
rename cc20_332a      pol_abort_always
rename cc20_332b      pol_abort_rape
rename cc20_332c      pol_abort_health
rename cc20_332d      pol_abort_heartbeat
rename cc20_332e      pol_abort_20wk
rename cc20_332f      pol_abort_fund
rename cc20_332g      pol_abort_ban

* --- Policy attitudes: environment/climate ---
rename cc20_333a      pol_climate_epa
rename cc20_333b      pol_climate_paris
rename cc20_333c      pol_climate_renewables
rename cc20_333d      pol_climate_carbon_tax

* --- Turnout & vote choice (post-election) ---
rename cc20_401       voted_2020
rename cc20_410       pres_vote


*==============================================================================
* SECTION 3: RECODE MISSING VALUES USING FOREACH LOOPS
*==============================================================================

/*
   CES uses numeric codes for non-response. We recode these to Stata's
   extended missing value (.) so they are excluded from all calculations.

   Missing codes by type:
     8  / 98  = Skipped (respondent saw question but skipped it)
     9  / 99  = Not Asked (question was not shown to this respondent)

   STRATEGY: Define global macros as "variable dictionaries" — one global
   per missing-code type. Then loop over each global and recode in one pass.
   This is far more efficient than recoding each variable individually.

   Global macro syntax:  global macroname "var1 var2 var3 ..."
   Foreach loop syntax:  foreach var of global macroname { ... }
*/


* --------------------------------------------------------------
* 3A. Variables with missing codes 8 (Skipped) and 9 (Not Asked)
* --------------------------------------------------------------

/*
   Most demographic and attitude variables use 8/9.
   We recode both to Stata missing (.) in a single loop.
*/

global vars_8_9 ///
    sex birth_year education race_eth hispanic_id voter_registered ///
    approve_trump approve_congress approve_scotus ///
    econ_retro hh_income_change police_safety self_rated_health ///
    pol_medicare_expand pol_drug_prices pol_aca_repeal pol_medicaid_work ///
    pol_mandate_repeal pol_public_option ///
    pol_assault_ban pol_concealed_carry pol_background_check ///
    pol_daca pol_border_patrol pol_wall pol_legal_status pol_deportation ///
    pol_abort_always pol_abort_rape pol_abort_health pol_abort_heartbeat ///
    pol_abort_20wk pol_abort_fund pol_abort_ban ///
    pol_climate_epa pol_climate_paris pol_climate_renewables pol_climate_carbon_tax

foreach var of global vars_8_9 {
    recode `var' (8=.) (9=.)
}


* --------------------------------------------------------------
* 3B. Variables with missing codes 98 and 99
* --------------------------------------------------------------

/*
   voted_2020 and pres_vote use 98/99 (Skipped/Not Asked) in the post-election
   wave — their substantive codes go up to 7, so single-digit 8/9 are NOT
   used. Recode 98 and 99 here only.
*/

global vars_98_99 ///
    voted_2020 pres_vote

foreach var of global vars_98_99 {
    recode `var' (98=.) (99=.)
}


* --------------------------------------------------------------
* 3C. Variables with missing code 6 = "Not sure" (treated as missing)
* --------------------------------------------------------------

/*
   econ_retro has a 6 = "Not sure" category that most analysts drop.
   If you want to keep "Not sure" as a separate category, skip this block.
*/

global vars_6_notsure ///
    econ_retro

foreach var of global vars_6_notsure {
    recode `var' (6=.)
}


* Spot-check: confirm no 8/9/98/99 values remain in key variables
foreach var in sex education pres_vote voted_2020 {
    quietly count if `var' == 8 | `var' == 9 | `var' == 98 | `var' == 99
    di "Remaining 8/9/98/99 in `var': `r(N)'"
}


*==============================================================================
* SECTION 4: GENERATE NEW VARIABLES
*==============================================================================

/*
   generate (or gen) creates new variables from existing ones.
   Common tasks: derive age, create binary indicators, collapse scales.

   Syntax: gen newvar = expression [if condition]
*/


* --------------------------------------------------------------
* 4A. Age (continuous)
* --------------------------------------------------------------

/*
   CES records birth year, not age. We calculate age as of election day 2020.
   Election day 2020: November 3, 2020.
*/

gen age = 2020 - birth_year
label variable age "Age as of 2020 election"

* Basic sanity check — flag anyone outside plausible range
count if age < 18 | age > 105
di "Observations with implausible age: `r(N)'"


* --------------------------------------------------------------
* 4B. College degree binary (0/1)
* --------------------------------------------------------------

/*
   education codes:
     1 = No HS diploma
     2 = HS graduate
     3 = Some college
     4 = 2-year college degree (Associate's)
     5 = 4-year college degree (Bachelor's)
     6 = Postgraduate degree

   college = 1 if respondent holds a 4-year degree or higher
*/

gen college = (education >= 5) if !missing(education)
label variable college "4-year college degree or higher (1=Yes)"


* --------------------------------------------------------------
* 4C. Biden voter binary (0/1)
* --------------------------------------------------------------

/*
   pres_vote codes (post-election):
     1 = Joe Biden
     2 = Donald Trump
     4 = Other candidate
     5 = Not on ballot in my state
     6 = Did not vote for president
     7 = Not sure

   biden_voter = 1 if voted for Biden, 0 if voted for Trump,
                 missing if anything else (didn't vote, other, not sure)
   This restricts the variable to a clean Biden vs. Trump comparison.
*/

gen biden_voter = .
replace biden_voter = 1 if pres_vote == 1
replace biden_voter = 0 if pres_vote == 2
label variable biden_voter "Voted for Biden (1=Yes, 0=Trump, .=Other/Missing)"


* --------------------------------------------------------------
* 4D. White non-Hispanic indicator
* --------------------------------------------------------------

/*
   race_eth codes:
     1 = White
     2 = Black / African American
     3 = Hispanic / Latino
     4 = Asian / Asian American
     5 = Native American
     6 = Two or more races
     7 = Other
     8 = Middle Eastern

   white_nh = 1 if race_eth==1 AND hispanic_id==2 (not Hispanic)
*/

gen white_nh = (race_eth == 1 & hispanic_id == 2) if ///
    !missing(race_eth) & !missing(hispanic_id)
label variable white_nh "White non-Hispanic (1=Yes)"


* --------------------------------------------------------------
* 4E. Voted indicator (binary, from turnout question)
* --------------------------------------------------------------

/*
   voted_2020 codes (post-election self-report):
     1 = I did not vote in the election
     2 = I thought about voting but did not
     3 = I usually vote but did not this time
     4 = I attempted to vote but could not
     5 = I voted in the election (most common)

   voted = 1 if code 5, 0 if codes 1-4
*/

gen voted = (voted_2020 == 5) if !missing(voted_2020)
label variable voted "Voted in 2020 election (1=Yes)"


* --------------------------------------------------------------
* 4F. Democrat / Republican binary from pid3
* --------------------------------------------------------------

/*
   party_id3 codes (from YouGov panel profile):
     1 = Democrat
     2 = Republican
     3 = Independent

   dem  = 1 if Democrat, 0 otherwise (among non-missing)
   rep  = 1 if Republican, 0 otherwise (among non-missing)
*/

gen dem = (party_id3 == 1) if !missing(party_id3)
gen rep = (party_id3 == 2) if !missing(party_id3)
label variable dem "Democrat (1=Yes)"
label variable rep "Republican (1=Yes)"


* --------------------------------------------------------------
* 4G. Policy support scale (additive index: immigration restrictionism)
* --------------------------------------------------------------

/*
   Create a simple additive index from the 5 immigration attitude items.
   Each item: 1=Support, 2=Oppose

   First flip so that 1=Restrictionist and 0=Non-restrictionist on each item,
   then sum. Higher score = more restrictionist.

   Note: this is a rough index — in a real analysis you'd check Cronbach's
   alpha and potentially use factor scores. See Module 5 (scale construction).
*/

* Flip each item: recode so 1=restrictionist position, 0=not
gen imm1 = (pol_daca       == 2) if !missing(pol_daca)         /* oppose DACA      */
gen imm2 = (pol_border_patrol == 1) if !missing(pol_border_patrol) /* support more patrol */
gen imm3 = (pol_wall       == 1) if !missing(pol_wall)         /* support wall     */
gen imm4 = (pol_legal_status == 2) if !missing(pol_legal_status) /* oppose path    */
gen imm5 = (pol_deportation == 1) if !missing(pol_deportation) /* support deport  */

* Sum the five items into an index (0–5)
egen imm_restrict = rowtotal(imm1 imm2 imm3 imm4 imm5)

* Set to missing if respondent skipped all five items
replace imm_restrict = . if missing(imm1) & missing(imm2) & ///
    missing(imm3) & missing(imm4) & missing(imm5)

label variable imm_restrict "Immigration restrictionism index (0=least, 5=most)"

* Drop the temporary item variables — index only
drop imm1 imm2 imm3 imm4 imm5


*==============================================================================
* SECTION 5: LABEL VALUES (OPTIONAL BUT RECOMMENDED)
*==============================================================================

/*
   Value labels attach text descriptions to numeric codes.
   Stata will display them in tables and graphs automatically.
   They don't change the underlying numbers — code still uses numerics.
*/

label define lbl_sex         1 "Male" 2 "Female"
label define lbl_college     0 "No 4-yr degree" 1 "College degree+"
label define lbl_voted       0 "Did not vote" 1 "Voted"
label define lbl_biden       0 "Trump" 1 "Biden"
label define lbl_white_nh    0 "Non-white or Hispanic" 1 "White non-Hispanic"
label define lbl_dem_rep     0 "No" 1 "Yes"
label define lbl_region      1 "Northeast" 2 "Midwest" 3 "South" 4 "West"

label values sex           lbl_sex
label values college       lbl_college
label values voted         lbl_voted
label values biden_voter   lbl_biden
label values white_nh      lbl_white_nh
label values dem           lbl_dem_rep
label values rep           lbl_dem_rep
label values census_region lbl_region


*==============================================================================
* SECTION 6: FINAL CHECKS
*==============================================================================

* Summarize key newly-generated variables
summarize age college voted biden_voter white_nh dem rep imm_restrict

* Tab a few categoricals to confirm recoding worked
tab sex,         missing
tab college,     missing
tab voted,       missing
tab biden_voter, missing

* Check vote share among those who reported voting
tab biden_voter if voted == 1, missing


*==============================================================================
* SECTION 7: SAVE CLEANED DATASET
*==============================================================================

/*
   Save as .dta so you don't have to re-import and re-clean each session.
   All subsequent modules start by loading this cleaned file.
*/

save "CES2020_clean.dta", replace

di "Module 1 complete. Cleaned dataset saved as CES2020_clean.dta"

* log close
