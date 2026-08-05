// =============================================================================
// MODULE 14: MULTILEVEL MODELS (MIXED-EFFECTS REGRESSION)
// CES 2020 Social Science Code Library
// =============================================================================
// Topics covered:
//   - Random intercept models (respondents nested in states)
//   - Random slope models (slopes allowed to vary by group)
//   - Intraclass correlation coefficient (ICC)
//   - Cross-level interactions (level-2 moderators of level-1 slopes)
//   - Comparison to fixed-effects (FE) models via Hausman-style test
//
// CES 2020 data note:
//   Stata cannot read .parquet files natively. Load the CES 2020 data in R or
//   Python first, then export as .dta (Stata 14 or 15 format) before running
//   this do file. See multilevel-models.R or multilevel-models.py for export
//   code.
//
// svyset note:
//   CES 2020 includes survey weights (commonweight). Mixed-effects models
//   (xtmixed / mixed) do not natively incorporate complex survey designs.
//   For descriptives and marginal tables use svyset + svy prefix. For the
//   multilevel models themselves, include commonweight as a pweight argument
//   and interpret variance components with appropriate caution.
// =============================================================================

// --- SECTION 1: DATA PREP AND xtset ---
// Import .dta converted from CES 2020 parquet
// Recode and label key variables
// xtset panelvar timevar (here: xtset inputstate, but MLM uses mixed, not xtreg)
// Explore nesting structure: tabulate inputstate

// --- SECTION 2: NULL MODEL AND ICC ---
// mixed outcome_var || inputstate:
// estat icc
// Interpret ICC: what proportion of variance is between states?

// --- SECTION 3: RANDOM INTERCEPT MODEL ---
// mixed outcome_var level1_predictors || inputstate:
// estimates store ri_model
// predict xb_ri, xb
// predict u0, reffects

// --- SECTION 4: RANDOM SLOPE MODEL ---
// mixed outcome_var level1_predictors || inputstate: level1_predictor, covariance(unstructured)
// estimates store rs_model
// lrtest ri_model rs_model   // compare fit

// --- SECTION 5: CROSS-LEVEL INTERACTION ---
// Generate product term: level2_var * level1_predictor
// mixed outcome_var level1_predictors##c.level2_var || inputstate: level1_predictor, covariance(unstructured)
// margins, dydx(level1_predictor) at(level2_var=(min mean max))

// --- SECTION 6: HAUSMAN-STYLE COMPARISON TO FE ---
// xtreg outcome_var level1_predictors, fe
// estimates store fe_model
// xtreg outcome_var level1_predictors, re
// estimates store re_model
// hausman fe_model re_model
// Discuss: when does FE win (causal id), when does MLM win (level-2 predictors,
//          small groups, interest in between-group variance)?
