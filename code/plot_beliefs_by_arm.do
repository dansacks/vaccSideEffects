/*==============================================================================
    Belief CDFs by Treatment Arm

    Creates CDF plots comparing each treatment arm to control.
    Shows distribution of posterior believed side effect rates (delta).

    Outputs:
        output/figures/belief_cdf_by_arm.png

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "plot_beliefs_by_arm"
do "code/_config.do"

* Load merged data
use "derived/merged_main_pre.dta", clear

*------------------------------------------------------------------------------
* Compute CDFs on common grid for each treatment arm
*------------------------------------------------------------------------------

* Create grid for CDF evaluation
gen b = .
forvalues a = 0/3 {
    gen p`a' = .
}

* Evaluate CDF at each grid point
local row = 1
forvalues bval = -100(0.5)100 {
    replace b = `bval' in `row'
    forvalues arm = 0/3 {
        count if arm_n == `arm'
        local N = r(N)
        count if arm_n == `arm' & delta <= `bval'
        replace p`arm' = r(N)/`N' in `row'
    }
    local ++row
}

* Calculate mean delta by arm
forvalues arm = 0/3 {
    sum delta if arm_n == `arm'
    local m`arm' = string(r(mean), "%3.2f")
}

* Regression for treatment effects
reg delta i.arm_n, r
forvalues n = 1/3 {
    local d`n' = string(_b[`n'.arm_n], "%3.2f")
    local se`n' = string(_se[`n'.arm_n], "%3.2f")
}

*------------------------------------------------------------------------------
* Create individual arm vs control plots
*------------------------------------------------------------------------------

* Industry arm
# delimit ;
twoway
    (line p1 b if b >= -50)
    (line p0 b if b >= -50, color(gs10))
    ,
    legend(off)
    text(.82 20 "Industry arm", color(stc1) place(w))
    text(.75 31 "Control arm", color(gs10) place(e))
    text(.2 100
        "Control mean: `m0'"
        "Industry arm mean: `m1'"
        "Unadjusted difference: `d1'" "(SE: `se1')" ,
        place(w) justification(right)
    )
    ytitle("")
    xtitle("Posterior believed side effect rate")
    title("Industry arm", span pos(11) ring(0))
    xsize(3) ysize(3)
    name(industry, replace)
;
# delimit cr

* Academic arm
# delimit ;
twoway
    (line p2 b if b >= -50)
    (line p0 b if b >= -50, color(gs10))
    ,
    legend(off)
    text(.82 20 "Academic arm", color(stc1) place(w))
    text(.75 31 "Control arm", color(gs10) place(e))
    text(.2 100
        "Control mean: `m0'"
        "Academic arm mean: `m2'"
        "Unadjusted difference: `d2'" "(SE: `se2')" ,
        place(w) justification(right)
    )
    ytitle("")
    xtitle("Posterior believed side effect rate")
    title("Academic arm", span pos(11) ring(0))
    xsize(3) ysize(3)
    name(academic, replace)
;
# delimit cr

* Personal arm
# delimit ;
twoway
    (line p3 b if b >= -50)
    (line p0 b if b >= -50, color(gs10))
    ,
    legend(off)
    text(.82 20 "Personal arm", color(stc1) place(w))
    text(.75 31 "Control arm", color(gs10) place(e))
    text(.2 100
        "Control mean: `m0'"
        "Personal arm mean: `m3'"
        "Unadjusted difference: `d3'" "(SE: `se3')" ,
        place(w) justification(right)
    )
    ytitle("")
    xtitle("Posterior believed side effect rate")
    title("Personal arm", span pos(11) ring(0))
    xsize(3) ysize(3)
    name(personal, replace)
;
# delimit cr

*------------------------------------------------------------------------------
* Combine and export
*------------------------------------------------------------------------------

graph combine industry academic personal, cols(3) xsize(9) ysize(3)
graph export "output/figures/belief_cdf_by_arm.png", replace width(1800) height(600)

capture log close
