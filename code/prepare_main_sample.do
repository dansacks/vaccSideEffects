global directory C:\Users\dwsacks\Box\VaccSideEffects


local file vacc_se_prescreen_full
local date November+28,+2025_07.35

import delimited using "$directory/data/`file'_`date'.csv", clear varn(1)
keep if _n> 15

gen consented = consent == "Yes"
gen pass_attention = favoritenumber == "1965"

gen next_study = strpos(vaccinestatus, "I may get") | ///
	strpos(vaccinestatus, "No, I do not")

rename q42 prolific_id
	
count 
count if consented
count if pass_attention & consented
count if pass_attention & consented & next_study
outsheet prolific_id if pass_attention & consented & next_study ///
	using $directory/data/main_study_invites.csv, replace delimit(",") 

egen item_miss = rowmiss(vaccinehistory vaccinestatus conditions insurance ///
	government doctors government_prior importance consumption reliability ///
	doctor socialmedia podcasts cdc)
gen item_nr_rate = item_miss / 14
sum item_nr_rate if pass_attention & consented & next_study
sum item_miss if pass_attention & consented & next_study
di r(sum)



foreach v in vaccinehistory vaccinestatus conditions insurance ///
	government doctors government_prior importance consumption reliability ///
	doctor socialmedia podcasts cdc {
	
		assert `v' != "-99"
	
	}


