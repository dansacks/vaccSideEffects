/*==============================================================================
    Persistence of Information Effects

    Input:  derived/merged_all.dta
    Output: output/tables/persistence_attrition.tex
            output/tables/persistence_recall.tex
            output/tables/persistence_adverse.tex

    Goal: Provide evidence on persistence of information, specifically, means
          and treatment effects for:
          - Differential attrition [plus test of joint significance]
          - Recall of study participation and info provision details
          - Clinical trial adverse event rates

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "explore_persistence"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Define controls
------------------------------------------------------------------------------*/
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    2. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear

* Sample indicators
gen se_sample = guess_vaccine ~= -99 & guess_placebo ~= -99 & ///
	in_followup & ~missing(guess_vaccine) & ~missing(guess_placebo)

egen recall_miss = rowmiss(recall_gavi recall_manufacturer recall_university)
gen invalid_miss = in_followup & inlist(recall_study, 1, 3) & recall_miss
gen recall_sample = in_followup & ~invalid_miss

* Recall outcome variables
gen yes_recall_study = 1.recall_study
gen yes_recall_manu = 1.recall_manufacturer
gen yes_recall_uni = 1.recall_university
gen yes_recall_gavi = 1.recall_gavi

* Adverse event rate guess
gen guess_delta = guess_vaccine - guess_placebo

/*------------------------------------------------------------------------------
    3. Attrition table
------------------------------------------------------------------------------*/

local outcomes "in_followup recall_sample se_sample"
local n_outcomes : word count `outcomes'

matrix b_treat = J(3, `n_outcomes', .)
matrix se_treat = J(3, `n_outcomes', .)
matrix N_obs = J(1, `n_outcomes', .)
matrix ctrl_mean = J(1, `n_outcomes', .)
matrix pval_joint = J(1, `n_outcomes', .)

local col = 1
foreach outcome of local outcomes {
	di ""
	di "=== Attrition regression: `outcome' ==="

	reg `outcome' arm_industry arm_academic arm_personal $controls, robust

	matrix N_obs[1, `col'] = e(N)

	matrix b_treat[1, `col'] = _b[arm_industry]
	matrix b_treat[2, `col'] = _b[arm_academic]
	matrix b_treat[3, `col'] = _b[arm_personal]

	matrix se_treat[1, `col'] = _se[arm_industry]
	matrix se_treat[2, `col'] = _se[arm_academic]
	matrix se_treat[3, `col'] = _se[arm_personal]

	testparm arm_industry arm_academic arm_personal
	matrix pval_joint[1, `col'] = r(p)

	qui sum `outcome' if arm_control == 1
	matrix ctrl_mean[1, `col'] = r(mean)

	local ++col
}

* Write attrition table
capture file close fout
file open fout using "output/tables/persistence_attrition.tex", write replace

* Industry coefficient
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

* Academic coefficient
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

* Personal coefficient
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

* Joint test p-value
file write fout "Joint p-value  "
forvalues col = 1/`n_outcomes' {
	local p = pval_joint[1, `col']
	file write fout " & " %9.3f (`p')
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
file write fout _n

file close fout
di "=== Table saved to output/tables/persistence_attrition.tex ==="

/*------------------------------------------------------------------------------
    4. Recall table
------------------------------------------------------------------------------*/

local outcomes "yes_recall_study yes_recall_manu yes_recall_uni yes_recall_gavi"
local n_outcomes : word count `outcomes'

matrix b_treat = J(3, `n_outcomes', .)
matrix se_treat = J(3, `n_outcomes', .)
matrix N_obs = J(1, `n_outcomes', .)
matrix ctrl_mean = J(1, `n_outcomes', .)

local col = 1
foreach outcome of local outcomes {
	di ""
	di "=== Recall regression: `outcome' ==="

	reg `outcome' arm_industry arm_academic arm_personal $controls if recall_sample, robust

	matrix N_obs[1, `col'] = e(N)

	matrix b_treat[1, `col'] = _b[arm_industry]
	matrix b_treat[2, `col'] = _b[arm_academic]
	matrix b_treat[3, `col'] = _b[arm_personal]

	matrix se_treat[1, `col'] = _se[arm_industry]
	matrix se_treat[2, `col'] = _se[arm_academic]
	matrix se_treat[3, `col'] = _se[arm_personal]

	qui sum `outcome' if arm_control == 1 & recall_sample
	matrix ctrl_mean[1, `col'] = r(mean)

	local ++col
}

* Write recall table
capture file close fout
file open fout using "output/tables/persistence_recall.tex", write replace

* Industry coefficient
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

* Academic coefficient
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

* Personal coefficient
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
file write fout _n

file close fout
di "=== Table saved to output/tables/persistence_recall.tex ==="

/*------------------------------------------------------------------------------
    5. Adverse event rates table
------------------------------------------------------------------------------*/

local outcomes "guess_placebo placebo_correct guess_vaccine vaccine_correct guess_delta"
local n_outcomes : word count `outcomes'

matrix b_treat = J(3, `n_outcomes', .)
matrix se_treat = J(3, `n_outcomes', .)
matrix N_obs = J(1, `n_outcomes', .)
matrix ctrl_mean = J(1, `n_outcomes', .)

local col = 1
foreach outcome of local outcomes {
	di ""
	di "=== Adverse event regression: `outcome' ==="

	reg `outcome' arm_industry arm_academic arm_personal $controls if se_sample, robust

	matrix N_obs[1, `col'] = e(N)

	matrix b_treat[1, `col'] = _b[arm_industry]
	matrix b_treat[2, `col'] = _b[arm_academic]
	matrix b_treat[3, `col'] = _b[arm_personal]

	matrix se_treat[1, `col'] = _se[arm_industry]
	matrix se_treat[2, `col'] = _se[arm_academic]
	matrix se_treat[3, `col'] = _se[arm_personal]

	qui sum `outcome' if arm_control == 1 & se_sample
	matrix ctrl_mean[1, `col'] = r(mean)

	local ++col
}

* Write adverse event table
capture file close fout
file open fout using "output/tables/persistence_adverse.tex", write replace

* Industry coefficient
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

* Academic coefficient
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

* Personal coefficient
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
file write fout _n

file close fout
di "=== Table saved to output/tables/persistence_adverse.tex ==="

capture log close
