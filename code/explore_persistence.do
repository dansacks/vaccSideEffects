/*==============================================================================
    Persistence of Information Effects

    Input:  derived/merged_all.dta
    Output: output/tables/persistence_attrition.tex/.md
            output/tables/persistence_recall.tex/.md
            output/tables/persistence_adverse.tex/.md

    Goal: Provide evidence on persistence of information, specifically, means
          and treatment effects for:
          - Differential attrition
          - Recall of study participation and info provision details
          - Clinical trial adverse event rates

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "explore_persistence"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Define controls
------------------------------------------------------------------------------*/

do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    2. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear

* Sample indicators
gen se_sample = guess_vaccine ~= -99 & guess_placebo ~= -99 & ///
	in_followup & ~missing(guess_vaccine) & ~missing(guess_placebo)

egen recall_miss = rowmiss(recall_gavi recall_manufacturer recall_university)
gen invalid_miss = in_followup & inlist(recall_study, 1, 3) & recall_miss
gen recall_sample = in_followup & ~invalid_miss

* Recall outcome variables
gen yes_recall_study = 1.recall_study
gen yes_recall_manu = 1.recall_manufacturer
gen yes_recall_uni = 1.recall_university
gen yes_recall_gavi = 1.recall_gavi

* Adverse event rate guess
gen guess_delta = guess_vaccine - guess_placebo

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

local keyvars arm_industry arm_academic arm_personal

/*------------------------------------------------------------------------------
    3. Attrition table
------------------------------------------------------------------------------*/

eststo clear

foreach y in in_followup recall_sample se_sample {
    regress `y' `keyvars' $controls, robust
    sum `y' if arm_control==1
    estadd scalar cm = r(mean)
    eststo m_`y'
}

local coltitles mtitles("In Followup" "Recall Sample" "SE Sample")

esttab m_in_followup m_recall_sample m_se_sample ///
    using output/tables/persistence_attrition.tex, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

esttab m_in_followup m_recall_sample m_se_sample ///
    using output/tables/persistence_attrition.md, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar `coltitles' ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nonotes nonumbers

/*------------------------------------------------------------------------------
    4. Recall table
------------------------------------------------------------------------------*/

eststo clear

foreach y in yes_recall_study yes_recall_manu yes_recall_uni yes_recall_gavi {
    regress `y' `keyvars' $controls if recall_sample, robust
    sum `y' if arm_control==1 & recall_sample
    estadd scalar cm = r(mean)
    eststo m_`y'
}

local coltitles mtitles("Recall Study" "Recall Manu" "Recall Uni" "Recall Gavi")

esttab m_yes_recall_study m_yes_recall_manu m_yes_recall_uni m_yes_recall_gavi ///
    using output/tables/persistence_recall.tex, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

esttab m_yes_recall_study m_yes_recall_manu m_yes_recall_uni m_yes_recall_gavi ///
    using output/tables/persistence_recall.md, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar `coltitles' ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nonotes nonumbers

/*------------------------------------------------------------------------------
    5. Adverse event rates table
------------------------------------------------------------------------------*/

eststo clear

foreach y in guess_placebo placebo_correct guess_vaccine vaccine_correct guess_delta {
    regress `y' `keyvars' $controls if se_sample, robust
    sum `y' if arm_control==1 & se_sample
    estadd scalar cm = r(mean)
    eststo m_`y'
}

local coltitles mtitles("Placebo SE" "Placebo Correct" "Vaccine SE" "Vaccine Correct" "SE Delta")

esttab m_guess_placebo m_placebo_correct m_guess_vaccine m_vaccine_correct m_guess_delta ///
    using output/tables/persistence_adverse.tex, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

esttab m_guess_placebo m_placebo_correct m_guess_vaccine m_vaccine_correct m_guess_delta ///
    using output/tables/persistence_adverse.md, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar `coltitles' ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nonotes nonumbers

capture log close
