
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

label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

reg main_maybe arm_industry arm_academic arm_personal $controls, r
sum main_maybe if arm_control==1
estadd scalar cm = r(mean)
eststo m_main_maybe


reg delta arm_industry arm_academic arm_personal $controls, r
sum delta if arm_control==1
estadd scalar cm = r(mean)
eststo m_delta


esttab m_delta m_main_maybe using output/tables/esttab_example.tex, b(%9.3f) se(%9.3f) ///
	keep(arm_industry arm_academic arm_personal) /// 
	label nostar ///
	stats(cm N, labels("Control mean" "Sample size") fmt(%5.2f  %4.0fc)) ///
	fragment replace  nomtitles nonotes
	
	
esttab m_delta m_main_maybe using output/tables/esttab_example.md, b(%9.3f) se(%9.3f) ///
	keep(arm_industry arm_academic arm_personal) /// 
	label nostar ///
	stats(cm N, labels("Control mean" "Sample size") fmt(%5.2f  %4.0fc)) ///
	fragment replace nomtitles nonotes