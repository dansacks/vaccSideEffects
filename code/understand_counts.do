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

use "derived/prescreen_clean.dta" if final_sample==1, clear
keep if vacc_intent<=2 
keep prolific_pid 
save derived/_prescreen1, replace 


use "derived/prescreen_clean.dta" if ~is_preview, clear

keep if consent == 1
keep if failed_attn == 0
keep if first_attempt == 1
keep if vacc_intent <= 2
assert final_sample==1
count
keep prolific_pid
save derived/_prescreen2, replace 

append using derived/_prescreen1
duplicates tag, gen(dupe)
assert dupe == 1


/*------------------------------------------------------------------------------
    2. Load and prepare main data
------------------------------------------------------------------------------*/

use "derived/main_clean.dta" if ~is_preview, clear
assert _N==3651
merge m:1 prolific_pid using derived/_prescreen1, keep(3)
assert _N==3637
ss


/*------------------------------------------------------------------------------
    3. Merge datasets
------------------------------------------------------------------------------*/

* Merge prescreen into main (1:1 on prolific_pid)
merge m:1 prolific_pid using `prescreen', update keep(1 3 4 5)

* Create merge indicator
gen in_pre= (_merge >= 3)
label var in_pre "Observation in pre-screen and main data"
count if in_pre 
assert r(N) == 3637 
ss
assert _merge <= 3 

count if _merge == 3
assert r(N) == 3526
ss

* Final sample flag (main survey requires non-missing outcomes)
gen final_sample = (consent == 1 & failed_attn == 0 ///
    & _distchannel == "anonymous" & is_preview == 0 ///
		& n_missing == 0 & first_attempt == 1)

Main	Started (non-preview)	3651
Main	Linked to prescreen final	3637
Main	Consented	3635
Main	Passed attention check	3619
Main	Non-missing delta (valid posteriors)	3547
Main	First attempt only (final main sample)	3526
Main	Matches to demographics	3526
		
Followup	Started (non-preview)	3210
Followup	Linked to main final	3178
Followup	Passed attention check	3134
Followup	Has non-missing outcome	3074
Followup	First attempt only (final followup sample)	3046
Followup	Matches to demographics	3046


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

* Create main_sample flag: in both prescreen and main final samples
gen main_sample = (pre_final_sample==1 & main_final_sample==1)
label var main_sample "In final sample for main analysis (pre + main)"

count if main_sample==1
di "Main analysis sample: " r(N)

* Compress and save
compress
save "derived/merged_main_pre.dta", replace

di ""
di "=== MERGE COMPLETE ==="
di "Saved: derived/merged_main_pre.dta"

capture log close
