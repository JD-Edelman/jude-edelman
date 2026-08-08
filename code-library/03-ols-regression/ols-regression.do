/*==============================================================================
   MODULE 3: OLS LINEAR REGRESSION
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Demonstrate OLS regression in Stata from a simple bivariate model
   up through multiple regression with controls, interaction terms,
   standardized coefficients, and post-estimation diagnostics.
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: SIMPLE (BIVARIATE) OLS
*==============================================================================

/*
   regress depvar indepvar(s)
   Stata calls the dependent variable first, then predictors.

   Output:
     Coef.     = unstandardized regression coefficient (slope)
     Std. Err. = standard error of the coefficient
     t         = t-statistic (Coef / Std. Err.)
     P>|t|     = two-tailed p-value
     [95% CI]  = 95% confidence interval around the coefficient
     R-squared = proportion of variance in Y explained by the model
*/

* Does education predict immigration restrictionism?
regress imm_restrict education

/*
   Interpretation template:
   Each additional unit of education is associated with a [coef] unit
   change in immigration restrictionism, holding all else constant.
   The coefficient is [significant/not significant] at p<.05 (p=[p-value]).
*/


*==============================================================================
* SECTION 2: MULTIPLE REGRESSION (ADDITIVE CONTROLS)
*==============================================================================

/*
   Add predictors separated by spaces after the dependent variable.
   Stata automatically listwise-deletes observations with missing on any variable
   in the model — check the N at the bottom of the output.
*/

* Immigration restrictionism as a function of education, age, sex, and region
regress imm_restrict education age i.sex i.census_region

/*
   The i. prefix before a categorical variable creates dummy variables
   automatically, with the lowest category as the reference group.
   Here sex: 1=Male is the reference. The coefficient on "2.sex" is the
   difference between females and males, net of other predictors.
*/


*==============================================================================
* SECTION 3: FULL MODEL WITH IDEOLOGY AND PARTY ID
*==============================================================================

/*
   Political science models often include ideology and party as controls.
   This is a realistic "Table 2"-style model.
*/

regress imm_restrict education age i.sex i.census_region ///
    ideology5 party_id7 i.college

* Store this model for later comparison
estimates store model_full

* Note the change in R-squared as you add ideology/party — these tend to
* explain a large share of variance in political attitudes.


*==============================================================================
* SECTION 4: COMPARING NESTED MODELS
*==============================================================================

/*
   Run a restricted model (no ideology/party), then test whether adding
   those predictors significantly improves fit using an F-test.

   lrtest compares nested models. nestreg does it in one step.
   Here we use the manual approach: run both models, compare R-squared,
   then use test or lrtest.
*/

* Restricted model (demographics only)
regress imm_restrict education age i.sex i.census_region
estimates store model_demog

* Full model again
regress imm_restrict education age i.sex i.census_region ideology5 party_id7
estimates store model_full2

* F-test: does adding ideology5 and party_id7 improve the model?
* NOTE: lrtest requires ML estimation — use the F-test approach for OLS.
* Re-run the full model and test the restricted coefficient set.
quietly regress imm_restrict education age i.sex i.census_region ideology5 party_id7
test ideology5 party_id7   /* H0: both coefficients == 0 simultaneously */


*==============================================================================
* SECTION 5: INTERACTION TERMS
*==============================================================================

/*
   Interactions test whether the effect of X on Y differs by a third variable Z.
   Syntax: X##Z creates the main effects of X, Z, AND the X×Z interaction.
   Always include both main effects when you include an interaction.

   c. prefix = treat as continuous
   i. prefix = treat as categorical (creates dummies)
*/

* Does the effect of education on restrictionism differ by party ID?
* (Hypothesis: education matters more for independents than strong partisans)

regress imm_restrict c.education##i.party_id3 age i.sex

* Interpret the interaction by computing marginal effects at specific values
* margins shows the predicted value of Y at specified covariate levels

margins party_id3, at(education=(1 2 3 4 5 6)) vsquish

/*
   marginsplot graphs the predicted values from margins automatically.
   See Module 6 (visualization) for formatting.
*/
marginsplot, ///
    title("Predicted Immigration Restrictionism by Education & Party") ///
    xtitle("Education Level") ///
    ytitle("Predicted Restrictionism (0-5)") ///
    legend(label(1 "Democrat") label(2 "Republican") label(3 "Independent"))


*==============================================================================
* SECTION 6: STANDARDIZED COEFFICIENTS (BETA WEIGHTS)
*==============================================================================

/*
   Standardized coefficients (beta weights) express each predictor's effect
   in standard deviation units, allowing comparison of relative importance
   across predictors measured on different scales.

   beta option after regress reports them directly.
*/

