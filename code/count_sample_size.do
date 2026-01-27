/*==============================================================================
    Count Sample Sizes at Various Inclusion Criteria

    Input:  derived/prescreen_clean.dta
            derived/main_clean.dta
            derived/followup_clean.dta
            derived/prolific_demographics_*.dta
    Output: output/tables/counts.csv

    Counts sample sizes as observations pass through sequential filters.
    Also counts matches to Prolific demographics (after final sample).

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "count_sample_size"
do "code/_config.do"


/*------------------------------------------------------------------------------
    1. Counts for pre-screen

    Sequential filters:
    1. started prescreen (# non preview survey attempt)
    2. consented
    3. passed prescreen attention check
    4. first attempt only
    5. hesitant (vacc_intent is "don't intend" or "may or may not", i.e. <= 2)
    + matches to demographics (not an inclusion criterion)
------------------------------------------------------------------------------*/

use "derived/prescreen_clean.dta" if ~is_preview, clear

capture file close fout
file open fout using "output/tables/counts.csv", write replace
file write fout "Survey,Condition,Count" _n
file write fout "Prescreen,Started (non-preview),`=_N'" _n

* Count after each sequential filter
keep if consent == 1
local n_consent = _N
file write fout "Prescreen,Consented,`=_N'" _n

keep if failed_attn == 0
local n_attn = _N
file write fout "Prescreen,Passed attention check,`=_N'" _n

keep if first_attempt == 1
local n_first = _N
file write fout "Prescreen,First attempt only,`=_N'" _n

keep if vacc_intent <= 2
local n_hesitant = _N
file write fout "Prescreen,Hesitant (final prescreen sample),`=_N'" _n

* Save prescreen final sample PIDs for linking
preserve
keep prolific_pid
tempfile prescreen_final
save `prescreen_final'
restore

* Count matches to demographics
merge m:1 prolific_pid using "derived/prolific_demographics_prescreen.dta", keep(1 3) keepusing(prolific_pid)
count if _merge == 3
local n_demog = r(N)
file write fout "Prescreen,Matches to demographics,`n_demog'" _n
drop _merge

di ""
di "=== PRESCREEN SUMMARY ==="
di "Started (non-preview): `n_started'"
di "Consented: `n_consent'"
di "Passed attention: `n_attn'"
di "First attempt: `n_first'"
di "Hesitant (final): `n_hesitant'"
di "Matches to demographics: `n_demog'"

/*------------------------------------------------------------------------------
    2. Counts for main survey

    Sequential filters:
    1. started (# non preview survey attempt)
    2. linked to the final set from prescreen (hesitant + pass all other checks)
    3. consented
    4. passed attention check in main
    5. non-missing value of delta (and no -99 in posterior_vacc, posterior_novacc)
    6. first attempt only - this is the main survey sample
    + matches to demographics (not an inclusion criterion)
------------------------------------------------------------------------------*/

use "derived/main_clean.dta" if ~is_preview, clear

file write fout _n
file write fout "Main,Started (non-preview),`=_N'" _n
local n_started = _N

* Merge with prescreen final sample
merge m:1 prolific_pid using `prescreen_final', keep(1 3)
keep if _merge == 3
drop _merge
local n_linked = _N
coun
file write fout "Main,Linked to prescreen final,`=_N'" _n

keep if consent == 1
local n_consent = _N
coun
file write fout "Main,Consented,`=_N'" _n

keep if failed_attn == 0
local n_attn = _N
coun
file write fout "Main,Passed attention check,`=_N'" _n

* Non-missing delta and no -99 values in posteriors
keep if ~missing(delta) & posterior_vacc != -99 & posterior_novacc != -99  ///
	& ~missing(post_trial)
local n_outcome = _N
count 
file write fout "Main,Non-missing delta (valid posteriors),`=_N'" _n

keep if first_attempt == 1
local n_first = _N
count 
file write fout "Main,First attempt only (final main sample),`=_N'" _n

* Save main final sample PIDs for linking
preserve
keep prolific_pid
tempfile main_final
save `main_final'
restore

* Combine main and main_morepay demographics for matching
preserve
use "derived/prolific_demographics_main.dta", clear
append using "derived/prolific_demographics_main_morepay.dta"
duplicates drop prolific_pid, force
tempfile main_demog_combined
save `main_demog_combined'
restore

* Count matches to demographics
merge m:1 prolific_pid using `main_demog_combined', keep(1 3) keepusing(prolific_pid)
count if _merge == 3
local n_demog = r(N)
file write fout "Main,Matches to demographics,`n_demog'" _n
drop _merge

di ""
di "=== MAIN SURVEY SUMMARY ==="
di "Started (non-preview): `n_started'"
di "Linked to prescreen: `n_linked'"
di "Consented: `n_consent'"
di "Passed attention: `n_attn'"
di "Non-missing delta: `n_outcome'"
di "First attempt (final): `n_first'"
di "Matches to demographics: `n_demog'"

/*------------------------------------------------------------------------------
    3. Counts for followup survey

    Sequential filters:
    1. started (# non preview attempt)
    2. linked to the final set from main survey
    3. passed attention check in follow up
    4. has non-missing outcome (got_flu_vacc)
    5. first attempt only
    + matches to demographics (not an inclusion criterion)
------------------------------------------------------------------------------*/

use "derived/followup_clean.dta" if ~is_preview, clear

file write fout _n
file write fout "Followup,Started (non-preview),`=_N'" _n
local n_started = _N

* Merge with main final sample
merge m:1 prolific_pid using `main_final', keep(1 3)
keep if _merge == 3
drop _merge
local n_linked = _N
file write fout "Followup,Linked to main final,`=_N'" _n

keep if failed_attn == 0
local n_attn = _N
file write fout "Followup,Passed attention check,`=_N'" _n

keep if ~missing(got_flu_vacc)
local n_outcome = _N
file write fout "Followup,Has non-missing outcome,`=_N'" _n

keep if first_attempt == 1
local n_first = _N
file write fout "Followup,First attempt only (final followup sample),`=_N'" _n

* Count matches to demographics
merge m:1 prolific_pid using "derived/prolific_demographics_followup.dta", keep(1 3) keepusing(prolific_pid)
count if _merge == 3
local n_demog = r(N)
file write fout "Followup,Matches to demographics,`n_demog'" _n
drop _merge

di ""
di "=== FOLLOWUP SUMMARY ==="
di "Started (non-preview): `n_started'"
di "Linked to main: `n_linked'"
di "Passed attention: `n_attn'"
di "Non-missing outcome: `n_outcome'"
di "First attempt (final): `n_first'"
di "Matches to demographics: `n_demog'"

file close fout

di ""
di "=== SAMPLE SIZE COUNTS COMPLETE ==="
di "Saved: output/tables/counts.csv"

capture log close
