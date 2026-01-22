/*==============================================================================
    Persistence of Information Effects

    Input:  derived/merged_all.dta
    Output: output/tables/persistence_attrition.tex
            output/tables/persistence_recall.tex
            output/tables/persistence_adverse.tex

    Goal: Provide evidence on persistence of information, specifically, means
          and treatment effects for:
          - Differential attrition
          - Recall of study participation and info provision details
          - Clinical trial adverse event rates

    Requires: code/ado/regression_table.ado

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

/*------------------------------------------------------------------------------
    3. Attrition table
------------------------------------------------------------------------------*/

regression_table in_followup recall_sample se_sample, ///
    keyvars(arm_industry arm_academic arm_personal) ///
    controls($controls) saving(output/tables/persistence_attrition.tex)

/*------------------------------------------------------------------------------
    4. Recall table
------------------------------------------------------------------------------*/

regression_table yes_recall_study yes_recall_manu yes_recall_uni yes_recall_gavi ///
    if recall_sample, ///
    keyvars(arm_industry arm_academic arm_personal) ///
    controls($controls) saving(output/tables/persistence_recall.tex)

/*------------------------------------------------------------------------------
    5. Adverse event rates table
------------------------------------------------------------------------------*/

regression_table guess_placebo placebo_correct guess_vaccine vaccine_correct guess_delta ///
    if se_sample, ///
    keyvars(arm_industry arm_academic arm_personal) ///
    controls($controls) saving(output/tables/persistence_adverse.tex)

capture log close
