/*==============================================================================
    Clean Prescreen Data

    Input:  data/vacc_se_prescreen_full_*.sav (SPSS export from Qualtrics)
    Output: data/prescreen_clean.dta

    This do-file cleans the raw Qualtrics SPSS export from the prescreen survey.
    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "clean_prescreen"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load raw SPSS data
------------------------------------------------------------------------------*/

import spss using "data/vacc_se_prescreen_full_January+9,+2026_19.47.sav", clear

* Verify we have data
assert _N > 0
di "Loaded " _N " observations"

/*------------------------------------------------------------------------------
    2. Drop unused metadata variables
------------------------------------------------------------------------------*/
drop RecipientLastName RecipientFirstName RecipientEmail ExternalReference

/*------------------------------------------------------------------------------
    3. Rename variables to clean names
------------------------------------------------------------------------------*/

* Rename Qualtrics metadata
rename StartDate start_date
rename EndDate end_date
rename Duration__in_seconds_ duration_sec
rename Finished _finished
rename ResponseId response_id
rename IPAddress _ipaddress
rename LocationLatitude _lat
rename LocationLongitude _long
rename Status _status
rename RecordedDate _recordeddate
rename DistributionChannel _distchannel
rename UserLanguage _userlang
rename Progress progress

* Rename survey variables from SPSS names
rename Q42 prolific_id_entered
rename Favorite_Number favorite_number
rename Vaccine_History flu_vacc_lastyear
rename Other_Vaccines prior_vaccines
rename Vaccine_Status vacc_intent

* Vaccine reactions (complex routing)
rename Reaction _covid_reaction1
rename Flu_Vax_Experience _flu_reaction1
rename COVID_Vax_Experience _covid_reaction2
rename _v1 _flu_reaction2

* Health conditions (already split in SPSS)
rename Conditions_1 cond_asthma
rename Conditions_2 cond_lung
rename Conditions_3 cond_heart
rename Conditions_4 cond_diabetes
rename Conditions_6 cond_kidney
rename Conditions_7 cond_rather_not_say
rename Conditions_8 cond_none

rename Insurance has_insurance
rename Government trust_govt
rename Doctors follow_doctor
rename government_prior trust_govt_prior
rename Importance info_source_main

* Source text fields
rename Source source_sm_text
rename _v2 source_podcast_text
rename _v3 source_news_text

* Info frequency
rename Doctor info_doctor
rename Social_Media info_sm
rename Podcasts info_podcasts
rename CDC info_cdc
rename News info_news
rename Consumption info_university

* Reliability (use wildcards for truncated names)
rename Reliability__Doctor reliable_doctor
rename Reliability__SM reliable_sm
rename Reliability__Pods reliable_podcasts
rename Reliability__CDC reliable_cdc
rename Reliability__News reliable_news
rename Reliability reliable_university

rename Final_Comments comments
rename PROLIFIC_PID prolific_pid

* Drop session/study IDs
drop SESSION_ID STUDY_ID


/*------------------------------------------------------------------------------
    4. Create preview flag from Status
------------------------------------------------------------------------------*/

* Status: 0 = IP Address (real), 1 = Survey Preview, etc.
gen is_preview = (_status == 1) if !mi(_status)
replace is_preview = 0 if mi(is_preview)


/*------------------------------------------------------------------------------
    5. Define value labels (numbered format)
------------------------------------------------------------------------------*/

* Boolean (Yes/No)
label define yesno 0 "0. No" 1 "1. Yes"

* Insurance (Yes/No/Not sure)
label define insurance_lbl -1 "-1. Not sure" 0 "0. No" 1 "1. Yes"

* Likert agreement scale
label define agree5 ///
    1 "1. Strongly disagree" ///
    2 "2. Somewhat disagree" ///
    3 "3. Neither agree nor disagree" ///
    4 "4. Somewhat agree" ///
    5 "5. Strongly agree"

* Frequency scale
label define freq4 ///
    1 "1. Never" ///
    2 "2. Rarely" ///
    3 "3. Sometimes" ///
    4 "4. Often"

* Frequency scale with "no doctor" option
label define freq4_nodoc ///
    -1 "-1. No doctor" ///
    1 "1. Never" ///
    2 "2. Rarely" ///
    3 "3. Sometimes" ///
    4 "4. Often"

