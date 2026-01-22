/*==============================================================================
    Test Cases for regression_table command

    Run interactively to verify regression_table.ado works correctly.
    Test cases 1-2 use deterministic data with known expected output.

    Created by Dan + Claude Code
==============================================================================*/

clear all
discard
global scriptname "test_regression_table"
do "code/_config.do"

/*------------------------------------------------------------------------------
    Test Case 1: Deterministic regression table
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 1: Deterministic regression"
di "=============================================="

clear
input arm_a arm_b y1 y2 x
0 0 10 5 1
0 0 10 5 1
1 0 12 6 1
1 0 12 6 1
0 1 11 4 1
0 1 11 4 1
end
label var arm_a "Treatment A"
label var arm_b "Treatment B"

regression_table y1 y2, keyvars(arm_a arm_b) controls(x) ///
    saving(output/tables/test_regression_basic.tex)

* Verify output
di ""
di "=== Verifying output ==="
type output/tables/test_regression_basic.tex

di ""
di "Expected coefficients (exact due to perfect fit):"
di "  y1: arm_a = 2.000, arm_b = 1.000, control mean = 10.000"
di "  y2: arm_a = 1.000, arm_b = -1.000, control mean = 5.000"
di "  N = 6 for both"

/*------------------------------------------------------------------------------
    Test Case 2: Regression with if condition
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 2: With if condition"
di "=============================================="

clear
input arm_a y1 insample
0 10 1
0 10 1
1 12 1
1 12 0
end
label var arm_a "Treatment A"

di "Full sample: N=4, arm_a coef = 2.0"
di "Restricted (insample==1): N=3, arm_a coef = 2.0"

regression_table y1 if insample==1, keyvars(arm_a) ///
    saving(output/tables/test_regression_if.tex)

* Verify output
di ""
di "=== Verifying output ==="
type output/tables/test_regression_if.tex

di ""
di "Expected: N = 3, arm_a = 2.000, control mean = 10.000"

/*------------------------------------------------------------------------------
    Test Case 3: Single outcome
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 3: Single outcome"
di "=============================================="

clear
input arm_a arm_b y1
0 0 5
0 0 5
1 0 8
1 0 8
0 1 6
0 1 6
end
label var arm_a "Treatment A"
label var arm_b "Treatment B"

regression_table y1, keyvars(arm_a arm_b) saving(output/tables/test_regression_single.tex)

* Verify output
di ""
di "=== Verifying output ==="
type output/tables/test_regression_single.tex

di ""
di "Expected: arm_a = 3.000, arm_b = 1.000, control mean = 5.000, N = 6"

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

/*------------------------------------------------------------------------------
    Summary
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST SUMMARY ==="
di "=============================================="
di "Test files created:"
di "  - output/tables/test_regression_basic.tex"
di "  - output/tables/test_regression_if.tex"
di "  - output/tables/test_regression_single.tex"
di "  - output/tables/test_replicate_treatment.tex"
di ""
di "Review output and compare test_replicate_treatment.tex with treatment_effects.tex"

capture log close
