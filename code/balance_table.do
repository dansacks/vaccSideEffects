/*==============================================================================
    Balance Table for Main Survey Sample

    Input:  derived/merged_main_pre.dta
    Output: output/tables/balance_table.csv
            output/tables/balance_table.tex (table body only, no headers/metadata)

    Creates balance table with treatment arm means and joint equality tests.
    Each row is a variable, each column is a treatment arm + p-value.

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "balance_table"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load merged data
------------------------------------------------------------------------------*/

use "derived/merged_main_pre.dta", clear
count
di "Total merged observations: " r(N)

/*------------------------------------------------------------------------------
    2. Create indicator variables for balance table
------------------------------------------------------------------------------*/

* Prior belief: somewhat likely or more likely to experience SE with vaccine (>=5)
gen prior_vacc_likely = (prior_self_vacc >= 5) if ~missing(prior_self_vacc)
label var prior_vacc_likely "Prior: SE likely with vaccine"

* Do not intend to vaccinate (from prescreen, vacc_intent == 1)
gen pre_no_intent = (pre_vacc_intent_pre == 1) if ~missing(pre_vacc_intent_pre)
label var pre_no_intent "Do not intend to vaccinate"

* Previously had flu vaccine
gen pre_had_flu = had_prior_flu_vacc
label var pre_had_flu "Previously had flu vaccine"

* Previously had COVID vaccine
gen pre_had_covid = had_prior_covid_vacc
label var pre_had_covid "Previously had COVID vaccine"

* Severe flu vaccine reaction (conditional on having had flu vacc)
gen severe_flu_reaction = (flu_vacc_reaction == 3) if had_prior_flu_vacc == 1
label var severe_flu_reaction "Severe flu vaccine reaction"

* Severe COVID vaccine reaction (conditional on having had COVID vacc)
gen severe_covid_reaction = (covid_vacc_reaction == 3) if had_prior_covid_vacc == 1
label var severe_covid_reaction "Severe COVID vaccine reaction"

* Has health condition (cond_none == 0, conditional on not missing)
gen has_condition = (cond_none == 0) if ~missing(cond_none)
label var has_condition "Has health condition"

