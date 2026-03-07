/*==============================================================================
    Sample Counts by Treatment Arm and Outcome

    Input:  derived/merged_all.dta
    Output: output/tables/counts_by_arm.tex

    Counts non-missing observations by arm for each outcome variable.
    Last row totals across all arms.

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "counts_by_arm"
do "code/_config.do"

use "derived/merged_all.dta", clear
keep if main_sample==1

local outcomes delta post_trial main_intent link_click got_flu_vacc

file open _counts using "output/tables/counts_by_arm.tex", write replace

forvalues arm = 0/3 {
    if `arm' == 0 local name "Control"
    if `arm' == 1 local name "Industry"
    if `arm' == 2 local name "Academic"
    if `arm' == 3 local name "Representative"

    file write _counts "`name'"
    foreach outcome of local outcomes {
        count if arm_n == `arm' & !missing(`outcome')
        file write _counts " & " %5.0fc (r(N))
    }
    file write _counts " \\" _n
}

* All row — no trailing \\ per project convention
file write _counts "All"
foreach outcome of local outcomes {
    count if !missing(`outcome')
    file write _counts " & " %5.0fc (r(N))
}

file close _counts

capture log close
