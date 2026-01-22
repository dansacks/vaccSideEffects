/*==============================================================================
    Comprehensive Balance Tables by Domain

    Input:  derived/merged_main_pre.dta (with indicator variables from cleaning files)
    Output: output/tables/balance_prior_beliefs.tex
            output/tables/balance_vacc.tex
            output/tables/balance_demographics.tex
            output/tables/balance_trust.tex
            output/tables/balance_health.tex
            output/tables/balance_omnibus.tex

    Creates balance tables for all control variables used in treatment_effects.do,
    organized by domain. Each table includes a joint significance test.
    Omnibus tests across all domains and excluding demographics.

    Indicator variables are created in:
    - clean_prescreen.do: intent_no, covid_react_*, flu_react_*, trust_*
    - clean_main.do: prior_placebo_*, prior_vacc_*, age_*, female, gender_other,
                     educ_*, income_*, race_*, hispanic, polviews_*

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "balance_tables_full"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load data
------------------------------------------------------------------------------*/

use "derived/merged_main_pre.dta", clear

/*------------------------------------------------------------------------------
    2. Program to create balance table for a domain
------------------------------------------------------------------------------*/

capture program drop make_balance_table
program define make_balance_table
    syntax, vars(string) filename(string) title(string)

    * Get sample sizes
    qui count if arm_n == 0
    local N0 = r(N)
    qui count if arm_n == 1
    local N1 = r(N)
    qui count if arm_n == 2
    local N2 = r(N)
    qui count if arm_n == 3
    local N3 = r(N)

    * Open output file
    capture file close fout
    file open fout using "output/tables/`filename'.tex", write replace

    * Count variables for joint test
    local nvars: word count `vars'
    local est_names ""
    local i = 1

    foreach var of local vars {
        * Get variable label
        local varlabel: variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"

        * Get means by arm
        quietly {
            sum `var' if arm_n == 0
            local mean0 = r(mean)
            local n0 = r(N)

            sum `var' if arm_n == 1
            local mean1 = r(mean)

            sum `var' if arm_n == 2
            local mean2 = r(mean)

            sum `var' if arm_n == 3
            local mean3 = r(mean)
        }

        * Test joint equality
        quietly regress `var' i.arm_n, vce(robust)
        quietly testparm i.arm_n
        local pval = r(p)

        * Store estimates for joint test
        quietly regress `var' i.arm_n
        estimates store est`i'
        local est_names "`est_names' est`i'"
        local ++i

        * Format for LaTeX
        local mean0_fmt: di %5.3f `mean0'
        local mean1_fmt: di %5.3f `mean1'
        local mean2_fmt: di %5.3f `mean2'
        local mean3_fmt: di %5.3f `mean3'
        local pval_fmt: di %5.3f `pval'

        file write fout "`varlabel' & `mean0_fmt' & `mean1_fmt' & `mean2_fmt' & `mean3_fmt' & `pval_fmt' \\" _n

        di "`varlabel': C=`mean0_fmt' I=`mean1_fmt' A=`mean2_fmt' P=`mean3_fmt' p=`pval_fmt'"
    }

    * Joint test using suest (only if more than one variable)
    if `nvars' > 1 {
        quietly suest `est_names', vce(robust)

        * Build test terms
        local test_terms ""
        forvalues j = 1/`nvars' {
            local test_terms "`test_terms' [est`j'_mean]1.arm_n [est`j'_mean]2.arm_n [est`j'_mean]3.arm_n"
        }

        quietly test `test_terms'
        local joint_chi2 = r(chi2)
        local joint_df = r(df)
        local joint_p = r(p)

        * Write joint test row
        file write fout "\addlinespace" _n
        local joint_chi2_fmt: di %5.2f `joint_chi2'
        local joint_p_fmt: di %5.3f `joint_p'
        file write fout "Joint test & \multicolumn{4}{c}{\$\chi^2(`joint_df')=`joint_chi2_fmt'\$} & `joint_p_fmt' \\" _n

        di ""
        di "`title': Joint chi2(`joint_df') = `joint_chi2_fmt', p = `joint_p_fmt'"
    }
    else {
        di ""
        di "`title': Single variable, no joint test needed"
    }

    * Write sample size row
    file write fout "\addlinespace" _n
    file write fout "N & `N0' & `N1' & `N2' & `N3' &" _n

    file close fout

    di "Saved: output/tables/`filename'.tex"
    di ""

    * Clean up estimates
    forvalues j = 1/`nvars' {
        estimates drop est`j'
    }
end

/*------------------------------------------------------------------------------
    3. Create balance tables by domain
------------------------------------------------------------------------------*/

di ""
di "=========================================="
di "=== DOMAIN 1: PRIOR BELIEFS ==="
di "=========================================="

local prior_vars "prior_placebo_1 prior_placebo_2 prior_placebo_3 prior_placebo_4 prior_placebo_5 prior_placebo_6 prior_placebo_7 prior_vacc_1 prior_vacc_2 prior_vacc_3 prior_vacc_4 prior_vacc_5 prior_vacc_6 prior_vacc_7"

