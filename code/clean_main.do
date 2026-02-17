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

use "raw_data/flu_survey_main_January+9,+2026_08.08.dta", clear

* Verify we have data
assert _N > 0
di "Loaded " _N " observations"

/*------------------------------------------------------------------------------
    2. Drop unused metadata variables
------------------------------------------------------------------------------*/
drop ExternalReference

/*------------------------------------------------------------------------------
    3. Rename variables to clean names
------------------------------------------------------------------------------*/

* Standard Qualtrics metadata renames
do "code/include/_rename_qualtrics_metadata.do"

* Rename main survey-specific variables
rename Q2 attn_check

/*------------------------------------------------------------------------------
    4. Create preview flag from Status
------------------------------------------------------------------------------*/

* Status: 0 = IP Address (real), 1 = Survey Preview
gen is_preview = (_status == 1) if !mi(_status)
replace is_preview = 0 if mi(is_preview)

/*------------------------------------------------------------------------------
    5. Define value labels
------------------------------------------------------------------------------*/

do "code/include/_define_value_labels.do"

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

* --- Trust/relevance (SPSS has 1-11, convert to 0-10 scale) ---
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
	destring link`i'_clicked, replace
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
count if mi(arm_n) & consent == 1 & _distchannel == "anonymous" & ///
	attn_check == $ATTN_CHECK_MAIN
	
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
* Clean text responses: remove % symbols and spaces from SPSS text fields

foreach a in c i a p {
		* remove white space and  %
		replace post_`a'_trial = ustrregexra(post_`a'_trial, "\s", "")
    replace post_`a'_trial = subinstr(post_`a'_trial, "%", "", .)
		assert post_`a'_trial == ",7" if missing(real(post_`a'_trial)) & ~missing(post_`a'_trial)
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

* Maybe: binary indicator for vaccine intention (intend to or already got)
gen main_intent = inlist(vacc_intentions, 3, 4) if !mi(vacc_intentions) & vacc_intentions ~= -99 
label var main_intent "Intends/already got vaccine"
label values main_intent yesno

* Link click: any link clicked
gen link_click = (link1_clicked == 1 | link2_clicked == 1 | link3_clicked == 1 | link4_clicked == 1)
label var link_click "Any link clicked"
label values link_click yesno


/*------------------------------------------------------------------------------
    10. Create quality/sample flags
------------------------------------------------------------------------------*/

* Set attention check parameters for this survey
global attn_check_var "attn_check"
global attn_check_val = $ATTN_CHECK_MAIN

do "code/include/_create_quality_flags.do"

* Count missing outcomes
egen n_missing = rowmiss(posterior_vacc posterior_novacc post_trial)

* Final sample flag (main survey requires non-missing outcomes)
gen final_sample = (consent == 1 & failed_attn == 0 ///
    & _distchannel == "anonymous" & is_preview == 0 ///
		& n_missing == 0 & first_attempt == 1)

label var final_sample "Final analysis sample (consent, passed attn, non-missing outcomes, first attempt)"
assert ~missing(arm_n) if final_sample

/*------------------------------------------------------------------------------
    11. Apply variable labels
------------------------------------------------------------------------------*/

label var start_date "Survey start date/time"
label var end_date "Survey end date/time"
label var duration_sec "Survey duration (seconds)"
label var progress "Survey progress (%)"
label var consent "Consent given"
label var study_id "Cross wave id"
label var attn_check "Attention check value (should be $ATTN_CHECK_MAIN)"
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
foreach var of varlist final_sample incomplete failed_attn pid_mismatch duplicate_study_id first_attempt is_preview ///
    arm_control arm_industry arm_academic arm_personal main_intent link_click {
    label values `var' yesno
}

/*------------------------------------------------------------------------------
    12. Create balance table indicator variables
------------------------------------------------------------------------------*/

* --- Prior Beliefs (7-point scales) ---
* prior_self_placebo: SE likelihood without vaccine
forvalues i = 1/7 {
    gen prior_placebo_`i' = (prior_self_placebo == `i') if ~missing(prior_self_placebo)
}
label var prior_placebo_1 "Prior placebo: Would definitely not"
label var prior_placebo_2 "Prior placebo: Very unlikely"
label var prior_placebo_3 "Prior placebo: Somewhat unlikely"
label var prior_placebo_4 "Prior placebo: Neither"
label var prior_placebo_5 "Prior placebo: Somewhat likely"
label var prior_placebo_6 "Prior placebo: Very likely"
label var prior_placebo_7 "Prior placebo: Would definitely"

* prior_self_vacc: SE likelihood with vaccine
forvalues i = 1/7 {
    gen prior_vacc_`i' = (prior_self_vacc == `i') if ~missing(prior_self_vacc)
}
label var prior_vacc_1 "Prior vacc: Would definitely not"
label var prior_vacc_2 "Prior vacc: Very unlikely"
label var prior_vacc_3 "Prior vacc: Somewhat unlikely"
label var prior_vacc_4 "Prior vacc: Neither"
label var prior_vacc_5 "Prior vacc: Somewhat likely"
label var prior_vacc_6 "Prior vacc: Very likely"
label var prior_vacc_7 "Prior vacc: Would definitely"

