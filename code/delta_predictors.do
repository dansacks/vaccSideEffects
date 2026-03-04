/*==============================================================================
    Predictors of Side Effect Beliefs (Delta) in Control Group

    Input:  derived/merged_main_pre.dta
    Output: output/tables/delta_predictors.tex

    Regresses delta on covariate groups among control arm (arm_n==0).
    Columns:
    (1) Post-trial side effect estimate only
    (2) Vaccine experience (flu/covid reaction)
    (3) Institutional trust (trust_govt, follow_doctor)
    (4) All covariates combined

    Base categories: no prior vaccine (reactions), strongly disagree (trust/follow),
    do not intend to vaccinate (vacc intent).

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "delta_predictors"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load data
------------------------------------------------------------------------------*/

use "derived/merged_main_pre.dta", clear
keep if main_sample==1

/*------------------------------------------------------------------------------
    2. Create indicator variables with clean labels
       (base categories excluded; no factor variable notation needed)
------------------------------------------------------------------------------*/

* --- Flu vaccine reaction (base: no prior flu vaccine) ---
gen flu_rx_none   = (flu_vacc_reaction == 1) if !missing(flu_vacc_reaction)
gen flu_rx_mild   = (flu_vacc_reaction == 2) if !missing(flu_vacc_reaction)
gen flu_rx_severe = (flu_vacc_reaction == 3) if !missing(flu_vacc_reaction)
label var flu_rx_none   "Flu vacc: no reaction"
label var flu_rx_mild   "Flu vacc: mild reaction"
label var flu_rx_severe "Flu vacc: severe reaction"

* --- COVID vaccine reaction (base: no prior COVID vaccine) ---
gen cov_rx_none   = (covid_vacc_reaction == 1) if !missing(covid_vacc_reaction)
gen cov_rx_mild   = (covid_vacc_reaction == 2) if !missing(covid_vacc_reaction)
gen cov_rx_severe = (covid_vacc_reaction == 3) if !missing(covid_vacc_reaction)
label var cov_rx_none   "COVID vacc: no reaction"
label var cov_rx_mild   "COVID vacc: mild reaction"
label var cov_rx_severe "COVID vacc: severe reaction"

* --- Trust in government (base: strongly disagree) ---
gen tgov_sm_dis  = (trust_govt == 2) if !missing(trust_govt)
gen tgov_neither = (trust_govt == 3) if !missing(trust_govt)
gen tgov_sm_agr  = (trust_govt == 4) if !missing(trust_govt)
gen tgov_st_agr  = (trust_govt == 5) if !missing(trust_govt)
label var tgov_sm_dis  "Trust govt: somewhat disagree"
label var tgov_neither "Trust govt: neither"
label var tgov_sm_agr  "Trust govt: somewhat agree"
label var tgov_st_agr  "Trust govt: strongly agree"

* --- Follow doctor advice (base: strongly disagree) ---
gen fdoc_sm_dis  = (follow_doctor == 2) if !missing(follow_doctor)
gen fdoc_neither = (follow_doctor == 3) if !missing(follow_doctor)
gen fdoc_sm_agr  = (follow_doctor == 4) if !missing(follow_doctor)
gen fdoc_st_agr  = (follow_doctor == 5) if !missing(follow_doctor)
label var fdoc_sm_dis  "Follow doctor: somewhat disagree"
label var fdoc_neither "Follow doctor: neither"
label var fdoc_sm_agr  "Follow doctor: somewhat agree"
label var fdoc_st_agr  "Follow doctor: strongly agree"

* --- Vaccination intent (base: do not intend) ---
gen intent_maybe = (pre_vacc_intent == 2) if !missing(pre_vacc_intent)
label var intent_maybe "Vacc intent: may or may not"

label var post_trial "Post-trial SE estimate"

/*------------------------------------------------------------------------------
    3. Define variable groups for regressions
------------------------------------------------------------------------------*/

local flu_vars   flu_rx_none flu_rx_mild flu_rx_severe
local cov_vars   cov_rx_none cov_rx_mild cov_rx_severe
local trust_vars tgov_sm_dis tgov_neither tgov_sm_agr tgov_st_agr
local follow_vars fdoc_sm_dis fdoc_neither fdoc_sm_agr fdoc_st_agr

/*------------------------------------------------------------------------------
    4. Run regressions
------------------------------------------------------------------------------*/

eststo clear

* Column 1: post-trial SE estimate only
regress delta post_trial if arm_n==0, robust
eststo m1

* Column 2: vaccine experience
regress delta `flu_vars' `cov_vars' if arm_n==0, robust
eststo m2

* Column 3: institutional trust
regress delta `trust_vars' `follow_vars' if arm_n==0, robust
eststo m3

* Column 4: full model
regress delta post_trial `flu_vars' `cov_vars' ///
    `trust_vars' `follow_vars' intent_maybe if arm_n==0, robust
eststo m4

/*------------------------------------------------------------------------------
    5. Export table
------------------------------------------------------------------------------*/

esttab m1 m2 m3 m4 using output/tables/delta_predictors.tex, ///
    b(%9.3f) se(%9.3f) ///
    label nostar drop(_cons) ///
    stats(N, labels("N") fmt(%9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

capture log close
