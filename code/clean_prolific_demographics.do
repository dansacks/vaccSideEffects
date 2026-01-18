/*==============================================================================
    Clean Prolific Demographic Exports

    Input:  data/prolific_demographic_export_*.csv
    Output: data/prolific_demographics_prescreen.dta
            data/prolific_demographics_main.dta
            data/prolific_demographics_main_morepay.dta
            data/prolific_demographics_followup.dta

    Cleans prolific demographic data for merging with survey data.

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "clean_prolific_demographics"
do "code/_config.do"

/*------------------------------------------------------------------------------
    Program to clean a single prolific demographic file
------------------------------------------------------------------------------*/

capture program drop clean_prolific
program define clean_prolific
    args infile outfile

    di ""
    di "=== Cleaning: `infile' ==="

    * Import CSV
    import delimited using "`infile'", clear varnames(1) stringcols(_all)

    * Rename key variables
    rename submissionid prolific_submission_id
    rename participantid prolific_pid
    rename status prolific_status
    rename startedat prolific_started
    rename completedat prolific_completed
    rename timetaken prolific_duration
    rename totalapprovals prolific_approvals

    * Clean demographics
    rename age prolific_age
    rename sex prolific_sex
    rename ethnicitysimplified prolific_ethnicity
    rename countryofbirth prolific_country_birth
    rename countryofresidence prolific_country_residence
    rename nationality prolific_nationality
    rename language prolific_language
    rename studentstatus prolific_student
    rename employmentstatus prolific_employment

    * Convert numeric variables
    destring prolific_age, replace force
    destring prolific_duration, replace force
    destring prolific_approvals, replace force

    * Clean string variables - handle DATA_EXPIRED
    foreach var in prolific_student prolific_employment {
        replace `var' = "" if `var' == "DATA_EXPIRED"
    }

    * Create numeric codes for categorical variables

    * Sex
    gen prolific_female = (prolific_sex == "Female") if prolific_sex != ""
    gen prolific_male = (prolific_sex == "Male") if prolific_sex != ""
    label var prolific_female "Female (Prolific)"
    label var prolific_male "Male (Prolific)"

    * Ethnicity
    encode prolific_ethnicity, gen(prolific_ethnicity_n)
    label var prolific_ethnicity_n "Ethnicity (Prolific, numeric)"

    * Student status
    gen prolific_is_student = (prolific_student == "Yes") if prolific_student != ""
    label var prolific_is_student "Currently a student (Prolific)"

    * Employment - create categories
    gen prolific_employed_ft = strpos(prolific_employment, "Full-Time") > 0 if prolific_employment != ""
    gen prolific_employed_pt = strpos(prolific_employment, "Part-Time") > 0 if prolific_employment != ""
    gen prolific_not_working = strpos(prolific_employment, "Not in paid work") > 0 if prolific_employment != ""
    gen prolific_unemployed = strpos(prolific_employment, "Unemployed") > 0 if prolific_employment != ""
    label var prolific_employed_ft "Employed full-time (Prolific)"
    label var prolific_employed_pt "Employed part-time (Prolific)"
    label var prolific_not_working "Not in paid work (Prolific)"
    label var prolific_unemployed "Unemployed (Prolific)"

    * Keep only relevant variables
    keep prolific_pid prolific_submission_id prolific_status ///
         prolific_started prolific_completed prolific_duration prolific_approvals ///
         prolific_age prolific_sex prolific_female prolific_male ///
         prolific_ethnicity prolific_ethnicity_n ///
         prolific_country_birth prolific_country_residence prolific_nationality ///
         prolific_language prolific_student prolific_is_student ///
         prolific_employment prolific_employed_ft prolific_employed_pt ///
         prolific_not_working prolific_unemployed

    * Label core variables
    label var prolific_pid "Prolific participant ID"
    label var prolific_submission_id "Prolific submission ID"
    label var prolific_status "Prolific submission status"
    label var prolific_started "Prolific start time"
    label var prolific_completed "Prolific completion time"
    label var prolific_duration "Time taken (seconds, Prolific)"
    label var prolific_approvals "Total approvals (Prolific)"
    label var prolific_age "Age (Prolific)"
    label var prolific_sex "Sex (Prolific)"
    label var prolific_ethnicity "Ethnicity simplified (Prolific)"
    label var prolific_country_birth "Country of birth (Prolific)"
    label var prolific_country_residence "Country of residence (Prolific)"
    label var prolific_nationality "Nationality (Prolific)"
    label var prolific_language "Language (Prolific)"
    label var prolific_student "Student status (Prolific)"
    label var prolific_employment "Employment status (Prolific)"

    * Check for duplicates
    duplicates report prolific_pid

    * Compress and save
    compress
    save "`outfile'", replace

    di "Saved: `outfile'"
    di "Observations: " _N
end

/*------------------------------------------------------------------------------
    Clean each file
------------------------------------------------------------------------------*/

* Prescreen (long string filename)
clean_prolific ///
    "data/prolific_demographic_export_692494f77a877e57e000eb60.csv" ///
    "data/prolific_demographics_prescreen.dta"

* Main
clean_prolific ///
    "data/prolific_demographic_export_main.csv" ///
    "data/prolific_demographics_main.dta"

* Main morepay
clean_prolific ///
    "data/prolific_demographic_export_main_morepay.csv" ///
    "data/prolific_demographics_main_morepay.dta"

* Followup
clean_prolific ///
    "data/prolific_demographic_export_followup.csv" ///
    "data/prolific_demographics_followup.dta"

/*------------------------------------------------------------------------------
    Summary
------------------------------------------------------------------------------*/

di ""
di "=== All prolific demographic files cleaned ==="

capture log close
