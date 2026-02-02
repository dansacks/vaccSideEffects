/*==============================================================================
		
		Validate polviews delta
		
		
    Input:  data/ (SPSS export from Qualtrics)
    Output: output/tables/ XXX 

		Validates the belief measure and political views by showing that, within
		polviews category, there is a high correlation between subjective beliefs
		and incentivized, objective beliefs, and between subjective beliefs and 
		obvious predictors (prior experiences)
		
    Created by Dan 
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
keep if main_sample==1


label var post_trial "Objective SE belief"

label var covid_react_none "No reaction to COVID vacc"
label var covid_react_mild "Mild reaction to COVID vacc"
label var covid_react_severe "Severe reaction to COVID vacc"

label var flu_react_none "No reaction to flu vacc"
label var flu_react_mild "Mild reaction to flu vacc"
label var flu_react_severe "Severe reaction to flu vacc"

foreach d in covid flu {
	foreach r in none mild severe {
		replace `d'_react_`r' = 0 if `d'_vacc_reaction == 0
	}
}

/*------------------------------------------------------------------------------
    2. Estimate
------------------------------------------------------------------------------*/

reg delta post_trial if inrange(polviews,4,7), r
eststo mc1

reg delta post_trial if polviews<=3, r
eststo ml1

reg delta post_trial flu_react_none flu_react_mild flu_react_severe ///
	covid_react_non covid_react_mild covid_react_severe if inrange(polviews,4,7), r
eststo mc2

reg delta post_trial flu_react_none flu_react_mild flu_react_severe ///
	covid_react_none covid_react_mild covid_react_severe if polviews<=3, r
eststo ml2 

* .md output: include column titles in header row

local coltitles mtitles("Delta, conservative" "Delta, liberal" "Delta, conservative" "Delta, liberal")

esttab mc1 ml1 mc2 ml2 ///
    using output/tables/delta_pols_validate.md, ///
    b(%9.3f) se(%9.3f) nocons ///
    label nostar `coltitles' ///
    stats(r2 N, labels("R-squared \$" "N") fmt(%9.2f %9.0fc)) ///
    fragment replace nonotes nonumbers  

