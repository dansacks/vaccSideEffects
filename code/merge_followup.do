/*==============================================================================
    Merge folloup data with combined prescreen and main data
    Input:  data/followup_clean.dta
            data/merged_main_pre.dta
    Output: data/merged_all.dta

    Merges on prolific_pid. 

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "merge_followup"
do "code/_config.do"

use "derived/followup_clean.dta" if final_sample , clear
rename attn_check attn_check_followup
rename final_sample followup_final_sample
drop is_preview

tempfile followup
save `followup'

use "derived/merged_main_pre", clear
* Note: final_sample was renamed to main_final_sample in merge_prescreen_main.do
assert main_final_sample 


merge 1:1 study_id using `followup', update assert(1 2 3) keep(1 3)

tab _merge
gen in_followup = _merge == 3
drop _merge
label var in_followup "Observation in main and followup"

* Create followup_sample flag: in all three final samples and merged
gen followup_sample = (main_sample==1 & in_followup==1 & followup_final_sample==1)
label var followup_sample "In final sample for followup analysis (pre + main + followup)"

count if followup_sample==1
di "Followup analysis sample: " r(N)

save "derived/merged_all", replace 