regress imm_restrict education age ideology5 party_id7 i.sex, beta

/*
   Read the "Beta" column: the predictor with the largest absolute beta
   has the strongest effect on Y relative to its variance.
   Cannot compute beta for dummies — Stata leaves those blank.
*/


*==============================================================================
* SECTION 7: ROBUST STANDARD ERRORS
*==============================================================================

/*
   OLS assumes homoskedasticity (equal error variance across fitted values).
   If violated, standard errors are wrong. Robust (Huber-White) SEs are
   asymptotically valid under heteroskedasticity.

   vce(robust) requests robust SEs. This is standard practice in sociology
   and political science with large cross-sectional surveys.
*/

regress imm_restrict education age ideology5 i.sex i.census_region, ///
    vce(robust)

/*
   Coefficients are identical to OLS — only the SEs (and thus t-stats and
   p-values) change. If results change a lot, heteroskedasticity is present.
*/


*==============================================================================
* SECTION 8: CLUSTERED STANDARD ERRORS
*==============================================================================

/*
   If observations are grouped (e.g., respondents within states), errors
   within clusters may be correlated. Clustered SEs correct for this.

   vce(cluster groupvar) clusters on the specified variable.
   State is a common clustering variable in survey data.
*/

regress imm_restrict education age ideology5 i.sex, ///
    vce(cluster state_fips)


*==============================================================================
* SECTION 9: POST-ESTIMATION DIAGNOSTICS
*==============================================================================

/*
   After regress, Stata stores results. Post-estimation commands use these.
   predict generates new variables from the fitted model.
*/

* Re-run the main model
regress imm_restrict education age ideology5 party_id7 i.sex i.census_region

* --- Predicted values ---
predict yhat, xb           /* fitted (predicted) values                  */
predict resid, residuals   /* raw residuals = observed - predicted        */
predict resid_std, rstandard /* standardized residuals                    */
predict leverage, leverage   /* leverage (hat values)                     */
predict cooksd, cooksd       /* Cook's D (influence measure)              */

* --- Check for outliers / influential cases ---
* Flag high leverage: leverage > 2*(k+1)/N where k = number of predictors
scalar k = e(df_m)
scalar n = e(N)
gen hi_leverage = (leverage > 2*(k+1)/n) if !missing(leverage)
count if hi_leverage == 1

* Flag Cook's D > 4/N (common threshold)
gen hi_cook = (cooksd > 4/n) if !missing(cooksd)
count if hi_cook == 1

* --- Residual vs. fitted plot (check linearity and homoskedasticity) ---
scatter resid yhat, ///
    yline(0) ///
    mcolor(navy%40) ///
    title("Residuals vs. Fitted Values") ///
    xtitle("Fitted Values") ytitle("Residuals")

* --- Normal Q-Q plot of standardized residuals ---
qnorm resid_std, ///
    title("Q-Q Plot of Standardized Residuals") ///
    mcolor(navy%40)

* --- Breusch-Pagan / Cook-Weisberg test for heteroskedasticity ---
hettest
/*
   Significant p-value = evidence of heteroskedasticity → use robust SEs.
*/

* --- Variance Inflation Factors (VIF) — multicollinearity check ---
vif
/*
   VIF > 10 (or even > 5) signals problematic multicollinearity.
   Highly correlated predictors inflate SEs and destabilize coefficients.
*/

* Clean up temporary variables
drop yhat resid resid_std leverage cooksd hi_leverage hi_cook


*==============================================================================
* SECTION 10: DISPLAYING RESULTS WITH ESTTAB
*==============================================================================

/*
   esttab (from the estout package) formats regression tables for publication.
   Install: ssc install estout

   Here we build a three-column table: bivariate, demographics, full model.
*/

* ssc install estout, replace

* Bivariate
quietly regress imm_restrict education
estimates store m1

* Demographics
quietly regress imm_restrict education age i.sex i.census_region
estimates store m2

* Full
quietly regress imm_restrict education age i.sex i.census_region ideology5 party_id7
estimates store m3

* Display in console
esttab m1 m2 m3, ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(r2 ar2 aic bic N, fmt(%8.3f %8.3f %8.1f %8.1f %8.0f)) ///
    title("OLS Regression: Predictors of Immigration Restrictionism") ///
    mtitles("Bivariate" "Demographics" "Full Model")

* Export to Word-compatible RTF
* esttab m1 m2 m3 using "table_ols.rtf", ///
*     b(%8.3f) se(%8.3f) star(* 0.05 ** 0.01 *** 0.001) r2 ar2 N replace

di "Module 3 complete."
