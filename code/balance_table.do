/*==============================================================================
    Balance Table for Main Survey Sample

    Input:  derived/merged_main_pre.dta
    Output: output/tables/balance_table.tex (table body only, no headers/metadata)

    Creates balance table with treatment arm means and joint equality tests.
    Each row is a variable, each column is a treatment arm + p-value.

    Requires: code/ado/balance_table.ado

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "balance_table"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load merged data
------------------------------------------------------------------------------*/

use "derived/merged_main_pre.dta", clear
keep if main_final_sample==1 & pre_final_sample==1
count
di "Total merged observations: " r(N)

/*------------------------------------------------------------------------------
    2. Create indicator variables for balance table
------------------------------------------------------------------------------*/

* Prior belief: somewhat likely or more likely to experience SE with vaccine (>=5)
gen prior_vacc_likely = (prior_self_vacc >= 5) if ~missing(prior_self_vacc)
label var prior_vacc_likely "Prior belief: SE likely with vaccine"

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
    3. Generate balance table
------------------------------------------------------------------------------*/
# delimit ;
balance_table 
	prior_vacc_likely pre_no_intent pre_had_flu pre_had_covid 
	severe_flu_reaction severe_covid_reaction 
	has_condition 
	age_18_34 age_35_49 race_white hispanic income_lt50k
	trust_govt_high follow_doc_high college, 
	group(arm_n) saving(output/tables/balance_table.tex) jointtest
;
# delimit cr
capture log close
