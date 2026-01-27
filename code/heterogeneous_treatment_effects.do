/*==============================================================================
    Heterogeneous Treatment Effects Regressions

    Input:  derived/merged_all.dta
    Output: output/tables/het_*.tex, output/tables/het_*.md

    Estimates treatment effects by subgroup splits:
    - low_prior: Prior SE expectation < 5 (somewhat likely)
    - good_experience: Good prior flu vaccine reaction
    - high_trust: Trust in clinical trial > 5 (median)
    - high_relevance: Trial relevance > 5 (median)

    Each table has 4 columns:
    - post_trial (split=0), post_trial (split=1)
    - delta (split=0), delta (split=1)

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "heterogeneous_treatment_effects"
do "code/_config.do"
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    1. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

* Create heterogeneity splits
gen high_prior = prior_self_vacc >= 5
gen bad_experience = ~inlist(flu_vacc_reaction, 1, 2)
gen high_trust = trust_trial > 5
gen high_relevance = relevant_trial > 5

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

local keyvars arm_industry arm_academic arm_personal

/*------------------------------------------------------------------------------
    2. Define split labels for table headers
------------------------------------------------------------------------------*/

local high_prior_label0 "Low"
local high_prior_label1 "High"
local high_prior_rowlabel "Prior"
local bad_experience_label1 "Severe/No vacc"
local bad_experience_label0 "Benign"
local bad_experience_rowlabel "Experience"
local high_trust_label0 "Low"
local high_trust_label1 "High"
local high_trust_rowlabel "Trust"
local high_relevance_label0 "Low"
local high_relevance_label1 "High"
local high_relevance_rowlabel "Relevance"

/*------------------------------------------------------------------------------
    3. Run regressions and create tables for each split
------------------------------------------------------------------------------*/

