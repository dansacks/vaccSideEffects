/*==============================================================================
    Test Cases for balance_table command

    Run interactively to verify balance_table.ado works correctly.
    Test cases 1-2 use deterministic data with known expected output.

    Created by Dan + Claude Code
==============================================================================*/

clear all
discard
global scriptname "test_balance_table"
do "code/_config.do"

/*------------------------------------------------------------------------------
    Test Case 1: Deterministic 2-group balance table
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 1: Deterministic 2-group"
di "=============================================="

clear
input group x1 x2
0 1.0 2.0
0 1.2 2.1
0 0.8 1.9
1 1.5 2.0
1 1.7 2.2
1 1.3 1.8
end
label var x1 "Variable One"
label var x2 "Variable Two"

balance_table x1 x2, group(group) saving(output/tables/test_balance_2group.tex)

* Verify output
di ""
di "=== Verifying output ==="
type output/tables/test_balance_2group.tex

di ""
di "Expected output:"
di "Variable One & 1.000 & 1.500 & [p-value] \\"
di "Variable Two & 2.000 & 2.000 & [p-value] \\"
di "N & 3 & 3 &"
di ""
di "x1: group 0 mean = 1.0, group 1 mean = 1.5"
di "x2: group 0 mean = 2.0, group 1 mean = 2.0 (identical, p=1)"

/*------------------------------------------------------------------------------
    Test Case 2: Deterministic 4-group with joint test
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 2: Deterministic 4-group with joint test"
di "=============================================="

clear
input arm x1 x2 x3
0 1.0 1.0 1.0
0 1.1 1.1 1.1
1 1.0 2.0 1.0
1 1.1 2.1 1.1
2 1.0 1.0 1.0
2 1.1 1.1 1.1
3 1.0 1.0 1.0
3 1.1 1.1 1.1
end
label var x1 "Balanced"
label var x2 "Imbalanced"
label var x3 "Also Balanced"

balance_table x1 x2 x3, group(arm) saving(output/tables/test_balance_4group.tex) jointtest

* Verify output
di ""
di "=== Verifying output ==="
type output/tables/test_balance_4group.tex

di ""
di "Expected:"
di "- x1: all means = 1.050, p = 1.000 (identical across arms)"
di "- x2: arm 0,2,3 mean = 1.050, arm 1 mean = 2.050, p << 0.05"
di "- x3: all means = 1.050, p = 1.000 (identical across arms)"
di "- Joint test should detect imbalance in x2"

/*------------------------------------------------------------------------------
    Test Case 3: With if condition
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 3: With if condition"
di "=============================================="

clear
input group x1 insample
0 1.0 1
0 2.0 1
0 3.0 0
1 4.0 1
1 5.0 1
1 6.0 0
end
label var x1 "Test Variable"

di "Full sample means: group 0 = 2.0, group 1 = 5.0"
di "Restricted sample (insample==1) means: group 0 = 1.5, group 1 = 4.5"

balance_table x1 if insample==1, group(group) saving(output/tables/test_balance_if.tex)

di ""
di "=== Verifying output ==="
type output/tables/test_balance_if.tex

di ""
di "Expected: means = 1.500 and 4.500, N = 2 and 2"

/*------------------------------------------------------------------------------
    Test Case 4: Replicate existing balance_table.do output
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 4: Replicate balance_table.do"
di "=============================================="

use "derived/merged_main_pre.dta", clear

* Create same indicator variables as balance_table.do
gen prior_vacc_likely = (prior_self_vacc >= 5) if ~missing(prior_self_vacc)
label var prior_vacc_likely "Prior: SE likely with vaccine"

gen pre_no_intent = (pre_vacc_intent == 1) if ~missing(pre_vacc_intent)
label var pre_no_intent "Do not intend to vaccinate"

gen pre_had_flu = had_prior_flu_vacc
label var pre_had_flu "Previously had flu vaccine"

gen pre_had_covid = had_prior_covid_vacc
label var pre_had_covid "Previously had COVID vaccine"

gen severe_flu_reaction = (flu_vacc_reaction == 3) if had_prior_flu_vacc == 1
label var severe_flu_reaction "Severe flu vaccine reaction"

gen severe_covid_reaction = (covid_vacc_reaction == 3) if had_prior_covid_vacc == 1
label var severe_covid_reaction "Severe COVID vaccine reaction"

gen has_condition = (cond_none == 0) if ~missing(cond_none)
label var has_condition "Has health condition"

capture gen age_18_34 = (age == 2) if ~missing(age) & age != $PREF_NOT_SAY
capture label var age_18_34 "Age 18--34"

capture gen age_35_49 = (age == 3) if ~missing(age) & age != $PREF_NOT_SAY
capture label var age_35_49 "Age 35--49"

capture gen race_white = (race == 1) if ~missing(race) & race != 7
capture label var race_white "White"

capture gen hispanic = (ethnicity == 1) if ~missing(ethnicity) & ethnicity != 3
capture label var hispanic "Hispanic"

gen income_lt50k = (income <= 2) if ~missing(income) & income != 6
label var income_lt50k "Income under 50k"

gen trust_govt_high = (trust_govt >= 4) if ~missing(trust_govt)
label var trust_govt_high "Trust government"

gen follow_doc_high = (follow_doctor >= 4) if ~missing(follow_doctor)
label var follow_doc_high "Follow doctor advice"

gen college = (education == 4 | education == 5) if ~missing(education) & education != 6
label var college "College degree"

* Run balance table with new command
balance_table prior_vacc_likely pre_no_intent pre_had_flu pre_had_covid ///
    severe_flu_reaction severe_covid_reaction has_condition ///
    age_18_34 age_35_49 race_white hispanic income_lt50k ///
    trust_govt_high follow_doc_high college, ///
    group(arm_n) saving(output/tables/test_replicate_balance.tex) jointtest

di ""
di "Compare output/tables/test_replicate_balance.tex with output/tables/balance_table.tex"
di "Values should match within floating point precision"
di ""

/*------------------------------------------------------------------------------
    Summary
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST SUMMARY ==="
di "=============================================="
di "Test files created:"
di "  - output/tables/test_balance_2group.tex"
di "  - output/tables/test_balance_4group.tex"
di "  - output/tables/test_balance_if.tex"
di "  - output/tables/test_replicate_balance.tex"
di ""
di "Review output and compare test_replicate_balance.tex with balance_table.tex"

capture log close
