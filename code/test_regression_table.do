/*==============================================================================
    Test Cases for regression_table command

    Run interactively to verify regression_table.ado works correctly.

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "test_regression_table"
do "code/_config.do"

/*------------------------------------------------------------------------------
    Test Case 1: Basic regression table
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 1: Basic regression table"
di "=============================================="

clear
set seed 12345
set obs 500

* Create treatment indicators (mutually exclusive)
gen u = runiform()
gen arm_ind = u > 0.75
gen arm_acad = u > 0.5 & u <= 0.75
gen arm_pers = u > 0.25 & u <= 0.5
gen control = u <= 0.25

* Control variable
gen x = rnormal()

* Outcomes with known effects
gen y1 = 10 + 2*arm_ind + 1*arm_acad + 0.5*arm_pers + x + rnormal()
gen y2 = 5 + 1*arm_ind - 0.5*arm_acad + 0*arm_pers + 0.5*x + rnormal()

label var arm_ind "Industry"
label var arm_acad "Academic"
label var arm_pers "Personal"
label var y1 "Outcome 1"
label var y2 "Outcome 2"

regression_table y1 y2, keyvars(arm_ind arm_acad arm_pers) controls(x) ///
    saving(output/tables/test_regression_basic.tex)

di ""
di "Expected coefficients (approximately):"
di "  y1: Industry~2, Academic~1, Personal~0.5, Control mean~10"
di "  y2: Industry~1, Academic~-0.5, Personal~0, Control mean~5"
di ""

/*------------------------------------------------------------------------------
    Test Case 2: Regression with sample restriction
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 2: With sample restriction"
di "=============================================="

* Create sample indicator (keep ~70%)
gen followup = runiform() > 0.3

regression_table y1 y2, keyvars(arm_ind arm_acad arm_pers) controls(x) ///
    sample(followup) saving(output/tables/test_regression_sample.tex)

di ""
di "Expected: N should be ~350 (70% of 500)"
di ""

/*------------------------------------------------------------------------------
    Test Case 3: Single outcome
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 3: Single outcome"
di "=============================================="

regression_table y1, keyvars(arm_ind arm_acad arm_pers) controls(x) ///
    saving(output/tables/test_regression_single.tex)

di ""
di "Expected: Single column with y1 results"
di ""

/*------------------------------------------------------------------------------
    Test Case 4: Replicate existing treatment_effects.do output
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 4: Replicate treatment_effects.do"
di "=============================================="

use "derived/merged_all.dta", clear
do "code/_set_controls.do"

* Create link_click if not already present
capture confirm variable link_click
if _rc {
    egen link_click = rowmax(link1_clicked link2_clicked link3_clicked link4_clicked)
    label var link_click "Any link clicked"
}

* Convert -99 to missing for categorical variables
foreach var in age gender education income race ethnicity {
    replace `var' = . if `var' == -99
}

* Create vacc_post outcome
gen vacc_post = got_flu_vacc == 1 | flu_why_already == 1 if ~missing(got_flu_vacc)

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

regression_table post_trial delta main_maybe link_click vacc_post, ///
    keyvars(arm_industry arm_academic arm_personal) ///
    controls($controls) saving(output/tables/test_replicate_treatment.tex)

di ""
di "Compare output/tables/test_replicate_treatment.tex with output/tables/treatment_effects.tex"
di "Values should match within floating point precision"
di ""
di "Note: treatment_effects.tex includes R-squared row which our command omits"
di ""

/*------------------------------------------------------------------------------
    Summary
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST SUMMARY ==="
di "=============================================="
di "Test files created:"
di "  - output/tables/test_regression_basic.tex"
di "  - output/tables/test_regression_sample.tex"
di "  - output/tables/test_regression_single.tex"
di "  - output/tables/test_replicate_treatment.tex"
di ""
di "Review output and compare test_replicate_treatment.tex with treatment_effects.tex"

capture log close
