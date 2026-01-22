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

    Requires: code/ado/balance_table.ado

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "balance_tables_full"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load data and define variable lists
------------------------------------------------------------------------------*/

use "derived/merged_main_pre.dta", clear

local prior_vars "prior_placebo_1 prior_placebo_2 prior_placebo_3 prior_placebo_4 prior_placebo_5 prior_placebo_6 prior_placebo_7 prior_vacc_1 prior_vacc_2 prior_vacc_3 prior_vacc_4 prior_vacc_5 prior_vacc_6 prior_vacc_7"

local vacc_vars "intent_no had_prior_covid_vacc had_prior_flu_vacc covid_react_none covid_react_mild covid_react_severe flu_react_none flu_react_mild flu_react_severe"

local demo_vars "age_18_34 age_35_49 age_50_64 age_65plus female gender_other educ_hs_or_less educ_some_college educ_college educ_grad income_lt25k income_25_50k income_50_75k income_75_100k income_100kplus race_white race_black race_asian race_native race_other hispanic polviews_very_liberal polviews_liberal polviews_slight_liberal polviews_moderate polviews_slight_conserv polviews_conservative polviews_very_conserv"

local trust_vars "trust_strongly_disagree trust_somewhat_disagree trust_neither trust_somewhat_agree trust_strongly_agree"

local health_vars "cond_none cond_asthma cond_lung cond_heart cond_diabetes cond_kidney cond_rather_not_say"

/*------------------------------------------------------------------------------
    2. Create balance tables by domain
------------------------------------------------------------------------------*/

balance_table `prior_vars', ///
    group(arm_n) saving(output/tables/balance_prior_beliefs.tex) jointtest

balance_table `vacc_vars', ///
    group(arm_n) saving(output/tables/balance_vacc.tex) jointtest

balance_table `demo_vars', ///
    group(arm_n) saving(output/tables/balance_demographics.tex) jointtest

balance_table `trust_vars', ///
    group(arm_n) saving(output/tables/balance_trust.tex) jointtest

balance_table `health_vars', ///
    group(arm_n) saving(output/tables/balance_health.tex) jointtest

/*------------------------------------------------------------------------------
    3. Omnibus tests (combining all domains)
------------------------------------------------------------------------------*/

* All domains
local all_vars "`prior_vars' `vacc_vars' `demo_vars' `trust_vars' `health_vars'"
local nvars: word count `all_vars'

local i = 1
local est_names ""
foreach var of local all_vars {
    quietly regress `var' i.arm_n
    estimates store omni`i'
    local est_names "`est_names' omni`i'"
    local ++i
}

quietly suest `est_names', vce(robust)

local test_terms ""
forvalues j = 1/`nvars' {
    local test_terms "`test_terms' [omni`j'_mean]1.arm_n [omni`j'_mean]2.arm_n [omni`j'_mean]3.arm_n"
}

test `test_terms'
local omni_chi2 = r(chi2)
local omni_df = r(df)
local omni_p = r(p)

forvalues j = 1/`nvars' {
    capture estimates drop omni`j'
}

* Excluding demographics
local nodemo_vars "`prior_vars' `vacc_vars' `trust_vars' `health_vars'"
local nvars_nodemo: word count `nodemo_vars'

local i = 1
local est_names ""
foreach var of local nodemo_vars {
    quietly regress `var' i.arm_n
    estimates store omni_nd`i'
    local est_names "`est_names' omni_nd`i'"
    local ++i
}

quietly suest `est_names', vce(robust)

local test_terms ""
forvalues j = 1/`nvars_nodemo' {
    local test_terms "`test_terms' [omni_nd`j'_mean]1.arm_n [omni_nd`j'_mean]2.arm_n [omni_nd`j'_mean]3.arm_n"
}

test `test_terms'
local omni_nd_chi2 = r(chi2)
local omni_nd_df = r(df)
local omni_nd_p = r(p)

forvalues j = 1/`nvars_nodemo' {
    capture estimates drop omni_nd`j'
}

* Write omnibus results to file
capture file close fout
file open fout using "output/tables/balance_omnibus.tex", write replace

local omni_chi2_fmt: di %6.2f `omni_chi2'
local omni_p_fmt: di %5.4f `omni_p'
local omni_nd_chi2_fmt: di %6.2f `omni_nd_chi2'
local omni_nd_p_fmt: di %5.4f `omni_nd_p'

file write fout "Omnibus (all domains) & \multicolumn{4}{c}{\$\chi^2(`omni_df')=`omni_chi2_fmt'\$} & `omni_p_fmt' \\" _n
file write fout "Omnibus (excl. demographics) & \multicolumn{4}{c}{\$\chi^2(`omni_nd_df')=`omni_nd_chi2_fmt'\$} & `omni_nd_p_fmt'" _n

file close fout

capture log close