* Reliability scale
label define reliable3 ///
    1 "1. Not reliable" ///
    2 "2. Somewhat reliable" ///
    3 "3. Yes, reliable"

* Flu vaccine last year
label define fluvax_lastyear_lbl 0 "0. No" 1 "1. Yes"

* Prior vaccines
label define prior_vax_lbl ///
    1 "1. Neither vaccine" ///
    2 "2. Flu only" ///
    3 "3. COVID only" ///
    4 "4. Both vaccines"

* Flu vaccine intent
label define flu_intent_lbl ///
    1 "1. No, do not intend" ///
    2 "2. May or may not" ///
    3 "3. Intend to get" ///
    4 "4. Already got"

* Vaccine reaction
label define reaction_lbl ///
    0 "0. No prior vaccine" ///
    1 "1. None/don't remember" ///
    2 "2. Mild (not severe)" ///
    3 "3. Severe"

* Main info source
label define source_main_lbl ///
    1 "1. Doctor" ///
    2 "2. Social media" ///
    3 "3. Podcasts" ///
    4 "4. CDC" ///
    5 "5. News organizations" ///
    6 "6. None of the above"

/*------------------------------------------------------------------------------
    6. Convert/recode variables
------------------------------------------------------------------------------*/

* --- Consent (SPSS: 4=Yes, 5=No, -99=missing-->did not consent) ---
tab consent, m nolabel
recode consent (4=1) (-99 5=0)
label values consent yesno

* --- Flu vaccine last year (SPSS: 1=Yes, 2=No) ---
recode flu_vacc_lastyear (1=1) (2=0)
label values flu_vacc_lastyear fluvax_lastyear_lbl

* --- Prior vaccines (SPSS: 1=Both, 2=Flu only, 3=COVID only, 4=Neither) ---
* Remap to: 1=Neither, 2=Flu only, 3=COVID only, 4=Both
recode prior_vaccines (1=4) (2=2) (3=3) (4=1)
label values prior_vaccines prior_vax_lbl


* --- Flu vaccine intent (SPSS already 1-4 matching) ---
label values vacc_intent flu_intent_lbl

* --- Insurance (SPSS: 1=Not sure, 2=No, 3=Yes) ---
recode has_insurance (1=-1) (2=0) (3=1),
label values has_insurance insurance_lbl

tab has_insurance 

* --- Trust/follow scales (SPSS already 1-5 matching) ---
label values trust_govt agree5
label values follow_doctor agree5
label values trust_govt_prior agree5

* --- Main info source (SPSS already 1-6 matching) ---
label values info_source_main source_main_lbl

* --- Info from doctor (SPSS: 1=Often, 2=Sometimes, 3=Rarely, 4=Never, 5=No doctor) ---
recode info_doctor (1=4) (2=3) (3=2) (4=1) (5=-1)
label values info_doctor freq4_nodoc

* --- Info from other sources (SPSS: 1=Often, 2=Sometimes, 3=Rarely, 4=Never) ---
foreach v in info_sm info_podcasts info_cdc info_news info_university {
	recode `v' (1=4) (2=3) (3=2) (4=1)
	label values `v' freq4
}

* --- Reliability (SPSS: 1=Yes reliable, 2=Somewhat, 3=Not reliable) ---
foreach v in reliable_doctor reliable_sm reliable_podcasts reliable_cdc reliable_news reliable_university {
	recode `v' (1=3) (2=2) (3=1)
	label values `v' reliable3
}

* --- Favorite number (attention check) ---
destring favorite_number, replace force

* --- Health condition dummies (SPSS: 1=selected, missing=not selected) ---
foreach v of varlist cond_asthma cond_lung cond_heart cond_diabetes cond_kidney cond_none {
	replace `v' = 0 if `v' == -99 & cond_rather_not_say ==-99
}

/*------------------------------------------------------------------------------
    7. Create quality/sample flags
------------------------------------------------------------------------------*/

* Incomplete flag
gen incomplete = (progress != 100 | _finished != 1)
label var incomplete "Incomplete response"

* Failed attention check (favorite number should be 1965)
gen failed_attn = (favorite_number != 1965) 
label var failed_attn "Failed attention check"

* PID mismatch
gen pid_mismatch = (prolific_pid != prolific_id_entered)
label var pid_mismatch "Prolific PID mismatch"

