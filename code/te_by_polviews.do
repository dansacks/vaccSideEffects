
clear all
global scriptname "treatment_effects"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Define controls
------------------------------------------------------------------------------*/

do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    2. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

* Create link_click if not already present (max of link1-4)
capture confirm variable link_click
if _rc {
    egen link_click = rowmax(link1_clicked link2_clicked link3_clicked link4_clicked)
    label var link_click "Any link clicked"
}

* Create vaccination outcome (got vaccine or already had it)
gen vacc_post = got_flu_vacc == 1 | flu_why_already == 1 if ~missing(got_flu_vacc)

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

/*------------------------------------------------------------------------------
    3. Histogram
------------------------------------------------------------------------------*/
recode polviews (8=9)

bysort polviews: egen mdelta = mean(delta)
by polviews: gen tag = _n == 1

# delimit ;
twoway
	(scatter mdelta polviews if tag, color(stc1) msize(vlarge))
	(histogram polviews, discrete fcolor(gs5%10) lcolor(gs4) yaxis(2))
	,
	ylabel(0(5)25) ylabel(, nolabel axis(2)) ytitle("Density of polviews", axis(2))
	xlabel(1(1)7) 
	xlabel(1 "Very liberal" 4 "Neutral" 7 "Very conservative" 9 "NR", 
		labsize(large))  
	ytitle("") title("Mean {&Delta}{sub:self}", span pos(11)) ylabel(, labsize(large))
	xtitle("Political views", size(large)) 
	xsize(7) ysize(4)
	legend(off)
;
# delimit cr
graph export output/figures/polviews_dist.png, width(1750) height(1000) replace


** Show differential trust and relevance by political views 
bysort polviews: egen mtrust = mean(trust_trial)
by polviews: egen mrelevance = mean(relevant_trial)

# delimit ;
twoway
	(scatter mtrust polviews if tag & polviews<8, msize(large))
	(scatter mrelevance polviews if tag & polviews<8, msize(large) msymbol(Oh))
	, 
	legend(ring(0) pos(7) cols(1) 
		order(1 "Trust in trial (0-10 scale)" 2 "Relevance of trial (0-10 scale)"))
	xlabel(1(1)7) xlabel(1 "Very liberal" 4 "Moderate" 7 "Very conservative",
		labsize(med_large) ) xtitle("")
	title("Mean trial view by politics", span pos(11))
	xsize(7) ysize(4) 
	graphregion(margin(r+10))
	name(trial, replace)
;
# delimit cr
graph export output/figures/trust_by_polviews.png, replace width(1750) height(1000)


** Show differential trust and relevance by political views 
gen uses_uni = info_university>=3 
gen relu = 3.reliable_university
bysort polviews: egen muse = mean(uses_uni)
by polviews: egen mrel = mean(relu)

# delimit ;
twoway
	(scatter mrel polviews if tag & polviews<8, msize(large))
	(scatter muse polviews if tag & polviews<8, msize(large) msymbol(Oh))
	, 
	legend(ring(0) pos(7) cols(1) 
		order(
			1 "Says university info is reliable"
			2 "Uses university health info at least sometimes" ))
	xlabel(1(1)7) xlabel(1 "Very liberal" 4 "Moderate" 7 "Very conservative",
		labsize(med_large) ) xtitle("")
	title("Mean view of university info by politics", span pos(11))
	xsize(7) ysize(4) 
	graphregion(margin(r+10))
;
# delimit cr
graph export output/figures/uni_by_polviews.png, replace width(1750) height(1000)


/*------------------------------------------------------------------------------
    4. Generate HTE table using esttab
------------------------------------------------------------------------------*/

gen liberal = inrange(polviews, 1,3)
eststo clear
local keyvars arm_industry arm_academic arm_personal

qui foreach y in post_trial delta main_maybe vacc_post {
	noi di "outcome `y'"
	forvalues l = 0/1 {
		reg `y' `keyvars' $controls if liberal==`l', r 
		sum `y' if arm_control & liberal==`l'
		estadd scalar cm = r(mean)
		eststo `y'_`l'
		noi di "  group `l' (mean: `r(mean)')"
		foreach v of local keyvars {
			noi di "    `v' :"  _b[`v']  "(" _se[`v']  ")"
			
		}
	}
}


/*------------------------------------------------------------------------------
    5. Put to md file 
------------------------------------------------------------------------------*/

local coltitles mtitles("SE (trial)" "Delta" "Vacc Intent" ///
	"SE (trial)" "Delta" "Vacc Intent")
	

* .md output: include column titles in header row, followed by split label row
esttab post_trial_0 delta_0 main_maybe_0 post_trial_1  delta_1 main_maybe_1 ///
		using output/tables/het_polviews.md, ///
		b(%9.3f) se(%9.3f) keep(`keyvars') label nostar `coltitles' ///
		stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
		fragment replace nonotes nonumbers

* Append split label row to .md file
local rowlab "Politics:"
local lab0 "Cons/mod"
local lab1 "Liberal"
file open _het_pv using "output/tables/het_polviews.md", write append
	file write _het_pv "| `rowlab' | `lab0' | `lab0' | `lab0' | `lab1' | `lab1' | `lab1' |" _n
	file close _het_pv

