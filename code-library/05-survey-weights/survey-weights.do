/*==============================================================================
   MODULE 5: SURVEY-WEIGHTED ANALYSIS (svyset / svy)
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Demonstrate proper survey-weighted estimation using Stata's svy
   suite. CES uses a complex sampling design — weighted analysis is required
   for nationally representative estimates.

   Key CES weights:
     wt_post          = post-election wave weight (use for post-wave variables)
     wt_cumulative    = weight for multi-year cumulative file (not used here)
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: WHAT ARE SURVEY WEIGHTS AND WHY DO THEY MATTER?
*==============================================================================

/*
   Survey weights correct for unequal probabilities of selection and
   non-response. Failing to weight produces biased estimates if the
   sample over- or under-represents groups that differ on your variables
   of interest.

   In CES, YouGov uses a matched random sample — the post-election weight
   (wt_post) adjusts for differential non-response across demographic
   and political subgroups.

   Two approaches:
   1. Weighted regression (regress ... [pweight=wt_post]) — adjusts point
      estimates but does NOT properly propagate sampling uncertainty.
   2. svyset + svy: prefix — correctly handles the complex design, giving
      design-based standard errors.

   Always use svyset for any estimate you'll publish.
*/


*==============================================================================
* SECTION 2: DECLARE THE SURVEY DESIGN
*==============================================================================

/*
   svyset tells Stata the structure of your sampling design.
   CES does not publish stratum or cluster variables publicly, so we
   declare only the weight. This gives correct weighted estimates;
   SEs will be Taylor-linearized.

   svyset [pweight variable], strata(strata_var) psu(cluster_var)
   For CES without public design variables:
*/

svyset [pweight=wt_post]

/*
   After svyset, all svy: commands use this design.
   You only need to run svyset once per session (or after clear).
*/

* Confirm design declaration
svyset


*==============================================================================
* SECTION 3: WEIGHTED MEANS AND PROPORTIONS
*==============================================================================

/*
   svy: mean estimates population means with design-based SEs.
   svy: proportion estimates population proportions for categorical vars.
*/

* Weighted mean age, ideology, restrictionism
svy: mean age ideology5 imm_restrict econ_retro

* Compare to unweighted
mean age ideology5 imm_restrict econ_retro

/*
   Notice how the point estimates shift slightly — this is the sample
   composition correction from weighting.
*/

* Weighted proportions for categorical variables
svy: proportion college
svy: proportion voted
svy: proportion biden_voter
svy: proportion party_id3

* Proportion by subgroup (e.g., voted broken down by census region)
svy: proportion voted, over(census_region)


*==============================================================================
* SECTION 4: WEIGHTED TABULATIONS
*==============================================================================

/*
   svy: tabulate is the weighted version of tabulate.
   row / col / cell options work the same as in unweighted tabulate.
   pearson requests a design-corrected chi-square test (Rao-Scott test).
*/

* Biden vote choice by party ID
svy: tabulate party_id3 biden_voter, row pearson

* Biden vote choice by college
svy: tabulate college biden_voter, row pearson

* Turnout by census region
svy: tabulate census_region voted, row pearson


*==============================================================================
* SECTION 5: SURVEY-WEIGHTED OLS (LINEAR REGRESSION)
*==============================================================================

/*
   svy: regress is the weighted version of regress.
   Standard errors are design-based (Taylor linearization).
   R-squared is not reported by default (it has limited meaning in survey context);
   use estat summarize after estimation to get weighted means.
*/

* Weighted OLS: predictors of immigration restrictionism
svy: regress imm_restrict education age i.sex i.census_region ideology5 party_id7

estimates store svy_ols

* Post-estimation: weighted summary of variables used in the model
estat summarize


*==============================================================================
* SECTION 6: SURVEY-WEIGHTED LOGIT
*==============================================================================

/*
   svy: logit produces design-weighted logistic regression.
   Interpretation is identical to unweighted logit — just with
   correctly propagated sampling uncertainty.
*/

* Weighted logit: voter turnout
svy: logit voted education age i.sex i.census_region ideology5 party_id7

estimates store svy_logit_voted

* Weighted odds ratios
svy: logit voted education age i.sex i.census_region ideology5 party_id7, or

* Weighted logit: Biden vote choice (among voters)
* Use subpop() NOT if — if drops cases from the design and gives wrong SEs
svy, subpop(if voted == 1): logit biden_voter education age i.sex ideology5 party_id7 ///
    white_nh college imm_restrict, or

estimates store svy_logit_biden


*==============================================================================
* SECTION 7: SUBPOPULATION ANALYSIS (subpop)
*==============================================================================

/*
   NEVER restrict your sample before estimation when using svy:.
   If you use "if condition" to restrict, Stata drops cases from the
   design — this can give wrong SEs.

   Instead, use the subpop() option, which keeps all cases in the design
   but estimates only for the specified subpopulation.

   Correct:   svy, subpop(if condition): command
   Wrong:     svy: command if condition
*/

* Create indicator for subpopulation of interest
gen black = (race_eth == 2) if !missing(race_eth)

* Analysis restricted to Black respondents — CORRECT way
svy, subpop(if black == 1): mean ideology5 imm_restrict econ_retro

* Vote choice among Black voters — CORRECT
svy, subpop(if black == 1 & voted == 1): proportion biden_voter

* Among college-educated only
svy, subpop(if college == 1): mean imm_restrict ideology5

* Among women only
svy, subpop(if sex == 2): mean imm_restrict ideology5 econ_retro


*==============================================================================
* SECTION 8: DESIGN EFFECT (DEFF)
*==============================================================================

/*
   The design effect (DEFF) measures how much the complex survey design
   inflates variance compared to a simple random sample of the same size.
   DEFF > 1 means you lose precision due to clustering/stratification.

   estat effects computes DEFF after any svy: estimation command.
*/

svy: mean age college voted ideology5
estat effects


*==============================================================================
* SECTION 9: WEIGHTED VS. UNWEIGHTED COMPARISON TABLE
*==============================================================================

/*
   A common robustness check is to show that substantive conclusions hold
   with and without weights. Build a side-by-side table.
*/

* Unweighted logit
quietly logit biden_voter education age i.sex ideology5 party_id7 ///
    white_nh college imm_restrict if voted == 1, vce(robust)
estimates store unweighted

* Weighted logit (note: cannot easily use svy: with esttab — use pweight as proxy)
quietly logit biden_voter education age i.sex ideology5 party_id7 ///
    white_nh college imm_restrict if voted == 1 ///
    [pweight=wt_post], vce(robust)
estimates store weighted_pweight

* Compare
esttab unweighted weighted_pweight, ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    pr2 N ///
    title("Biden Vote Choice: Unweighted vs. Weighted Logit") ///
    mtitles("Unweighted" "Weighted")


*==============================================================================
* SECTION 10: NOTES ON WHEN TO WEIGHT
*==============================================================================

/*
   ALWAYS weight when:
   - Making population-level descriptive claims ("X% of Americans voted")
   - The paper's goal is to describe the general population

   SOMETIMES weight when:
   - Running causal models — if your controls fully account for the design
     variables, weighting may change little. Still run weighted as robustness.

   Publish BOTH in supplementary materials and note if results diverge.
*/

di "Module 5 complete."
