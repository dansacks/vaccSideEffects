/*==============================================================================
    HTE Forest Plot

    Input:  derived/merged_all.dta
    Output: output/figures/hte_forest.png

    Creates a single-panel forest plot showing heterogeneous treatment effects
    on delta. 8 subgroups × 3 arms = 24 data points, stacked vertically.

    Sections (top to bottom):
      Prior belief      (Low: prior_self_vacc < 5 / High: >= 5)
      Flu vacc exp      (No vaccine / No reaction / Mild / Severe reaction)
      Univ. reliable    (Not reliable: <= 2 / Reliable: == 3)

    Colors: Industry=blue, Academic=orange, Personal=green (same as plot_hte.do)
    Shapes: circle=industry, diamond=academic, square=personal

    Y-position layout (bottom to top):
      Uni Not reliable:   ind=1,    aca=2,    per=3
      Uni Reliable:       ind=4.5,  aca=5.5,  per=6.5
      [section gap → 9]
      Flu No vaccine:     ind=9,    aca=10,   per=11
      Flu No reaction:    ind=12.5, aca=13.5, per=14.5
      Flu Mild reaction:  ind=16,   aca=17,   per=18
      Flu Severe:         ind=19.5, aca=20.5, per=21.5
      [section gap → 24]
      Prior Low:          ind=24,   aca=25,   per=26
      Prior High:         ind=27.5, aca=28.5, per=29.5

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "plot_hte_forest"
do "code/_config.do"
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    1. Load data
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

/*------------------------------------------------------------------------------
    2. Run regressions and collect into postfile
------------------------------------------------------------------------------*/

tempfile coefs
postfile handle str32 section str32 subgroup_label str10 arm ///
    byte section_ord byte subgrp_ord byte arm_ord ///
    float coef float se float ci_lo float ci_hi using `coefs', replace

* --- Section 1: Prior belief ---

regress delta arm_industry arm_academic arm_personal $controls ///
    if prior_self_vacc < 5, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Prior belief") ("Low") ("`arm'") (1) (1) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

regress delta arm_industry arm_academic arm_personal $controls ///
    if prior_self_vacc >= 5, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Prior belief") ("High") ("`arm'") (1) (2) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

* --- Section 2: Flu vacc experience ---

regress delta arm_industry arm_academic arm_personal $controls ///
    if flu_vacc_reaction == 0, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Flu vacc experience") ("No vaccine") ("`arm'") (2) (1) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

regress delta arm_industry arm_academic arm_personal $controls ///
    if flu_vacc_reaction == 1, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Flu vacc experience") ("No reaction") ("`arm'") (2) (2) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

regress delta arm_industry arm_academic arm_personal $controls ///
    if flu_vacc_reaction == 2, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Flu vacc experience") ("Mild reaction") ("`arm'") (2) (3) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

regress delta arm_industry arm_academic arm_personal $controls ///
    if flu_vacc_reaction == 3, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Flu vacc experience") ("Severe reaction") ("`arm'") (2) (4) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

* --- Section 3: Univ. reliable ---

regress delta arm_industry arm_academic arm_personal $controls ///
    if reliable_university <= 2, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Univ. reliable") ("Not reliable (1/2)") ("`arm'") (3) (1) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

regress delta arm_industry arm_academic arm_personal $controls ///
    if reliable_university == 3, robust
