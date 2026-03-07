/*==============================================================================
    Merge Prescreen and Main Survey Data

    Input:  data/prescreen_clean.dta
            data/main_clean.dta
    Output: data/merged_main_pre.dta

    Merges on prolific_pid. Renames conflicting variables with prefixes.

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "merge_prescreen_main"
do "code/_config.do"

** 0. temp follow up sample 
use "derived/followup_clean.dta" if final_sample , clear
rename attn_check attn_check_followup
rename final_sample followup_final_sample
drop is_preview
gen in_followup= 1
label var in_followup "=1 if in follow up sample"
tempfile followup
save `followup'


/*------------------------------------------------------------------------------
    1. Load and prepare prescreen data
------------------------------------------------------------------------------*/

use "derived/prescreen_clean.dta" if final_sample , clear


* Rename conflicting variables with pre_ prefix
rename start_date pre_start_date
rename end_date pre_end_date
rename duration_sec pre_duration_sec
rename progress pre_progress
rename consent pre_consent
rename final_sample pre_final_sample
rename incomplete pre_incomplete
rename failed_attn pre_failed_attn
rename pid_mismatch pre_pid_mismatch
rename duplicate_study_id pre_duplicate_study_id
rename comments pre_comments
rename vacc_intent pre_vacc_intent

* Rename missing indicators with pre_ prefix
rename had_prior_covid_vacc_miss pre_had_prior_covid_vacc_miss
rename had_prior_flu_vacc_miss pre_had_prior_flu_vacc_miss
rename covid_vacc_reaction_miss pre_covid_vacc_reaction_miss
rename flu_vacc_reaction_miss pre_flu_vacc_reaction_miss

* Keep the key variable unchanged
* prolific_pid is the merge key

* Save temporary file
gen in_pre = 1
label var in_pre "=1 if in prescreen data"
tempfile prescreen
save `prescreen'

di "Prescreen observations: " _N

/*------------------------------------------------------------------------------
    2. Load and prepare main data
------------------------------------------------------------------------------*/

use "derived/main_clean.dta" if final_sample, clear


* Rename conflicting variables with main_ prefix
rename start_date main_start_date
rename end_date main_end_date
rename duration_sec main_duration_sec
rename progress main_progress
rename consent main_consent
rename final_sample main_final_sample
rename incomplete main_incomplete
rename failed_attn main_failed_attn
rename pid_mismatch main_pid_mismatch
rename duplicate_study_id main_duplicate_study_id
rename comments main_comments

di "Main observations: " _N

/*------------------------------------------------------------------------------
    3. Merge datasets
------------------------------------------------------------------------------*/
gen in_main = 1
label var in_main "=1 if in main survey experiment"
* Merge prescreen into main (1:1 on study_id)
merge 1:1 study_id using `prescreen', update 
assert _merge <= 3 
drop _merge



** merge in follow up
merge 1:1 study_id using `followup', update
assert _merge <= 3 
drop _merge 

replace in_pre= 0 if missing(in_pre)
replace in_main = 0 if missing(in_main)
replace in_followup = 0 if missing(in_followup)


desc 
drop main_comments debrief_about _status prior_placebo_1-polviews_very_conserv
drop comments pre_comments 

export excel using derived/deid_all_data.xlsx, replace firstrow(variables)

capture log close
