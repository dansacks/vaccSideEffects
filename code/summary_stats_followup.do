/*==============================================================================
    Summary Statistics: Follow-up Survey Data

    Input:  data/followup_clean.dta
    Output:
      - output/tables/stats_followup_continuous.csv
      - output/tables/stats_followup_categorical.csv

    Produces summary statistics for valid observations (final_sample == 1):
    - Continuous variables: mean, SD, percentiles
    - Categorical variables: frequency distribution

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "summary_stats_followup"
do "code/_config.do"

* Load cleaned data
use "derived/followup_clean.dta", clear

* Keep only valid observations
keep if final_sample == 1
count
local n_valid = r(N)

/*==============================================================================
    EXPORT CONTINUOUS VARIABLE STATISTICS TO CSV
==============================================================================*/

file open contcsv using "output/tables/stats_followup_continuous.csv", write replace
file write contcsv "variable,n,mean,sd,min,p50,max" _n

* Continuous variables
local cont_vars duration_sec guess_placebo guess_vaccine

foreach var of local cont_vars {
    summarize `var', detail
    file write contcsv "`var'," (r(N)) "," (r(mean)) "," (r(sd)) "," (r(min)) "," (r(p50)) "," (r(max)) _n
}

file close contcsv

/*==============================================================================
    EXPORT CATEGORICAL VARIABLE STATISTICS TO CSV
==============================================================================*/

file open catcsv using "output/tables/stats_followup_categorical.csv", write replace
file write catcsv "variable,value,n,pct" _n

* Helper program to write categorical stats
capture program drop write_cat_stats
program define write_cat_stats
    args varname

    quietly levelsof `varname', local(levels)
    quietly count if !mi(`varname')
    local n_nonmiss = r(N)

    foreach val of local levels {
        quietly count if `varname' == `val'
        local n = r(N)
        local pct = 100 * `n' / `n_nonmiss'
        file write catcsv "`varname',`val'," (`n') "," (`pct') _n
    }

    * Also write missing count if any
    quietly count if mi(`varname')
    if r(N) > 0 {
        local n = r(N)
        local pct = 100 * `n' / ($n_valid)
        file write catcsv "`varname',.,`n',`pct'" _n
    }
end

* Store n_valid as global for use in program
global n_valid = `n_valid'

* Loop over categorical variables
# delimit ;
local cat_vars
    consent first_attempt
    incomplete failed_attn pid_mismatch duplicate_pid is_preview
    pharmacy_factor price_compare use_coupons
    got_glp1 got_flu_vacc got_covid_vacc
    med_pharmacy_chain med_grocery med_independent med_mail_order
    med_online med_provider med_other med_none
    flu_why_already flu_why_side_effects flu_why_bad_flu flu_why_needles
    flu_why_time flu_why_location flu_why_cost flu_why_none
    recall_study recall_manufacturer recall_university recall_gavi
    found_trustworthy
    placebo_correct vaccine_correct
;
# delimit cr

foreach v of local cat_vars {
    write_cat_stats `v'
    tab `v'
}

file close catcsv
capture log close
