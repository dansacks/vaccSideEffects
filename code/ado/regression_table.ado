*! regression_table v1.1 - Generate regression results tables
*! Created by Dan + Claude Code

program define regression_table
    version 14.0
    syntax varlist [if] [in], keyvars(varlist) [controls(varlist) saving(string)]

    /*--------------------------------------------------------------------------
        1. Mark sample and validate inputs
    --------------------------------------------------------------------------*/

    marksample touse

    * Check we have observations
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no observations"
        exit 2000
    }

    * Set default saving filename
    if "`saving'" == "" {
        local saving "regression_table.tex"
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
        quietly regress `outcome' `keyvars' `controls' if `touse', robust

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

        quietly sum `outcome' if `ctrl_condition' & `touse'
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
        4. Print to console (truncate long lines at 78 chars)
    --------------------------------------------------------------------------*/

    local maxwidth = 78

    di as text ""
    di as text "Regression Table"
    di as text "{hline `maxwidth'}"

    * Build header with outcome names
    local header = ""
    foreach outcome of varlist `varlist' {
        local outcome_short = abbrev("`outcome'", 10)
        local outcome_fmt : di %12s "`outcome_short'"
        local header = "`header'`outcome_fmt'"
    }
    if strlen("`header'") > `maxwidth' {
        local header = substr("`header'", 1, `maxwidth')
    }
    di as text "`header'"
    di as text "{hline `maxwidth'}"

    * Coefficient and SE rows for each keyvar
    local row = 1
    foreach keyvar of varlist `keyvars' {
        local varlabel : variable label `keyvar'
        if "`varlabel'" == "" local varlabel "`keyvar'"
        local varlabel = abbrev("`varlabel'", 20)

        * Coefficient row
        local coef_line = "`varlabel'"
        forvalues col = 1/`n_outcomes' {
            local b = coefs[`row', `col']
            if `b' == . {
                local coef_line = "`coef_line'           ."
            }
            else {
                local b_fmt : di %12.3f `b'
                local coef_line = "`coef_line'`b_fmt'"
            }
        }
        if strlen("`coef_line'") > `maxwidth' {
            local coef_line = substr("`coef_line'", 1, `maxwidth')
        }
        di as text "`coef_line'"

        * SE row
        local se_line = ""
        forvalues col = 1/`n_outcomes' {
            local se = ses[`row', `col']
            if `se' == . {
                local se_line = "`se_line'           ."
            }
            else {
                local se_fmt : di %6.3f `se'
                local se_line = "`se_line'    (`se_fmt')"
            }
        }
        if strlen("`se_line'") > `maxwidth' {
            local se_line = substr("`se_line'", 1, `maxwidth')
        }
        di as text "`se_line'"

        local ++row
    }

    * Control mean row
    di as text "{hline `maxwidth'}"
    local mean_line = "Control mean"
    forvalues col = 1/`n_outcomes' {
        local m = ctrl_means[1, `col']
        local m_fmt : di %12.3f `m'
        local mean_line = "`mean_line'`m_fmt'"
    }
    if strlen("`mean_line'") > `maxwidth' {
        local mean_line = substr("`mean_line'", 1, `maxwidth')
    }
    di as text "`mean_line'"

    * N row
    local n_line = "N"
    forvalues col = 1/`n_outcomes' {
        local n = n_obs[1, `col']
        local n_fmt : di %12.0fc `n'
        local n_line = "`n_line'`n_fmt'"
    }
    if strlen("`n_line'") > `maxwidth' {
        local n_line = substr("`n_line'", 1, `maxwidth')
    }
    di as text "`n_line'"
    di as text "{hline `maxwidth'}"

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

        * Escape special LaTeX characters
        local varlabel_tex = subinstr("`varlabel'", "$", "\$", .)
        local varlabel_tex = subinstr("`varlabel_tex'", "%", "\%", .)
        local varlabel_tex = subinstr("`varlabel_tex'", "&", "\&", .)
        local varlabel_tex = subinstr("`varlabel_tex'", "_", "\_", .)

        * Coefficient row
        local tex_line = "`varlabel_tex'"
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