foreach split in high_prior bad_experience high_trust high_relevance {

    di as text ""
    di as text "=============================================="
    di as text "Split: `split'"
    di as text "=============================================="

    * Initialize matrices (3 keyvars x 6 columns)
    matrix coefs = J(3, 6, .)
    matrix ses = J(3, 6, .)
    matrix ctrl_means = J(1, 6, .)
    matrix n_obs = J(1, 6, .)

    * Column mapping: 1=post_trial split0, 2=post_trial split1, 3=delta split0, 4=delta split1
    local col = 1
    foreach y in post_trial delta main_maybe {
        foreach splitval in 0 1 {

            di as text ""
            di as text "--- `y', `split'=`splitval' ---"

            * Run regression
            qui regress `y' `keyvars' $controls if `split' == `splitval', robust
						
            * Store sample size
            matrix n_obs[1, `col'] = e(N)

            * Store coefficients and SEs
            local row = 1
            foreach keyvar of varlist `keyvars' {
								noi di "`keyvar' : " _b[`keyvar'] "(" _se[`keyvar'] ")"
                capture local b = _b[`keyvar']
                if _rc {
                    matrix coefs[`row', `col'] = .
                    matrix ses[`row', `col'] = .
                }
                else {
                    matrix coefs[`row', `col'] = _b[`keyvar']
                    matrix ses[`row', `col'] = _se[`keyvar']
                }
                local ++row
            }

            * Calculate control mean
            quietly sum `y' if arm_industry==0 & arm_academic==0 & arm_personal==0 & `split'==`splitval'
            matrix ctrl_means[1, `col'] = r(mean)

            local ++col
        }
    }
}
ss
    /*--------------------------------------------------------------------------
        Write .tex file
    --------------------------------------------------------------------------*/

    local tex_file "output/tables/het_`split'.tex"
    capture file close _het_tex
    file open _het_tex using "`tex_file'", write replace

    * Coefficient and SE rows for each keyvar
    local row = 1
    foreach keyvar of varlist `keyvars' {
        local varlabel : variable label `keyvar'
        if "`varlabel'" == "" local varlabel "`keyvar'"

        * Coefficient row
        local tex_line = "`varlabel'"
        forvalues col = 1/4 {
            local b = coefs[`row', `col']
            if `b' == . {
                local tex_line = "`tex_line' & ."
            }
            else {
                local b_fmt : di %9.3f `b'
                local tex_line = "`tex_line' & `b_fmt'"
            }
        }
        local tex_line = "`tex_line' \\"
        file write _het_tex "`tex_line'" _n

        * SE row
        local tex_line = "               "
        forvalues col = 1/4 {
            local se = ses[`row', `col']
            if `se' == . {
                local tex_line = "`tex_line' & ."
            }
            else {
                local se_fmt : di %7.3f `se'
                local tex_line = "`tex_line' & (`se_fmt')"
            }
        }
        local tex_line = "`tex_line' \\"
        file write _het_tex "`tex_line'" _n

        local ++row
    }

    * Control mean row
    local tex_line = "Control mean   "
    forvalues col = 1/4 {
        local m = ctrl_means[1, `col']
        local m_fmt : di %9.3f `m'
        local tex_line = "`tex_line' & `m_fmt'"
    }
    local tex_line = "`tex_line' \\"
    file write _het_tex "`tex_line'" _n

    * N row
    local tex_line = "N              "
    forvalues col = 1/4 {
        local n = n_obs[1, `col']
        local tex_line = "`tex_line' & " + string(`n', "%9.0fc")
    }
    local tex_line = "`tex_line' \\"
    file write _het_tex "`tex_line'" _n

    * Split label row (no trailing \\)
    local lab0 "``split'_label0'"
    local lab1 "``split'_label1'"
    local rowlab "``split'_rowlabel'"
    file write _het_tex "`rowlab' & `lab0' & `lab1' & `lab0' & `lab1'" _n

    file close _het_tex
    di as text "Saved: `tex_file'"

    /*--------------------------------------------------------------------------
        Write .md file
    --------------------------------------------------------------------------*/

    local md_file "output/tables/het_`split'.md"
    capture file close _het_md
    file open _het_md using "`md_file'", write replace

    * Separator row
    file write _het_md "|--|--:|--:|--:|--:|" _n

    * Coefficient and SE rows for each keyvar
    local row = 1
    foreach keyvar of varlist `keyvars' {
        local varlabel : variable label `keyvar'
        if "`varlabel'" == "" local varlabel "`keyvar'"

        * Coefficient row
        local md_line = "| `varlabel' |"
        forvalues col = 1/4 {
            local b = coefs[`row', `col']
            if `b' == . {
                local md_line = "`md_line' . |"
            }
            else {
                local b_fmt = trim("`: di %9.3f `b''")
                local md_line = "`md_line' `b_fmt' |"
            }
        }
        file write _het_md "`md_line'" _n

        * SE row
        local md_line = "|  |"
        forvalues col = 1/4 {
            local se = ses[`row', `col']
            if `se' == . {
                local md_line = "`md_line' . |"
            }
            else {
                local se_fmt = trim("`: di %7.3f `se''")
                local md_line = "`md_line' (`se_fmt') |"
            }
        }
        file write _het_md "`md_line'" _n

        local ++row
    }

    * Control mean row
    local md_line = "| Control mean |"
    forvalues col = 1/4 {
        local m = ctrl_means[1, `col']
        local m_fmt = trim("`: di %9.3f `m''")
        local md_line = "`md_line' `m_fmt' |"
    }
    file write _het_md "`md_line'" _n

    * N row
    local md_line = "| N |"
    forvalues col = 1/4 {
        local n = n_obs[1, `col']
        local md_line = "`md_line' " + string(`n', "%9.0fc") + " |"
    }
    file write _het_md "`md_line'" _n

    * Split label row
    local lab0 "``split'_label0'"
    local lab1 "``split'_label1'"
    local rowlab "``split'_rowlabel'"
    file write _het_md "| `rowlab' | `lab0' | `lab1' | `lab0' | `lab1' |" _n

    file close _het_md
    di as text "Saved: `md_file'"

    * Clean up matrices
    matrix drop coefs ses ctrl_means n_obs
}

capture log close
