/*==============================================================================
    Treatment Effects on Trust and Relevance Perceptions

    Input:  derived/merged_all.dta
    Output: output/tables/trust_relevance.tex

    Estimates the effect of treatment arm on perceptions of the trial:
    - trust_trial:     Trust in trial information (0-10)   [all arms]
    - relevant_trial:  Relevance of trial information (0-10) [all arms]
    - trust_academic:  Trust in academic source (0-10)     [Academic, Representative only]
    - relevant_academic: Relevance of academic source (0-10) [Academic, Representative only]

    Columns 1-2 include all four arms with Control as the omitted category.
    Columns 3-4 restrict to Academic and Representative arms; Academic is the
    omitted category so only the Representative arm indicator is reported.

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "trust_relevance_effects"
do "code/_config.do"
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    1. Load data
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Representative"

/*------------------------------------------------------------------------------
    2. Columns 1-2: all arms, trust and relevance of trial
------------------------------------------------------------------------------*/

eststo clear

foreach y in trust_trial relevant_trial {
    regress `y' arm_industry arm_academic arm_personal $controls, robust
    sum `y' if arm_control == 1
    estadd scalar cm = r(mean)
    eststo m_`y'
}

/*------------------------------------------------------------------------------
    3. Columns 3-4: Academic and Representative arms only
       arm_personal = Representative indicator; Academic is base category
------------------------------------------------------------------------------*/

foreach y in trust_academic relevant_academic {
    regress `y' arm_personal $controls if arm_n >= 2, robust
    sum `y' if arm_n == 2   // academic arm mean as base
    estadd scalar cm = r(mean)
    eststo m_`y'
}

/*------------------------------------------------------------------------------
    4. Export table
------------------------------------------------------------------------------*/

esttab m_trust_trial m_relevant_trial m_trust_academic m_relevant_academic ///
    using output/tables/trust_relevance.tex, ///
    b(%9.3f) se(%9.3f) ///
    keep(arm_industry arm_academic arm_personal) ///
    label nostar ///
    stats(cm N, labels("Control/Academic mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

capture log close
