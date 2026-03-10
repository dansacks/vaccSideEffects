
clear all
global scriptname "plot_trust_by_hes"
do "code/_config.do"

use "derived/prescreen_clean.dta", clear

gen ok_sample = consent == 1 & failed_attn == 0 & ~is_preview & first_attempt == 1
keep if ok_sample

gen hes = vacc_intent <= 3

forvalues k = 1/5 {
	gen pt`k' = (trust_govt   == `k') if !missing(trust_govt)
	gen pf`k' = (follow_doctor == `k') if !missing(follow_doctor)
}

collapse (mean) pt1 pt2 pt3 pt4 pt5 pf1 pf2 pf3 pf4 pf5, by(hes)
reshape long pt pf, i(hes) j(cat)

replace cat = 2*cat
replace cat = cat - .45 if hes == 0
replace cat = cat + .45 if hes == 1

* --- trust_govt panel ---
# delimit ;
twoway
	(bar pt cat if hes == 0, barwidth(.9) fcolor(stc1%30) lcolor(none))
	(bar pt cat if hes == 1, barwidth(.9) fcolor(stc2%60) lcolor(none))
	,
	title("Trust government's vaccine information", span pos(11))
	ytitle("") ylabel(0(0.2)0.6)
	xtitle("")
	xlabel(2 "Strongly disagree" 4 "Somewhat disagree" 6 "Neither"
	       8 "Somewhat agree" 10 "Strongly agree", angle(45))
	legend(ring(0) pos(10) cols(1)
		order(1 "Not vaccine hesitant" 2 "Vaccine hesitant"))
	xsize(4) ysize(4)
	name(trust_govt, replace)
;
# delimit cr

* --- follow_doctor panel ---
# delimit ;
twoway
	(bar pf cat if hes == 0, barwidth(.9) fcolor(stc1%30) lcolor(none))
	(bar pf cat if hes == 1, barwidth(.9) fcolor(stc2%60) lcolor(none))
	,
	title("Follow doctor's vaccine recommendations", span pos(11))
	ytitle("") ylabel(0(0.2)0.6)
	xtitle("")
	xlabel(2 "Strongly disagree" 4 "Somewhat disagree" 6 "Neither"
	       8 "Somewhat agree" 10 "Strongly agree", angle(45))
	legend(off)
	xsize(4) ysize(4)
	name(follow_doctor, replace)
;
# delimit cr

* --- combine panels ---
graph combine trust_govt follow_doctor, cols(1) xsize(4) ysize(8)
graph export output/figures/trust_by_hes.png, replace width(1000) height(2000)

capture log close
