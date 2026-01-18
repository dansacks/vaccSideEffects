/*==============================================================================
    Clean Main Survey Data

    Input:  data/flu_survey_main_*.sav (SPSS export from Qualtrics)
    Output: data/main_clean.dta

    This do-file cleans the raw Qualtrics SPSS export from the main survey.
    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "clean_main"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load raw SPSS data
------------------------------------------------------------------------------*/

import spss using "data/flu_survey_main_January+9,+2026_08.08.sav", clear

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

* Rename survey variables
rename Q52 prolific_id_entered
rename Q2 attn_check
* consent, prior_self_placebo, prior_self_vacc already named correctly
* post_c_trial, post_i_trial, post_a_trial, post_p_trial already named correctly
* posterior_novacc, posterior_vacc already named correctly (but need underscore fix)
rename posterior_novacc posterior_novacc
rename posterior_vacc posterior_vacc
* trust_trial, relevant_trial, trust_academic, relevant_academic already named
* vacc_intentions, age, gender, education, income, race, ethnicity, polviews already named
* debrief_about, comments already named
* link1_clicked - link4_clicked already named
rename PROLIFIC_PID prolific_pid

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

* Treatment arm
label define arm_lbl ///
    0 "0. Control" ///
    1 "1. Industry" ///
    2 "2. Academic" ///
    3 "3. Personal"

* Prior beliefs (7-point) - SPSS already has numeric codes
label define prior7_lbl ///
    1 "1. Would definitely not" ///
    2 "2. Very unlikely" ///
    3 "3. Somewhat unlikely" ///
    4 "4. Neither likely nor unlikely" ///
    5 "5. Somewhat likely" ///
    6 "6. Very likely" ///
    7 "7. Would definitely"

* Trust/relevance (0-10) - SPSS already has numeric codes
label define scale10_lbl ///
    0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10"

* Vaccination intentions - SPSS already has numeric codes
label define vacc_intent_lbl ///
    1 "1. No, do not intend" ///
    2 "2. May or may not" ///
    3 "3. Intend to get" ///
    4 "4. Already got" ///
    -99 "-99. Prefer not to say"

* Age - SPSS already has numeric codes
label define age_lbl ///
    1 "1. Under 18" ///
    2 "2. 18-34" ///
    3 "3. 35-49" ///
    4 "4. 50-64" ///
    5 "5. 65-74" ///
    6 "6. 75+" ///
    -99 "-99. Prefer not to say"

* Gender
label define gender_lbl ///
    1 "1. Male" ///
    2 "2. Female" ///
    3 "3. Other" ///
    4 "4. Prefer not to say"

* Education (SPSS codes 1-6)
label define educ_lbl ///
    1 "1. Less than HS" ///
    2 "2. HS" ///
    3 "3. Some college" ///
    4 "4. 4-year degree" ///
    5 "5. More than 4-year" ///
    6 "6. Prefer not to say"

* Income (SPSS codes 1-6)
label define income_lbl ///
    1 "1. <$25k" ///
    2 "2. $25-50k" ///
    3 "3. $50-75k" ///
    4 "4. $75-100k" ///
    5 "5. >$100k" ///
    6 "6. Prefer not to say"

* Race (SPSS codes 1-7)
label define race_lbl ///
    1 "1. White" ///
    2 "2. Black" ///
    3 "3. Asian" ///
    4 "4. Am Indian/Alaska Native" ///
    5 "5. Pacific Islander" ///
    6 "6. Other" ///
    7 "7. Prefer not to say"

* Ethnicity (SPSS codes 1-3)
label define ethnicity_lbl ///
    1 "1. Yes" ///
    2 "2. No" ///
    3 "3. Prefer not to say"

* Political views (SPSS codes 1-8)
label define polviews_lbl ///
    1 "1. Very liberal" ///
    2 "2. Liberal" ///
    3 "3. Slightly liberal" ///
    4 "4. Moderate" ///
    5 "5. Slightly conservative" ///
    6 "6. Conservative" ///
    7 "7. Very conservative" ///
    8 "8. Prefer not to say"

/*------------------------------------------------------------------------------
    6. Convert/clean variables
------------------------------------------------------------------------------*/

* --- Consent (SPSS imports as numeric) ---
* Check current values
tab consent, m
* SPSS has 4=Yes, 5=No - recode to 1/0
recode consent (4=1) (5=0)
label values consent yesno

* --- Attention check ---
destring attn_check, replace force

* --- Prior beliefs (already numeric from SPSS) ---
label values prior_self_placebo prior7_lbl
label values prior_self_vacc prior7_lbl

