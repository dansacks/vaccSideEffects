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

/*------------------------------------------------------------------------------
    1. Load and prepare prescreen data
------------------------------------------------------------------------------*/

use "data/prescreen_clean.dta" if quality_sample , clear


* Rename conflicting variables with pre_ prefix
rename response_id pre_response_id
rename prolific_id_entered pre_prolific_id_entered
rename start_date pre_start_date
rename end_date pre_end_date
rename duration_sec pre_duration_sec
rename progress pre_progress
rename consent pre_consent
rename final_sample pre_final_sample
rename incomplete pre_incomplete
rename failed_attn pre_failed_attn
rename pid_mismatch pre_pid_mismatch
rename duplicate_pid pre_duplicate_pid
rename comments pre_comments
rename vacc_intent pre_vacc_intent_pre

* Keep the key variable unchanged
* prolific_pid is the merge key

* Save temporary file
tempfile prescreen
save `prescreen'

di "Prescreen observations: " _N

/*------------------------------------------------------------------------------
    2. Load and prepare main data
------------------------------------------------------------------------------*/

use "data/main_clean.dta" if quality_sample, clear


* Rename conflicting variables with main_ prefix
rename response_id main_response_id
rename prolific_id_entered main_prolific_id_entered
rename start_date main_start_date
rename end_date main_end_date
rename duration_sec main_duration_sec
rename progress main_progress
rename consent main_consent
rename final_sample main_final_sample
rename incomplete main_incomplete
rename failed_attn main_failed_attn
rename pid_mismatch main_pid_mismatch
rename duplicate_pid main_duplicate_pid
rename comments main_comments

* Rename vacc_intentions to distinguish from prescreen's flu_vax_intent
rename vacc_intent main_vacc_intent
label var main_vacc_intent "Main survey: flu vaccine intentions"

* Update maybe variable name for clarity
rename maybe main_maybe
label var main_maybe "Main survey: intends/already got vaccine"

di "Main observations: " _N

/*------------------------------------------------------------------------------
    3. Merge datasets
------------------------------------------------------------------------------*/

* Merge prescreen into main (1:1 on prolific_pid)
merge 1:1 prolific_pid using `prescreen', update keep(1 3 4 5)
assert _merge <= 3 


* Create merge indicator
gen in_pre= (_merge == 3)
label var in_pre "Observation in pre-screen and main data"

* Summary
di ""
di "=== MERGE SUMMARY ==="
count if _merge == 1
di "In main only (not in prescreen): " r(N)
count if _merge == 2
di "In prescreen only (not in main): " r(N)
count if _merge == 3
di "In both: " r(N)

* List observations in main only (should be none - investigate if any exist)
count if _merge == 1
if r(N) > 0 {
    di ""
    di "=== WARNING: " r(N) " observations in main but not prescreen ==="
    di "Exporting to output/logs/main_only_observations.csv"
    preserve
    keep if _merge == 1
    keep prolific_pid main_response_id main_start_date main_consent arm_n
    export delimited using "output/logs/main_only_observations.csv", replace
    restore
}



/*------------------------------------------------------------------------------
    4. save
------------------------------------------------------------------------------*/

* Variable count
desc, short
di "Total variables: " r(k)

* Drop merge indicator
drop _merge

* Compress and save
compress
save "data/merged_main_pre.dta", replace

di ""
di "=== MERGE COMPLETE ==="
di "Saved: data/merged_main_pre.dta"

capture log close
