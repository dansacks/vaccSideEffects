/*==============================================================================
    Simple power calculations 
==============================================================================*/

clear all
global scriptname "expost_power"
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


* Create vaccination outcome (got vaccine or already had it)
gen vacc_post = got_flu_vacc == 1 if ~missing(got_flu_vacc)


* get residual mse
reg vacc_post $controls if arm_n ==0
local rmse = e(rmse) 
di e(rmse)

power twomeans 0, diff(`=0.031/`rmse'') n1(750)
power twomeans 0, diff(`=0.031/`rmse'')
power twomeans 0, diff(`=0.024/`rmse'')

capture log close