* Age, race, ethnicity variables already created in clean_main.do
* Use existing variables from merged dataset (capture gen in case they don't exist)
capture gen age_18_34 = (age == 2) if ~missing(age) & age != $PREF_NOT_SAY
capture label var age_18_34 "Age 18--34"

capture gen age_35_49 = (age == 3) if ~missing(age) & age != $PREF_NOT_SAY
capture label var age_35_49 "Age 35--49"

capture gen race_white = (race == 1) if ~missing(race) & race != 7
capture label var race_white "White"

capture gen hispanic = (ethnicity == 1) if ~missing(ethnicity) & ethnicity != 3
capture label var hispanic "Hispanic"

* Income < 50k (income == 1 or 2)
* Exclude 6 = "Prefer not to say"
gen income_lt50k = (income <= 2) if ~missing(income) & income != 6
label var income_lt50k "Income under 50k"

* Trust government somewhat or strongly (trust_govt >= 4)
gen trust_govt_high = (trust_govt >= 4) if ~missing(trust_govt)
label var trust_govt_high "Trust government"

* Follow doctor somewhat or strongly (follow_doctor >= 4)
gen follow_doc_high = (follow_doctor >= 4) if ~missing(follow_doctor)
label var follow_doc_high "Follow doctor advice"

* College degree (education == 4 or 5)
* Exclude 6 = "Prefer not to say"
gen college = (education == 4 | education == 5) if ~missing(education) & education != 6
label var college "College degree"

/*------------------------------------------------------------------------------
    3. Define variable list for balance table
------------------------------------------------------------------------------*/

local balance_vars ///
    prior_vacc_likely ///
    pre_no_intent ///
    pre_had_flu ///
    pre_had_covid ///
    severe_flu_reaction ///
    severe_covid_reaction ///
    has_condition ///
    age_18_34 ///
    age_35_49 ///
    race_white ///
    hispanic ///
    income_lt50k ///
    trust_govt_high ///
    follow_doc_high ///
    college

/*------------------------------------------------------------------------------
    4. Calculate sample sizes by arm
------------------------------------------------------------------------------*/

* Get sample sizes for each arm (using a variable with no missings for full sample)
count if arm_n == 0
local N0 = r(N)
count if arm_n == 1
local N1 = r(N)
count if arm_n == 2
local N2 = r(N)
count if arm_n == 3
local N3 = r(N)
local N_total = `N0' + `N1' + `N2' + `N3'

di "Sample sizes: Control=`N0' Industry=`N1' Academic=`N2' Personal=`N3' Total=`N_total'"

/*------------------------------------------------------------------------------
    5. Program to calculate balance stats for a variable
------------------------------------------------------------------------------*/

capture program drop calc_balance_stats
program define calc_balance_stats, rclass
    syntax varname

    * Get means by arm
    quietly {
        sum `varlist' if arm_n == 0
        local mean0 = r(mean)

        sum `varlist' if arm_n == 1
        local mean1 = r(mean)

        sum `varlist' if arm_n == 2
        local mean2 = r(mean)

        sum `varlist' if arm_n == 3
        local mean3 = r(mean)
    }

    * Test joint equality (F-test from regression with robust SEs)
    quietly regress `varlist' i.arm_n, vce(robust)
    quietly testparm i.arm_n
    local pval = r(p)

    * Return results
    return scalar mean0 = `mean0'
    return scalar mean1 = `mean1'
    return scalar mean2 = `mean2'
    return scalar mean3 = `mean3'
    return scalar pval = `pval'
end

/*------------------------------------------------------------------------------
    6. Calculate means by treatment arm and p-values
------------------------------------------------------------------------------*/

* Open output files
capture file close csvout
capture file close texout
file open csvout using "output/tables/balance_table.csv", write replace
file open texout using "output/tables/balance_table.tex", write replace

* Write CSV header
file write csvout "Variable,Control,Industry,Academic,Personal,P-value" _n

foreach var of local balance_vars {
    * Get variable label for display
    local varlabel: variable label `var'
    if "`varlabel'" == "" local varlabel "`var'"

    * Calculate stats
    calc_balance_stats `var'

    * Format means (3 decimal places)
    local mean0_fmt: di %6.3f r(mean0)
    local mean1_fmt: di %6.3f r(mean1)
    local mean2_fmt: di %6.3f r(mean2)
    local mean3_fmt: di %6.3f r(mean3)
    local pval_fmt: di %6.3f r(pval)

    * Write to CSV
    file write csvout "`varlabel',`mean0_fmt',`mean1_fmt',`mean2_fmt',`mean3_fmt',`pval_fmt'" _n

    * Write to LaTeX
    file write texout "`varlabel' & `mean0_fmt' & `mean1_fmt' & `mean2_fmt' & `mean3_fmt' & `pval_fmt' \\" _n

    di "`varlabel': Control=`mean0_fmt' Industry=`mean1_fmt' Academic=`mean2_fmt' Personal=`mean3_fmt' p=`pval_fmt'"
}

/*------------------------------------------------------------------------------
    7. Joint F-test for all variables (SUR approach)
------------------------------------------------------------------------------*/

di ""
di "=== JOINT BALANCE TEST ==="

* Use seemingly unrelated regression for joint test
quietly {
    preserve

    * Run suest for joint test across all variables
    local nvars: word count `balance_vars'
    local i = 1
    local est_names ""
    foreach var of local balance_vars {
        quietly regress `var' i.arm_n
        estimates store est`i'
        local est_names "`est_names' est`i'"
        local ++i
    }

    * Joint test using suest
    suest `est_names', vce(robust)

    * Test all arm coefficients jointly
    local test_terms ""
    forvalues i = 1/`nvars' {
        local test_terms "`test_terms' [est`i'_mean]1.arm_n [est`i'_mean]2.arm_n [est`i'_mean]3.arm_n"
    }

    test `test_terms'
    local joint_chi2 = r(chi2)
    local joint_df = r(df)
    local joint_p = r(p)

    restore
}

di "Joint chi-squared(`joint_df') = " %8.3f `joint_chi2'
di "Joint p-value = " %6.3f `joint_p'

/*------------------------------------------------------------------------------
    8. Write joint test and sample sizes to output files
------------------------------------------------------------------------------*/

* Format joint test results
local joint_chi2_fmt: di %8.3f `joint_chi2'
local joint_p_fmt: di %6.3f `joint_p'

* Append to CSV
file write csvout _n
file write csvout "Joint test,chi2(`joint_df')=`joint_chi2_fmt',,,`joint_p_fmt'" _n
file write csvout _n
file write csvout "N,`N0',`N1',`N2',`N3'," _n

* Append to LaTeX
file write texout "\addlinespace" _n
local joint_chi2_tex: di %5.3f `joint_chi2'
local joint_p_tex: di %5.3f `joint_p'
file write texout "Joint test & \multicolumn{4}{c}{\$\chi^2(`joint_df')=`joint_chi2_tex'\$} & `joint_p_tex' \\" _n
file write texout "\addlinespace" _n
file write texout "N & `N0' & `N1' & `N2' & `N3' &" _n

file close csvout
file close texout

di ""
di "=== BALANCE TABLE COMPLETE ==="
di "Saved: output/tables/balance_table.csv"
di "Saved: output/tables/balance_table.tex"

capture log close
