
** pediatric unvaccinated rate 
local data "Vaccination_Coverage_and_Exemptions_among_Kindergartners_20260128.csv"

import delimited using "raw_data/`data'", clear 

gen is_state = inlist(geography, "Alabama", "Alaska", "Arizona", "Arkansas", "California") | ///
	inlist(geography, "Colorado", "Connecticut", "Delaware", "Florida", "Georgia") | ///
	inlist(geography, "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa") | ///
	inlist(geography, "Kansas", "Kentucky", "Louisiana", "Maine", "Maryland") | ///
	inlist(geography, "Massachusetts", "Michigan", "Minnesota", "Mississippi", "Missouri") | ///
	inlist(geography, "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey") | ///
	inlist(geography, "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio") | ///
	inlist(geography, "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina") | ///
	inlist(geography, "South Dakota", "Tennessee", "Texas", "Utah", "Vermont") | ///
	inlist(geography, "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming")


destring estimate, gen(est_n) force
gen unvacc = 100 - est_n
table schoolyear if strpos(vaccineexemption, "Polio") , ///
	stat(mean unvacc)

	
gen type = 1 if strpos(vaccineexemption, "DTP")
replace type = 2 if strpos(vaccineexemption, "Hepatitis")
replace type = 3 if vaccineexemption == "MMR"
replace type = 4 if strpos(vaccineexemption, "MMR (PAC)")
replace type = 5 if strpos(vaccineexemption, "Polio")

* impute population size when missing 
keep if is_state & ~missing(type)
bysort geography schoolyear (populationsize) : ///
	assert populationsize == populationsize[1] if ~missing(populationsize)
bysort geography schoolyear (populationsize) : replace populationsize = populationsize[1]

keep if is_state & ~missing(type)
keep geography schoolyear est_n type unvacc populationsize
reshape wide est_n unvacc, i(geography schoolyear) j(type)

rename unvacc1 dtp_unvacc
rename unvacc2 hepb_unvacc
gen mmr_unvacc = unvacc4 
rename unvacc5 polio_unvacc
collapse (mean) dtp_unvacc hepb_unvacc mmr_unvacc polio_unvacc ///
	[fw=populationsize],	by(schoolyear)
gen year = real(substr(schoolyear, 1,4))

gen l1 = "TDAP" if year == 2024 
gen l2 = "Hep-B" if year == 2024 
gen l3 = "MMR" if year == 2024 
gen l4 = "Polio" if year == 2024 
keep if year>=2014
# delimit ;
twoway
	(connected dtp_unvacc year, mlabel(l1) mlabpos(3) mlabsize(lage))
	(connected mmr_unvacc year, mlabel(l2) mlabpos(3) mlabsize(large))
	(connected hepb_unvacc year, mlabel(l3) mlabpos(3) mlabsize(large))
	(connected polio_unvacc year, mlabel(l4) mlabpos(3) mlabsize(large)
		color(gs5%90) mlabcolor(gs5%90))
	, 
	legend(off)
	title("Share of unvaccianted kindergartners", pos(11) span)
	xtitle("School year", size(large)) ytitle("")
	graphregion(margin(r+10))
	xlabel(,labsize(large)) ylabel(, labsize(large))
	xsize(7) ysize(4) 
	ylabel(0(2)8)
	text(0 2014 "Source: data.cdc.gov", place(e))
	name(peds, replace)
;
# delimit cr
graph export output/figures/pediatric_unvacc.png, width(1750) height(1000) replace

