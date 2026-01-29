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
        "Subjective belief quantiles:"
        "  Pr({&Delta}<0) = `plt0'"
        "  Pr({&Delta}=0) = `p0'"
        "  Pr(0<{&Delta}<2) = `p02'"
        "  Pr(2<{&Delta}<10) = `p210'"
        "  Pr(10<{&Delta}) = `pgt10'",
				place(e) justification(left) size(large))
				
    text(.4 100
        "Subjective beliefs:"
        "  Mean: `mean'  "
        "  p25: `p25'  "
        "  p50: `p50'  "
        "  p75: `p75'  " ,
				place(w) justification(right) size(large))
    ytitle("", size(large))
    xtitle("Posterior believed side effect rate", size(large))
    xlabel(, labsize(large))
    ylabel(, labsize(large))
    title("CDF of posterior believed side effect rate", size(large) span pos(11))
		xsize(7) ysize(3)
;
# delimit cr


graph export "output/figures/beliefs_pooled.png", replace width(1750) height(750)

* Clean up CDF variable before next analysis
drop prob

*------------------------------------------------------------------------------
* Mean beliefs by vaccine experience and trust
*------------------------------------------------------------------------------
label define ad_alt 1 "Strongly disagree" 2 " " 3 " " 4 " " 5 "Strongly agree"
label values trust_govt follow_doctor ad_alt
label define rxn_alt 0 "No prior vaccine" 1 "No reaction remembered" 2 "Mild" 3 "Severe " 
label values flu_vacc_reaction covid_vacc_reaction rxn_alt 

foreach cat in  trust_govt follow_doctor flu_vacc_reaction covid_vacc_reaction {
    preserve
    if "`cat'" == "flu_vacc_reaction" local title "Flu vaccine reaction"
    if "`cat'" == "covid_vacc_reaction" local title "Covid vaccine reaction"
    if "`cat'" == "trust_govt" local title "Trust gov on vaccines"
    if "`cat'" == "follow_doctor" local title "Follow doc on vaccines"

    * Vaccine reaction panels need more bottom margin for angled labels
    if inlist("`cat'", "flu_vacc_reaction", "covid_vacc_reaction") {
				local ylab 0(10)30
    }
    else {
				local ylabel 0(10)40
    }
		local panel_margin graphregion(margin(b+5))
    collapse (mean) delta (semean) se=delta, by(`cat')
    gen upper = delta + 1.96*se
    gen lower = delta - 1.96*se
    drop if missing(`cat')

    # delimit ;
    twoway
        (bar delta `cat', color(stc1%60))
        (rcap upper lower `cat', color(black)),
				legend(off) name(`cat', replace)
        xlabel(,valuelabel labsize(medlarge) angle(45))
				
        ylabel(`ylabel', labsize(medlarge))
        title("`title'", pos(11) size(large) span)
        xtitle("")
        xsize(7) ysize(8) 
    ;
    # delimit cr

    restore
}


* Combine vaccine reaction plots
graph combine flu_vacc_reaction covid_vacc_reaction, cols(2) iscale(1) ///
	xsize(7) ysize(4)
graph export "output/figures/delta_by_vacc_reaction.png", replace width(1750) height(1000)

* Combine trust plots
graph combine trust_govt follow_doctor, cols(2) iscale(1) ///
	xsize(7) ysize(4) 
graph export "output/figures/delta_by_trust.png", replace width(1750) height(1000)


** beliefs by trust in trial and relevance of trial
bysort trust_trial: egen delta_by_trust = mean(delta)
by trust_trial: gen tag_trust = _n==1 

bysort relevant_trial: egen delta_by_relevant =mean(delta)
by relevant_trial: gen tag_relevant = _n ==1

# delimit ;
twoway 
	(connected delta_by_trust trust_trial if tag_trust, sort msize(large))
	(histogram trust_trial, discrete color(stc2%25) yaxis(2))
	,
	legend(off)
	xtitle("Trust in trial", size(large)) ytitle("")  ytitle("", axis(2))
	ylabel(0(10)30) ylabel(0(.05).25, axis(2))
	title("Mean {&Delta}{sub:self} by trust", span pos(11) size(large))
	xsize(7) ysize(6)
	xlabel(, labsize(medlarge))
	name(trust, replace)
;
# delimit cr

# delimit ;
twoway 
	(connected delta_by_relevant relevant_trial if tag_relevant, sort msize(large))
	(histogram relevant_trial, discrete color(stc2%25) yaxis(2))
	,
	legend(off)
	xtitle("Trial relevance", size(large)) ytitle("") ytitle("", axis(2))
	ylabel(0(10)30) ylabel(0(.05).25, axis(2))
	title("Mean {&Delta}{sub:self} by relevance", span pos(11) size(large))
	xsize(7) ysize(6)
	xlabel(, labsize(medlarge))
	name(relevance, replace)
;
# delimit cr
graph combine trust relevance, cols(2) xsize(7) ysize(3) iscale(1)

graph export "output/figures/delta_by_trial_views.png", replace width(1750) height(750)

capture log close
