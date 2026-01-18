/*==============================================================================
		Count sample sizes at various inclusion criteria
    Input:  data/prescreen_clean
						data/main_clean.dta
            data/followup_clean.dta
    Output: data/counts.csv

    Created by Dan 
==============================================================================*/

clear all
global scriptname "merge_prescreen_main"
do "code/_config.do"


/*------------------------------------------------------------------------------
    1. Counts for pre-screen
------------------------------------------------------------------------------*/


use data/prescreen_clean if ~is_preview, clear 

gen started  = 1
gen attention = failed_attn == 0 
gen single = duplicate_pid == 0
gen hesitant = vacc_intent <= 2 

capture file close fout
file open fout using "output/tables/counts.csv", write replace
file write fout "Condition, count" _n
file write fout "Prescreen survey" _n
foreach cond in started consent attention single hesitant {
	keep if `cond'
	
	file write fout "`cond', `=_N'" _n
}


keep prolific_pid 
tempfile prescreen
save `prescreen'

/*------------------------------------------------------------------------------
    2. Counts for main
------------------------------------------------------------------------------*/
use data/main_clean if ~is_preview, clear 
merge m:1 prolific_pid using `prescreen', keep(3) 

gen started = 1
gen attention = failed_attn == 0 
gen single = duplicate_pid == 0
gen outcome = n_missing == 0 


file write fout _n
file write fout "Main survey" _n
foreach cond in started consent attention outcome single {
	keep if `cond'
	
	file write fout "`cond', `=_N'" _n
}

keep prolific_pid
tempfile main_pre  
save `main_pre'


/*------------------------------------------------------------------------------
    3. Counts for followup
------------------------------------------------------------------------------*/
use data/followup_clean if ~is_preview, clear 
merge m:1 prolific_pid using `main_pre', keep(3)

gen started = 1
gen attention = failed_attn == 0 
gen single = duplicate_pid == 0
gen outcome = ~missing(got_flu_vacc)


file write fout _n
file write fout "Followup survey" _n
foreach cond in started consent attention outcome single {
	keep if `cond'
	
	file write fout "`cond', `=_N'" _n
}


file close fout


