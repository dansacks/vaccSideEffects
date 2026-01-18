/*==============================================================================
    Clean Follow-up Survey Data

    Input:  data/flu_vacc_se_followup_*.sav (SPSS export from Qualtrics)
    Output: data/followup_clean.dta

    This do-file cleans the raw Qualtrics SPSS export from the follow-up survey.
    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "clean_followup"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load raw SPSS data
------------------------------------------------------------------------------*/

import spss using "raw_data/flu_vacc_se_followup_January+9,+2026_19.43.sav", clear

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
rename Survey_Information consent
rename prolific_pid prolific_id_entered
rename Attention attn_check
rename _v1 prolific_pid

* Pharmacy factors and shopping
rename factors pharmacy_factor
rename Price_compare_ price_compare
rename Coupons_deals_ use_coupons

* Vaccination status
rename GLP1_ got_glp1
rename Flu_vax_ got_flu_vacc
rename COVID_Vax_ got_covid_vacc

* Recall questions
rename recall recall_study
rename Placebo___ guess_placebo
rename Q32 guess_vaccine
rename Manufacturer_* recall_manufacturer
rename University_trial_* recall_university
rename Gavi_trial_ recall_gavi
rename Trustworthy_ found_trustworthy
rename Q1 comments

* Where medicine dummies (already split in SPSS)
* Use wildcards because SPSS names are truncated
rename Where_Medicin*1 med_pharmacy_chain
rename Where_Medicin*2 med_grocery
rename Where_Medicin*3 med_independent
rename Where_Medicin*4 med_mail_order
rename Where_Medicin*5 med_online
rename Where_Medicin*6 med_provider
rename Where_Medicin*7 med_other
rename Where_Medicin*8 med_none

* Flu why not dummies (note: "fly" typo in SPSS)
rename fly_why_1 flu_why_already
rename fly_why_2 flu_why_side_effects
rename fly_why_3 flu_why_bad_flu
rename fly_why_4 flu_why_needles
rename fly_why_5 flu_why_time
rename fly_why_6 flu_why_location
rename fly_why_7 flu_why_cost
rename fly_why_8 flu_why_none

* Drop display order variables and unused sub-selects
capture drop fly_why_DO_*
capture drop Where_online*
capture drop Where_grocery*
capture drop What_chain*

/*------------------------------------------------------------------------------
    4. Create preview flag from Status
------------------------------------------------------------------------------*/

* Status: 0 = IP Address (real), 1 = Survey Preview
gen is_preview = (_status == 1) 

/*------------------------------------------------------------------------------
    5. Define value labels (numbered format)
------------------------------------------------------------------------------*/

* Boolean (Yes/No)
label define yesno 0 "0. No" 1 "1. Yes"

* Pharmacy factor (SPSS codes)
label define factor_lbl ///
    1 "1. Price" ///
    2 "2. Convenience" ///
    3 "3. Quality/reputation" ///
    4 "4. Pharmacist access" ///
    5 "5. None important"

* Price compare / coupons (SPSS codes)
label define shopping_lbl ///
    1 "1. Yes, at least once" ///
    2 "2. No" ///
    3 "3. Did not shop for medicines"

* Recall study (SPSS codes)
label define recall_lbl ///
    1 "1. Yes" ///
    2 "2. No" ///
    3 "3. Don't remember"

* Recall info (SPSS codes)
label define recallinfo_lbl ///
    1 "1. Yes" ///
    2 "2. No" ///
    3 "3. Don't remember study"

* Trustworthy (SPSS codes)
label define trust_lbl ///
    1 "1. Don't remember study" ///
    2 "2. Trustworthy" ///
    3 "3. Somewhat trustworthy" ///
    4 "4. Not trustworthy"

/*------------------------------------------------------------------------------
    6. Convert/clean variables
------------------------------------------------------------------------------*/

* --- Consent (SPSS codes: 1=Yes, 2=No, -99=missing) ---
tab consent, m nolabel
* Recode to 0/1
recode consent (1=1) (2 -99=0) (-99=.)
label values consent yesno

* --- Attention check (should be 1163) ---
destring attn_check, replace force

* --- Pharmacy factor (already numeric from SPSS) ---
label values pharmacy_factor factor_lbl

* --- Price compare / coupons (already numeric from SPSS) ---
label values price_compare shopping_lbl
label values use_coupons shopping_lbl

* --- GLP-1 (SPSS codes: recode to 0/1, prefer not to answer -> missing) ---
tab got_glp1, m nolabel
recode got_glp1 (1=1) (2=0) (3=.)
label values got_glp1 yesno

