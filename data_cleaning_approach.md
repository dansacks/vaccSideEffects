# Data Cleaning Approach: Prescreen Survey

## Overview

This document summarizes the approach used to clean the Qualtrics prescreen survey data. The methodology can be adapted for cleaning the main and follow-up survey waves.

## Key Steps

### 1. Define Cleaning Requirements

Before writing any code, we specified:
- **Variable naming convention**: snake_case (e.g., `flu_vax_lastyear`)
- **Value label format**: Numbered labels like `1 "1. Strongly disagree"` for easy interpretation in output
- **Categorical coding**: Ordered categories start at 1 (not 0), with special codes like -1 for "Not sure" or "No doctor"
- **Quality flags needed**: `incomplete`, `failed_attn`, `pid_mismatch`, `duplicate_pid`, `final_sample`
- **Derived variables**: Binary indicators for multi-category variables, consolidated reaction variables

### 2. Locate Raw Data Files

- **Raw CSV**: `data/vacc_se_prescreen_full_November+28,+2025_07.35.csv`
- **Survey definition (QSF)**: `design_materials/qualtrics/vacc_se_prescreen_full.qsf`

The QSF file is critical - it contains the authoritative question text, response options, and skip logic.

### 3. Parse the QSF File for Codebook

The QSF file is JSON-formatted and contains:
- `SurveyElements` array with question definitions
- For each question: `QuestionID`, `DataExportTag`, `QuestionText`, `Choices`, `ChoiceOrder`
- Survey flow logic showing skip patterns

We parsed this to create `design_materials/prescreen_codebook.txt` mapping:
- Qualtrics QID → Export variable name → Cleaned variable name
- Response option codes and text

### 4. Understand Skip Logic and Duplicate Variable Names

**Critical insight**: Qualtrics exports can have duplicate column names when:
- The same `DataExportTag` is used for multiple questions
- Questions appear in different survey branches

In this survey:
- `Reaction` appears twice (QID18 for flu-only path, QID22 for COVID-only path)
- `Source` appears three times (social media, podcasts, news follow-ups)

Stata handles duplicates by keeping the first name and using `v#` for subsequent duplicates:
- First `Reaction` → `reaction`
- Second `Reaction` → `v27`
- First `Source` → `source`
- Second `Source` → `v35`
- Third `Source` → `v36`

**Survey flow for vaccine reactions**:
```
If prior_vaccines == "COVID only" → QID22 (reaction) asked
If prior_vaccines == "Flu only" → QID18 (v27) asked
If prior_vaccines == "Both" → QID49 (fluvaxexperience) + QID51 (covidvaxexperience) asked
If prior_vaccines == "Neither" → No reaction questions asked
```

### 5. Determine Actual Stata Variable Names on Import

**Do not assume Stata uses the CSV header names directly.**

After importing, run `describe` to see actual variable names. Stata:
- Lowercases everything
- Removes spaces and special characters
- Truncates long names
- Uses `v#` for duplicates

We saved the output to `notes/prescreen_imported_variables.txt` for reference.

Example mappings:
| CSV Header | Stata Imports As |
|------------|------------------|
| Duration (in seconds) | durationinseconds |
| DistributionChannel | distributionchannel |
| Favorite Number | favoritenumber |
| Vaccine History | vaccinehistory |
| Reliability: Doctor | reliabilitydoctor |

### 6. Handle Qualtrics Export Header Rows

Qualtrics CSV exports include metadata rows:
- **Row 1**: Variable names (short labels)
- **Row 2**: Full question text
- **Row 3**: Import IDs (JSON format with QID references)
- **Row 4+**: Actual response data

**Important**: The number of rows to drop depends on how the question text wraps. In this export, the consent form text spanned multiple lines, requiring `drop in 1/15` rather than `drop in 1/2`. Always verify by inspecting the first observations after import.

### 7. Recode String Variables to Labeled Numeric

For each categorical variable:
1. Create temporary `*_num` variable
2. Use `strpos()` to match response text patterns
3. Assert missing-iff-missing: `assert mi(*_num) == (orig == "" | orig == "-99")`
4. Drop original string, rename numeric to final name
5. Apply value label

Example:
```stata
gen flu_vax_intent_num = .
replace flu_vax_intent_num = 1 if strpos(flu_vax_intent, "do not intend") > 0
replace flu_vax_intent_num = 2 if strpos(flu_vax_intent, "may not") > 0
replace flu_vax_intent_num = 3 if flu_vax_intent == "I intend to get the flu vaccine."
replace flu_vax_intent_num = 4 if strpos(flu_vax_intent, "already") > 0
assert mi(flu_vax_intent_num) == (flu_vax_intent == "" | flu_vax_intent == "-99")
drop flu_vax_intent
rename flu_vax_intent_num flu_vax_intent
label values flu_vax_intent flu_intent_lbl
```

### 8. Consolidate Variables from Different Survey Paths

When the same conceptual variable is asked in different branches:
1. Rename each path's variable to a temporary name (e.g., `_covid_reaction1`, `_covid_reaction2`)
2. Create derived indicator for which path was taken (e.g., `had_prior_covid`)
3. Consolidate into single variable, coding 0 for "not applicable" path
4. Drop temporary variables

### 9. Validate with Assertions

Include assertions throughout:
- `assert _N > 0` after import
- `assert inlist(var, valid_values)` for each recoded variable
- `assert mi(new) == (old == "" | old == "-99")` for missing preservation
- `assert` derived variables are consistent with source variables
- `desc` + `assert r(k) == expected_count` for final variable count

### 10. Document and Save

- Apply variable labels to all variables
- Order variables logically
- Compress dataset
- Save as `.dta`

## Files Produced

| File | Description |
|------|-------------|
| `code/clean_prescreen.do` | Stata do-file for cleaning |
| `data/prescreen_clean.dta` | Cleaned dataset |
| `design_materials/prescreen_codebook.txt` | Human-readable codebook from QSF |
| `notes/prescreen_imported_variables.txt` | Stata variable names after import |
| `notes/data_cleaning_approach.md` | This methodology document |

## Lessons Learned

1. **Always check actual Stata variable names** - don't assume they match CSV headers
2. **Parse the QSF file** - it's the authoritative source for question text and response options
3. **Understand skip logic** - affects which variables are populated for which respondents
4. **Handle duplicate export tags** - Stata uses `v#` naming for duplicates
5. **Verify rows to drop** - depends on how multi-line question text exports
6. **Use string matching for recoding** - Qualtrics numeric codes may not match desired coding scheme
7. **Assert liberally** - catch errors early with validation checks
