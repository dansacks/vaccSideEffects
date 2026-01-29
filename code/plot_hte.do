/*==============================================================================
    HTE Coefficient Plot

    Input:  derived/merged_all.dta
    Output: output/figures/hte_coefplot.png

    Creates a 2×4 faceted coefficient plot showing heterogeneous treatment effects:
    - Rows: 2 outcomes (delta, main_maybe)
    - Columns: 4 splitting variables (high_prior, bad_experience, high_trust, high_relevance)
    - Within each panel: 3 treatment arms, with Low/High subgroup points offset vertically

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "plot_hte"
do "code/_config.do"
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    1. Load data and create heterogeneity splits
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

* Create heterogeneity splits (same as heterogeneous_treatment_effects.do)
gen high_prior = prior_self_vacc >= 5
gen bad_experience = ~inlist(flu_vacc_reaction, 1, 2)
gen high_trust = trust_trial > 5
gen high_relevance = relevant_trial > 5

/*------------------------------------------------------------------------------
    2. Build coefficient dataset using postfile
------------------------------------------------------------------------------*/

tempfile coefs
postfile handle str12 outcome str16 split str10 treatment subgroup ///
    coef se ci_lo ci_hi using `coefs', replace

foreach outcome in delta main_maybe {
    foreach split in high_prior bad_experience high_trust high_relevance {
        forvalues subgrp = 0/1 {
            regress `outcome' arm_industry arm_academic arm_personal ///
                $controls if `split'==`subgrp', robust

            foreach arm in industry academic personal {
                local b = _b[arm_`arm']
                local se = _se[arm_`arm']
                post handle ("`outcome'") ("`split'") ("`arm'") (`subgrp') ///
                    (`b') (`se') (`b' - 1.96*`se') (`b' + 1.96*`se')
            }
        }
    }
}
postclose handle

/*------------------------------------------------------------------------------
    3. Prepare data for plotting
------------------------------------------------------------------------------*/

use `coefs', clear

* Create y-position: treatment baseline (1=industry, 2=academic, 3=personal)
gen ybase = cond(treatment=="industry", 1, cond(treatment=="academic", 2, 3))

* Offset subgroups vertically (+/- 0.15)
gen ypos = ybase + cond(subgroup==0, -0.15, 0.15)

* Define colors (RGB)
* Blue for industry: 31 119 180
* Orange for academic: 255 127 14
* Green for personal: 44 160 44

/*------------------------------------------------------------------------------
    4. Create 8 individual panels (2 outcomes × 4 splits)
------------------------------------------------------------------------------*/

* Define labels for column titles
local high_prior_label "Prior"
local bad_experience_label "Experience"
local high_trust_label "Trust"
local high_relevance_label "Relevance"

* Define labels for row titles
local delta_label "Delta"
local main_maybe_label "Vacc Intent"

local row = 0
foreach out in delta main_maybe {
    local row = `row' + 1
    local col = 0
    foreach spl in high_prior bad_experience high_trust high_relevance {
        local col = `col' + 1

        * Create short graph name (max 32 chars)
        local gname "g`row'_`col'"

        * Get labels
        local spl_label "``spl'_label'"
        local out_label "``out'_label'"

        * Determine if this is top row (show column title) or left column (show y labels)
        local title_opt ""
        if `row' == 1 {
            local title_opt `"title("`spl_label'", size(medium))"'
        }

        local ylab_opt `"ylabel(1 "Industry" 2 "Academic" 3 "Personal", angle(0) labsize(small))"'
        if `col' > 1 {
            local ylab_opt "ylabel(1 " " 2 " " 3 " ", angle(0) labsize(small) noticks)"
        }

        * Build twoway command with all 6 point/CI combinations
        * Industry (blue): subgroup 0 = circle, subgroup 1 = square
        * Academic (orange): subgroup 0 = circle, subgroup 1 = square
        * Personal (green): subgroup 0 = circle, subgroup 1 = square

        * Add legend only to bottom-right panel (row 2, col 4)
        local legend_opt "legend(off)"
        if `row' == 2 & `col' == 4 {
            local legend_opt `"legend(order(2 "Low" 3 "High") rows(1) position(6) size(small) region(lcolor(white)))"'
        }

        twoway ///
            (rcap ci_lo ci_hi ypos if outcome=="`out'" & split=="`spl'" ///
                & treatment=="industry", horizontal lcolor("31 119 180")) ///
            (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
                & treatment=="industry" & subgroup==0, ///
                msymbol(O) mcolor("31 119 180") msize(medium)) ///
            (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
                & treatment=="industry" & subgroup==1, ///
                msymbol(S) mcolor("31 119 180") msize(medium)) ///
            (rcap ci_lo ci_hi ypos if outcome=="`out'" & split=="`spl'" ///
                & treatment=="academic", horizontal lcolor("255 127 14")) ///
            (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
                & treatment=="academic" & subgroup==0, ///
                msymbol(O) mcolor("255 127 14") msize(medium)) ///
            (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
                & treatment=="academic" & subgroup==1, ///
                msymbol(S) mcolor("255 127 14") msize(medium)) ///
            (rcap ci_lo ci_hi ypos if outcome=="`out'" & split=="`spl'" ///
                & treatment=="personal", horizontal lcolor("44 160 44")) ///
            (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
                & treatment=="personal" & subgroup==0, ///
                msymbol(O) mcolor("44 160 44") msize(medium)) ///
            (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
                & treatment=="personal" & subgroup==1, ///
                msymbol(S) mcolor("44 160 44") msize(medium)) ///
            , xline(0, lcolor(gray) lpattern(dash)) ///
              `ylab_opt' ///
              yscale(range(0.5 3.5)) ///
              xlabel(, labsize(small)) ///
              `title_opt' ///
              ytitle("") xtitle("") ///
              `legend_opt' ///
              graphregion(color(white)) plotregion(margin(zero)) ///
              name(`gname', replace)
    }
}

/*------------------------------------------------------------------------------
    5. Combine panels and export
------------------------------------------------------------------------------*/

* Combine all panels with row titles using note option on leftmost panels
* First, recreate leftmost panels with row labels
foreach out in delta main_maybe {
    local spl "high_prior"
    local spl_label "Prior"

    if "`out'" == "delta" {
        local row = 1
        local out_label "Delta"
    }
    else {
        local row = 2
        local out_label "Vacc Intent"
    }

    local gname "g`row'_1"
    local title_opt ""
    if `row' == 1 {
        local title_opt `"title("`spl_label'", size(medium))"'
    }

    twoway ///
        (rcap ci_lo ci_hi ypos if outcome=="`out'" & split=="`spl'" ///
            & treatment=="industry", horizontal lcolor("31 119 180")) ///
        (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
            & treatment=="industry" & subgroup==0, ///
            msymbol(O) mcolor("31 119 180") msize(medium)) ///
        (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
            & treatment=="industry" & subgroup==1, ///
            msymbol(S) mcolor("31 119 180") msize(medium)) ///
        (rcap ci_lo ci_hi ypos if outcome=="`out'" & split=="`spl'" ///
            & treatment=="academic", horizontal lcolor("255 127 14")) ///
        (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
            & treatment=="academic" & subgroup==0, ///
            msymbol(O) mcolor("255 127 14") msize(medium)) ///
        (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
            & treatment=="academic" & subgroup==1, ///
            msymbol(S) mcolor("255 127 14") msize(medium)) ///
        (rcap ci_lo ci_hi ypos if outcome=="`out'" & split=="`spl'" ///
            & treatment=="personal", horizontal lcolor("44 160 44")) ///
        (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
            & treatment=="personal" & subgroup==0, ///
            msymbol(O) mcolor("44 160 44") msize(medium)) ///
        (scatter ypos coef if outcome=="`out'" & split=="`spl'" ///
            & treatment=="personal" & subgroup==1, ///
            msymbol(S) mcolor("44 160 44") msize(medium)) ///
        , xline(0, lcolor(gray) lpattern(dash)) ///
          ylabel(1 "Industry" 2 "Academic" 3 "Personal", angle(0) labsize(small)) ///
          yscale(range(0.5 3.5)) ///
          xlabel(, labsize(small)) ///
          `title_opt' ///
          ytitle("`out_label'", size(medium)) xtitle("") ///
          legend(off) ///
          graphregion(color(white)) plotregion(margin(zero)) ///
          name(`gname', replace)
}

* Combine all panels
graph combine g1_1 g1_2 g1_3 g1_4 ///
              g2_1 g2_2 g2_3 g2_4, ///
    rows(2) cols(4) ///
    b1title("Treatment Effect (95% CI)", size(small)) ///
    xsize(16) ysize(8) imargin(small) ///
    graphregion(color(white)) ///
    name(combined, replace)

* Export
graph export "output/figures/hte_coefplot.png", width(3200) height(1600) replace

di as text "Saved: output/figures/hte_coefplot.png"

capture log close