make_balance_table, vars(`prior_vars') filename(balance_prior_beliefs) title("Prior Beliefs")

di ""
di "=========================================="
di "=== DOMAIN 2: VACCINATION INTENT & EXPERIENCE ==="
di "=========================================="

local vacc_vars "intent_no had_prior_covid_vacc had_prior_flu_vacc covid_react_none covid_react_mild covid_react_severe flu_react_none flu_react_mild flu_react_severe"

make_balance_table, vars(`vacc_vars') filename(balance_vacc) title("Vaccination Intent & Experience")

di ""
di "=========================================="
di "=== DOMAIN 3: DEMOGRAPHICS ==="
di "=========================================="

local demo_vars "age_18_34 age_35_49 age_50_64 age_65plus female gender_other educ_hs_or_less educ_some_college educ_college educ_grad income_lt25k income_25_50k income_50_75k income_75_100k income_100kplus race_white race_black race_asian race_native race_other hispanic polviews_very_liberal polviews_liberal polviews_slight_liberal polviews_moderate polviews_slight_conserv polviews_conservative polviews_very_conserv"

make_balance_table, vars(`demo_vars') filename(balance_demographics) title("Demographics")

di ""
di "=========================================="
di "=== DOMAIN 4: TRUST ==="
di "=========================================="

local trust_vars "trust_strongly_disagree trust_somewhat_disagree trust_neither trust_somewhat_agree trust_strongly_agree"

make_balance_table, vars(`trust_vars') filename(balance_trust) title("Trust")

di ""
di "=========================================="
di "=== DOMAIN 5: HEALTH CONDITIONS ==="
di "=========================================="

local health_vars "cond_none cond_asthma cond_lung cond_heart cond_diabetes cond_kidney cond_rather_not_say"

make_balance_table, vars(`health_vars') filename(balance_health) title("Health Conditions")

/*------------------------------------------------------------------------------
    4. Omnibus tests
------------------------------------------------------------------------------*/

di ""
di "=========================================="
di "=== OMNIBUS BALANCE TEST (ALL DOMAINS) ==="
di "=========================================="

* Combine all variables for omnibus test
local all_vars "`prior_vars' `vacc_vars' `demo_vars' `trust_vars' `health_vars'"
local nvars: word count `all_vars'

di "Total variables in omnibus test: `nvars'"

* Run suest for joint test across all variables
local i = 1
local est_names ""
foreach var of local all_vars {
    quietly regress `var' i.arm_n
    estimates store omni`i'
    local est_names "`est_names' omni`i'"
    local ++i
}

quietly suest `est_names', vce(robust)

* Build test terms
local test_terms ""
forvalues j = 1/`nvars' {
    local test_terms "`test_terms' [omni`j'_mean]1.arm_n [omni`j'_mean]2.arm_n [omni`j'_mean]3.arm_n"
}

test `test_terms'
local omni_chi2 = r(chi2)
local omni_df = r(df)
local omni_p = r(p)

di ""
di "Omnibus chi-squared(`omni_df') = " %8.3f `omni_chi2'
di "Omnibus p-value = " %6.4f `omni_p'

* Write omnibus results to file
capture file close fout
file open fout using "output/tables/balance_omnibus.tex", write replace

local omni_chi2_fmt: di %6.2f `omni_chi2'
local omni_p_fmt: di %5.4f `omni_p'

file write fout "Omnibus (all domains) & \multicolumn{4}{c}{\$\chi^2(`omni_df')=`omni_chi2_fmt'\$} & `omni_p_fmt' \\" _n

* Clean up estimates
forvalues j = 1/`nvars' {
    capture estimates drop omni`j'
}

di ""
di "=========================================="
di "=== OMNIBUS TEST (EXCLUDING DEMOGRAPHICS) ==="
di "=========================================="

* Combine variables excluding demographics
local nodemo_vars "`prior_vars' `vacc_vars' `trust_vars' `health_vars'"
local nvars_nodemo: word count `nodemo_vars'

di "Total variables (excl. demographics): `nvars_nodemo'"

* Run suest for joint test
local i = 1
local est_names ""
foreach var of local nodemo_vars {
    quietly regress `var' i.arm_n
    estimates store omni_nd`i'
    local est_names "`est_names' omni_nd`i'"
    local ++i
}

quietly suest `est_names', vce(robust)

* Build test terms
local test_terms ""
forvalues j = 1/`nvars_nodemo' {
    local test_terms "`test_terms' [omni_nd`j'_mean]1.arm_n [omni_nd`j'_mean]2.arm_n [omni_nd`j'_mean]3.arm_n"
}

test `test_terms'
local omni_nd_chi2 = r(chi2)
local omni_nd_df = r(df)
local omni_nd_p = r(p)

di ""
di "Omnibus (excl. demo) chi-squared(`omni_nd_df') = " %8.3f `omni_nd_chi2'
di "Omnibus (excl. demo) p-value = " %6.4f `omni_nd_p'

* Write to same file
local omni_nd_chi2_fmt: di %6.2f `omni_nd_chi2'
local omni_nd_p_fmt: di %5.4f `omni_nd_p'

file write fout "Omnibus (excl. demographics) & \multicolumn{4}{c}{\$\chi^2(`omni_nd_df')=`omni_nd_chi2_fmt'\$} & `omni_nd_p_fmt'" _n

file close fout

di ""
di "Saved: output/tables/balance_omnibus.tex"

* Clean up estimates
forvalues j = 1/`nvars_nodemo' {
    capture estimates drop omni_nd`j'
}

di ""
di "=== BALANCE TABLES COMPLETE ==="
di "Files created:"
di "  - output/tables/balance_prior_beliefs.tex"
di "  - output/tables/balance_vacc.tex"
di "  - output/tables/balance_demographics.tex"
di "  - output/tables/balance_trust.tex"
di "  - output/tables/balance_health.tex"
di "  - output/tables/balance_omnibus.tex"

capture log close
