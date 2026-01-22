*! plot_to_csv v2.3.0 - Export graph data to CSV from in-memory plot
*! Created by Dan + Claude Code
*!
*! Extracts the underlying data from a Stata graph in memory and saves to CSV.
*! Uses Stata's serset system to access the plotted data points.
*!
*! Syntax:
*!   plot_to_csv using filename [, options]
*!
*! Options:
*!   replace       - Overwrite existing file
*!   name(string)  - Name of graph to export (default: current graph)
*!
*! Usage pattern:
*!   serset drop _all              // Clear sersets before plotting
*!   twoway scatter y x            // Create plot (creates serset 0)
*!   plot_to_csv using "file.csv", replace   // Export serset 0
*!
*! Notes:
*!   - A graph must be in memory before calling this command
*!   - Use `serset drop _all` before plotting to ensure clean serset state
*!   - Variable names in the CSV match those used in the plot
*!   - For plots with multiple series, all sersets are exported with _serset column

program define plot_to_csv
    version 14.0

    syntax using/ [, REPLACE NAME(string)]

    * Validate that file path ends in .csv
    if !regexm("`using'", "\.csv$") {
        di as error "Output file must have .csv extension"
        exit 198
    }

    * Check if file exists and replace not specified
    capture confirm file "`using'"
    if _rc == 0 & "`replace'" == "" {
        di as error "File `using' already exists. Use replace option to overwrite."
        exit 602
    }

    * Check that a graph exists
    if "`name'" == "" {
        capture graph describe
        if _rc != 0 {
            di as error "No graph in memory. Create a graph before using plot_to_csv."
            exit 198
        }
    }
    else {
        capture graph describe `name'
        if _rc != 0 {
            di as error "Graph `name' not found in memory."
            exit 198
        }
    }

    * Preserve current data
    preserve

    * Count sersets by trying to access them
    local nserset = 0
    local done = 0
    while !`done' {
        capture serset set `nserset'
        if _rc == 0 {
            local ++nserset
        }
        else {
            local done = 1
        }
    }

    if `nserset' == 0 {
        di as error "No sersets found. The graph may not contain plottable data."
        restore
        exit 198
    }

    * Export sersets
    if `nserset' == 1 {
        * Single serset - export directly
        quietly serset set 0
        clear
        quietly serset use
        quietly export delimited using "`using'", `replace'
        local nobs = _N
        di as text "Exported `nobs' observations to `using'"
    }
    else {
        * Multiple sersets - combine with _serset identifier
        clear
        tempfile combined

        forvalues s = 0/`=`nserset'-1' {
            quietly serset set `s'
            clear
            quietly serset use
            gen int _serset = `s' + 1

            if `s' == 0 {
                quietly save `combined', replace
            }
            else {
                quietly append using `combined'
                quietly save `combined', replace
            }
        }

        order _serset
        quietly export delimited using "`using'", `replace'
        local nobs = _N
        di as text "Exported `nserset' serset(s) (`nobs' total observations) to `using'"
    }

    restore
end
