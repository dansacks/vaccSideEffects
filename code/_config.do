/*==============================================================================
    Project Configuration

    Set the project directory once here; all other scripts include this file.

    Usage: Include at the top of each do-file:
        global scriptname "my_script"
        do "code/_config.do"

    In batch mode (stata -e), logs to output/logs/{scriptname}.log
    In interactive mode, no logging occurs.

    Created by Dan + Claude Code
==============================================================================*/

* Settings for both batch and interactive mode
set more off
set rmsg off

* Set project directory
local usr `c(username)'
global projdir "C:/Users/`usr'/Box/VaccSideEffects"
cd "$projdir"

* Create output subdirectories if they don't exist
capture mkdir "output"
capture mkdir "output/logs"
capture mkdir "output/tables"
capture mkdir "output/docs"
capture mkdir "output/figures"

* Conditional logging: only log in batch mode
if "`c(mode)'" == "batch" & "$scriptname" != "" {
    capture log close _all
    log using "output/logs/$scriptname.log", replace text
    di "=== Running in batch mode: $scriptname ==="
    di "Log: output/logs/$scriptname.log"
    di ""
}
