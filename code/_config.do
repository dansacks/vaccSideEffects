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

* Set project directory based on operating system
* c(os) returns "Windows" on Windows, "Unix" or "MacOSX" on Mac
local usr `c(username)'
if "`c(os)'" == "Windows" {
    global projdir "C:/Users/`usr'/Projects/VaccSideEffects"
}
else {
    * macOS (Unix or MacOSX)
    global projdir "/Users/`usr'/Projects/VaccSideEffects"
}
cd "$projdir"

* Add local ado files to path (for plot_to_csv and other custom programs)
adopath + "$projdir/code/include"
adopath + "$projdir/code/ado"

* Create output subdirectories if they don't exist
capture mkdir "output"
capture mkdir "output/logs"
capture mkdir "output/tables"
capture mkdir "output/docs"
capture mkdir "output/figures"

/*------------------------------------------------------------------------------
    Named Constants

    These replace magic numbers scattered throughout the codebase.
------------------------------------------------------------------------------*/

* Attention check expected values (from survey design)
global ATTN_CHECK_PRESCREEN = 1965
global ATTN_CHECK_MAIN = 4419
global ATTN_CHECK_FOLLOWUP = 1163

* Special code for unselected responses
global UNSELECTED_VALUE  = -99

/*------------------------------------------------------------------------------
    Conditional Logging
------------------------------------------------------------------------------*/

* Only log in batch mode
if "`c(mode)'" == "batch" & "$scriptname" != "" {
    capture log close _all
    log using "output/logs/$scriptname.log", replace text
    di "=== Running in batch mode: $scriptname ==="
    di "Log: output/logs/$scriptname.log"
    di ""
}
