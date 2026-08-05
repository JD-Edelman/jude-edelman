/*==============================================================================
   MODULE 4: LOGISTIC REGRESSION
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Predict binary outcomes (voted, biden_voter) using logit and probit.
   Covers: model estimation, odds ratios, marginal effects, GOF tests,
   predicted probabilities, and classification diagnostics.
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: WHY LOGIT, NOT OLS?
*==============================================================================

/*
   When Y is binary (0/1), OLS (the Linear Probability Model) can produce
   predicted probabilities outside [0,1] and has heteroskedastic errors by
   construction. Logistic regression models the log-odds of Y=1 and
   constrains predictions to (0,1).

   logit  estimates the logistic regression model
   probit uses a normal CDF instead of the logistic CDF
   Both give similar results; logit coefficients have a natural odds-ratio
   interpretation so it is more common in social science.
*/


*==============================================================================
* SECTION 2: SIMPLE LOGIT — DID RESPONDENT VOTE?
*==============================================================================

/*
   Outcome: voted (1=voted, 0=did not vote)
   Predictor: education (1-6 scale)

   logit depvar indepvar(s)

   Output:
     Coef.  = log-odds coefficient (not directly interpretable as a probability)
     Std. Err., z, P>|z|, CI = same logic as OLS but uses z not t
     LR chi2   = likelihood ratio test of overall model fit
     Prob>chi2 = p-value for LR test
     Pseudo R2  = McFadden's pseudo R-squared (not comparable to OLS R2;
                  .10-.20 is good fit in most applications)
*/

logit voted education


*==============================================================================
* SECTION 3: ODDS RATIOS
*==============================================================================

/*
   Exponentiating log-odds gives odds ratios (OR), which many readers find
   easier to interpret.

   OR interpretation:
     OR > 1 = predictor increases the odds of Y=1
     OR < 1 = predictor decreases the odds of Y=1
     OR = 1 = no relationship

   or option on logit requests ORs directly.
   eform option on esttab converts to ORs in a table.
*/

logit voted education age i.sex i.census_region ideology5, or

/*
   Example interpretation:
   "Each additional year of education multiplies the odds of voting by [OR],
   a statistically significant increase (p<.05)."
*/


*==============================================================================
* SECTION 4: FULL TURNOUT MODEL
*==============================================================================

logit voted education age i.sex i.census_region ideology5 party_id7 ///
    college white_nh imm_restrict econ_retro, ///
    vce(robust) or

estimates store logit_voted


*==============================================================================
* SECTION 5: PREDICTING BIDEN VOTE CHOICE
*==============================================================================

/*
   Restrict to those who voted and chose between Biden and Trump.
   biden_voter = 1 (Biden) or 0 (Trump), missing for everyone else.
*/

logit biden_voter education age i.sex i.census_region ideology5 party_id7 ///
    college white_nh imm_restrict econ_retro ///
    if voted == 1, ///
    vce(robust) or

estimates store logit_biden


*==============================================================================
* SECTION 6: AVERAGE MARGINAL EFFECTS (AME)
*==============================================================================

/*
   Logit coefficients are in log-odds units, which are hard to communicate.
   Marginal effects convert them to probability scale:

   dY/dX = the change in Pr(Y=1) for a one-unit increase in X, averaged
           across all observations (Average Marginal Effect, AME).

   margins, dydx(*) computes AMEs for all predictors.
   This is what most applied sociologists report instead of log-odds.
*/

quietly logit voted education age i.sex i.census_region ideology5 party_id7, ///
    vce(robust)

margins, dydx(*) post

/*
   The dy/dx for education tells you: on average across respondents,
   a one-unit increase in education is associated with a [X] percentage
   point increase in the probability of voting.
*/


*==============================================================================
* SECTION 7: PREDICTED PROBABILITIES AT SPECIFIC VALUES
*==============================================================================

/*
   margins with at() computes the predicted probability of Y=1 at specified
   covariate values. This is useful for illustrating nonlinearity.

   atmeans = evaluate at the mean of all other covariates
*/

