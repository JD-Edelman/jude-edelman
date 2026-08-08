/*==============================================================================
   MODULE 8: EXPORTING TABLES TO WORD, LATEX, AND EXCEL
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Automate production of publication-ready tables from Stata output.
   Covers esttab (regression tables), putdocx (Word), putexcel (Excel),
   and tabout/outreg2 for descriptive tables.

   Required packages (install once):
     ssc install estout       /* esttab, estpost */
     ssc install outreg2      /* alternative regression exporter */
     ssc install tabout       /* descriptive/frequency tables */
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear


*==============================================================================
* SECTION 1: REGRESSION TABLES WITH ESTTAB
*==============================================================================

/*
   esttab is the gold standard for regression tables in Stata.
   Workflow:
     1. Run models and store with: estimates store name
     2. Call esttab with the stored model names
     3. Specify output format (rtf for Word, tex for LaTeX, csv for Excel)
*/

* --- Run three nested models ---
quietly regress imm_restrict education, vce(robust)
estimates store m1

quietly regress imm_restrict education age i.sex i.census_region, vce(robust)
estimates store m2

quietly regress imm_restrict education age i.sex i.census_region ///
    ideology5 party_id7, vce(robust)
estimates store m3

* --- Display in console first (always check before exporting) ---
esttab m1 m2 m3, ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(r2 ar2 aic bic N, fmt(%8.3f %8.3f %8.1f %8.1f %8.0f) labels("R2" "Adj. R2" "AIC" "BIC" "N")) ///
    scalars("F F-stat") ///
    title("OLS Regression: Immigration Restrictionism") ///
    mtitles("Bivariate" "Demographics" "Full") ///
    label                     /* use Stata variable labels instead of names */

* --- Export to Word-compatible RTF ---
esttab m1 m2 m3 using "table_ols_restrict.rtf", ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(r2 ar2 N, fmt(%8.3f %8.3f %8.0f)) ///
    title("OLS Regression: Predictors of Immigration Restrictionism") ///
    mtitles("Bivariate" "Demographics" "Full") ///
    label replace

* --- Export to LaTeX ---
esttab m1 m2 m3 using "table_ols_restrict.tex", ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    booktabs alignment(D{.}{.}{-1}) ///
    stats(r2 ar2 N, fmt(%8.3f %8.3f %8.0f)) ///
    title("OLS Regression: Predictors of Immigration Restrictionism") ///
    mtitles("Bivariate" "Demographics" "Full") ///
    label replace

* --- Export to CSV (for Excel) ---
esttab m1 m2 m3 using "table_ols_restrict.csv", ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(r2 ar2 N, fmt(%8.3f %8.3f %8.0f)) ///
    csv replace


*==============================================================================
* SECTION 2: LOGIT TABLE WITH ODDS RATIOS
*==============================================================================

quietly logit voted education age i.sex ideology5, vce(robust)
estimates store l1

quietly logit voted education age i.sex ideology5 party_id7 college, vce(robust)
estimates store l2

quietly logit voted education age i.sex ideology5 party_id7 college ///
    white_nh imm_restrict, vce(robust)
estimates store l3

* Display ORs with eform
esttab l1 l2 l3, ///
    eform ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(pr2 aic N, fmt(%8.3f %8.1f %8.0f)) ///
    title("Logistic Regression: Odds Ratios for Voter Turnout") ///
    mtitles("Model 1" "Model 2" "Model 3") ///
    label

esttab l1 l2 l3 using "table_logit_turnout.rtf", ///
    eform ///
    b(%8.3f) se(%8.3f) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(pr2 aic N, fmt(%8.3f %8.1f %8.0f)) ///
    title("Logistic Regression: Odds Ratios for Voter Turnout") ///
    mtitles("Model 1" "Model 2" "Model 3") ///
    label replace


*==============================================================================
* SECTION 3: DESCRIPTIVE STATISTICS TABLE WITH ESTPOST
*==============================================================================

/*
   estpost summarize stores descriptive stats in a format esttab can export.
   This creates a "Table 1" style summary statistics table.
*/

estpost summarize age education ideology5 imm_restrict econ_retro ///
    self_rated_health college voted biden_voter white_nh

esttab using "table1_descriptives.rtf", ///
    cells("mean(fmt(%6.2f)) sd(fmt(%6.2f)) min max count(fmt(%8.0f))") ///
    noobs ///
    title("Table 1. Descriptive Statistics — CES 2020") ///
    collabels("Mean" "SD" "Min" "Max" "N") ///
    label replace


*==============================================================================
* SECTION 4: DESCRIPTIVE TABLE BY GROUP
*==============================================================================

/*
   Compare means across groups (e.g., Biden vs. Trump voters).
   One approach: run estpost mean twice with an if condition, then combine.
*/

estpost ttest age education ideology5 imm_restrict econ_retro ///
    if !missing(biden_voter), ///
    by(biden_voter)

esttab using "table_ttest_votechoice.rtf", ///
    cells("mu_1(fmt(%6.2f)) mu_2(fmt(%6.2f)) b(star fmt(%6.2f)) se(fmt(%6.2f))") ///
    collabels("Trump Voters" "Biden Voters" "Diff." "SE") ///
    noobs ///
    title("Table 2. Mean Differences by Presidential Vote Choice") ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    label replace


*==============================================================================
* SECTION 5: CROSS-TABULATION TABLE WITH TABOUT
*==============================================================================

/*
   tabout creates formatted frequency and cross-tabulation tables.
   Install: ssc install tabout

   tabout var1 var2 using "file", c(freq col) f(0c 1p) style(docx)
     c()     = cells to show: freq=frequency, col=column%, row=row%
     f()     = format: 0c=integer with commas, 1p=1 decimal place percent
     style() = output format: docx, tex, csv, htm
*/

