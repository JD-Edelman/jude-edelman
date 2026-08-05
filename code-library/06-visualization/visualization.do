/*==============================================================================
   MODULE 6: DATA VISUALIZATION
   Dataset: CES 2020 Common Content (cleaned from Module 1)

   Purpose: Build a library of publication-quality graphs in Stata.
   Covers histograms, bar charts, box plots, scatter plots, coefficient
   plots, predicted probability plots, and heat maps.

   Stata's graph syntax follows a consistent grammar:
     twoway plottype (vars), [global options]
   Most aesthetics are controlled through options in parentheses.
==============================================================================*/

clear all
set more off

use "CES2020_clean.dta", clear

* Create an output folder for graphs (adjust path as needed)
* capture mkdir "graphs"


*==============================================================================
* SECTION 1: HISTOGRAM — CONTINUOUS VARIABLE
*==============================================================================

/*
   histogram varname, options
   frequency = raw counts (default is density)
   normal    = overlay a normal curve
   bin()     = number of bins (or width() for bin width)
   color()   = bar fill color
   lcolor()  = bar outline color
*/

* Age distribution
histogram age, ///
    frequency ///
    bin(30) ///
    color(navy%60) lcolor(white) ///
    title("Age Distribution of CES 2020 Respondents") ///
    xtitle("Age") ytitle("Frequency") ///
    normal normopts(lcolor(red) lwidth(medthick))

graph export "hist_age.png", replace width(1200)

* Immigration restrictionism index (0-5, discrete)
histogram imm_restrict, ///
    discrete ///
    frequency ///
    color(dkgreen%60) lcolor(white) ///
    title("Immigration Restrictionism Index") ///
    xtitle("Restrictionism Score (0=Least, 5=Most)") ytitle("Frequency") ///
    xlabel(0 1 2 3 4 5)

graph export "hist_imm_restrict.png", replace width(1200)


*==============================================================================
* SECTION 2: BAR CHARTS — CATEGORICAL PROPORTIONS
*==============================================================================

/*
   graph bar makes a bar chart of means/proportions by category.
   (mean) yvar = mean of yvar within each category
   over(groupvar) = break out by groupvar
   ytitle, blabel, etc. are standard options
*/

* Proportion voting by education level
graph bar (mean) voted, ///
    over(education, label(angle(45))) ///
    bar(1, color(navy%70)) ///
    ytitle("Proportion Who Voted") ///
    title("Voter Turnout by Education Level") ///
    blabel(bar, format(%4.2f) size(vsmall)) ///
    yline(.5, lcolor(red) lpattern(dash))

graph export "bar_voted_by_educ.png", replace width(1200)

* Biden vote share by party ID
graph bar (mean) biden_voter if voted == 1, ///
    over(party_id3, relabel(1 "Democrat" 2 "Republican" 3 "Independent")) ///
    bar(1, color(blue%70)) ///
    ytitle("Proportion Voting Biden") ///
    title("Biden Vote Share by Party Identification (Voters Only)") ///
    blabel(bar, format(%4.2f)) ///
    yline(.5, lcolor(red) lpattern(dash))

graph export "bar_biden_by_party.png", replace width(1200)

* Stacked bar: vote choice by region
* (requires reshaping — use a simpler grouped bar instead)
graph bar (mean) biden_voter dem rep if voted==1, ///
    over(census_region, ///
         relabel(1 "Northeast" 2 "Midwest" 3 "South" 4 "West")) ///
    bar(1, color(blue%60)) bar(2, color(navy%60)) bar(3, color(red%60)) ///
    ytitle("Proportion") ///
    title("Vote Choice and Party ID by Region") ///
    legend(label(1 "Biden") label(2 "Democrat") label(3 "Republican"))

graph export "bar_votechoice_by_region.png", replace width(1200)


*==============================================================================
* SECTION 3: BOX PLOTS — DISTRIBUTIONS BY GROUP
*==============================================================================

/*
   graph box shows the median, IQR, and outliers by group.
   over(groupvar) breaks out by category.
   nooutsides suppresses outlier dots (cleaner for large N).
*/

* Immigration restrictionism by party ID
graph box imm_restrict, ///
    over(party_id3, relabel(1 "Democrat" 2 "Republican" 3 "Independent")) ///
    box(1, color(blue%70)) box(2, color(maroon%70)) box(3, color(dkgreen%70)) ///
    ytitle("Immigration Restrictionism (0-5)") ///
    title("Distribution of Immigration Restrictionism by Party")

