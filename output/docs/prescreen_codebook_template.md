# Prescreen Survey Codebook

**Dataset:** `data/prescreen_clean.dta`
**Source:** `data/vacc_se_prescreen_full_November+28,+2025_07.35.csv`
**Analysis Sample:** `final_sample == 1` (consented + passed attention check + anonymous channel)

---

## Overview

This codebook documents all variables in the cleaned prescreen survey dataset. Variables are organized into the following sections:

1. [Identifiers & Metadata](#identifiers--metadata)
2. [Quality Flags](#quality-flags)
3. [Vaccine History & Intent](#vaccine-history--intent)
4. [Vaccine Reactions](#vaccine-reactions)
5. [Health Conditions](#health-conditions)
6. [Trust & Attitudes](#trust--attitudes)
7. [Information Sources](#information-sources)
8. [Information Frequency](#information-frequency)
9. [Source Reliability](#source-reliability)
10. [Open-Ended Responses](#open-ended-responses)

---

## Identifiers & Metadata

### `response_id`
- **Type:** String
- **Label:** Qualtrics response ID
- **Description:** Unique identifier assigned by Qualtrics

### `prolific_pid`
- **Type:** String
- **Label:** Prolific ID (from URL)
- **Description:** Prolific participant ID passed via URL parameter

### `prolific_id_entered`
- **Type:** String
- **Label:** Prolific ID (entered)
- **Description:** Prolific ID manually entered by participant
- **Question:** "What is your prolific ID? Please note that this response should auto-fill with the correct ID, but just in case, please enter below"

### `start_date`
- **Type:** String (datetime)
- **Label:** Survey start date/time

### `end_date`
- **Type:** String (datetime)
- **Label:** Survey end date/time

### `duration_sec`
- **Type:** Numeric (continuous)
- **Label:** Survey duration (seconds)
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |
- **Summary Statistics (N=7,873):**

| Statistic | Value |
|-----------|-------|
| Mean | 248.2 |
| SD | 651.6 |
| Min | 11 |
| Median | 188 |
| Max | 55,342 |

### `progress`
- **Type:** Numeric (continuous)
- **Label:** Survey progress (%)
- **Range:** 0-100

---

## Quality Flags

### `consent`
- **Type:** Binary
- **Label:** Consent given
- **Question:** University of Wisconsin-Madison research consent form
- **Values:**

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `final_sample`
- **Type:** Binary
- **Label:** Final analysis sample
- **Description:** 1 if consent==1 AND failed_attn==0 AND distribution channel=="anonymous"
- **Values:**

| Code | Label |
|------|-------|
| 0 | Excluded |
| 1 | Included in final sample |

### `incomplete`
- **Type:** Binary
- **Label:** Incomplete response
- **Description:** 1 if progress < 100 or finished != "True"
- **Values:**

| Code | Label |
|------|-------|
| 0 | Complete  |
| 1 | Incomplete  |

### `failed_attn`
- **Type:** Binary
- **Label:** Failed attention check
- **Description:** 1 if favorite_number != 1965
- **Values:**

| Code | Label |
|------|-------|
| 0 | Passed |
| 1 | Failed |

### `pid_mismatch`
- **Type:** Binary
- **Label:** Prolific PID mismatch
- **Description:** 1 if prolific_pid != prolific_id_entered
- **Values:**

| Code | Label |
|------|-------|
| 0 | Match  |
| 1 | Mismatch  |

### `duplicate_pid`
- **Type:** Binary
- **Label:** Duplicate Prolific PID
- **Description:** 1 if prolific_pid appears more than once in the dataset
- **Values:**

| Code | Label |
|------|-------|
| 0 | Unique  |
| 1 | Duplicate  |

### `favorite_number`
- **Type:** Numeric
- **Label:** Favorite number (attention check)
- **Question:** "Given the above, what is your favorite number?" (correct answer: 1965)

---

## Vaccine History & Intent

### `flu_vacc_lastyear`
- **Type:** Binary
- **Label:** Got flu vaccine last year
- **Question:** "Did you get the flu vaccine during last year's flu season?"
- **Values:**

| Code | Label |
|------|-------|
| 0 | No  |
| 1 | Yes  |

### `prior_vaccines`
- **Type:** Categorical
- **Label:** Prior vaccine history
- **Question:** "Have you ever previously gotten the flu vaccine or the COVID vaccine?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Neither vaccine  |
| 2 | Flu only  |
| 3 | COVID only  |
| 4 | Both vaccines  |

### `vacc_intent`
- **Type:** Categorical (ordered)
- **Label:** Flu vaccine intent this season
- **Question:** "Do you intend to get, or have you already got, the flu vaccine for this flu season?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | No, do not intend  |
| 2 | May or may not  |
| 3 | Intend to get  |
| 4 | Already got  |

### `had_prior_covid`
- **Type:** Binary (derived)
- **Label:** Had prior COVID vaccine
- **Description:** Derived from `prior_vaccines`; 1 if prior_vaccines in {3, 4}
- **Values:**

| Code | Label |
|------|-------|
| 0 | No prior COVID vaccine  |
| 1 | Had prior COVID vaccine  |

### `had_prior_flu`
- **Type:** Binary (derived)
- **Label:** Had prior flu vaccine
- **Description:** Derived from `prior_vaccines`; 1 if prior_vaccines in {2, 4}
- **Values:**

| Code | Label |
|------|-------|
| 0 | No prior flu vaccine  |
| 1 | Had prior flu vaccine  |

---

## Vaccine Reactions

These variables consolidate responses from multiple survey questions that were shown based on skip logic.

### `covid_reaction`
- **Type:** Categorical
- **Label:** COVID vaccine reaction
- **Question:** "You indicated that you previously got the COVID vaccine. Did you experience severe adverse events in the days afterwards?"
- **Skip Logic:** Asked only if `prior_vaccines` in {3, 4} (had COVID vaccine)
- **Values:**

| Code | Label |
|------|-------|
| 0 | No prior vaccine  |
| 1 | None/don't remember  |
| 2 | Mild (not severe)  |
| 3 | Severe  |

### `flu_reaction`
- **Type:** Categorical
- **Label:** Flu vaccine reaction
- **Question:** "You indicated that you previously got the flu vaccine. Did you experience severe adverse events afterwards?"
- **Skip Logic:** Asked only if `prior_vaccines` in {2, 4} (had flu vaccine)
- **Values:**

| Code | Label |
|------|-------|
| 0 | No prior vaccine  |
| 1 | None/don't remember  |
| 2 | Mild (not severe)  |
| 3 | Severe  |

---

## Health Conditions

### `has_insurance`
- **Type:** Categorical
- **Label:** Has health insurance
- **Question:** "Do you have health insurance?"
- **Values:**

| Code | Label |
|------|-------|
| -1 | Not sure  |
| 0 | No  |
| 1 | Yes  |

### `health_conditions`
- **Type:** String
- **Label:** Health conditions (raw)
- **Question:** "Do you have any of these health conditions? (check any that apply)"
- **Description:** Raw comma-separated response; see derived dummies below

### `cond_none`
- **Type:** Binary (derived)
- **Label:** No health conditions
- **Values:** 0 = No, 1 = Yes

### `cond_asthma`
- **Type:** Binary (derived)
- **Label:** Has asthma
- **Values:** 0 = No, 1 = Yes

### `cond_diabetes`
- **Type:** Binary (derived)
- **Label:** Has diabetes
- **Values:** 0 = No, 1 = Yes

### `cond_heart`
- **Type:** Binary (derived)
- **Label:** Has heart disease
- **Values:** 0 = No, 1 = Yes

### `cond_lung`
- **Type:** Binary (derived)
- **Label:** Has lung disease
- **Values:** 0 = No, 1 = Yes

### `cond_kidney`
- **Type:** Binary (derived)
- **Label:** Has kidney disease
- **Values:** 0 = No, 1 = Yes

### `cond_rather_not_say`
- **Type:** Binary (derived)
- **Label:** Health conditions: rather not say
- **Values:** 0 = No, 1 = Yes

---

## Trust & Attitudes

### `trust_govt`
- **Type:** Categorical (Likert 5-point)
- **Label:** Trust government info about flu vaccine
- **Question:** "Please indicate how much you agree or disagree with this statement: 'The information I receive from government sources about the flu vaccine is reliable'."
- **Values:**

| Code | Label |
|------|-------|
| 1 | Strongly disagree  |
| 2 | Somewhat disagree  |
| 3 | Neither agree nor disagree  |
| 4 | Somewhat agree  |
| 5 | Strongly agree  |

### `trust_govt_prior`
- **Type:** Categorical (Likert 5-point)
- **Label:** Prior trust in government info
- **Question:** "Please indicate how much you agree or disagree with this statement: 'In prior years, the information I received from government sources about the flu vaccine was reliable'."
- **Values:**

| Code | Label |
|------|-------|
| 1 | Strongly disagree  |
| 2 | Somewhat disagree  |
| 3 | Neither agree nor disagree  |
| 4 | Somewhat agree  |
| 5 | Strongly agree  |

### `follow_doctor`
- **Type:** Categorical (Likert 5-point)
- **Label:** Generally follow doctor's vaccine advice
- **Question:** "Please indicate how much you agree or disagree with this statement: 'Generally I do what my doctor recommends about vaccines'."
- **Values:**

| Code | Label |
|------|-------|
| 1 | Strongly disagree  |
| 2 | Somewhat disagree  |
| 3 | Neither agree nor disagree  |
| 4 | Somewhat agree  |
| 5 | Strongly agree  |

---

## Information Sources

### `info_source_main`
- **Type:** Categorical
- **Label:** Most important health info source
- **Question:** "Which of these sources is your most important source of information about health care?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Doctor  |
| 2 | Social media  |
| 3 | Podcasts  |
| 4 | CDC  |
| 5 | News organizations  |
| 6 | None of the above  |

### Binary Indicators (derived from `info_source_main`)

| Variable | Label | N (%) Yes |
|----------|-------|-----------|
| `source_doctor` | Main source: Doctor | 5,559 (70.83%) |
| `source_sm` | Main source: Social media | 386 (4.92%) |
| `source_podcasts` | Main source: Podcasts | 127 (1.62%) |
| `source_cdc` | Main source: CDC | 767 (9.77%) |
| `source_news` | Main source: News | 250 (3.19%) |
| `source_none` | Main source: None of the above | 759 (9.67%) |

All binary indicators: 0 = No, 1 = Yes

---

## Information Frequency

### `info_doctor`
- **Type:** Categorical (frequency)
- **Label:** Get info from doctor
- **Question:** "Do you obtain health care information from your doctor?"
- **Values:**

| Code | Label |
|------|-------|
| -1 | No doctor  |
| 1 | Never  |
| 2 | Rarely  |
| 3 | Sometimes  |
| 4 | Often  |

### `info_sm`
- **Type:** Categorical (frequency)
- **Label:** Get info from social media
- **Question:** "Do you obtain health care information from social media (for example, Facebook, X/Twitter, YouTube, Instagram, and TikTok)?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Never  |
| 2 | Rarely  |
| 3 | Sometimes  |
| 4 | Often  |

### `info_podcasts`
- **Type:** Categorical (frequency)
- **Label:** Get info from podcasts
- **Question:** "Do you obtain health care information from podcasts?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Never  |
| 2 | Rarely  |
| 3 | Sometimes  |
| 4 | Often  |

### `info_cdc`
- **Type:** Categorical (frequency)
- **Label:** Get info from CDC
- **Question:** "Do you obtain health care information from the U.S. Centers for Disease Control and Prevention (CDC)?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Never  |
| 2 | Rarely  |
| 3 | Sometimes  |
| 4 | Often  |

### `info_news`
- **Type:** Categorical (frequency)
- **Label:** Get info from news
- **Question:** "Do you obtain health care information from news organizations (for example, CNN, Fox News, or the New York Times)?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Never  |
| 2 | Rarely  |
| 3 | Sometimes  |
| 4 | Often  |

### `info_university`
- **Type:** Categorical (frequency)
- **Label:** Get info from university research
- **Question:** "Do you ever obtain health care information from university research or researchers?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Never  |
| 2 | Rarely  |
| 3 | Sometimes  |
| 4 | Often  |

---

## Source Reliability

### `reliable_doctor`
- **Type:** Categorical
- **Label:** Find doctor info reliable
- **Question:** "When you obtain health care information from your doctor, do you find it reliable?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Not reliable  |
| 2 | Somewhat reliable  |
| 3 | Yes, reliable  |

### `reliable_sm`
- **Type:** Categorical
- **Label:** Find social media info reliable
- **Question:** "When you obtain health care information from social media, do you find it reliable?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Not reliable  |
| 2 | Somewhat reliable  |
| 3 | Yes, reliable  |

### `reliable_podcasts`
- **Type:** Categorical
- **Label:** Find podcast info reliable
- **Question:** "When you obtain health care information from podcasts, do you find it reliable?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Not reliable  |
| 2 | Somewhat reliable  |
| 3 | Yes, reliable  |

### `reliable_cdc`
- **Type:** Categorical
- **Label:** Find CDC info reliable
- **Question:** "When you obtain health care information from the U.S. Centers for Disease Control and Prevention (CDC), do you find it reliable?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Not reliable  |
| 2 | Somewhat reliable  |
| 3 | Yes, reliable  |

### `reliable_news`
- **Type:** Categorical
- **Label:** Find news info reliable
- **Question:** "When you obtain health care information from news organizations, do you find it reliable?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Not reliable  |
| 2 | Somewhat reliable  |
| 3 | Yes, reliable  |

### `reliable_university`
- **Type:** Categorical
- **Label:** Find university research reliable
- **Question:** "Do you consider health care information from university research or researchers reliable?"
- **Values:**

| Code | Label |
|------|-------|
| 1 | Not reliable  |
| 2 | Somewhat reliable  |
| 3 | Yes, reliable  |

---

## Open-Ended Responses

### `source_sm_text`
- **Type:** String
- **Label:** Social media source (text)
- **Question:** "You said your most important source of information is social media. Please list the account that is most important."
- **Skip Logic:** Asked only if `info_source_main == 2`

### `source_podcast_text`
- **Type:** String
- **Label:** Podcast source (text)
- **Question:** "You said your most important source of information is podcasts. Please list the podcast that is most important."
- **Skip Logic:** Asked only if `info_source_main == 3`

### `source_news_text`
- **Type:** String
- **Label:** News source (text)
- **Question:** "You said your most important source of information is news organizations. Please list the news organization that is most important."
- **Skip Logic:** Asked only if `info_source_main == 5`

### `comments`
- **Type:** String
- **Label:** Final comments
- **Question:** "This is the last page of the survey. Thank you for your time and attention. On the next page you will be redirected back to prolific, with a valid completion code. If you have any comments for the study team, you can leave them in the field below. Please do not enter any information about yourself."

---

## Variable Summary

| Variable | Type | Values/Range |
|----------|------|--------------|
| response_id | String | Unique ID |
| prolific_pid | String | Prolific ID |
| prolific_id_entered | String | Prolific ID |
| start_date | String | Datetime |
| end_date | String | Datetime |
| duration_sec | Continuous | Seconds |
| progress | Continuous | 0-100 |
| consent | Binary | 0, 1 |
| final_sample | Binary | 0, 1 |
| incomplete | Binary | 0, 1 |
| failed_attn | Binary | 0, 1 |
| pid_mismatch | Binary | 0, 1 |
| duplicate_pid | Binary | 0, 1 |
| favorite_number | Numeric | Any (1965 = correct) |
| flu_vacc_lastyear | Binary | 0, 1 |
| prior_vaccines | Categorical | 1-4 |
| vacc_intent | Categorical | 1-4 |
| had_prior_covid | Binary | 0, 1 |
| had_prior_flu | Binary | 0, 1 |
| covid_reaction | Categorical | 0-3 |
| flu_reaction | Categorical | 0-3 |
| has_insurance | Categorical | -1, 0, 1 |
| cond_* | Binary | 0, 1 |
| trust_govt | Likert | 1-5 |
| trust_govt_prior | Likert | 1-5 |
| follow_doctor | Likert | 1-5 |
| info_source_main | Categorical | 1-6 |
| source_* | Binary | 0, 1 |
| info_doctor | Categorical | -1, 1-4 |
| info_sm | Categorical | 1-4 |
| info_podcasts | Categorical | 1-4 |
| info_cdc | Categorical | 1-4 |
| info_news | Categorical | 1-4 |
| info_university | Categorical | 1-4 |
| reliable_doctor | Categorical | 1-3 |
| reliable_sm | Categorical | 1-3 |
| reliable_podcasts | Categorical | 1-3 |
| reliable_cdc | Categorical | 1-3 |
| reliable_news | Categorical | 1-3 |
| reliable_university | Categorical | 1-3 |
| source_sm_text | String | Open text |
| source_podcast_text | String | Open text |
| source_news_text | String | Open text |
| comments | String | Open text |

**Total variables:** 54
