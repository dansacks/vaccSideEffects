*! regression_table v1.0 - Generate regression results tables
*! Created by Dan + Claude Code

program define regression_table
    version 14.0
    syntax varlist, keyvars(varlist) [controls(varlist) saving(string) sample(varname)]

    /*--------------------------------------------------------------------------
        1. Validate inputs
    --------------------------------------------------------------------------*/

    * Check sample variable if specified
    if "`sample'" != "" {
        capture confirm numeric variable `sample'
        if _rc {
            di as error "sample() variable must be numeric"
            exit 109
        }
    }

    * Set default saving filename
    if "`saving'" == "" {
        local saving "regression_table.tex"
    }

    * Build sample condition
    if "`sample'" != "" {
        local if_sample "if `sample' == 1"
    }
    else {
        local if_sample ""
    }

    * Check we have observations
    quietly count `if_sample'
    if r(N) == 0 {
        di as error "no observations after sample restriction"
        exit 2000
    }

    /*--------------------------------------------------------------------------
        2. Setup dimensions
    --------------------------------------------------------------------------*/

    local n_outcomes : word count `varlist'
    local n_keyvars : word count `keyvars'

    * Initialize matrices
    matrix coefs = J(`n_keyvars', `n_outcomes', .)
    matrix ses = J(`n_keyvars', `n_outcomes', .)
    matrix ctrl_means = J(1, `n_outcomes', .)
    matrix n_obs = J(1, `n_outcomes', .)

    * Track collinearity warnings
    local collinear_warnings ""

    /*--------------------------------------------------------------------------
        3. Run regressions and store results
    --------------------------------------------------------------------------*/

    local col = 1
    foreach outcome of varlist `varlist' {
        di as text ""
        di as text "=== Regression: `outcome' ==="

        * Run regression
        quietly regress `outcome' `keyvars' `controls' `if_sample', robust

        * Store sample size
        matrix n_obs[1, `col'] = e(N)

        * Store coefficients and SEs for keyvars
        local row = 1
        foreach keyvar of varlist `keyvars' {
            * Check if coefficient exists (not omitted due to collinearity)
            capture local b = _b[`keyvar']
            if _rc {
                matrix coefs[`row', `col'] = .
                matrix ses[`row', `col'] = .
                local collinear_warnings "`collinear_warnings' `keyvar' (in `outcome')"
            }
            else {
                matrix coefs[`row', `col'] = _b[`keyvar']
                matrix ses[`row', `col'] = _se[`keyvar']
            }
            local ++row
        }

        * Calculate control mean (where all keyvars == 0)
        local ctrl_condition ""
        foreach keyvar of varlist `keyvars' {
            if "`ctrl_condition'" == "" {
                local ctrl_condition "`keyvar' == 0"
            }
            else {
                local ctrl_condition "`ctrl_condition' & `keyvar' == 0"
            }
        }

        if "`if_sample'" != "" {
            quietly sum `outcome' if `ctrl_condition' & `sample' == 1
        }
        else {
            quietly sum `outcome' if `ctrl_condition'
        }
        matrix ctrl_means[1, `col'] = r(mean)

        local ++col
    }

    * Report collinearity warnings
    if "`collinear_warnings'" != "" {
        di as text ""
        di as text "warning: the following variables were omitted due to collinearity:"
        di as text "  `collinear_warnings'"
    }

    /*--------------------------------------------------------------------------
        4. Print to console
    --------------------------------------------------------------------------*/

    * Calculate column widths
    local varlabel_width = 28
    local col_width = 12

    * Header
    di as text ""
    di as text "Regression Table"
    di as text "{hline 80}"

    * Column headers (outcome variable names)
    local header_line = "{col `=`varlabel_width'+3'}|"
    local col_pos = `varlabel_width' + 5
    foreach outcome of varlist `varlist' {
        local outcome_short = abbrev("`outcome'", `=`col_width'-2')
        local header_line = "`header_line'" + "{col `col_pos'}`outcome_short'"
        local col_pos = `col_pos' + `col_width'
    }
    di as text "`header_line'"
    di as text "{hline `varlabel_width'}|{hline `=`col_pos' - `varlabel_width'}"

    * Coefficient and SE rows for each keyvar
    local row = 1
    foreach keyvar of varlist `keyvars' {
        local varlabel : variable label `keyvar'
        if "`varlabel'" == "" local varlabel "`keyvar'"
        local varlabel = abbrev("`varlabel'", `varlabel_width')

        * Coefficient row
        local coef_line = "`varlabel'{col `=`varlabel_width'+3'}|"
        local col_pos = `varlabel_width' + 5
        forvalues col = 1/`n_outcomes' {
            local b = coefs[`row', `col']
            if `b' == . {
                local coef_line = "`coef_line'" + "{col `col_pos'}."
            }
            else {
                local coef_line = "`coef_line'" + "{col `col_pos'}" + string(`b', "%`col_width'.3f")
            }
            local col_pos = `col_pos' + `col_width'
        }
        di as text "`coef_line'"

        * SE row
        local se_line = "{col `=`varlabel_width'+3'}|"
        local col_pos = `varlabel_width' + 5
        forvalues col = 1/`n_outcomes' {
            local se = ses[`row', `col']
            if `se' == . {
                local se_line = "`se_line'" + "{col `col_pos'}."
            }
            else {
                local se_line = "`se_line'" + "{col `col_pos'}(" + string(`se', "%9.3f") + ")"
            }
            local col_pos = `col_pos' + `col_width'
        }
        di as text "`se_line'"

        local ++row
    }

    * Control mean row
    di as text "{hline `varlabel_width'}|{hline `=`col_pos' - `varlabel_width'}"
    local mean_line = "Control mean{col `=`varlabel_width'+3'}|"
    local col_pos = `varlabel_width' + 5
    forvalues col = 1/`n_outcomes' {
        local m = ctrl_means[1, `col']
        local mean_line = "`mean_line'" + "{col `col_pos'}" + string(`m', "%`col_width'.3f")
        local col_pos = `col_pos' + `col_width'
    }
    di as text "`mean_line'"

    * N row
    local n_line = "N{col `=`varlabel_width'+3'}|"
    local col_pos = `varlabel_width' + 5
    forvalues col = 1/`n_outcomes' {
        local n = n_obs[1, `col']
        local n_line = "`n_line'" + "{col `col_pos'}" + string(`n', "%`col_width'.0fc")
        local col_pos = `col_pos' + `col_width'
    }
    di as text "`n_line'"
    di as text "{hline 80}"

    /*--------------------------------------------------------------------------
        5. Write to .tex file
    --------------------------------------------------------------------------*/

    capture file close _rt_fout
    file open _rt_fout using "`saving'", write replace

    * Coefficient and SE rows for each keyvar
    local row = 1
    foreach keyvar of varlist `keyvars' {
        local varlabel : variable label `keyvar'
        if "`varlabel'" == "" local varlabel "`keyvar'"

        * Coefficient row
        local tex_line = "`varlabel'"
        forvalues col = 1/`n_outcomes' {
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
        file write _rt_fout "`tex_line'" _n

        * SE row
        local tex_line = "               "
        forvalues col = 1/`n_outcomes' {
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
        file write _rt_fout "`tex_line'" _n

        local ++row
    }

    * Control mean row
    local tex_line = "Control mean   "
    forvalues col = 1/`n_outcomes' {
        local m = ctrl_means[1, `col']
        local m_fmt : di %9.3f `m'
        local tex_line = "`tex_line' & `m_fmt'"
    }
    local tex_line = "`tex_line' \\"
    file write _rt_fout "`tex_line'" _n

    * N row (no trailing \\)
    local tex_line = "N              "
    forvalues col = 1/`n_outcomes' {
        local n = n_obs[1, `col']
        local tex_line = "`tex_line' & " + string(`n', "%9.0fc")
    }
    file write _rt_fout "`tex_line'" _n

    file close _rt_fout

    di as text "Saved: `saving'"

    * Clean up matrices
    matrix drop coefs ses ctrl_means n_obs

end