graph export "box_imm_by_party.png", replace width(1200)

* Age by voter turnout status
graph box age, ///
    over(voted, relabel(1 "Did Not Vote" 2 "Voted")) ///
    box(1, color(gray%70)) box(2, color(navy%70)) ///
    ytitle("Age") ///
    title("Age Distribution by Voter Turnout")

graph export "box_age_by_voted.png", replace width(1200)


*==============================================================================
* SECTION 4: SCATTER PLOT AND FITTED LINE
*==============================================================================

/*
   twoway (scatter y x) (lfit y x) overlays a scatter plot with an OLS line.
   jitter() adds random noise to spread out discrete points.
   mcolor/msize control marker appearance.
   lfit = linear fit; qfit = quadratic; lowess = nonparametric smoother
*/

* Age vs. immigration restrictionism (with jitter for discrete Y)
twoway ///
    (scatter imm_restrict age, ///
        mcolor(navy%20) msize(vtiny) jitter(2)) ///
    (lfit imm_restrict age, ///
        lcolor(red) lwidth(medthick)), ///
    title("Age and Immigration Restrictionism") ///
    xtitle("Age") ytitle("Restrictionism Index (0-5)") ///
    legend(label(1 "Respondent") label(2 "OLS Fit"))

graph export "scatter_age_imm.png", replace width(1200)

* Education vs. ideology with lowess smoother
twoway ///
    (scatter ideology5 education, ///
        mcolor(dkgreen%15) msize(vtiny) jitter(3)) ///
    (lowess ideology5 education, ///
        lcolor(orange) lwidth(medthick)), ///
    title("Education and Ideology") ///
    xtitle("Education Level") ytitle("Ideology (1=Very Liberal, 5=Very Conservative)") ///
    legend(label(1 "Respondent") label(2 "Lowess"))

graph export "scatter_educ_ideo.png", replace width(1200)


*==============================================================================
* SECTION 5: COEFFICIENT PLOT (FOREST PLOT)
*==============================================================================

/*
   A coefficient plot displays regression estimates with confidence intervals.
   More readable than a table for many audiences.

   coefplot (from ssc install coefplot) is the standard tool.
   Install: ssc install coefplot
*/

* ssc install coefplot, replace

* Run a model to plot
quietly logit voted education age i.sex i.census_region ideology5 party_id7, ///
    vce(robust)

coefplot, ///
    drop(_cons) ///
    xline(0, lcolor(red) lpattern(dash)) ///
    title("Logit Coefficients: Voter Turnout Model") ///
    xtitle("Log-Odds Coefficient (with 95% CI)") ///
    mcolor(navy) ciopts(lcolor(navy)) ///
    grid(glcolor(gray%20))

graph export "coefplot_turnout.png", replace width(1200)

* Coefficient plot with odds ratios (eform)
coefplot, ///
    eform ///
    drop(_cons) ///
    xline(1, lcolor(red) lpattern(dash)) ///
    title("Odds Ratios: Voter Turnout Model") ///
    xtitle("Odds Ratio (with 95% CI)") ///
    mcolor(dkgreen) ciopts(lcolor(dkgreen))

graph export "coefplot_turnout_OR.png", replace width(1200)


*==============================================================================
* SECTION 6: PREDICTED PROBABILITY PLOTS FROM MARGINS
*==============================================================================

/*
   After logit, use margins + marginsplot to show how predicted
   probabilities change across values of a predictor.
   This is the most intuitive way to communicate nonlinear effects.
*/

quietly logit voted education age i.sex ideology5 party_id7, vce(robust)

* Predicted Pr(voted) across education levels, by sex
margins sex, at(education=(1 2 3 4 5 6)) vsquish

marginsplot, ///
    recast(line) recastci(rarea) ///
    ciopt(color(%20)) ///
    title("Predicted Probability of Voting") ///
    subtitle("By Education and Sex") ///
    xtitle("Education Level") ytitle("Pr(Voted)") ///
    xlabel(1 "No HS" 2 "HS grad" 3 "Some coll." ///
           4 "Assoc." 5 "Bach." 6 "Postgrad", angle(45)) ///
    legend(label(1 "Male CI") label(2 "Female CI") ///
           label(3 "Male") label(4 "Female"))

graph export "marginsplot_voted_educ_sex.png", replace width(1200)


