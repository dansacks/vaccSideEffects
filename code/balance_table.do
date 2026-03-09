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
keep if main_sample==1
count
di "Total merged observations: " r(N)

/*------------------------------------------------------------------------------
    2. Create indicator variables for balance table
------------------------------------------------------------------------------*/

* Prior belief: somewhat likely or more likely to experience SE with vaccine (>=5)
gen prior_vacc_likely = (prior_self_vacc >= 5) if ~missing(prior_self_vacc)
label var prior_vacc_likely "Adverse event at least likely if vaccinate"

* Do not intend to vaccinate (from prescreen, vacc_intent == 1)
gen pre_no_intent = (pre_vacc_intent == 1) if ~missing(pre_vacc_intent)
label var pre_no_intent "Do not intend to vaccinate"

* Previously had flu vaccine
foreach d in flu covid {
	
	gen no_prior_`d' = 0.`d'_vacc_reaction if ~missing(`d'_vacc_reaction)
	label var no_prior_`d' "No prior `d' vaccine" 
	
	gen no_react_`d' = 1.`d'_vacc_reaction if ~missing(`d'_vacc_reaction)
	label var no_react_`d' "No reaction remembered to `d' vaccine" 
	
	gen mild_react_`d' = 2.`d'_vacc_reaction if ~missing(`d'_vacc_reaction)
	label var mild_react_`d' "Mild reaction remembered to `d' vaccine" 
	
	gen severe_react_`d' = 3.`d'_vacc_reaction if ~missing(`d'_vacc_reaction)
	label var severe_react_`d' "Severe reaction remembered to `d' vaccine" 
}


* Has health condition (cond_none == 0, conditional on not missing)
gen has_condition = (cond_none == 0) if ~missing(cond_none)
label var has_condition "Has health condition"

* Age, race, ethnicity variables already created in clean_main.do
* Use existing variables from merged dataset (capture gen in case they don't exist)
capture gen age_18_34 = (age == 2) if ~missing(age) & age != $PREF_NOT_SAY
capture label var age_18_34 "Age 18--34"

capture gen age_35_49 = (age == 3) if ~missing(age) & age != $PREF_NOT_SAY
capture label var age_35_49 "Age 35--49"

capture gen age_50_64 = (age == 4) if ~missing(age) & age != $PREF_NOT_SAY
capture label var age_50_64 "Age 50--64"

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
	prior_vacc_likely pre_no_intent 
	
	no_prior_flu no_react_flu mild_react_flu severe_react_flu
	no_prior_covid severe_react_covid mild_react_covid severe_react_covid
	
	has_condition trust_govt_high follow_doc_high
	age_18_34 age_35_49 age_50_64 race_white hispanic income_lt50k
	college,
	group(arm_n) saving(output/tables/balance_table.tex) jointtest
	labels(Control Industry Academic Representative)
;
# delimit cr



/*------------------------------------------------------------------------------
    3. Generate balance tables for slides
------------------------------------------------------------------------------*/
# delimit ;
balance_table
	prior_vacc_likely pre_no_intent 
	no_prior_flu severe_react_flu no_prior_covid severe_react_covid 
		has_condition trust_govt_high follow_doc_high,
	group(arm_n) saving(output/tables/balance_table_slides.tex) jointtest
	labels(Control Industry Academic Representative)
;

balance_table
	age_18_34 age_35_49 age_50_64 race_white hispanic income_lt50k
	college,
	group(arm_n) saving(output/tables/balance_table_slides_demo.tex) jointtest
	labels(Control Industry Academic Representative)
;
# delimit cr
capture log close
