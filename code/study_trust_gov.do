global directory C:\Users\sacks\Box\VaccSideEffects
global olddir  C:\Users\sacks\Box\VaccDemand
local file vacc_se_prescreen_full
local date November+28,+2025_07.35

import delimited using "$directory/data/`file'_`date'.csv", clear varn(1)
keep if _n> 15

gen consented = consent == "Yes"
gen pass_attention = favoritenumber == "1965"

gen next_study = strpos(vaccinestatus, "I may get") | ///
	strpos(vaccinestatus, "No, I do not")

rename q42 prolific_id


foreach v in government government_prior {
	gen tt = .
	replace tt = 1 if `v' == "Strongly disagree."
	replace tt = 2 if `v' == "Somewhat disagree."
	replace tt = 3 if `v' == "Neither agree nor disagree."
	replace tt = 4 if `v' == "Somewhat agree."
	replace tt = 5 if `v' == "Strongly agree."
	
	rename `v' `v'_s
	rename tt `v'
}

label define agree 1 "1. Strongly disagree" 2 "2. Somewhat disagree" ///
	3 "3. Neither agree nor disagree" 4 "4. Somewhat agree" 5 "5. Strongly agree"
	
label values government government_prior agree


histogram government, discrete start(1) xlabel(1(1)5) width(1) percent

histogram government_prior, discrete start(1) xlabel(1(1)5) width(1) percent

gen pro_vacc = 1-next_study
table government, stat(mean pro_vacc)
table government_prior, stat(mean pro_vacc)

bysort government: gen ngov = _N
by government: egen pro_vacc_rate = mean(pro_vacc)
by government: gen tag = _n ==1
gen gov_rate = ngov/_N

bysort government_prior: gen nprior = _N
by government_prior: egen pro_vacc_rate_prior = mean(pro_vacc)
by government_prior: gen tag_p = _n==1
gen prior_rate = nprior/_N


# delimit ;
twoway
	(connected pro_vacc_rate government if tag & ~missing(government), sort)
	(connected pro_vacc_rate_prior government_prior if tag_p & ~missing(government_prior), sort)
	,
	legend(ring(0) pos(10) 
		order(1 "Gov flu vacc info reliable?" 2 "Prior gov flu vacc info reliable?"))
		ylabel(0(.15).75)
	xlabel(1 "Strongly disagree" 2 "Somewhat disagree"
		3 "Neutral" 4 "Somewhat agree" 5 "Strongly agree", angle(45) labsize(small))
	title("Pr(Vaccinated or intend to vaccinate against flu) by trust in government",
		size(small))
	graphregion(margin(r+10 l+10))
	name(vacc_rate, replace)
;
# delimit cr


# delimit ;
twoway
	(bar gov_rate government if tag & ~missing(government), color(stc1%50))
	(bar prior_rate government_prior if tag_p 
		& ~missing(government_prior), fcolor(none) lcolor(black))
	,
	legend(ring(0) pos(10) 
		order(1 "Gov flu vacc info reliable?" 2 "Prior gov flu vacc info reliable?"))
	xlabel(1 "Strongly disagree" 2 "Somewhat disagree"
		3 "Neutral" 4 "Strongly agree" 5 "Strong agree", angle(45) labsize(small))
	title("Distribution of trust in government",
		size(small))
	name(dist, replace)
;
# delimit cr

graph combine dist vacc_rate, cols(1) xsize(5) ysize(6) imargin(small)
graph export $directory/figures/vacc_by_trust2025.pdf , replace


use $olddir/data/deidentify_merge, clear


gen pro_vacc = vacc_intent < 3

bysort vhs_government: gen ngov = _N
by vhs_government: egen pro_vacc_rate = mean(pro_vacc)
by vhs_government: gen tag = _n ==1
gen gov_rate = ngov/_N


# delimit ;
twoway
	(connected pro_vacc_rate vhs_government if tag & ~missing(vhs_government), sort)
	,
	ylabel(0(.15).75)
	xlabel(1 "Strongly disagree" 2 "Somewhat disagree"
		3 "Neutral" 4 "Somewhat agree" 5 "Strongly agree", angle(45) labsize(small))
	title("Pr(Vaccinated or intend to vaccinate against flu) by trust in government, 2024",
		size(small))  xtitle("") ytitle("")
	graphregion(margin(r+10 l+10))
	name(vacc_rate, replace)
;
# delimit cr


# delimit ;
twoway
	(bar gov_rate vhs_government if tag & ~missing(vhs_government), color(stc1%50))
	,
	xlabel(1 "Strongly disagree" 2 "Somewhat disagree"
		3 "Neutral" 4 "Strongly agree" 5 "Strong agree", angle(45) labsize(small))
	title("Distribution of trust in government, 2024",
		size(small)) xtitle("") ytitle("")
	name(dist, replace)
;
# delimit cr

graph combine dist vacc_rate, cols(1) xsize(5) ysize(6) imargin(small)
graph export $directory/figures/vacc_by_trust2024.pdf , replace

