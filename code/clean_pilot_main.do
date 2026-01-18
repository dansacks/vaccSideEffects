set seed 1115
import delimited using "data/flu_survey_main_pilot_alt_order_November+17,+2025_09.30.csv", clear varn(1)


keep if length(prolific_pid)==24


foreach arm in c i a p {
	replace post_`arm'_trial = subinstr(post_`arm'_trial, "%", "", .)
	destring post_`arm'_trial, replace 
}

replace posterior_vacc = subinstr(posterior_vacc, "%", "", .)
replace posterior_novacc = subinstr(posterior_novacc, "%", "", .)

destring posterior_vacc posterior_novacc, replace

gen treatment = 0 if fl_17_do == "CONTROLARM"
replace treatment = 1 if fl_17_do == "INDUSTRYARM"
replace treatment = 2 if fl_17_do == "ACADEMICARM"
replace treatment = 3 if fl_17_do == "PERSONALARM"

label define treatment 0 "0. Control" 1 "1. Industry" 2 "2. Academic" 3 "3. Personal"
label values treatment treatment

foreach b in trial  {
	gen 		posterior_`b' = post_c_`b' if 0.treatment
	replace posterior_`b' = post_i_`b' if 1.treatment
	replace posterior_`b' = post_a_`b' if 2.treatment
	replace posterior_`b' = post_p_`b' if 3.treatment
}

foreach v in prior_self_vacc prior_self_placebo {
	gen n = 1 if strpos(`v', "Would not experience")
	replace n = 1 if strpos(`v', "Would definitely not experience")
	replace n = 2 if strpos(`v', "Very unlikely to")
	replace n = 3 if strpos(`v', "Somewhat unlikely to")
	replace n = 4 if strpos(`v', "Neither likely nor")
	replace n = 5 if strpos(`v', "Somewhat likely")
	replace n = 6 if strpos(`v', "Very likely to")
	replace n = 7 if strpos(`v', "Would experience")
	replace n = 7 if strpos(`v', "Would definitely experience")


	rename `v' `v'_s
	rename n `v'
}


label define beliefs 1 "1. Would not" 2 "2. Very unlikely" 3 "3. Somewhat unlikely" ///
	4 "4. Neither likely nor unlikley" 5 "5. Somewhat likely" 6 "6. Very likely" ///
	7 "7. Would happen"
label values prior_self_vacc prior_self_placebo beliefs


gen n = 1 if strpos(vacc_intentions, "already got")
replace n = 3 if strpos(vacc_intentions, "not sure")
replace n = 2 if strpos(vacc_intentions, "I think so")
replace n =4 if strpos(vacc_intentions, "No, I don")
rename vacc_intentions vacc_intentions_s
rename n vacc_intent
label define vi 1 "1. Already got" 2 "2. Think so" 3 "3. Unsure" 4 "4. Don't intend"
label values vacc_intent vi

** clean trust and relevance
qui foreach source in trial academic {
	foreach q in trust relevant {
		replace `q'_`source' = "0" if substr(`q'_`source',1,1)=="0"
		replace `q'_`source' = "10" if substr(`q'_`source',1,2)=="10"	
		destring `q'_`source', replace 
	}
}


** clean demographics
gen n = 1 if age == "18-34"
replace n = 2 if age == "35-49"
replace n = 3 if age == "50-64"
replace n = 4 if age == "65 or older"
rename age age_s
rename n age
label define age 1 "1. 18-34" 2 "2. 35-49" 3 "3. 50-64" 4 "65+"
label values age age

gen n = 1 if gender == "Female"
replace n=2 if gender == "Male"
replace n = 3 if gender == "Other"
replace n =4 if strpos(gender, "Prefer")
rename gender gender_s
rename n gender
label define gender 1 "1. Female" 2 "2. Male" 3 "3. Other" 4 "4. Prefer not to say"

local n 0
gen n = 1 if strpos(education, "Have not finished")
replace n = 2 if strpos(education, "High school degree")
replace n = 3 if strpos(education, "Some college")
replace n = 4 if education == "4-year college degree"
replace n = 5 if strpos(education, "More than a")

rename education educ_s
rename n education
label define education 1 "1. < HS" 2 "2. HS" 3 "3. Some college" ///
	4 "4. College" 5 "5. > College"
label values education education 

gen n = 1 if strpos(income, "Less than")
replace n =2 if substr(income, 1, 3) == "\$25"
replace n =3 if substr(income, 1, 3)== "\$50"
replace n =4 if substr(income, 1, 3)== "\$75"
replace n =5 if strpos(income, "More than")
replace n = 6 if strpos(income, "Prefer")

rename income income_s
rename n income
label define income 1 "1. < 25k" 2 "2. 25k-50k" 3 "3. 50k-75k" 4 "4.75k-100k" ///
	5 "5. > 100k"  6 "6. Prefer not to say"
label values income income

local n = 0
gen n = .
foreach race in White Black Asian Native Other  {
	local ++n
	replace n = `n' if strpos(race, "`race'")
	label define race `n' "`n'. `race'", add
}
replace n = 6 if strpos(race, "Prefer")
label define race 6 "6. Prefer not to say", add
rename race race_s
rename n race
label values race race 
tab race

replace polviews = lower(subinstr(polviews, " ", "_", .))
local views extremely_conservative conservative slightly_conservative moderate ///
	slightly_liberal liberal extremely_liberal prefer_not_to_say
gen n = .
local n=0 
foreach view of local views {
	local ++n
	di "`view'" 
	replace n = `n' if polviews == "`view'"
	local lab = subinstr("`view'", "_", " ", .)
	label define polviews `n' "`n'. `lab'", add 
}
rename polviews polviews_s
rename n polviews
label values polviews polviews


** residual error in posterior
save data/pilot_main_clean, replace 

** pay out beliefs 
gen posterior_right = inrange(posterior_trial, 0.3, 2.3)
count if posterior_right
outsheet prolific_pid if posterior_right using data/pilot_bonus.csv, replace delimit(",")

