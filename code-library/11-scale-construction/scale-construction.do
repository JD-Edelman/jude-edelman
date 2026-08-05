/*==============================================================================
   MODULE 11: SCALE CONSTRUCTION & RELIABILITY
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Build and validate multi-item scales from attitude batteries.
   Covers: Cronbach's alpha, exploratory factor analysis (EFA),
   confirmatory factor analysis (CFA), and principal components (PCA).

   CES has several attitude batteries (immigration, guns, climate, abortion)
   that are natural candidates for scale construction.
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: PREP — RECODE ITEMS TO CONSISTENT DIRECTION
*==============================================================================

/*
   Before computing a scale, all items must point in the same direction.
   In CES policy items: 1=Support, 2=Oppose.
   We recode so that higher numbers = more of the construct we're measuring.

   For immigration restrictionism:
     Restrictionist positions are:
       - Oppose DACA (pol_daca == 2)
       - Support more border patrol (pol_border_patrol == 1)
       - Support wall (pol_wall == 1)
       - Oppose path to legal status (pol_legal_status == 2)
       - Support deportation (pol_deportation == 1)

   We create 0/1 items (1 = restrictionist) so the scale runs 0-5.
*/

* Immigration restrictionism items (already created in Module 1 as imm_restrict)
gen imm_item1 = (pol_daca == 2)        if !missing(pol_daca)
gen imm_item2 = (pol_border_patrol==1) if !missing(pol_border_patrol)
gen imm_item3 = (pol_wall == 1)        if !missing(pol_wall)
gen imm_item4 = (pol_legal_status==2)  if !missing(pol_legal_status)
gen imm_item5 = (pol_deportation==1)   if !missing(pol_deportation)

* Gun control items (restrictionist = supports more gun control)
gen gun_item1 = (pol_assault_ban == 1)      if !missing(pol_assault_ban)
gen gun_item2 = (pol_concealed_carry == 2)  if !missing(pol_concealed_carry)
gen gun_item3 = (pol_background_check == 1) if !missing(pol_background_check)

* Climate items (pro-environment = supports policy)
gen climate_item1 = (pol_climate_epa == 1)         if !missing(pol_climate_epa)
gen climate_item2 = (pol_climate_paris == 1)        if !missing(pol_climate_paris)
gen climate_item3 = (pol_climate_renewables == 1)   if !missing(pol_climate_renewables)
gen climate_item4 = (pol_climate_carbon_tax == 1)   if !missing(pol_climate_carbon_tax)


*==============================================================================
* SECTION 2: CRONBACH'S ALPHA — INTERNAL CONSISTENCY
*==============================================================================

/*
   Cronbach's alpha (α) measures how consistently a set of items measures
   the same underlying construct. Items should correlate positively with
   each other if they measure the same thing.

   Benchmarks (George & Mallery):
     α ≥ .90 = Excellent
     α ≥ .80 = Good
     α ≥ .70 = Acceptable
     α ≥ .60 = Questionable
     α < .60 = Problematic

   alpha varlist, item
     item    = show item-rest correlations and α-if-deleted for each item
     std     = compute alpha on standardized items (use when items are on
                different scales)
     casewise = use only observations complete on all items
*/

* Immigration scale alpha
alpha imm_item1 imm_item2 imm_item3 imm_item4 imm_item5, ///
    item std casewise

/*
   Read the output:
   - "Test scale = mean(unstandardized items)" shows the raw mean
   - "Average interitem correlation" should be .15-.50 for most social
     science scales (too high = redundancy; too low = no common factor)
   - "Alpha if item deleted" — if this is higher than the current α for
     any item, consider dropping that item
*/

* Gun scale alpha
alpha gun_item1 gun_item2 gun_item3, ///
    item std casewise

* Climate scale alpha
alpha climate_item1 climate_item2 climate_item3 climate_item4, ///
    item std casewise


*==============================================================================
* SECTION 3: SIMPLE ADDITIVE SCALE SCORES
*==============================================================================

/*
   For scales with good alpha (>.7), a simple sum or mean is usually
   sufficient. Use rowtotal to handle partial missing (sum of observed items).

   Decision: sum vs. mean?
   - Sum: ranges with N_items (different respondents may have different N)
   - Mean: standardized to [0,1] range; handles partial missing better
   Use mean if respondents have different numbers of valid items (avoid this
   by requiring a minimum number of valid items).
*/

* Immigration scale — mean of items (requires at least 4 of 5 valid)
egen imm_scale_mean = rowmean(imm_item1 imm_item2 imm_item3 imm_item4 imm_item5)
egen imm_n_valid    = rownonmiss(imm_item1 imm_item2 imm_item3 imm_item4 imm_item5)

replace imm_scale_mean = . if imm_n_valid < 4
label variable imm_scale_mean "Immigration restrictionism scale (mean, 0-1)"

* Gun control scale mean
egen gun_scale_mean = rowmean(gun_item1 gun_item2 gun_item3)
label variable gun_scale_mean "Gun control support scale (mean, 0-1)"

* Climate policy scale mean
egen climate_scale_mean = rowmean(climate_item1 climate_item2 climate_item3 climate_item4)
label variable climate_scale_mean "Climate policy support scale (mean, 0-1)"

* Quick check
summarize imm_scale_mean gun_scale_mean climate_scale_mean


*==============================================================================
* SECTION 4: EXPLORATORY FACTOR ANALYSIS (EFA)
*==============================================================================