foreach arm in industry academic personal {
    local b_val  = _b[arm_`arm']
    local se_val = _se[arm_`arm']
    local ao = cond("`arm'"=="industry", 1, cond("`arm'"=="academic", 2, 3))
    post handle ("Univ. reliable") ("Reliable (3)") ("`arm'") (3) (2) (`ao') ///
        (`b_val') (`se_val') (`b_val' - 1.96*`se_val') (`b_val' + 1.96*`se_val')
}

postclose handle

/*------------------------------------------------------------------------------
    3. Compute y positions
------------------------------------------------------------------------------*/

use `coefs', clear

* Y-position layout (building from bottom to top):
*   Sections appear top-to-bottom in display; Prior = highest y values.
*
*   Within subgroup:  arms spaced 1 unit  (ind=base, aca=base+1, per=base+2)
*   Between subgroups within section: 1.5-unit gap  (next base = prev base + 3.5)
*   Between sections: 2.5-unit gap  (next base = prev personal + 2.5)
*
*   (section_ord, subgrp_ord) → base_y:
*     (3,1) Uni Not reliable:    1
*     (3,2) Uni Reliable:        4.5     (1 + 3.5)
*     section gap: 6.5 + 2.5 = 9.0
*     (2,1) Flu No vaccine:      9
*     (2,2) Flu No reaction:     12.5
*     (2,3) Flu Mild reaction:   16
*     (2,4) Flu Severe reaction: 19.5
*     section gap: 21.5 + 2.5 = 24.0
*     (1,1) Prior Low:           24
*     (1,2) Prior High:          27.5

gen base_y = .
replace base_y = 1    if section_ord==3 & subgrp_ord==1
replace base_y = 4.5  if section_ord==3 & subgrp_ord==2
replace base_y = 9    if section_ord==2 & subgrp_ord==1
replace base_y = 12.5 if section_ord==2 & subgrp_ord==2
replace base_y = 16   if section_ord==2 & subgrp_ord==3
replace base_y = 19.5 if section_ord==2 & subgrp_ord==4
replace base_y = 24   if section_ord==1 & subgrp_ord==1
replace base_y = 27.5 if section_ord==1 & subgrp_ord==2

* arm_ord: 1=industry (bottom), 2=academic (middle), 3=personal (top)
gen ypos = base_y + (arm_ord - 1)

assert !missing(ypos)

/*------------------------------------------------------------------------------
    4. Plot
------------------------------------------------------------------------------*/

* Y-axis labels: subgroup name at academic (middle) row of each subgroup;
* blank at industry and personal rows.
* Academic row ypos = base_y + 1 for each subgroup.

local ylabs ""
local ylabs `"`ylabs' 1 " " 2 "Uni.: Not reliable (1/2)" 3 " ""'
local ylabs `"`ylabs' 4.5 " " 5.5 "Uni.: Reliable (3)" 6.5 " ""'
local ylabs `"`ylabs' 9 " " 10 "Flu: No vaccine" 11 " ""'
local ylabs `"`ylabs' 12.5 " " 13.5 "Flu: No reaction" 14.5 " ""'
local ylabs `"`ylabs' 16 " " 17 "Flu: Mild reaction" 18 " ""'
local ylabs `"`ylabs' 19.5 " " 20.5 "Flu: Severe reaction" 21.5 " ""'
local ylabs `"`ylabs' 24 " " 25 "Prior: Low" 26 " ""'
local ylabs `"`ylabs' 27.5 " " 28.5 "Prior: High" 29.5 " ""'

* Horizontal dividers between sections:
*   Uni/Flu border: midpoint of gap [6.5, 9.0] = 7.75
*   Flu/Prior border: midpoint of gap [21.5, 24.0] = 22.75

twoway ///
    (rcap ci_lo ci_hi ypos if arm=="industry", horizontal lcolor("31 119 180")) ///
    (scatter ypos coef if arm=="industry", ///
        msymbol(O) mcolor("31 119 180") msize(medsmall)) ///
    (rcap ci_lo ci_hi ypos if arm=="academic", horizontal lcolor("255 127 14")) ///
    (scatter ypos coef if arm=="academic", ///
        msymbol(D) mcolor("255 127 14") msize(medsmall)) ///
    (rcap ci_lo ci_hi ypos if arm=="personal", horizontal lcolor("44 160 44")) ///
    (scatter ypos coef if arm=="personal", ///
        msymbol(S) mcolor("44 160 44") msize(medsmall)) ///
    , xline(0, lcolor(gray) lpattern(dash)) ///
      ylabel(`ylabs', angle(0) labsize(small) noticks nogrid) ///
      yline(7.75 22.75, lcolor(gs12) lpattern(solid) lwidth(thin)) ///
      yscale(range(0 31)) ///
      xlabel(, labsize(small)) ///
      xtitle("Treatment Effect on Delta (95% CI)", size(small)) ///
      ytitle("") ///
      legend(order(2 "Industry" 4 "Academic" 6 "Personal") ///
             rows(1) position(6) size(small) region(lcolor(white))) ///
      graphregion(color(white)) plotregion(margin(zero)) ///
      name(hte_forest, replace)

/*------------------------------------------------------------------------------
    5. Export
------------------------------------------------------------------------------*/

graph export "output/figures/hte_forest.png", width(1750) height(2000) replace

di as text "Saved: output/figures/hte_forest.png"

capture log close
