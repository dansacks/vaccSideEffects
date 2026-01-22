/*==============================================================================
    Treatment Effects Regressions

    Input:  data/merged_all.dta
    Output: output/tables/treatment_effects.tex

    Estimates treatment effects of information source on:
    - post_trial: Post-trial side effect estimate
    - delta: Posterior difference (vacc - novacc)
    - main_maybe: Binary vaccination intention
    - link_click: Any link clicked
    - got_flu_vacc: Got flu vaccine (followup)

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "treatment_effects"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Define controls
------------------------------------------------------------------------------*/

* Prior beliefs from main survey
global prior_beliefs "i.prior_self_placebo i.prior_self_vacc"


* Vaccine experiences from prescreen
global vacc_experience "had_prior_covid_vacc had_prior_flu_vacc i.covid_vacc_reaction i.flu_vacc_reaction"


* Demographics from main survey
global demographics "i.age i.gender i.education i.income i.race i.ethnicity i.polviews"

* All controls combined
global controls "$prior_beliefs i.pre_vacc_intent $vacc_experience $demographics i.trust_govt cond_*"



/*------------------------------------------------------------------------------
    2. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear

* Create link_click if not already present (max of link1-4)
capture confirm variable link_click
if _rc {
    egen link_click = rowmax(link1_clicked link2_clicked link3_clicked link4_clicked)
    label var link_click "Any link clicked"
}

* Convert -99 (prefer not to say) to missing for categorical variables
foreach var in age gender education income race ethnicity {
    replace `var' = . if `var' == -99
}

* Treatment indicators (control is omitted category)
* arm_industry, arm_academic, arm_personal already exist

/*------------------------------------------------------------------------------
    3. Run regressions and store results
------------------------------------------------------------------------------*/
gen vacc_post = got_flu_vacc ==1 | flu_why_already == 1 if ~missing(got_flu_vacc)

local outcomes "post_trial delta main_maybe link_click vacc_post"
local n_outcomes : word count `outcomes'

* Initialize matrices for results
matrix b_treat = J(3, `n_outcomes', .)
matrix se_treat = J(3, `n_outcomes', .)
matrix N_obs = J(1, `n_outcomes', .)
matrix R2 = J(1, `n_outcomes', .)

local col = 1
foreach outcome of local outcomes {
    di ""
    di "=== Regression: `outcome' ==="

    * Run regression
    reg `outcome' arm_industry arm_academic arm_personal $controls, robust

    * Store sample size and R-squared
    matrix N_obs[1, `col'] = e(N)
    matrix R2[1, `col'] = e(r2)

    * Store coefficients and standard errors for treatment arms
    matrix b_treat[1, `col'] = _b[arm_industry]
    matrix b_treat[2, `col'] = _b[arm_academic]
    matrix b_treat[3, `col'] = _b[arm_personal]

    matrix se_treat[1, `col'] = _se[arm_industry]
    matrix se_treat[2, `col'] = _se[arm_academic]
    matrix se_treat[3, `col'] = _se[arm_personal]

    local ++col
}

/*------------------------------------------------------------------------------
    4. Calculate control group means
------------------------------------------------------------------------------*/

matrix ctrl_mean = J(1, `n_outcomes', .)
local col = 1
foreach outcome of local outcomes {
    qui sum `outcome' if arm_control == 1
    matrix ctrl_mean[1, `col'] = r(mean)
    local ++col
}

/*------------------------------------------------------------------------------
    5. Output results to tex file
------------------------------------------------------------------------------*/

capture file close fout
file open fout using "output/tables/treatment_effects.tex", write replace

* Industry arm coefficient
file write fout "Industry       "
forvalues col = 1/`n_outcomes' {
    local b = b_treat[1, `col']
    file write fout " & " %9.3f (`b')
}
file write fout " \\" _n

* Industry SE
file write fout "               "
forvalues col = 1/`n_outcomes' {
    local se = se_treat[1, `col']
    file write fout " & (" %7.3f (`se') ")"
}
file write fout " \\" _n

* Academic arm coefficient
file write fout "Academic       "
forvalues col = 1/`n_outcomes' {
    local b = b_treat[2, `col']
    file write fout " & " %9.3f (`b')
}
file write fout " \\" _n

* Academic SE
file write fout "               "
forvalues col = 1/`n_outcomes' {
    local se = se_treat[2, `col']
    file write fout " & (" %7.3f (`se') ")"
}
file write fout " \\" _n

* Personal arm coefficient
file write fout "Personal       "
forvalues col = 1/`n_outcomes' {
    local b = b_treat[3, `col']
    file write fout " & " %9.3f (`b')
}
file write fout " \\" _n

* Personal SE
file write fout "               "
forvalues col = 1/`n_outcomes' {
    local se = se_treat[3, `col']
    file write fout " & (" %7.3f (`se') ")"
}
file write fout " \\" _n

* Control mean
file write fout "Control mean   "
forvalues col = 1/`n_outcomes' {
    local mean = ctrl_mean[1, `col']
    file write fout " & " %9.3f (`mean')
}
file write fout " \\" _n

* N
file write fout "N              "
forvalues col = 1/`n_outcomes' {
    local n = N_obs[1, `col']
    file write fout " & " %9.0fc (`n')
}
file write fout " \\" _n

* R-squared
file write fout "R-squared      "
forvalues col = 1/`n_outcomes' {
    local r2 = R2[1, `col']
    file write fout " & " %9.3f (`r2')
}
file write fout _n

file close fout

di ""
di "=== Table saved to output/tables/treatment_effects.tex ==="

capture log close