* --- Flu vaccine (SPSS codes: recode to 0/1, prefer not to answer -> missing) ---
tab got_flu_vacc, m nolabel
recode got_flu_vacc (1=1) (2=0) (3=.), gen(got_flu_vacc_new)
drop got_flu_vacc
rename got_flu_vacc_new got_flu_vacc
label values got_flu_vacc yesno

* --- COVID vaccine (SPSS codes: recode to 0/1, prefer not to answer -> missing) ---
tab got_covid_vacc, m nolabel
recode got_covid_vacc (1=1) (2=0) (3=.), gen(got_covid_vacc_new)
drop got_covid_vacc
rename got_covid_vacc_new got_covid_vacc
label values got_covid_vacc yesno

* --- Recall study (already numeric from SPSS) ---
label values recall_study recall_lbl

* --- Recall manufacturer/university/gavi (already numeric from SPSS) ---
label values recall_manufacturer recallinfo_lbl
label values recall_university recallinfo_lbl
label values recall_gavi recallinfo_lbl

* --- Found trustworthy (already numeric from SPSS) ---
label values found_trustworthy trust_lbl

* --- Numeric guesses ---
replace guess_placebo= subinstr(guess_placebo, "%", "", .)
replace guess_placebo = "4" if strpos(guess_placebo, "id say 4")
replace guess_vaccine= subinstr(guess_vaccine, " ", "", .)
tab guess_placebo if missing(real(guess_placebo))

replace guess_vaccine= subinstr(guess_vaccine, "%", "", .)
replace guess_vaccine= subinstr(guess_vaccine, " ", "", .)

destring guess_placebo, replace force
destring guess_vaccine, replace force

* --- Medicine dummies (SPSS: 1=selected, missing=not selected) ---
foreach v of varlist med_pharmacy_chain med_grocery med_independent med_mail_order ///
    med_online med_provider med_other med_none {
    replace `v' = 0 if mi(`v')
}

* --- Flu why not dummies (SPSS: 1=selected, missing=not selected) ---
foreach v of varlist flu_why_already flu_why_side_effects flu_why_bad_flu flu_why_needles ///
    flu_why_time flu_why_location flu_why_cost flu_why_none {
    replace `v' = 0 if mi(`v')
}

/*------------------------------------------------------------------------------
    7. Create quality/sample flags
------------------------------------------------------------------------------*/

* Incomplete flag
gen incomplete = (progress != 100 | _finished != 1)
label var incomplete "Incomplete response"

* Failed attention check (should be 1163)
gen failed_attn = (attn_check != 1163) if !mi(attn_check)
replace failed_attn = 1 if mi(attn_check)
label var failed_attn "Failed attention check"

* PID mismatch
gen pid_mismatch = (prolific_pid != prolific_id_entered)
label var pid_mismatch "Prolific PID mismatch"

* Flag first attempt per PID (sort by start_date, keep first)
bysort prolific_pid (start_date): gen first_attempt = (_n == 1)
label var first_attempt "First survey attempt for this PID"

* Duplicate PID (for reference/reporting only)
duplicates tag prolific_pid, gen(duplicate_pid)
replace duplicate_pid = (duplicate_pid > 0)
label var duplicate_pid "Duplicate Prolific PID"

* Final sample flag (exclude previews)
gen final_sample = (consent == 1 & failed_attn == 0 & _distchannel == "anonymous" & is_preview == 0 & first_attempt == 1)
gen quality_sample = final_sample

label var final_sample "Final analysis sample"
label var is_preview "Preview/test response"

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
count if is_preview == 1
di "Preview responses: " r(N)

/*------------------------------------------------------------------------------
    8. Create derived variables
------------------------------------------------------------------------------*/

* Correct placebo guess (3%) - exclude -99 values
gen placebo_correct = (guess_placebo >= 2 & guess_placebo <= 4) 
label var placebo_correct "Placebo guess within 1% of 3%"
label values placebo_correct yesno

* Correct vaccine guess (1.3%) - exclude -99 values
gen vaccine_correct = (guess_vaccine >= 0.3 & guess_vaccine <= 2.3) 
label var vaccine_correct "Vaccine guess within 1% of 1.3%"
label values vaccine_correct yesno

/*------------------------------------------------------------------------------
    9. Apply variable labels
------------------------------------------------------------------------------*/

