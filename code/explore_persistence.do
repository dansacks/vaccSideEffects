/*==============================================================================
    Treatment Effects Regressions

    Input:  data/merged_all.dta
    Output: XXX tbd 

		Goal: Provide evidence on persistence of information, specifically, means
			and treatment effects for:
			
			differential attrition [plus test of joint significance]
			Recall of study participation and info provision details
			
			Clinical trial adverse event rates
			
		
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
    2. Load data
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear


/*------------------------------------------------------------------------------
    3. Tests of differential attrition
------------------------------------------------------------------------------*/
gen se_sample = guess_vaccine ~= -99 & guess_placebo ~=-99 & ///
	in_followup & ~missing(guess_vaccine) & ~missing(guess_placebo)

egen recall_miss = rowmiss(recall_gavi recall_manufacturer recall_university)
gen invalid_miss = in_followup & inlist(recall_study, 1, 3) & recall_miss
gen recall_sample = in_followup & ~invalid_miss
 
reg in_followup i.arm_n $controls ,r 
testparm i.arm_n
reg recall_sample i.arm_n $controls ,r 
testparm i.arm_n
reg se_sample i.arm_n $controls ,r 
testparm i.arm_n

/*------------------------------------------------------------------------------
    4. Tests of recall
------------------------------------------------------------------------------*/

* recall study
gen yes_recall_study = 1.recall_study
gen yes_recall_manu = 1.recall_manufacturer
gen yes_recall_uni = 1.recall_university 
gen yes_recall_gavi = 1.recall_gavi 

reg yes_recall_study i.arm_n $controls if recall_sample, r
reg yes_recall_manu i.arm_n $controls if recall_sample, r
reg yes_recall_uni i.arm_n $controls if recall_sample, r
reg yes_recall_gavi i.arm_n $controls if recall_sample, r



/*------------------------------------------------------------------------------
    5. Remember side effect rates
------------------------------------------------------------------------------*/

gen guess_delta = guess_vaccine - guess_placebo

foreach y in guess_placebo placebo_correct guess_vaccine vaccine_correct guess_delta {
	reg `y' i.arm_n $controls if se_sample, r	
}




 

 
 
 