
clear all
global scriptname "heterogeneous_treatment_effects"
do "code/_config.do"
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    1. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

* Create heterogeneity splits
gen high_prior = prior_self_vacc >= 5
gen bad_experience = ~inlist(flu_vacc_reaction, 1, 2)
gen high_trust = trust_trial > 5
gen high_relevance = relevant_trial > 5
gen reliable_uni = (reliable_university == 3)

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

local keyvars arm_industry arm_academic arm_personal

qui forvalues r = 0/3 {
	count if flu_vacc_reaction == `r'
	noi di "reaction = `r', outcome= post_trial, N = `r(N)'"
	regress post_trial `keyvars' $controls if flu_vacc_reaction==`r', robust
	foreach v of local keyvars {
		noi di "   `v' : " _b[`v'] "(" _se[`v'] ")"
		
	}
}


qui forvalues r = 0/3 {
	count if flu_vacc_reaction == `r'
	noi di "reaction = `r', outcome= delta, N=`r(N)'"
	regress delta `keyvars' $controls if flu_vacc_reaction==`r', robust
	foreach v of local keyvars {
		noi di "   `v' : " _b[`v'] "(" _se[`v'] ")"
		
	}
}

/*  What do I want to show? 

Much of the belief updating is coming from people with no prior experience.
That is what you'd expect! 

Maybe more generally a slide on "who updates?"

1. people with moore pessimistic prior beliefs
2. people with no prior experience 
3. liberals 

is it true that belief updating implies intent effects? No.
	--> more belief updating when priors are worse --> far from margin 

*/
