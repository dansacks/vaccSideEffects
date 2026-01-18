global directory C:\Users\dwsacks\Box\VaccSideEffects


import delimited using "$directory/data/flu_survey_main_December+2,+2025_15.54.csv", clear varn(1)
keep if consent =="Yes" & distributionchannel=="anonymous"


gen post_trial = .
gen arm = ""
foreach arm in c i a p {
	replace post_`arm'_trial = subinstr(post_`arm'_trial, "%", "", .) 
	destring post_`arm'_trial, replace 
	assert missing(post_trial) if ~missing(post_`arm'_trial)
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
gen pay = "0.50"
outsheet prolific_id pay using $directory/data/reward_day1.csv, replace ///
	delimit(",") noquote

