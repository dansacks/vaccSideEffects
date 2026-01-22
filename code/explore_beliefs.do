/*==============================================================================
    Descriptive Analysis of Side Effect Beliefs

    Creates:
    1. CDF of posterior believed side effect rate (delta)
    2. Mean beliefs by flu/covid vaccine reaction experience
    3. Mean beliefs by trust in government and doctor-following

    Outputs:
        output/figures/beliefs_pooled.png
        output/figures/delta_by_vacc_reaction.png
        output/figures/delta_by_trust.png

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "explore_beliefs"
do "code/_config.do"

* Load merged data
use "derived/merged_main_pre.dta", clear

*------------------------------------------------------------------------------
* CDF of beliefs (pooled across all arms)
*------------------------------------------------------------------------------

assert ~missing(delta)

* Calculate distribution statistics
count if delta < 0
local plt0 = string(r(N)/_N, "%3.2f")

count if delta == 0
local p0 = string(r(N)/_N, "%3.2f")

count if delta > 0 & delta <= 2
local p02 = string(r(N)/_N, "%3.2f")

count if delta > 2 & delta <= 10
local p210 = string(r(N)/_N, "%3.2f")

count if delta > 10
local pgt10 = string(r(N)/_N, "%3.2f")

sum delta, detail
local mean = string(r(mean), "%3.2f")
local p25 = string(r(p25), "%3.2f")
local p50 = string(r(p50), "%3.2f")
local p75 = string(r(p75), "%3.2f")

* Generate CDF
cumul delta, gen(prob)
sort delta prob

# delimit ;
twoway
    (line prob delta if delta >= -50),
    text(.65 -50
        "Clinical trial estimate: -1.7 to 1.0"
        " "
        "Subjective beliefs:"
        "  Pr({&Delta}<0) = `plt0'"
        "  Pr({&Delta}=0) = `p0'"
        "  Pr(0<{&Delta}<2) = `p02'"
        "  Pr(2<{&Delta}<10) = `p210'"
        "  Pr(10<{&Delta}) = `pgt10'"
        " "
        "  Mean: `mean'"
        "  p25: `p25'"
        "  p50: `p50'"
        "  p75: `p75'" ,
        place(e) justification(left))
    ytitle("")
    xtitle("Posterior believed side effect rate")
    title("Cumulative distribution of posterior believed side effect rate")
;
# delimit cr

graph export "output/figures/beliefs_pooled.png", replace width(1600) height(900)

* Clean up CDF variable before next analysis
drop prob

*------------------------------------------------------------------------------
* Mean beliefs by vaccine experience and trust
*------------------------------------------------------------------------------

foreach cat in flu_vacc_reaction covid_vacc_reaction trust_govt follow_doctor {
    preserve

    if "`cat'" == "flu_vacc_reaction" local title "Flu vaccine reaction"
    if "`cat'" == "covid_vacc_reaction" local title "Covid vaccine reaction"
    if "`cat'" == "trust_govt" local title "Trust gov on vaccines"
    if "`cat'" == "follow_doctor" local title "Follow doc on vaccines"

    collapse (mean) delta (semean) se=delta, by(`cat')
    gen upper = delta + 1.96*se
    gen lower = delta - 1.96*se
    drop if missing(`cat')

    # delimit ;
    twoway
        (bar delta `cat', color(stc1%60))
        (rcap upper lower `cat', color(black))
        ,
        legend(off)
        xlabel(,valuelabel labsize(small) angle(45))
        name(`cat', replace)
        title("`title'", pos(11) size(medium))
        xtitle("")
        xsize(3) ysize(4)
        graphregion(margin(b+5))
    ;
    # delimit cr

    restore
}

* Combine vaccine reaction plots
graph combine flu_vacc_reaction covid_vacc_reaction, cols(2) ///
    graphregion(margin(b+10)) xsize(6) ysize(4)
graph export "output/figures/delta_by_vacc_reaction.png", replace width(600) height(400)

* Combine trust plots
graph combine trust_govt follow_doctor, cols(2) xsize(6) ysize(4) ///
    graphregion(margin(b+10))
graph export "output/figures/delta_by_trust.png", replace width(600) height(400)

capture log close
