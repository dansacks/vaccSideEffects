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

use "data/followup_clean.dta" if quality_sample , clear
rename attn_check attn_check_followup
drop quality_sample is_preview

tempfile followup
save `followup'

use "data/merged_main_pre", clear
assert quality_sample 


merge 1:1 prolific_pid using `followup', update assert(1 2 3) keep(1 3)

tab _merge
gen in_followup = _merge == 3
drop _merge
label var in_followup "Observation in main and followup"


save "data/merged_all", replace 