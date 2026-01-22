*! balance_table v1.1 - Generate balance tables with group means and p-values
*! Created by Dan + Claude Code

program define balance_table
    version 14.0
    syntax varlist [if] [in], group(varname) [saving(string) jointtest]

    /*--------------------------------------------------------------------------
        1. Mark sample and validate inputs
    --------------------------------------------------------------------------*/

    marksample touse, novarlist

    * Check group variable is numeric
    capture confirm numeric variable `group'
    if _rc {
        di as error "group() variable must be numeric"
        exit 109
    }

    * Mark sample must also have non-missing group
    markout `touse' `group'

    * Check we have observations
    quietly count if `touse'
    if r(N) == 0 {
        di as error "no observations"
        exit 2000
    }

    * Get group levels (only among touse observations)
    quietly levelsof `group' if `touse', local(group_levels)
    local n_groups : word count `group_levels'

    * Warn if many groups
    if `n_groups' > 10 {
        di as text "warning: group variable has `n_groups' levels - table may be very wide"
    }

    * Check for empty groups
    foreach g of local group_levels {
        quietly count if `group' == `g' & `touse'
        if r(N) == 0 {
            di as error "no observations for `group' == `g'"
            exit 2000
        }
    }

    * Check all variables exist and have observations
    foreach var of varlist `varlist' {
        quietly count if !missing(`var') & `touse'
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

    foreach g of local group_levels {
        quietly count if `group' == `g' & `touse'
        local n_`g' = r(N)
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
            quietly sum `var' if `group' == `g' & `touse'
            matrix means[`row', `col'] = r(mean)
            local ++col
        }

        * F-test for joint equality
        quietly regress `var' i.`group' if `touse', vce(robust)
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
        * Create common sample marker (non-missing on ALL variables)
        tempvar joint_touse
        quietly gen byte `joint_touse' = `touse'
        markout `joint_touse' `varlist' `group'

        * Check we have observations for joint test
        quietly count if `joint_touse'
        if r(N) == 0 {
            di as text "warning: no common sample for joint test (skipping)"
        }
        else {
            * Preserve data and keep only common sample for suest
            preserve
            quietly keep if `joint_touse'

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
            capture quietly suest `est_names', vce(robust)
            if _rc {
                di as text "warning: joint test failed - skipping"
                * Clean up estimates and restore data
                forvalues j = 1/`n_vars' {
                    capture estimates drop _bt_est`j'
                }
                restore
            }
            else {
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

                * Clean up estimates and restore data
                forvalues j = 1/`n_vars' {
                    estimates drop _bt_est`j'
                }
                restore
            }
        }
    }

    /*--------------------------------------------------------------------------
        5. Print to console (truncate long lines at 78 chars)
    --------------------------------------------------------------------------*/

    local maxwidth = 78

    di ""
    di as text "Balance Table: group(`group')"
    di as text "{hline `maxwidth'}"

    * Build and display header
    local header = "Variable"
    foreach g of local group_levels {
        local g_fmt : di %9.0f `g'
        local header = "`header'`g_fmt'"
    }
    local header = "`header'   P-value"
    if strlen("`header'") > `maxwidth' {
        local header = substr("`header'", 1, `maxwidth')
    }
    di as text "`header'"
    di as text "{hline `maxwidth'}"

    * Data rows
    local row = 1
    foreach var of varlist `varlist' {
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"
        local varlabel = abbrev("`varlabel'", 24)

        local line = "`varlabel'"
        forvalues col = 1/`n_groups' {
            local val = means[`row', `col']
            local val_fmt : di %9.3f `val'
            local line = "`line'`val_fmt'"
        }
        local pval = pvals[`row', 1]
        local pval_fmt : di %9.3f `pval'
        local line = "`line'`pval_fmt'"

        if strlen("`line'") > `maxwidth' {
            local line = substr("`line'", 1, `maxwidth')
        }
        di as text "`line'"
        local ++row
    }

    * Joint test row (if computed)
    if `joint_p' != . {
        di as text "{hline `maxwidth'}"
        local joint_chi2_fmt : di %8.3f `joint_chi2'
        local joint_p_fmt : di %5.3f `joint_p'
        local jline = "Joint test: chi2(`joint_df') = `joint_chi2_fmt', p = `joint_p_fmt'"
        if strlen("`jline'") > `maxwidth' {
            local jline = substr("`jline'", 1, `maxwidth')
        }
        di as text "`jline'"
    }

    * Sample size row
    di as text "{hline `maxwidth'}"
    local nline = "N"
    foreach g of local group_levels {
        local n_fmt : di %9.0fc `n_`g''
        local nline = "`nline'`n_fmt'"
    }
    if strlen("`nline'") > `maxwidth' {
        local nline = substr("`nline'", 1, `maxwidth')
    }
    di as text "`nline'"
    di as text "{hline `maxwidth'}"

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
        local joint_chi2_fmt : di %5.3f `joint_chi2'
        local joint_p_fmt : di %5.3f `joint_p'
        file write _bt_fout "Joint test & \multicolumn{`n_groups'}{c}{\$\chi^2(`joint_df')=`joint_chi2_fmt'\$} & `joint_p_fmt' \\" _n
    }

    * Sample size row (no trailing \\)
    local n_line = "N"
    foreach g of local group_levels {
        local n_line = "`n_line' & `n_`g''"
    }
    file write _bt_fout "`n_line'" _n

    file close _bt_fout

    di as text "Saved: `saving'"

    * Clean up matrices
    matrix drop means pvals

end