/*
   EFA identifies underlying latent factors from a set of items when you
   don't have a strong theory about how many factors exist.

   factor varlist, factors(k) method(pf|pc|ml|ipf)
     factors(k) = number of factors to extract
     method:
       pf  = principal factor (common variance only, default)
       pc  = principal components (includes unique variance)
       ml  = maximum likelihood (for CFA-style inference)

   rotate, options
     varimax   = orthogonal rotation (factors uncorrelated)
     oblique   = allows factors to correlate (more realistic for attitudes)
     oblimin   = common oblique rotation
*/

* EFA of all immigration items — do they load on one factor?
factor imm_item1 imm_item2 imm_item3 imm_item4 imm_item5, ///
    factors(2) method(pf)

/*
   Eigenvalue > 1 (Kaiser criterion) = keep factor
   Scree plot helps visually identify the "elbow"
*/

screeplot, ///
    title("Scree Plot: Immigration Attitude Items") ///
    yline(1, lcolor(red) lpattern(dash))

* Rotate for interpretability
rotate, varimax blanks(.3)

/*
   After rotation, each item should load highly on one factor only.
   Loadings > .4 are typically considered meaningful.
   Blanks(.3) suppresses loadings below .3 to ease reading.
*/

* EFA across all attitude domains — how many attitude dimensions?
factor imm_item1-imm_item5 gun_item1-gun_item3 ///
    climate_item1-climate_item4, ///
    factors(3) method(pf)

rotate, varimax blanks(.3)

/*
   Expected: 3 factors corresponding to immigration, guns, and climate.
   High cross-loadings suggest items don't discriminate well between domains.
*/


*==============================================================================
* SECTION 5: FACTOR SCORES
*==============================================================================

/*
   Factor scores are respondent-level estimates of the underlying latent
   factor, saved as new variables. They account for differential item
   loadings (items that load more strongly get more weight).

   predict after factor saves factor scores.
   regression method is most common.
*/

factor imm_item1 imm_item2 imm_item3 imm_item4 imm_item5, ///
    factors(1) method(pf)

predict imm_factor_score, ///
    regression  /* regression-method factor score */

label variable imm_factor_score "Immigration restrictionism factor score (EFA)"

* Compare factor score to simple mean — they should correlate highly
corr imm_factor_score imm_scale_mean

/*
   If r > .95, the simple mean is a good approximation of the factor score.
   Factor scores are preferred when items have very different loadings.
*/


*==============================================================================
* SECTION 6: PRINCIPAL COMPONENTS ANALYSIS (PCA)
*==============================================================================

/*
   PCA is related to EFA but distinct: it maximizes explained variance
   in the observed items (including unique variance), not just common variance.

   PCA is appropriate when:
   - You want a data reduction summary, not a latent variable model
   - Items are highly reliable (measurement error is low)

   pca varlist, components(k)
   predict after pca saves component scores
*/

pca imm_item1 imm_item2 imm_item3 imm_item4 imm_item5, ///
    components(2)

screeplot, yline(1, lcolor(red))

* First component score (linear combination maximizing variance)
* predict with score after pca generates one variable per retained component.
* With components(2), this creates pc1_imm AND pc2_imm. Drop pc2_imm after.
predict pc1_imm pc2_imm, score
label variable pc1_imm "First principal component — immigration"
drop pc2_imm

* Compare to factor score
corr imm_factor_score pc1_imm


*==============================================================================
* SECTION 7: CONFIRMATORY FACTOR ANALYSIS (CFA) WITH SEM
*==============================================================================

/*
   CFA tests a specific factor structure (from theory or prior EFA).
   In Stata, CFA is run using the sem command.

   Basic single-factor CFA:
     sem (FactorName -> item1 item2 item3 ...), latent(FactorName)

   Key fit indices:
     CFI (Comparative Fit Index): > .95 = excellent, > .90 = acceptable
     RMSEA: < .05 = close fit, < .08 = acceptable, > .10 = poor
     SRMR: < .08 = acceptable
*/

* Single-factor CFA for immigration restrictionism
sem (ImmRestrict -> imm_item1 imm_item2 imm_item3 imm_item4 imm_item5), ///
    latent(ImmRestrict) ///
    method(ml) ///
    var(ImmRestrict@1)   /* fix variance to 1 for identification */

* Fit statistics
estat gof, stats(all)

/*
   With binary items, robust ML (method(mlmv)) handles non-normality better.
   For ordinal items, use method(wls) or wsls (diagonally weighted least squares).
*/

* Two-factor CFA: immigration and gun control
sem (ImmRestrict -> imm_item1 imm_item2 imm_item3 imm_item4 imm_item5) ///
    (GunControl  -> gun_item1 gun_item2 gun_item3), ///
    latent(ImmRestrict GunControl) ///
    method(ml) ///
    cov(ImmRestrict*GunControl)   /* allow factors to correlate */

estat gof, stats(all)

* Modification indices (suggest freeing parameters to improve fit)
estat mindices


*==============================================================================
* SECTION 8: SAVE SCALES AND FACTOR SCORES
*==============================================================================

* Drop item helper variables, keep scales and factor scores
drop imm_item? gun_item? climate_item?
drop imm_n_valid

* Final dataset with scales
save "CES2020_with_scales.dta", replace
di "Module 11 complete. Dataset with scales saved."
