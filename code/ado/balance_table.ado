*! balance_table v1.1 - Generate balance tables with group means and p-values
*! Created by Dan + Claude Code

program define balance_table
    version 14.0
    syntax varlist [if] [in], group(varname) [saving(string) jointtest labels(string)]

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
        * Use preserve/restore approach matching original balance_table.do
        quietly {
            preserve

            * Keep only touse sample
            keep if `touse'

            * Store estimates for suest (each regression uses casewise deletion)
            local est_names ""
            local i = 1
            foreach var of varlist `varlist' {
                regress `var' i.`group'
                estimates store _bt_est`i'
                local est_names "`est_names' _bt_est`i'"
                local ++i
            }

            * Joint test using suest
            capture noisily suest `est_names', vce(robust)
            if _rc == 0 {
                * Build test terms for all group coefficients
                local test_terms ""
                forvalues j = 1/`n_vars' {
                    foreach g of local group_levels {
                        if `g' != `: word 1 of `group_levels'' {
                            local test_terms "`test_terms' [_bt_est`j'_mean]`g'.`group'"
                        }
                    }
                }

                test `test_terms'
                local joint_chi2 = r(chi2)
                local joint_df = r(df)
                local joint_p = r(p)
            }

            * Clean up estimates
            forvalues j = 1/`n_vars' {
                capture estimates drop _bt_est`j'
            }

            restore
        }

        if `joint_p' == . {
            di as text "warning: joint test failed"
        }
    }

    /*--------------------------------------------------------------------------
        5. Print to console
    --------------------------------------------------------------------------*/

    local maxwidth = c(linesize)

    di ""
    di as text "Balance Table: group(`group')"
    di as text "{hline `maxwidth'}"

    * Build group labels (use provided labels or default to "Arm N")
    local col = 1
    foreach g of local group_levels {
        local lab`col' : word `col' of `labels'
        if "`lab`col''" == "" local lab`col' "Arm `g'"
        local ++col
    }

    * Build and display header
    local header : di %-24s "Variable"
    forvalues col = 1/`n_groups' {
        local col_fmt : di %9s "`lab`col''"
        local header = "`header'`col_fmt'"
    }
    local header = "`header'   P-value"
    di as text "`header'"
    di as text "{hline `maxwidth'}"

    * Data rows
    local row = 1
    foreach var of varlist `varlist' {
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"
        local varlabel = abbrev("`varlabel'", 24)

        local line : di %-24s "`varlabel'"
        forvalues col = 1/`n_groups' {
            local val = means[`row', `col']
            local val_fmt : di %9.3f `val'
            local line = "`line'`val_fmt'"
        }
        local pval = pvals[`row', 1]
        local pval_fmt : di %9.3f `pval'
        local line = "`line'`pval_fmt'"

        di as text "`line'"
        local ++row
    }

    * Joint test row (if computed)
    if `joint_p' != . {
        di as text "{hline `maxwidth'}"
        local joint_chi2_fmt : di %8.3f `joint_chi2'
        local joint_p_fmt : di %5.3f `joint_p'
        local jline = "Joint test: chi2(`joint_df') = `joint_chi2_fmt', p = `joint_p_fmt'"
        di as text "`jline'"
    }

    * Sample size row
    di as text "{hline `maxwidth'}"
    local nline : di %-24s "N"
    foreach g of local group_levels {
        local n_fmt : di %9.0fc `n_`g''
        local nline = "`nline'`n_fmt'"
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
        local joint_p_fmt : di %5.3f `joint_p'
        file write _bt_fout "Joint test & \multicolumn{`n_groups'}{c}{} & `joint_p_fmt' \\" _n
    }

    * Sample size row (no trailing \\)
    local n_line = "N"
    foreach g of local group_levels {
        local n_line = "`n_line' & `n_`g''"
    }
    file write _bt_fout "`n_line'" _n

    file close _bt_fout

    di as text "Saved: `saving'"

    /*--------------------------------------------------------------------------
        7. Write to .md file
    --------------------------------------------------------------------------*/

    * Derive .md path from .tex path
    local md_saving = subinstr("`saving'", ".tex", ".md", .)

    capture file close _bt_mdout
    file open _bt_mdout using "`md_saving'", write replace

    * Header row
    local md_header = "| |"
    local md_sep = "|---|"
    local col = 1
    forvalues col = 1/`n_groups' {
        local md_header = "`md_header' `lab`col'' |"
        local md_sep = "`md_sep'---:|"
    }
    local md_header = "`md_header' P-value |"
    local md_sep = "`md_sep'---:|"
    file write _bt_mdout "`md_header'" _n
    file write _bt_mdout "`md_sep'" _n

    * Data rows
    local row = 1
    foreach var of varlist `varlist' {
        local varlabel : variable label `var'
        if "`varlabel'" == "" local varlabel "`var'"

        * Escape pipe characters for markdown
        local varlabel_md = subinstr("`varlabel'", "|", "\|", .)

        local md_line = "| `varlabel_md'"
        forvalues col = 1/`n_groups' {
            local val = means[`row', `col']
            local val_fmt : di %5.3f `val'
            local md_line = "`md_line' | `val_fmt'"
        }
        local pval = pvals[`row', 1]
        local pval_fmt : di %5.3f `pval'
        local md_line = "`md_line' | `pval_fmt' |"

        file write _bt_mdout "`md_line'" _n
        local ++row
    }

    * Joint test row (if computed)
    if `joint_p' != . {
        local joint_p_fmt : di %5.3f `joint_p'
        local md_line = "| Joint test"
        forvalues col = 1/`n_groups' {
            local md_line = "`md_line' |"
        }
        local md_line = "`md_line' | `joint_p_fmt' |"
        file write _bt_mdout "`md_line'" _n
    }

    * Sample size row
    local md_nline = "| N"
    foreach g of local group_levels {
        local md_nline = "`md_nline' | `n_`g''"
    }
    local md_nline = "`md_nline' | |"
    file write _bt_mdout "`md_nline'" _n

    file close _bt_mdout

    di as text "Saved: `md_saving'"

    * Clean up matrices
    matrix drop means pvals

end
