
** deidentify raw-data
local spss_files flu_survey_main_January+9,+2026_08.08 ///
	flu_vacc_se_followup_January+9,+2026_19.43 ///
	vacc_se_prescreen_full_January+9,+2026_19.47 

local demo_files 692494f77a877e57e000eb60 followup main main_morepay


* 1. load all the data 
local n 0 
foreach f of local spss_files {
	di "`f'"
	local ++n 
	
	import spss using "raw_data/`f'.sav", clear 
	
	if `n' == 2 rename _v1 PROLIFIC_PID
	keep PROLIFIC_PID 
	
	tempfile f`n'
	save `f`n'', replace 
	
}

foreach f of local demo_files {
	
	import delimited using "raw_data/prolific_demographic_export_`f'.csv", clear 
	keep participantid 
	rename participantid PROLIFIC_PID 
	
	local ++n 
	tempfile f`n'
	save `f`n'', replace 
	
}

* 2. append together and make a new identifier
clear 
forvalues j = 1/`n' {
	append using `f`j''
	
}
duplicates drop 
gen order = runiform()
sort order
gen study_id = _n 
drop order 
gen participantid = PROLIFIC_PID
save raw_data/crosswalk , replace


* 3. impute study_id and drop prolific id and ipaddress 
local n = 0
foreach f of local spss_files {
	di "`f'"
	
	import spss using "raw_data/`f'.sav", clear 
	local ++n 
	if `n' == 1 gen pid_mismatch = PROLIFIC_PID ~= Q52
	if `n' == 2 {
			rename _v1 PROLIFIC_PID 
			gen pid_mismatch = PROLIFIC_PID ~= prolific_pid
	}
	if `n' == 3 gen pid_mismatch = PROLIFIC_PID ~= Q42 
	
	merge m:1 PROLIFIC_PID using raw_data/crosswalk , keep(1 3) assert(2 3)
	drop _merge 
	
	drop PROLIFIC_PID participantid IPAddress
	drop RecipientEmail RecipientFirstName RecipientLastName 
	drop LocationLatitude LocationLongitude 
	capture drop STUDY_ID 
	capture drop SESSION_ID
	capture drop Q52 
	capture drop Q42 
	capture drop prolific_pid
	save "raw_data/`f'", replace 
	
}

foreach f of local demo_files {
	
	import delimited using "raw_data/prolific_demographic_export_`f'.csv", clear 
	merge m:1 participantid using raw_data/crosswalk , keep(1 3) assert(2 3)
	drop _merge
	
	drop PROLIFIC_PID participantid 
	save "raw_data/prolific_demographic_export_`f'", replace 
	
}