* Duplicate PID
duplicates tag prolific_pid, gen(duplicate_pid)
replace duplicate_pid = (duplicate_pid > 0)
label var duplicate_pid "Duplicate Prolific PID"

* Final sample flag (exclude previews)
gen final_sample = (consent == 1 & failed_attn == 0 & _distchannel == "anonymous" & ~is_preview)
label var final_sample "Final analysis sample (consent, passsed attention)"
gen quality_sample = final_sample & duplicate_pid == 0 
label var quality_sample "Final sample + non-duplicate" 

* Report quality flags
di "=== QUALITY FLAG SUMMARY ==="
count
di "Total observations: " r(N)
count if final_sample == 1
di "Final sample: " r(N)
count if incomplete == 1
di "Incomplete: " r(N)
count if failed_attn == 1
di "Failed attention check: " r(N)
count if pid_mismatch == 1
di "PID mismatch: " r(N)
count if duplicate_pid == 1
di "Duplicate PIDs: " r(N)

/*------------------------------------------------------------------------------
    8. Consolidate vaccine experience variables
------------------------------------------------------------------------------*/

* Create binary indicators for prior vaccination
gen had_prior_covid_vacc = inlist(prior_vaccines, 3, 4) if !mi(prior_vaccines)
gen had_prior_flu_vacc = inlist(prior_vaccines, 2, 4) if !mi(prior_vaccines)
label var had_prior_covid_vacc "Had prior COVID vaccine"
label var had_prior_flu_vacc "Had prior flu vaccine"

