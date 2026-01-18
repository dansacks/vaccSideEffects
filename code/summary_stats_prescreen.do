/*==============================================================================
    Summary Statistics: Prescreen Data

    Input:  data/prescreen_clean.dta
    Output:
      - output/stats_continuous.csv (for Python codebook builder)
      - output/stats_categorical.csv (for Python codebook builder)
      - output/prescreen_summary_stats.txt (human-readable log)

    Produces summary statistics for valid observations (final_sample == 1):
    - Continuous variables: mean, SD, percentiles
    - Categorical variables: frequency distribution

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "summary_stats_prescreen"
do "code/_config.do"

* Load cleaned data
use "data/prescreen_clean.dta", clear

* Keep only valid observations
keep if final_sample == 1
count
local n_valid = r(N) 

/*==============================================================================
    EXPORT CONTINUOUS VARIABLE STATISTICS TO CSV
==============================================================================*/

file open contcsv using "output/tables/stats_continuous.csv", write replace
file write contcsv "variable,n,mean,sd,min,p50,max" _n

* Duration (only continuous variable with meaningful stats in final sample)
summarize duration_sec, detail
file write contcsv "duration_sec," (r(N)) "," (r(mean)) "," (r(sd)) "," (r(min)) "," (r(p50)) "," (r(max)) _n

file close contcsv

/*==============================================================================
    EXPORT CATEGORICAL VARIABLE STATISTICS TO CSV
==============================================================================*/

file open catcsv using "output/tables/stats_categorical.csv", write replace
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


* loop over variables, writing out stats
# delimit ;
local vars 
	flu_vacc_lastyear prior_vaccines vacc_intent had_prior_covid had_prior_covid 
	had_prior_flu covid_reaction flu_reaction
	cond_none cond_asthma cond_diabetes cond_heart cond_lung cond_kidney cond_rather_not_say
	has_insurance trust_govt trust_govt_prior follow_doctor
	info_source_main source_doctor source_sm source_podcasts source_cdc source_news source_none
	info_doctor info_sm info_podcasts info_cdc info_news info_university
	reliable_doctor reliable_sm reliable_podcasts reliable_cdc reliable_news reliable_university
	incomplete pid_mismatch duplicate_pid
;
# delimit cr  
	
foreach v of local vars {
  write_cat_stats `v'
	tab `v'
}


file close catcsv
capture log close 