* --- Demographics ---
* Create missing indicators and impute missing values to avoid dropping observations
* in regressions. The missing indicator captures any systematic missingness effect.
* Treat both Stata-missing and PREF_NOT_SAY (-99) as missing.
* Note: trust_govt is from prescreen, handled in merge step
foreach var in age gender education income race ethnicity polviews {
    gen `var'_miss = (missing(`var') | `var' == $PREF_NOT_SAY)
    label var `var'_miss "`var' missing"
    * Impute missing/PREF_NOT_SAY to base category (will be absorbed by factor variable)
    replace `var' = 1 if missing(`var') | `var' == $PREF_NOT_SAY
}

* Age (2=18-34, 3=35-49, 4=50-64, 5=65+)
gen age_18_34 = (age == 2) if ~missing(age)
gen age_35_49 = (age == 3) if ~missing(age)
gen age_50_64 = (age == 4) if ~missing(age)
gen age_65plus = (age == 5) if ~missing(age)

label var age_18_34 "Age 18--34"
label var age_35_49 "Age 35--49"
label var age_50_64 "Age 50--64"
label var age_65plus "Age 65+"

* Gender (1=Male, 2=Female, 3=Other)
gen female = (gender == 2) if ~missing(gender)
gen gender_other = (gender == 3) if ~missing(gender)

label var female "Female"
label var gender_other "Gender: Other"

* Education (1=<HS, 2=HS, 3=Some college, 4=4-year, 5=>4-year)
gen educ_hs_or_less = (education <= 2) if ~missing(education)
gen educ_some_college = (education == 3) if ~missing(education)
gen educ_college = (education == 4) if ~missing(education)
gen educ_grad = (education == 5) if ~missing(education)

label var educ_hs_or_less "Education: HS or less"
label var educ_some_college "Education: Some college"
label var educ_college "Education: 4-year degree"
label var educ_grad "Education: Graduate degree"

* Income (1=<25k, 2=25-50k, 3=50-75k, 4=75-100k, 5=>100k)
gen income_lt25k = (income == 1) if ~missing(income)
gen income_25_50k = (income == 2) if ~missing(income)
gen income_50_75k = (income == 3) if ~missing(income)
gen income_75_100k = (income == 4) if ~missing(income)
gen income_100kplus = (income == 5) if ~missing(income)

label var income_lt25k "Income: Under \$25k"
label var income_25_50k "Income: \$25--50k"
label var income_50_75k "Income: \$50--75k"
label var income_75_100k "Income: \$75--100k"
label var income_100kplus "Income: Over \$100k"

* Race (1=White, 2=Black, 3=Asian, 4=Am Indian, 5=Other)
gen race_white = (race == 1) if ~missing(race)
gen race_black = (race == 2) if ~missing(race)
gen race_asian = (race == 3) if ~missing(race)
gen race_native = (race == 4) if ~missing(race)
gen race_other = (race == 5) if ~missing(race)

label var race_white "White"
label var race_black "Black"
label var race_asian "Asian"
label var race_native "American Indian/Alaska Native"
label var race_other "Race: Other"

* Ethnicity (1=Hispanic)
gen hispanic = (ethnicity == 1) if ~missing(ethnicity)

label var hispanic "Hispanic"

* Political views (1-7)
gen polviews_very_liberal = (polviews == 1) if ~missing(polviews)
gen polviews_liberal = (polviews == 2) if ~missing(polviews)
gen polviews_slight_liberal = (polviews == 3) if ~missing(polviews)
gen polviews_moderate = (polviews == 4) if ~missing(polviews)
gen polviews_slight_conserv = (polviews == 5) if ~missing(polviews)
gen polviews_conservative = (polviews == 6) if ~missing(polviews)
gen polviews_very_conserv = (polviews == 7) if ~missing(polviews)

label var polviews_very_liberal "Very liberal"
label var polviews_liberal "Liberal"
label var polviews_slight_liberal "Slightly liberal"
label var polviews_moderate "Moderate"
label var polviews_slight_conserv "Slightly conservative"
label var polviews_conservative "Conservative"
label var polviews_very_conserv "Very conservative"

/*------------------------------------------------------------------------------
    13. Drop unnecessary variables and reorder
------------------------------------------------------------------------------*/

* Drop temporary variables and unused vars
drop _finished _recordeddate _distchannel _userlang
drop FL_17_DO_CONTROLARM FL_17_DO_INDUSTRYARM FL_17_DO_ACADEMICARM FL_17_DO_PERSONALARM
drop response_id 
* Note: Progress already renamed to progress by _rename_qualtrics_metadata.do

* Order variables logically
order study_id ///
      start_date end_date duration_sec progress ///
      consent final_sample incomplete failed_attn pid_mismatch duplicate_study_id ///
			first_attempt is_preview ///
      attn_check ///
      arm_n arm arm_control arm_industry arm_academic arm_personal ///
      prior_self_placebo prior_self_vacc  ///
      post_trial post_c_trial post_i_trial post_a_trial post_p_trial ///
      posterior_novacc posterior_vacc delta ///
      trust_trial relevant_trial trust_academic relevant_academic ///
      vacc_intentions main_intent ///
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
assert inlist(vacc_intent, 1, 2, 3, 4, $PREF_NOT_SAY, .)
assert inlist(age, 1, 2, 3, 4, 5, 6, .)  // PREF_NOT_SAY recoded to 1
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
do "code/include/_report_sample_quality.do"

* Compress and save
compress
save "derived/main_clean.dta", replace

di ""
di "=== CLEANING COMPLETE ==="
di "Saved: derived/main_clean.dta"

capture log close
