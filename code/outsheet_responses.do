

clear all
global scriptname "outsheet_responses"
do "code/_config.do"

use derived/merged_all, clear 
replace debrief_about = subinstr(debrief_about, char(10), " <NL> ", .)

outsheet study_id debrief_about using derived/open_responses.tsv, replace 
outsheet study_id debrief_about in 1/10 using derived/open_responses_test.tsv, replace 