*==============================================================================
* SECTION 7: HEAT MAP / TABULATION VISUALIZATION
*==============================================================================

/*
   heatplot (ssc install heatplot) creates color-coded grid plots.
   It is excellent for showing bivariate distributions of two discrete vars.

   ssc install heatplot
   ssc install palettes  /* required dependency */
   ssc install colrspace /* required dependency */
*/

* heatplot imm_restrict party_id3, ///
*     title("Joint Distribution: Restrictionism × Party") ///
*     xlabel(1 "Dem" 2 "Rep" 3 "Ind") ///
*     ylabel(0(1)5) ///
*     color(viridis)

* Simple alternative using tabplot (ssc install tabplot)
* ssc install tabplot
* tabplot imm_restrict party_id3, ///
*     showval percent(imm_restrict) ///
*     title("Restrictionism by Party ID")


*==============================================================================
* SECTION 8: LINE PLOT — MEAN BY GROUP (PROFILE PLOT)
*==============================================================================

/*
   A profile plot shows how the mean of Y changes across categories of X,
   broken out by a grouping variable. Useful for showing interactions visually.

   collapse computes group means; then twoway connected draws the lines.
*/

* Preserve data before collapsing
preserve

* Compute mean restrictionism by education and party ID
collapse (mean) mean_restrict = imm_restrict ///
         (semean) se_restrict = imm_restrict, ///
    by(education party_id3)

* Drop missing group identifiers
drop if missing(education) | missing(party_id3)

* Generate upper and lower bounds for error bars
gen upper = mean_restrict + 1.96 * se_restrict
gen lower = mean_restrict - 1.96 * se_restrict

* Profile plot
twoway ///
    (connected mean_restrict education if party_id3 == 1, ///
        lcolor(blue) mcolor(blue) msymbol(circle)) ///
    (connected mean_restrict education if party_id3 == 2, ///
        lcolor(red) mcolor(red) msymbol(square)) ///
    (connected mean_restrict education if party_id3 == 3, ///
        lcolor(dkgreen) mcolor(dkgreen) msymbol(triangle)), ///
    title("Immigration Restrictionism by Education and Party") ///
    xtitle("Education Level") ytitle("Mean Restrictionism (0-5)") ///
    xlabel(1 "No HS" 2 "HS" 3 "Some coll." 4 "Assoc." 5 "Bach." 6 "Postgrad", ///
           angle(45)) ///
    legend(label(1 "Democrat") label(2 "Republican") label(3 "Independent")) ///
    yline(2.5, lcolor(gray) lpattern(dash))

graph export "profile_restrict_educ_party.png", replace width(1200)

restore


*==============================================================================
* SECTION 9: COMBINING GRAPHS WITH GRAPH COMBINE
*==============================================================================

/*
   graph combine stacks or grids previously saved graphs.
   name() assigns a graph a name so it can be combined without saving to disk.
*/

* Make two named graphs
histogram age, ///
    bin(25) color(navy%60) lcolor(white) ///
    frequency ///
    title("Age") xtitle("Age") ytitle("N") ///
    name(g_age, replace)

histogram imm_restrict, ///
    discrete frequency ///
    color(dkgreen%60) lcolor(white) ///
    title("Restrictionism") xtitle("Score") ytitle("N") ///
    xlabel(0 1 2 3 4 5) ///
    name(g_imm, replace)

* Combine side by side
graph combine g_age g_imm, ///
    title("CES 2020: Key Variable Distributions") ///
    cols(2)

graph export "combined_distributions.png", replace width(1800)


*==============================================================================
* SECTION 10: GRAPH SCHEME AND FORMATTING NOTES
*==============================================================================

/*
   Stata ships with several built-in schemes:
     s2color   = default (gray background, colored lines)
     s1color   = white background, better for print
     s1mono    = monochrome — required for journals that ban color figures
     lean1/2   = minimalist, no grid lines

   Change scheme globally:  set scheme s1color
   Change for one graph:    graph ... , scheme(s1mono)

   For publication:
   - Use scheme(s1color) or s1mono
   - Export at 300+ DPI: graph export "file.tif", width(2400) replace
   - TIF for Word/LaTeX, PNG for web
   - EPS for vector-based journals: graph export "file.eps", replace

   Fonts: Stata uses system fonts. For consistent output match your Word doc font.
*/

set scheme s1color

di "Module 6 complete. Check your working directory for .png graph files."