label var start_date "Survey start date/time"
label var end_date "Survey end date/time"
label var duration_sec "Survey duration (seconds)"
label var progress "Survey progress (%)"
label var response_id "Qualtrics response ID"
label var consent "Consent given"
label var prolific_id_entered "Prolific ID (entered)"
label var prolific_pid "Prolific ID (from URL)"
label var attn_check "Attention check value (should be 1163)"
label var pharmacy_factor "Most important factor for pharmacy choice"
label var price_compare "Compared prices at pharmacies"
label var use_coupons "Used coupons/deals like GoodRx"
label var got_glp1 "Got GLP-1 prescription last month"
label var got_flu_vacc "Got flu vaccine last month"
label var got_covid_vacc "Got COVID vaccine last month"
label var recall_study "Recalls participating in main study"
label var guess_placebo "Guessed placebo arm SE rate"
label var guess_vaccine "Guessed vaccine arm SE rate"
label var recall_manufacturer "Recalls manufacturer/trial info"
label var recall_university "Recalls university research info"
label var recall_gavi "Recalls Gavi info"
label var found_trustworthy "Found study info trustworthy"
label var comments "Final comments"

label var med_pharmacy_chain "Gets medicine: Pharmacy chain"
label var med_grocery "Gets medicine: Grocery/superstore"
label var med_independent "Gets medicine: Independent pharmacy"
label var med_mail_order "Gets medicine: Mail-order"
label var med_online "Gets medicine: Online pharmacy"
label var med_provider "Gets medicine: Healthcare provider"
label var med_other "Gets medicine: Somewhere else"
label var med_none "Gets medicine: Does not purchase"

label var flu_why_already "Flu why not: Already got earlier"
label var flu_why_side_effects "Flu why not: Worried about side effects"
label var flu_why_bad_flu "Flu why not: Worried about bad flu"
label var flu_why_needles "Flu why not: Don't like needles"
label var flu_why_time "Flu why not: Time concern"
label var flu_why_location "Flu why not: Location concern"
label var flu_why_cost "Flu why not: Cost concern"
label var flu_why_none "Flu why not: None relevant"

* Label all yes/no variables
foreach var of varlist final_sample incomplete failed_attn pid_mismatch duplicate_pid first_attempt is_preview ///
    med_pharmacy_chain med_grocery med_independent med_mail_order med_online med_provider med_other med_none ///
    flu_why_already flu_why_side_effects flu_why_bad_flu flu_why_needles flu_why_time flu_why_location flu_why_cost flu_why_none ///
    got_glp1 got_flu_vacc got_covid_vacc placebo_correct vaccine_correct {
    label values `var' yesno
}

/*------------------------------------------------------------------------------
    10. Drop unnecessary variables and reorder
------------------------------------------------------------------------------*/

* Drop temporary variables
drop _ipaddress _lat _long _status _finished _recordeddate _distchannel _userlang

* Order variables logically
order response_id prolific_pid prolific_id_entered ///
      start_date end_date duration_sec progress ///
      consent final_sample incomplete failed_attn pid_mismatch duplicate_pid first_attempt is_preview ///
      attn_check ///
      med_pharmacy_chain med_grocery med_independent med_mail_order med_online med_provider med_other med_none ///
      pharmacy_factor price_compare use_coupons ///
      got_glp1 got_flu_vacc got_covid_vacc ///
      flu_why_already flu_why_side_effects flu_why_bad_flu flu_why_needles flu_why_time flu_why_location flu_why_cost flu_why_none ///
      recall_study guess_placebo guess_vaccine placebo_correct vaccine_correct ///
      recall_manufacturer recall_university recall_gavi found_trustworthy ///
      comments

/*------------------------------------------------------------------------------
    11. Final assertions and save
------------------------------------------------------------------------------*/

* Verify key variable ranges
assert inlist(consent, 0, 1, .)
assert inlist(pharmacy_factor, 1, 2, 3, 4, 5, .)
assert inlist(price_compare, 1, 2, 3, .)
assert inlist(use_coupons, 1, 2, 3, .)
assert inlist(got_glp1, 0, 1, .)
assert inlist(got_flu_vacc, 0, 1, .)
assert inlist(got_covid_vacc, 0, 1, .)
assert inlist(recall_study, 1, 2, 3, .)
assert inlist(recall_manufacturer, 1, 2, 3, .)
assert inlist(recall_university, 1, 2, 3, .)
assert inlist(recall_gavi, 1, 2, 3, .)
assert inlist(found_trustworthy, 1, 2, 3, 4, .)
assert (guess_placebo >= 0 & guess_placebo <= 100) | guess_placebo == -99 if !mi(guess_placebo)
assert (guess_vaccine >= 0 & guess_vaccine <= 100) | guess_vaccine == -99 if !mi(guess_vaccine)

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
tab got_flu_vacc if final_sample == 1, m
tab recall_study if final_sample == 1, m

* Compress and save
compress
save "derived/followup_clean.dta", replace

di ""
di "=== CLEANING COMPLETE ==="
di "Saved: derived/followup_clean.dta"

capture log close
