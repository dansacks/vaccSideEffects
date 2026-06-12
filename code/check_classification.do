

import excel using output/tables/dan_hand_classifications.xlsx, clear firstrow
tempfile dan
save `dan'

import delimited using output/tables/debrief_classifications.csv,  clear 

merge 1:1 study_id using `dan', keep(2 3)
assert missing(debrief_about) if _merge == 2
drop if _merge == 2

* hand coded = actual 
assert understood_intent == understood 

foreach c in flu attitude info beliefs intent change {
	rename about_`c' a`c'
	
}