quietly logit voted education age i.sex ideology5, vce(robust)

* Predicted probability of voting at each education level (other vars at mean)
margins, at(education=(1 2 3 4 5 6)) atmeans vsquish

* Graph it
marginsplot, ///
    title("Predicted Probability of Voting by Education") ///
    xtitle("Education Level (1=No HS ... 6=Postgrad)") ///
    ytitle("Pr(Voted)") ///
    recast(line) recastci(rarea) ///
    ciopt(color(navy%20))


*==============================================================================
* SECTION 8: PREDICTED PROBABILITY BY SEX AND EDUCATION (INTERACTION)
*==============================================================================

quietly logit voted c.education##i.sex age ideology5, vce(robust)

margins sex, at(education=(1 2 3 4 5 6)) vsquish

marginsplot, ///
    title("Predicted Pr(Voted) by Education and Sex") ///
    xtitle("Education Level") ytitle("Pr(Voted)") ///
    legend(label(1 "Male") label(2 "Female"))


*==============================================================================
* SECTION 9: GOODNESS OF FIT
*==============================================================================

/*
   Several GOF tests exist for logit. None is definitively "the" standard;
   report whichever your field expects.
*/

quietly logit voted education age i.sex ideology5 party_id7, vce(robust)

* --- Hosmer-Lemeshow test ---
* Compares observed to expected probabilities in decile groups.
* Non-significant p-value = adequate fit.
* estat gof (requires model run without vce(robust))

quietly logit voted education age i.sex ideology5 party_id7
estat gof, group(10) table

* --- Pseudo R-squared options ---
fitstat
/*
   fitstat (install: ssc install fitstat) reports McFadden's, Cox-Snell,
   Nagelkerke, and other pseudo R2 measures together.
*/

* --- Classification table ---
/*
   estat classification shows how well the model predicts Y=1 vs Y=0.
   The default cut-point is 0.5 (predict Y=1 if Pr>0.5).

   Reports:
     Sensitivity = % of actual Y=1 correctly predicted as 1
     Specificity = % of actual Y=0 correctly predicted as 0
     Correctly classified = overall accuracy rate
*/

estat classification


*==============================================================================
* SECTION 10: ROC CURVE AND AUC
*==============================================================================

/*
   The ROC (Receiver Operating Characteristic) curve plots sensitivity vs.
   (1-specificity) across all possible cut-points.
   AUC (Area Under the Curve) = probability that the model ranks a random
   positive case above a random negative case.
     AUC = 0.5 = no better than chance
     AUC = 1.0 = perfect discrimination
     AUC > 0.7 = acceptable; > 0.8 = excellent

   lroc plots the ROC curve and reports AUC.
*/

lroc, title("ROC Curve: Logit Model of 2020 Voter Turnout")


*==============================================================================
* SECTION 11: PROBIT AS ALTERNATIVE
*==============================================================================

/*
   probit uses the standard normal CDF instead of the logistic CDF.
   Coefficients are in probit units (not directly comparable to logit),
   but marginal effects at the mean should be similar.

   Rule of thumb: logit coef ≈ probit coef × 1.6
*/

probit voted education age i.sex ideology5 party_id7, vce(robust)

* Marginal effects from probit
margins, dydx(*)


*==============================================================================
* SECTION 12: PRESENTING RESULTS WITH ESTTAB
*==============================================================================

/*
   Display logit models as ORs in a formatted table.
   eform converts log-odds to odds ratios automatically.
*/

quietly logit voted education age i.sex ideology5, vce(robust)
estimates store m_simple

quietly logit voted education age i.sex ideology5 party_id7 college, vce(robust)
estimates store m_controls

quietly logit voted education age i.sex ideology5 party_id7 college ///
    white_nh imm_restrict, vce(robust)
estimates store m_full

esttab m_simple m_controls m_full, ///
    eform ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    pr2 aic bic N ///
    title("Logistic Regression: Odds Ratios for Voter Turnout (2020)") ///
    mtitles("Model 1" "Model 2" "Model 3")

di "Module 4 complete."
