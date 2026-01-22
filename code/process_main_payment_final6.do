global directory C:\Users\dwsacks\Box\VaccSideEffects

foreach d in 1 3 6 {
	import delimited $directory/data/reward_day`d'.csv, clear
	tempfile day`d'
	duplicates drop
	save `day`d''
}


import delimited using "$directory/data/flu_survey_main_December+8,+2025_15.41.csv", clear varn(1)
keep if consent =="Yes" & distributionchannel=="anonymous"


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



sum post_trial
gen reward = inrange(post_trial, 0.2, 2.4)
count
count if reward
keep if reward

rename q52 prolific_id
keep prolific_id 
duplicates drop

foreach d in  1 3 6 {
	merge m:1 prolific_id using `day`d'', keep(1) nogen
	drop pay
}

gen pay = "0.50"




outsheet prolific_id pay using $directory/data/reward_final.csv, replace ///
	delimit(",") noquote


	
