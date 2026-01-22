/*==============================================================================
    Define Common Value Labels

    This include file defines all value labels used across survey cleaning files.
    Centralizes label definitions to ensure consistency and reduce duplication.

    Must be called before variable recoding/labeling.

    Usage: do "code/include/_define_value_labels.do"
==============================================================================*/

* Boolean (Yes/No)
label define yesno 0 "0. No" 1 "1. Yes", replace

* Insurance (Yes/No/Not sure) - prescreen only
label define insurance_lbl -1 "-1. Not sure" 0 "0. No" 1 "1. Yes", replace

* Likert agreement scale (1-5)
label define agree5 ///
    1 "1. Strongly disagree" ///
    2 "2. Somewhat disagree" ///
    3 "3. Neither agree nor disagree" ///
    4 "4. Somewhat agree" ///
    5 "5. Strongly agree", replace

* Frequency scale (1-4)
label define freq4 ///
    1 "1. Never" ///
    2 "2. Rarely" ///
    3 "3. Sometimes" ///
    4 "4. Often", replace

* Frequency scale with "no doctor" option
label define freq4_nodoc ///
    -1 "-1. No doctor" ///
    1 "1. Never" ///
    2 "2. Rarely" ///
    3 "3. Sometimes" ///
    4 "4. Often", replace

* Reliability scale (1-3)
label define reliable3 ///
    1 "1. Not reliable" ///
    2 "2. Somewhat reliable" ///
    3 "3. Yes, reliable", replace

* Flu vaccine last year - prescreen
label define fluvax_lastyear_lbl 0 "0. No" 1 "1. Yes", replace

* Prior vaccines - prescreen
label define prior_vax_lbl ///
    1 "1. Neither vaccine" ///
    2 "2. Flu only" ///
    3 "3. COVID only" ///
    4 "4. Both vaccines", replace

* Flu vaccine intent - prescreen
label define flu_intent_lbl ///
    1 "1. No, do not intend" ///
    2 "2. May or may not" ///
    3 "3. Intend to get" ///
    4 "4. Already got", replace

* Vaccine reaction - prescreen
label define reaction_lbl ///
    0 "0. No prior vaccine" ///
    1 "1. None/don't remember" ///
    2 "2. Mild (not severe)" ///
    3 "3. Severe", replace

* Main info source - prescreen
label define source_main_lbl ///
    1 "1. Doctor" ///
    2 "2. Social media" ///
    3 "3. Podcasts" ///
    4 "4. CDC" ///
    5 "5. News organizations" ///
    6 "6. None of the above", replace

* Treatment arm - main
label define arm_lbl ///
    0 "0. Control" ///
    1 "1. Industry" ///
    2 "2. Academic" ///
    3 "3. Personal", replace

* Prior beliefs (7-point) - main
label define prior7_lbl ///
    1 "1. Would definitely not" ///
    2 "2. Very unlikely" ///
    3 "3. Somewhat unlikely" ///
    4 "4. Neither likely nor unlikely" ///
    5 "5. Somewhat likely" ///
    6 "6. Very likely" ///
    7 "7. Would definitely", replace

* Trust/relevance (0-10) - main
label define scale10_lbl ///
    0 "0" 1 "1" 2 "2" 3 "3" 4 "4" 5 "5" 6 "6" 7 "7" 8 "8" 9 "9" 10 "10", replace

* Vaccination intentions - main
label define vacc_intent_lbl ///
    1 "1. No, do not intend" ///
    2 "2. May or may not" ///
    3 "3. Intend to get" ///
    4 "4. Already got" ///
    $PREF_NOT_SAY "$PREF_NOT_SAY. Prefer not to say", replace

* Age - main
label define age_lbl ///
    1 "1. Under 18" ///
    2 "2. 18-34" ///
    3 "3. 35-49" ///
    4 "4. 50-64" ///
    5 "5. 65-74" ///
    6 "6. 75+" ///
    $PREF_NOT_SAY "$PREF_NOT_SAY. Prefer not to say", replace

* Gender - main
label define gender_lbl ///
    1 "1. Male" ///
    2 "2. Female" ///
    3 "3. Other" ///
    4 "4. Prefer not to say", replace

* Education - main
label define educ_lbl ///
    1 "1. Less than HS" ///
    2 "2. HS" ///
    3 "3. Some college" ///
    4 "4. 4-year degree" ///
    5 "5. More than 4-year" ///
    6 "6. Prefer not to say", replace

* Income - main
label define income_lbl ///
    1 "1. <$25k" ///
    2 "2. $25-50k" ///
    3 "3. $50-75k" ///
    4 "4. $75-100k" ///
    5 "5. >$100k" ///
    6 "6. Prefer not to say", replace

* Race - main
label define race_lbl ///
    1 "1. White" ///
    2 "2. Black" ///
    3 "3. Asian" ///
    4 "4. Am Indian/Alaska Native" ///
    5 "5. Pacific Islander" ///
    6 "6. Other" ///
    7 "7. Prefer not to say", replace

* Ethnicity - main
label define ethnicity_lbl ///
    1 "1. Yes" ///
    2 "2. No" ///
    3 "3. Prefer not to say", replace

* Political views - main
label define polviews_lbl ///
    1 "1. Very liberal" ///
    2 "2. Liberal" ///
    3 "3. Slightly liberal" ///
    4 "4. Moderate" ///
    5 "5. Slightly conservative" ///
    6 "6. Conservative" ///
    7 "7. Very conservative" ///
    8 "8. Prefer not to say", replace

* Pharmacy factor - followup
label define factor_lbl ///
    1 "1. Price" ///
    2 "2. Convenience" ///
    3 "3. Quality/reputation" ///
    4 "4. Pharmacist access" ///
    5 "5. None important", replace

* Price compare / coupons - followup
label define shopping_lbl ///
    1 "1. Yes, at least once" ///
    2 "2. No" ///
    3 "3. Did not shop for medicines", replace

* Recall study - followup
label define recall_lbl ///
    1 "1. Yes" ///
    2 "2. No" ///
    3 "3. Don't remember", replace

* Recall info - followup
label define recallinfo_lbl ///
    1 "1. Yes" ///
    2 "2. No" ///
    3 "3. Don't remember study", replace

* Trustworthy - followup
label define trust_lbl ///
    1 "1. Don't remember study" ///
    2 "2. Trustworthy" ///
    3 "3. Somewhat trustworthy" ///
    4 "4. Not trustworthy", replace