* ssc install tabout, replace

* tabout is user-installed and may not be available; use tabulate instead
tabulate party_id3 biden_voter, row

tabulate census_region voted, row


*==============================================================================
* SECTION 6: WRITING DIRECTLY TO WORD WITH PUTDOCX
*==============================================================================

/*
   putdocx is a built-in Stata command (v15+) that creates Word documents
   without any packages. More control than RTF exports; useful for
   writing entire manuscripts programmatically.
*/

putdocx begin

* Title and intro
putdocx paragraph, style(Title)
putdocx text ("CES 2020 Analysis: Selected Results")

putdocx paragraph, style(Heading1)
putdocx text ("Sample Characteristics")

putdocx paragraph
quietly summarize age
putdocx text ("The analytic sample includes `=_N' respondents. ")
putdocx text ("Mean age was `=string(round(r(mean), .1), "%4.1f")' years.")

* Add a table of means from scratch
putdocx table t1 = (5, 3), ///
    border(all, single) ///
    memtable

putdocx table t1(1,1) = ("Variable"),   bold
putdocx table t1(1,2) = ("Mean"),       bold
putdocx table t1(1,3) = ("SD"),         bold

local row = 1   /* row 1 = header; loop starts at row 2 */
foreach v in age education ideology5 imm_restrict {
    quietly summarize `v'
    local row = `row' + 1
    putdocx table t1(`row', 1) = ("`v'")
    putdocx table t1(`row', 2) = ("`=round(r(mean),.001)'")
    putdocx table t1(`row', 3) = ("`=round(r(sd),.001)'")
}

putdocx save "ces_report.docx", replace


*==============================================================================
* SECTION 7: WRITING TO EXCEL WITH PUTEXCEL
*==============================================================================

/*
   putexcel exports Stata matrix output to an Excel workbook.
   Combine it with matrix or r() stored results to populate cells.
*/

* Run a model and store the coefficient matrix
quietly regress imm_restrict education age ideology5 party_id7 i.sex, vce(robust)

* Extract coefficient matrix
matrix b  = e(b)
matrix V  = e(V)
matrix se = J(1, colsof(b), 0)
forvalues i = 1/`=colsof(b)' {
    matrix se[1,`i'] = sqrt(V[`i',`i'])
}

* Write to Excel
putexcel set "regression_output.xlsx", replace

putexcel A1 = "Variable"
putexcel B1 = "Coefficient"
putexcel C1 = "Std. Error"
putexcel D1 = "p-value"

* Write coefficients from the stored matrix directly — avoids lincom errors
* with factor variable names (2.sex) and the _cons term.
local names : colnames b
local row = 2
local ncols = colsof(b)
forvalues j = 1/`ncols' {
    local name : word `j' of `names'
    local coef  = b[1, `j']
    local stderr = sqrt(V[`j', `j'])
    local tstat  = `coef' / `stderr'
    local pval   = 2 * (1 - normal(abs(`tstat')))
    putexcel A`row' = "`name'"
    putexcel B`row' = `coef'
    putexcel C`row' = `stderr'
    putexcel D`row' = `pval'
    local row = `row' + 1
}

di "Excel file written: regression_output.xlsx"


*==============================================================================
* SECTION 8: OUTREG2 ALTERNATIVE
*==============================================================================

/*
   outreg2 is another popular regression table tool, especially common in
   economics. Syntax is slightly different from esttab.
   Install: ssc install outreg2

   Key options:
     word    = export to Word (.doc)
     excel   = export to Excel
     tex     = export to LaTeX
     addstat = manually add statistics to the bottom
*/

quietly regress imm_restrict education age ideology5 party_id7 i.sex, vce(robust)
estimates store m_simple

* Append next model to same file
quietly regress imm_restrict education age ideology5 party_id7 i.sex ///
    white_nh college econ_retro, vce(robust)
estimates store m_full

* Export both models to RTF (esttab replaces outreg2 here)
esttab m_simple m_full using output.rtf, replace rtf ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(r2 N, fmt(%8.3f %8.0f)) ///
    title("OLS Regression") ///
    mtitles("Bivariate" "Full")


*==============================================================================
* SECTION 9: LABELING VARIABLES FOR CLEANER TABLE OUTPUT
*==============================================================================

/*
   esttab uses variable labels in the table when you specify the label option.
   If your variables have clear labels, the exported table is immediately
   readable without manual editing in Word.

   Always label new variables you generate.
*/

label variable age             "Age (years)"
label variable education       "Education (1-6)"
label variable ideology5       "Ideology (1=Very Lib, 5=Very Con)"
label variable imm_restrict    "Immigration Restrictionism (0-5)"
label variable econ_retro      "Retrospective Econ (1=Much Better)"
label variable college         "College Degree (1=Yes)"
label variable voted           "Voted 2020 (1=Yes)"
label variable biden_voter     "Voted Biden (1=Yes, 0=Trump)"
label variable white_nh        "White Non-Hispanic (1=Yes)"
label variable dem             "Democrat (1=Yes)"
label variable rep             "Republican (1=Yes)"
label variable party_id7       "Party ID (1=Strong Dem, 7=Strong Rep)"
label variable party_id3       "Party ID (1=Dem, 2=Rep, 3=Ind)"
label variable approve_trump   "Approve Trump (1=Strongly, 4=Strongly not)"
label variable self_rated_health "Self-Rated Health (1=Excellent, 5=Poor)"
label variable hh_income_change "HH Income Change (1=Much more, 5=Much less)"

* Now the table output will show these labels automatically with the label option

di "Module 8 complete. Check your directory for RTF, DOCX, XLSX, and TEX files."
