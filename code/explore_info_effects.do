


global directory c:\users\sacks\Box\vaccSideEffects
import delimited using "$directory/data/flu_survey_main_December+9,+2025_08.17.csv", clear varn(1)
keep if consent =="Yes" & distributionchannel=="anonymous"


gen arm_n = 0 if fl_17_do =="CONTROLARM"
replace arm_n = 1 if fl_17_do =="INDUSTRYARM"
replace arm_n = 2 if fl_17_do =="ACADEMICARM"
replace arm_n = 3 if fl_17_do =="PERSONALARM"

gen post_trial = .
gen arm = ""
foreach arm in c i a p {
	replace post_`arm'_trial = subinstr(post_`arm'_trial, "%", "", .) 
	destring post_`arm'_trial, replace force
	count if missing(post_`arm'_trial) & ~missing(post_`arm'_trial)
	assert r(N)<=1
	replace post_trial = post_`arm'_trial if ~missing(post_`arm'_trial)
	replace arm = "`arm'" if ~missing(post_`arm'_trial)
}




reg post_trial i.arm_n, r

foreach v in posterior_novacc posterior_vacc {
	gen pct= strpos(`v', "%")  != 0 
	replace `v' = subinstr(`v', "%", "", .)
	destring `v', replace
	replace `v' = `v' / 100 if pct
	drop pct
}


egen prior_p = group(prior_self_placebo)
egen prior_v = group(prior_self_vacc)

gen delta = posterior_vacc - posterior_novacc
sum delta, d



reg post_trial i.arm_n i.prior_p i.prior_v, r
reg delta i.arm_n i.prior_p i.prior_v, r


gen maybe = strpos(vacc_intentions, "I have already") | strpos(vacc_intentions, "I intend to")

reg maybe i.arm_n i.prior_p i.prior_v if ~strpos(vacc_intentions, "I have already"), r


gen link_click = 0
forvalues l = 1/4 {
	replace link_click = 1 if link`l'_clicked == "1"
}