* --- Trust/relevance (SPSS has 1-11, recode to 0-10) ---
foreach v of varlist trust_trial relevant_trial trust_academic relevant_academic {
	sum `v' 
	assert r(max) == 11 & r(min)==1
	replace `v' = `v' - 1 if !mi(`v')
}
label values trust_trial scale10_lbl
label values relevant_trial scale10_lbl
label values trust_academic scale10_lbl
label values relevant_academic scale10_lbl

* --- Vaccination intentions (already numeric from SPSS) ---
label values vacc_intentions vacc_intent_lbl

* --- Demographics (already numeric from SPSS) ---
label values age age_lbl
label values gender gender_lbl
label values education educ_lbl
label values income income_lbl
label values race race_lbl
label values ethnicity ethnicity_lbl
label values polviews polviews_lbl

* --- Link clicks ---
foreach i of numlist 1/4 {
	destring link`i'_clicked, replace force
}

/*------------------------------------------------------------------------------
    7. Consolidate treatment arm variables
------------------------------------------------------------------------------*/

* Treatment arm is stored in FL_17_DO_* variables (1 if assigned to that arm)
gen arm_n = .
replace arm_n = 0 if FL_17_DO_CONTROLARM == 1
replace arm_n = 1 if FL_17_DO_INDUSTRYARM == 1
replace arm_n = 2 if FL_17_DO_ACADEMICARM == 1
replace arm_n = 3 if FL_17_DO_PERSONALARM == 1
label values arm_n arm_lbl
label var arm_n "Treatment arm (numeric)"

* Check arm assignment
count if mi(arm_n) & consent == 1 & _distchannel == "anonymous"
di "Consented anonymous without arm assignment: " r(N)

* Create string arm indicator
gen arm = ""
replace arm = "control" if arm_n == 0
replace arm = "industry" if arm_n == 1
replace arm = "academic" if arm_n == 2
replace arm = "personal" if arm_n == 3
label var arm "Treatment arm (string)"

* Create arm dummies
local arms "control industry academic personal"
local i = 0
foreach a of local arms {
    gen arm_`a' = (arm_n == `i') if !mi(arm_n)
    label var arm_`a' "Treatment: `a' arm"
    label values arm_`a' yesno
    local ++i
}

/*------------------------------------------------------------------------------
    8. Consolidate post-trial and posterior belief variables
------------------------------------------------------------------------------*/

* --- Consolidate post-trial estimate ---
foreach a in c i a p {
    replace post_`a'_trial = subinstr(post_`a'_trial, "%", "", .)
    replace post_`a'_trial = subinstr(post_`a'_trial, " ", "", .)
    count if missing(real(post_`a'_trial)) & ~missing(post_`a'_trial)
    if r(N)>0 {
        assert r(N)<=2
        list post_`a'_trial if missing(real(post_`a'_trial)) & ~missing(post_`a'_trial)
    }
    destring post_`a'_trial, replace force
}
gen post_trial = .
foreach a in c i a p {
    replace post_trial = post_`a'_trial if !mi(post_`a'_trial)
}
label var post_trial "Post-trial side effect estimate (0-100)"

* --- Consolidate posterior beliefs ---
* Remove "%" if present and convert to numeric
foreach v in posterior_novacc posterior_vacc {
    capture confirm string variable `v'
    if !_rc {
        replace `v' = subinstr(`v', "%", "", .)
        destring `v', replace
    }
}

label var posterior_novacc "Posterior: SE probability without vaccine (0-100)"
label var posterior_vacc "Posterior: SE probability with vaccine (0-100)"

/*------------------------------------------------------------------------------
    9. Create derived variables
------------------------------------------------------------------------------*/

* Delta: difference between posterior with vaccine and without vaccine
gen delta = posterior_vacc - posterior_novacc
label var delta "Posterior difference (vacc - novacc)"

* Prior diff: difference between prior belief with vaccine and without
gen prior_diff = prior_self_vacc - prior_self_placebo
label var prior_diff "Prior difference (vacc - placebo)"

* Maybe: binary indicator for vaccine intention (intend to or already got)
gen maybe = inlist(vacc_intentions, 3, 4) if !mi(vacc_intentions)
label var maybe "Intends/already got vaccine"
label values maybe yesno

* Link click: any link clicked
gen link_click = (link1_clicked == 1 | link2_clicked == 1 | link3_clicked == 1 | link4_clicked == 1)
label var link_click "Any link clicked"
label values link_click yesno


/*------------------------------------------------------------------------------
    10. Create quality/sample flags
------------------------------------------------------------------------------*/

* Incomplete flag
gen incomplete = (Progress != 100 | _finished != 1)
label var incomplete "Incomplete response"

* Failed attention check (should be 4419)
gen failed_attn = (attn_check != 4419) 
label var failed_attn "Failed attention check"

* PID mismatch
gen pid_mismatch = (prolific_pid != prolific_id_entered)
label var pid_mismatch "Prolific PID mismatch"

* Duplicate PID
duplicates tag prolific_pid, gen(duplicate_pid)
replace duplicate_pid = (duplicate_pid > 0)
label var duplicate_pid "Duplicate Prolific PID"

* count missing outcomes
egen n_missing = rowmiss(posterior_vacc posterior_novacc post_trial)

* Update final sample flag
gen final_sample = (consent == 1 & failed_attn == 0 ///
    & _distchannel == "anonymous" & is_preview == 0 ///
		& n_missing == 0)
		
label var final_sample "Final analysis sample"
assert ~missing(arm_n) if final_sample
gen quality_sample = final_sample & ~duplicate_pid


* Report quality flags (preliminary)
di "=== PRELIMINARY QUALITY FLAG SUMMARY ==="
count
di "Total observations: " r(N)
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
    11. Apply variable labels
------------------------------------------------------------------------------*/

label var start_date "Survey start date/time"
label var end_date "Survey end date/time"
label var duration_sec "Survey duration (seconds)"
label var Progress "Survey progress (%)"
label var response_id "Qualtrics response ID"
label var consent "Consent given"
label var prolific_id_entered "Prolific ID (entered)"
label var prolific_pid "Prolific ID (from URL)"
label var attn_check "Attention check value (should be 4419)"
label var prior_self_placebo "Prior belief: SE likelihood without vaccine (1-7)"
label var prior_self_vacc "Prior belief: SE likelihood with vaccine (1-7)"
label var post_c_trial "Post-trial estimate: Control arm"
label var post_i_trial "Post-trial estimate: Industry arm"
label var post_a_trial "Post-trial estimate: Academic arm"
label var post_p_trial "Post-trial estimate: Personal arm"
label var trust_trial "Trust in trial information (0-10)"
label var relevant_trial "Relevance of trial information (0-10)"
label var trust_academic "Trust in academic source (0-10)"
label var relevant_academic "Relevance of academic source (0-10)"
label var vacc_intentions "Flu vaccine intentions"
label var age "Age group"
label var gender "Gender"
label var education "Education level"
label var income "Household income"
label var race "Race"
label var ethnicity "Hispanic/Latino"
label var polviews "Political views"
label var debrief_about "Debrief: What survey was about"
label var comments "Final comments"
label var link1_clicked "Link 1 clicked"
label var link2_clicked "Link 2 clicked"
label var link3_clicked "Link 3 clicked"
label var link4_clicked "Link 4 clicked"

* Label all yes/no variables
foreach var of varlist final_sample incomplete failed_attn pid_mismatch duplicate_pid is_preview ///
    arm_control arm_industry arm_academic arm_personal maybe link_click {
    label values `var' yesno
}

