/*==============================================================================
    Treatment Effects Regressions

    Input:  derived/merged_all.dta
    Output: output/tables/treatment_effects.tex

    Estimates treatment effects of information source on:
    - post_trial: Post-trial side effect estimate
    - delta: Posterior difference (vacc - novacc)
    - main_maybe: Binary vaccination intention
    - link_click: Any link clicked
    - vacc_post: Got flu vaccine or already had it (followup)

    Requires: code/ado/regression_table.ado

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "treatment_effects"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Define controls
------------------------------------------------------------------------------*/

do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    2. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear

* Create link_click if not already present (max of link1-4)
capture confirm variable link_click
if _rc {
    egen link_click = rowmax(link1_clicked link2_clicked link3_clicked link4_clicked)
    label var link_click "Any link clicked"
}

* Convert -99 (prefer not to say) to missing for categorical variables
foreach var in age gender education income race ethnicity {
    replace `var' = . if `var' == -99
}

* Create vaccination outcome (got vaccine or already had it)
gen vacc_post = got_flu_vacc == 1 | flu_why_already == 1 if ~missing(got_flu_vacc)

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

/*------------------------------------------------------------------------------
    3. Generate treatment effects table
------------------------------------------------------------------------------*/

regression_table post_trial delta main_maybe link_click vacc_post, ///
    keyvars(arm_industry arm_academic arm_personal) ///
    controls($controls) saving(output/tables/treatment_effects.tex)

capture log close
