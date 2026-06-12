
clear all
global scriptname "treatment_effects_demand"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Define controls
------------------------------------------------------------------------------*/

do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    2. Load data and prepare variables
------------------------------------------------------------------------------*/
import delimited using output/tables/debrief_classifications.csv,  clear 
tempfile classifications 
save `classifications'

use "derived/merged_all.dta", clear

merge 1:1 study_id using `classifications', assert(1 3)

assert _merge == 1 if missing(debrief_about) | debrief_about == "n/a"
assert _merge == 3 if ~missing(debrief_about) & debrief_about ~= "n/a"
drop _merge 
replace understood_intent=0 if missing(debrief_about)
keep if main_sample==1

* Create vaccination outcome (got vaccine or already had it)
gen vacc_post = got_flu_vacc == 1 if ~missing(got_flu_vacc)

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

/*------------------------------------------------------------------------------
    3. Generate treatment effects table using esttab
------------------------------------------------------------------------------*/

local keyvars arm_industry arm_academic arm_personal

eststo clear

qui foreach y in post_trial delta main_intent link_click vacc_post {
    regress `y' `keyvars' $controls if understood_intent==0, robust 
    estadd scalar cm = r(mean)
    eststo m_`y'
		
}



* Column titles for output
local coltitles mtitles("SE (trial)" "Delta" "Vacc Intent" "Link Click" "Vaccinated")

* .tex output: remove header, rules, and spacing for input into larger doc
esttab m_post_trial m_delta m_main_intent m_link_click m_vacc_post ///
    using output/tables/treatment_effects_demand.tex, ///
    b(%9.3f) se(%9.3f) ///
    keep(`keyvars') ///
    label nostar ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

* .md output: include column titles in header row
esttab m_post_trial m_delta m_main_intent m_link_click m_vacc_post ///
    using output/tables/treatment_effects_demand.md, ///
    b(%9.3f) se(%9.3f) ///
    keep(`keyvars') ///
    label nostar `coltitles' ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nonotes nonumbers

capture log close
