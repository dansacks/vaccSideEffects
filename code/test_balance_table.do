/*==============================================================================
    Test Cases for balance_table command

    Run interactively to verify balance_table.ado works correctly.

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "test_balance_table"
do "code/_config.do"

/*------------------------------------------------------------------------------
    Test Case 1: Basic 2-group balance table
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 1: Basic 2-group balance table"
di "=============================================="

clear
set seed 12345
set obs 200
gen group = runiform() > 0.5
gen x1 = rnormal(0, 1) + 0.1*group
gen x2 = rnormal(0.5, 1)
label var x1 "Outcome 1 (slight imbalance)"
label var x2 "Outcome 2 (balanced)"

balance_table x1 x2, group(group) saving(output/tables/test_balance_2group.tex)

di ""
di "Expected: 2 columns (group 0, group 1) + p-value column"
di "x1 should show ~0.1 difference, x2 should show ~0 difference"
di ""

/*------------------------------------------------------------------------------
    Test Case 2: 4-group balance table with joint test
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 2: 4-group with joint test"
di "=============================================="

clear
set seed 12345
set obs 400
gen arm = floor(runiform() * 4)
gen x1 = rnormal(0, 1)
gen x2 = rnormal(0, 1) + 0.5*(arm==1)
gen x3 = rnormal(0, 1)
label var x1 "Balanced var"
label var x2 "Imbalanced var (arm 1 higher)"
label var x3 "Another balanced var"

balance_table x1 x2 x3, group(arm) saving(output/tables/test_balance_4group.tex) jointtest

di ""
di "Expected: x2 should have low p-value, x1 and x3 should have high p-values"
di "Joint test should detect imbalance"
di ""

/*------------------------------------------------------------------------------
    Test Case 3: Replicate existing balance_table.do output
------------------------------------------------------------------------------*/

di ""
di "=============================================="
di "=== TEST CASE 3: Replicate balance_table.do"
di "=============================================="

use "derived/merged_main_pre.dta", clear

* Create same indicator variables as balance_table.do
gen prior_vacc_likely = (prior_self_vacc >= 5) if ~missing(prior_self_vacc)
label var prior_vacc_likely "Prior: SE likely with vaccine"

gen pre_no_intent = (pre_vacc_intent_pre == 1) if ~missing(pre_vacc_intent_pre)
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
di "  - output/tables/test_replicate_balance.tex"
di ""
di "Review output and compare test_replicate_balance.tex with balance_table.tex"

capture log close
