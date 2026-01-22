*! balance_table v1.0 - Generate balance tables with group means and p-values
*! Created by Dan + Claude Code

program define balance_table
    version 14.0
    syntax varlist, group(varname) [saving(string) jointtest]

    /*--------------------------------------------------------------------------
        1. Validate inputs
    --------------------------------------------------------------------------*/

    * Check group variable is numeric
    capture confirm numeric variable `group'
    if _rc {
        di as error "group() variable must be numeric"
        exit 109
    }

    * Get group levels
    quietly levelsof `group', local(group_levels)
    local n_groups : word count `group_levels'

    * Warn if many groups
    if `n_groups' > 10 {
        di as text "warning: group variable has `n_groups' levels - table may be very wide"
    }

    * Check for empty groups
    foreach g of local group_levels {
        quietly count if `group' == `g'
        if r(N) == 0 {
            di as error "no observations for `group' == `g'"
            exit 2000
        }
    }

    * Check all variables exist and have observations
    foreach var of varlist `varlist' {
        quietly count if !missing(`var')
        if r(N) == 0 {
            di as error "variable `var' has no non-missing observations"
            exit 2000
        }
    }

    * Set default saving filename
    if "`saving'" == "" {
        local saving "balance_table.tex"
    }

    /*--------------------------------------------------------------------------
        2. Get sample sizes by group
    --------------------------------------------------------------------------*/

    local group_ns ""
    foreach g of local group_levels {
        quietly count if `group' == `g'
        local n_`g' = r(N)
        local group_ns "`group_ns' `r(N)'"
    }

    /*--------------------------------------------------------------------------
        3. Calculate means and p-values for each variable
    --------------------------------------------------------------------------*/

    local n_vars : word count `varlist'

    * Store results in matrices
    matrix means = J(`n_vars', `n_groups', .)
    matrix pvals = J(`n_vars', 1, .)

    local row = 1
    foreach var of varlist `varlist' {
        * Get means by group
        local col = 1
        foreach g of local group_levels {
            quietly sum `var' if `group' == `g'
            matrix means[`row', `col'] = r(mean)
            local ++col
        }

        * F-test for joint equality
        quietly regress `var' i.`group', vce(robust)
        quietly testparm i.`group'
        matrix pvals[`row', 1] = r(p)

        local ++row
    }

    /*--------------------------------------------------------------------------
        4. Joint test (if requested)
    --------------------------------------------------------------------------*/

    local joint_chi2 = .
    local joint_df = .
    local joint_p = .

    if "`jointtest'" != "" & `n_vars' > 1 {
        * Store estimates for suest
        local est_names ""
        local i = 1
        foreach var of varlist `varlist' {
            quietly regress `var' i.`group'
            estimates store _bt_est`i'
            local est_names "`est_names' _bt_est`i'"
            local ++i
        }

        * Joint test using suest
        quietly suest `est_names', vce(robust)

        * Build test terms for all group coefficients
        local test_terms ""
        forvalues j = 1/`n_vars' {
            foreach g of local group_levels {
                if `g' != `: word 1 of `group_levels'' {
                    local test_terms "`test_terms' [_bt_est`j'_mean]`g'.`group'"
                }
            }
        }

        quietly test `test_terms'
        local joint_chi2 = r(chi2)
        local joint_df = r(df)
        local joint_p = r(p)

        * Clean up estimates
        forvalues j = 1/`n_vars' {
            estimates drop _bt_est`j'
        }
    }

    /*--------------------------------------------------------------------------
        5. Print to console
    --------------------------------------------------------------------------*/

    * Calculate column widths
    local varlabel_width = 28
    local col_width = 10

    * Header
    di ""
    di as text "Balance Table: group(`group')"
    di as text "{hline 80}"

    * Column headers
    local header_line = "Variable"
    local header_line = abbrev("`header_line'", `varlabel_width')
    local header_line = "`header_line'" + "{col `=`varlabel_width'+3'}|"
    local col_pos = `varlabel_width' + 5
    foreach g of local group_levels {
        local header_line = "`header_line'" + "{col `col_pos'}" + string(`g', "%`col_width'.0f")
        local col_pos = `col_pos' + `col_width'
    }
    local header_line = "`header_line'" + "{col `col_pos'}P-value"
    di as text "`header_line'"
    di as text "{hline `varlabel_width'}|{hline `=`col_pos' - `varlabel_width' + 5'}"

    * Data rows
    local row = 1
    foreach var of varlist `varlist' {
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"
        local varlabel = abbrev("`varlabel'", `varlabel_width')

        local data_line = "`varlabel'"
        local data_line = "`data_line'" + "{col `=`varlabel_width'+3'}|"
        local col_pos = `varlabel_width' + 5

        forvalues col = 1/`n_groups' {
            local val = means[`row', `col']
            local data_line = "`data_line'" + "{col `col_pos'}" + string(`val', "%`col_width'.3f")
            local col_pos = `col_pos' + `col_width'
        }

        local pval = pvals[`row', 1]
        local data_line = "`data_line'" + "{col `col_pos'}" + string(`pval', "%8.3f")

        di as text "`data_line'"
        local ++row
    }

    * Joint test row (if computed)
    if `joint_p' != . {
        di as text "{hline `varlabel_width'}|{hline `=`col_pos' - `varlabel_width' + 5'}"
        local joint_chi2_fmt = string(`joint_chi2', "%8.3f")
        di as text "Joint test{col `=`varlabel_width'+3'}|{col `=`varlabel_width'+5'}chi2(`joint_df') = `joint_chi2_fmt'{col `col_pos'}" string(`joint_p', "%8.3f")
    }

    * Sample size row
    di as text "{hline `varlabel_width'}|{hline `=`col_pos' - `varlabel_width' + 5'}"
    local n_line = "N{col `=`varlabel_width'+3'}|"
    local col_pos = `varlabel_width' + 5
    foreach g of local group_levels {
        local n_line = "`n_line'" + "{col `col_pos'}" + string(`n_`g'', "%`col_width'.0fc")
        local col_pos = `col_pos' + `col_width'
    }
    di as text "`n_line'"
    di as text "{hline 80}"

    /*--------------------------------------------------------------------------
        6. Write to .tex file
    --------------------------------------------------------------------------*/

    capture file close _bt_fout
    file open _bt_fout using "`saving'", write replace

    * Data rows
    local row = 1
    foreach var of varlist `varlist' {
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"

        * Escape special LaTeX characters
        local varlabel_tex = subinstr("`varlabel'", "$", "\$", .)
        local varlabel_tex = subinstr("`varlabel_tex'", "%", "\%", .)
        local varlabel_tex = subinstr("`varlabel_tex'", "&", "\&", .)
        local varlabel_tex = subinstr("`varlabel_tex'", "_", "\_", .)

        * Build row: label & mean1 & mean2 & ... & pval \\
        local tex_line = "`varlabel_tex'"
        forvalues col = 1/`n_groups' {
            local val = means[`row', `col']
            local val_fmt : di %5.3f `val'
            local tex_line = "`tex_line' & `val_fmt'"
        }
        local pval = pvals[`row', 1]
        local pval_fmt : di %5.3f `pval'
        local tex_line = "`tex_line' & `pval_fmt' \\"

        file write _bt_fout "`tex_line'" _n
        local ++row
    }

    * Joint test row (if computed)
    if `joint_p' != . {
        file write _bt_fout "\addlinespace" _n
        local joint_chi2_fmt : di %5.3f `joint_chi2'
        local joint_p_fmt : di %5.3f `joint_p'
        local n_groups_minus1 = `n_groups' - 1
        file write _bt_fout "Joint test & \multicolumn{`n_groups'}{c}{\$\chi^2(`joint_df')=`joint_chi2_fmt'\$} & `joint_p_fmt' \\" _n
    }

    * Sample size row (no trailing \\)
    file write _bt_fout "\addlinespace" _n
    local n_line = "N"
    foreach g of local group_levels {
        local n_line = "`n_line' & `n_`g''"
    }
    local n_line = "`n_line' &"
    file write _bt_fout "`n_line'" _n

    file close _bt_fout

    di as text "Saved: `saving'"

    * Clean up matrices
    matrix drop means pvals

end