* Consolidate COVID reaction (SPSS: 1=None/don't remember, 2=Mild, 3=Severe)
* _covid_reaction1 is asked if prior_vaccines == 3 (COVID only)
* _covid_reaction2 is asked if prior_vaccines == 4 (both)
gen covid_vacc_reaction = .
replace covid_vacc_reaction = 0 if had_prior_covid_vacc == 0
replace covid_vacc_reaction = _covid_reaction1 if !mi(_covid_reaction1)
replace covid_vacc_reaction = _covid_reaction2 if !mi(_covid_reaction2)
label values covid_vacc_reaction reaction_lbl
label var covid_vacc_reaction "COVID vaccine reaction"

* Consolidate flu reaction (SPSS: 1=None/don't remember, 2=Mild, 3=Severe)
* _flu_reaction1 is asked if prior_vaccines == 4 (both)
* _flu_reaction2 is asked if prior_vaccines == 2 (flu only)
gen flu_vacc_reaction = .
replace flu_vacc_reaction = 0 if had_prior_flu_vacc == 0
replace flu_vacc_reaction = _flu_reaction1 if !mi(_flu_reaction1)
replace flu_vacc_reaction = _flu_reaction2 if !mi(_flu_reaction2)
label values flu_vacc_reaction reaction_lbl
label var flu_vacc_reaction "Flu vaccine reaction"

* Assertions for reaction variables
assert covid_vacc_reaction == 0 if had_prior_covid_vacc == 0 & !mi(prior_vaccines)
assert inlist(covid_vacc_reaction, 1, 2, 3) if had_prior_covid_vacc == 1 & (!mi(_covid_reaction1) | !mi(_covid_reaction2))
assert flu_vacc_reaction == 0 if had_prior_flu_vacc == 0 & !mi(prior_vaccines)
assert inlist(flu_vacc_reaction, 1, 2, 3) if had_prior_flu_vacc == 1 & (!mi(_flu_reaction1) | !mi(_flu_reaction2))

* Drop temporary reaction variables
drop _covid_reaction1 _covid_reaction2 _flu_reaction1 _flu_reaction2

/*------------------------------------------------------------------------------
    9. Create binary indicators for main info source
------------------------------------------------------------------------------*/

gen source_doctor = (info_source_main == 1) if !mi(info_source_main)
gen source_sm = (info_source_main == 2) if !mi(info_source_main)
gen source_podcasts = (info_source_main == 3) if !mi(info_source_main)
gen source_cdc = (info_source_main == 4) if !mi(info_source_main)
gen source_news = (info_source_main == 5) if !mi(info_source_main)
gen source_none = (info_source_main == 6) if !mi(info_source_main)

label var source_doctor "Main source: Doctor"
label var source_sm "Main source: Social media"
label var source_podcasts "Main source: Podcasts"
label var source_cdc "Main source: CDC"
label var source_news "Main source: News"
label var source_none "Main source: None of the above"

* Assert source dummies sum to 1 (or all 0 if missing)
egen _src_sum = rowtotal(source_doctor source_sm source_podcasts source_cdc source_news source_none)
assert _src_sum == 1 if !mi(info_source_main)
assert _src_sum == 0 if mi(info_source_main)
drop _src_sum

/*------------------------------------------------------------------------------
    10. Apply variable labels
------------------------------------------------------------------------------*/

label var start_date "Survey start date/time"
label var end_date "Survey end date/time"
label var duration_sec "Survey duration (seconds)"
label var progress "Survey progress (%)"
label var response_id "Qualtrics response ID"
label var consent "Consent given"
label var prolific_id_entered "Prolific ID (entered)"
label var prolific_pid "Prolific ID (from URL)"
label var favorite_number "Favorite number (attention check)"
label var flu_vacc_lastyear "Got flu vaccine last year"
label var prior_vaccines "Prior vaccine history"
label var vacc_intent "Flu vaccine intent this season"
label var has_insurance "Has health insurance"
label var trust_govt "Trust government info about flu vaccine"
label var follow_doctor "Generally follow doctor's vaccine advice"
label var trust_govt_prior "Prior trust in government info"
label var info_source_main "Most important health info source"
label var source_sm_text "Social media source (text)"
label var source_podcast_text "Podcast source (text)"
label var source_news_text "News source (text)"
label var info_doctor "Get info from doctor"
label var info_sm "Get info from social media"
label var info_podcasts "Get info from podcasts"
label var info_cdc "Get info from CDC"
label var info_news "Get info from news"
label var info_university "Get info from university research"
label var reliable_doctor "Find doctor info reliable"
label var reliable_sm "Find social media info reliable"
label var reliable_podcasts "Find podcast info reliable"
label var reliable_cdc "Find CDC info reliable"
label var reliable_news "Find news info reliable"
label var reliable_university "Find university research reliable"
label var comments "Final comments"

label var cond_none "No health conditions"
label var cond_asthma "Has asthma"
label var cond_diabetes "Has diabetes"
label var cond_heart "Has heart disease"
label var cond_lung "Has lung disease"
label var cond_kidney "Has kidney disease"
label var cond_rather_not_say "Health conditions: rather not say"

* Label all yes/no variables
foreach var of varlist final_sample incomplete failed_attn pid_mismatch duplicate_pid is_preview ///
    had_prior_covid had_prior_flu cond_* source_doctor source_sm source_podcasts source_cdc source_news source_none {
    label values `var' yesno
}

/*------------------------------------------------------------------------------
    11. Drop unnecessary variables and reorder
------------------------------------------------------------------------------*/

* Drop temporary variables
drop _ipaddress _lat _long _status _finished _recordeddate _distchannel _userlang

* Order variables logically
order response_id prolific_pid prolific_id_entered ///
      start_date end_date duration_sec progress ///
      consent final_sample incomplete failed_attn pid_mismatch duplicate_pid ///
      favorite_number is_preview ///
      flu_vacc_lastyear prior_vaccines vacc_intent ///
      had_prior_covid_vacc had_prior_flu_vacc covid_vacc_reaction flu_vacc_reaction ///
      cond_* ///
      has_insurance ///
      trust_govt follow_doctor trust_govt_prior ///
      info_source_main source_* ///
      info_doctor info_sm info_podcasts info_cdc info_news info_university ///
      reliable_* ///
      comments

/*------------------------------------------------------------------------------
    12. Final assertions and save
------------------------------------------------------------------------------*/


* Check variable count
desc
local nvars = r(k)
di "Total variables: `nvars'"

* Final quality summary
di ""
di "=== FINAL DATA QUALITY SUMMARY ==="
count
di "Total observations: " r(N)
count if final_sample == 1
di "Final sample: " r(N)
tab prior_vaccines if final_sample == 1, m
tab vacc_intent if final_sample == 1, m

* Compress and save
compress
save "data/prescreen_clean.dta", replace

di ""
di "=== CLEANING COMPLETE ==="
di "Saved: data/prescreen_clean.dta"

capture log close
