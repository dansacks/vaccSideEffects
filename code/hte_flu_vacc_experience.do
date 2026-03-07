/*==============================================================================
    HTE by Flu Vaccine Experience

    Input:  derived/merged_all.dta
    Output: output/tables/het_flu_vacc_experience.tex
            output/tables/het_flu_vacc_experience.md

    Estimates treatment effect on delta for each level of flu_vacc_reaction:
      0 = No vaccine
      1 = No reaction
      2 = Mild reaction
      3 = Severe reaction

    4-column table (one column per subgroup), single outcome (delta).

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "hte_flu_vacc_experience"
do "code/_config.do"
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    1. Load data
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Representative"

local keyvars arm_industry arm_academic arm_personal

/*------------------------------------------------------------------------------
    2. Run regressions by flu vaccine experience level
------------------------------------------------------------------------------*/

eststo clear

foreach k in 0 1 2 3 {
    regress delta `keyvars' $controls if flu_vacc_reaction == `k', robust
    sum delta if arm_control == 1 & flu_vacc_reaction == `k'
    estadd scalar cm = r(mean)
    eststo delta_`k'
}

/*------------------------------------------------------------------------------
    3. Export table
------------------------------------------------------------------------------*/

* .tex output: fragment only (no headers, no environment)
esttab delta_0 delta_1 delta_2 delta_3 ///
    using output/tables/het_flu_vacc_experience.tex, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

* Append subgroup label row to .tex file
file open _fout using "output/tables/het_flu_vacc_experience.tex", write append
file write _fout "Flu vacc experience & No vaccine & No reaction & Mild & Severe"
file close _fout

* .md output: include column titles in header row
esttab delta_0 delta_1 delta_2 delta_3 ///
    using output/tables/het_flu_vacc_experience.md, ///
    b(%9.3f) se(%9.3f) keep(`keyvars') label nostar ///
    mtitles("No vaccine" "No reaction" "Mild" "Severe") ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nonotes nonumbers

* Append subgroup label row to .md file
file open _fmd using "output/tables/het_flu_vacc_experience.md", write append
file write _fmd "| Flu vacc experience | No vaccine | No reaction | Mild | Severe |"
file close _fmd

di as text "Saved: output/tables/het_flu_vacc_experience.tex"
di as text "Saved: output/tables/het_flu_vacc_experience.md"

capture log close