/*------------------------------------------------------------------------------
    12. Drop unnecessary variables and reorder
------------------------------------------------------------------------------*/

* Drop temporary variables
drop _ipaddress _lat _long _status _finished _recordeddate _distchannel _userlang
drop FL_17_DO_CONTROLARM FL_17_DO_INDUSTRYARM FL_17_DO_ACADEMICARM FL_17_DO_PERSONALARM

* Rename Progress to lowercase
rename Progress progress

* Order variables logically
order response_id prolific_pid prolific_id_entered ///
      start_date end_date duration_sec progress ///
      consent final_sample incomplete failed_attn pid_mismatch duplicate_pid is_preview ///
      attn_check ///
      arm_n arm arm_control arm_industry arm_academic arm_personal ///
      prior_self_placebo prior_self_vacc prior_diff ///
      post_trial post_c_trial post_i_trial post_a_trial post_p_trial ///
      posterior_novacc posterior_vacc delta ///
      trust_trial relevant_trial trust_academic relevant_academic ///
      vacc_intentions maybe ///
      link_click link1_clicked link2_clicked link3_clicked link4_clicked ///
      age gender education income race ethnicity polviews ///
      debrief_about comments
rename vacc_intentions vacc_intent

/*------------------------------------------------------------------------------
    13. Final assertions and save
------------------------------------------------------------------------------*/

* Verify key variable ranges
assert inlist(consent, 0, 1, .)
assert inlist(arm_n, 0, 1, 2, 3, .)
assert inlist(prior_self_placebo, 1, 2, 3, 4, 5, 6, 7, .)
assert inlist(prior_self_vacc, 1, 2, 3, 4, 5, 6, 7, .)
assert post_trial >= 0 & post_trial <= 100 if !mi(post_trial)
assert posterior_novacc >= 0 & posterior_novacc <= 100 if !mi(posterior_novacc)
assert posterior_vacc >= 0 & posterior_vacc <= 100 if !mi(posterior_vacc)
assert inlist(trust_trial, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, .)
assert inlist(relevant_trial, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, .)
assert inlist(vacc_intent, 1, 2, 3, 4, -99, .)
assert inlist(age, 1, 2, 3, 4, 5, 6, -99, .)
assert inlist(gender, 1, 2, 3, 4, .)
assert inlist(education, 1, 2, 3, 4, 5, 6, .)
assert inlist(income, 1, 2, 3, 4, 5, 6, .)
assert inlist(race, 1, 2, 3, 4, 5, 6, 7, .)
assert inlist(ethnicity, 1, 2, 3, .)
assert inlist(polviews, 1, 2, 3, 4, 5, 6, 7, 8, .)

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
tab arm_n if final_sample == 1, m
tab vacc_intent if final_sample == 1, m

* Compress and save
compress
save "data/main_clean.dta", replace

di ""
di "=== CLEANING COMPLETE ==="
di "Saved: data/main_clean.dta"

capture log close
