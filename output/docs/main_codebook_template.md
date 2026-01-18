# Main Survey Codebook

**Dataset:** `data/main_clean.dta`
**Source:** `data/flu_survey_main_December+9,+2025_08.17.csv`
**Analysis Sample:** `final_sample == 1` (consented + passed attention check + anonymous channel + no duplicate)

---

## Overview

This codebook documents all variables in the cleaned main survey dataset. The main survey is a 4-arm randomized controlled trial examining the effect of different information sources on vaccine-related beliefs.

### Treatment Arms

| Arm | Code | Description |
|-----|------|-------------|
| Control | 0 | Clinical trial results (no source attribution) |
| Industry | 1 | Trial results attributed to pharmaceutical industry |
| Academic | 2 | Trial results attributed to academic researchers |
| Personal | 3 | Trial results with personal testimonial framing |

---

## Identifiers & Metadata

### `response_id`
- **Type:** String
- **Label:** Qualtrics response ID

### `prolific_pid`
- **Type:** String
- **Label:** Prolific ID (from URL)

### `prolific_id_entered`
- **Type:** String
- **Label:** Prolific ID (entered by participant)

### `start_date`
- **Type:** String (datetime)
- **Label:** Survey start date/time

### `end_date`
- **Type:** String (datetime)
- **Label:** Survey end date/time

### `duration_sec`
- **Type:** Numeric (continuous)
- **Label:** Survey duration (seconds)

### `progress`
- **Type:** Numeric (continuous)
- **Label:** Survey progress (%)

---

## Quality Flags

### `consent`
- **Type:** Binary
- **Label:** Consent given

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `final_sample`
- **Type:** Binary
- **Label:** Final analysis sample
- **Description:** 1 if consent==1 AND failed_attn==0 AND distribution channel=="anonymous" AND duplicate_pid==0

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `incomplete`
- **Type:** Binary
- **Label:** Incomplete response

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `failed_attn`
- **Type:** Binary
- **Label:** Failed attention check
- **Description:** 1 if attn_check != 4419

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `pid_mismatch`
- **Type:** Binary
- **Label:** Prolific PID mismatch

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `duplicate_pid`
- **Type:** Binary
- **Label:** Duplicate Prolific PID

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `attn_check`
- **Type:** Numeric
- **Label:** Attention check value (should be 4419)

---

## Treatment Assignment

### `arm_n`
- **Type:** Categorical
- **Label:** Treatment arm (numeric)

| Code | Label |
|------|-------|
| 0 | Control |
| 1 | Industry |
| 2 | Academic |
| 3 | Personal |

### `arm`
- **Type:** String
- **Label:** Treatment arm (string)
- **Values:** "control", "industry", "academic", "personal"

### `arm_control`
- **Type:** Binary
- **Label:** Treatment: Control arm

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `arm_industry`
- **Type:** Binary
- **Label:** Treatment: Industry arm

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `arm_academic`
- **Type:** Binary
- **Label:** Treatment: Academic arm

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `arm_personal`
- **Type:** Binary
- **Label:** Treatment: Personal arm

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

---

## Prior Beliefs

### `prior_self_placebo`
- **Type:** Categorical (7-point)
- **Label:** Prior belief: SE likelihood without vaccine
- **Question:** "Imagine you do NOT get the flu vaccine. How likely do you think you would be to experience a severe adverse event?"

| Code | Label |
|------|-------|
| 1 | Would definitely not |
| 2 | Very unlikely |
| 3 | Somewhat unlikely |
| 4 | Neither likely nor unlikely |
| 5 | Somewhat likely |
| 6 | Very likely |
| 7 | Would definitely |

### `prior_self_vacc`
- **Type:** Categorical (7-point)
- **Label:** Prior belief: SE likelihood with vaccine
- **Question:** "Imagine you DO GET the flu vaccine. How likely do you think you would be to experience a severe adverse event?"

| Code | Label |
|------|-------|
| 1 | Would definitely not |
| 2 | Very unlikely |
| 3 | Somewhat unlikely |
| 4 | Neither likely nor unlikely |
| 5 | Somewhat likely |
| 6 | Very likely |
| 7 | Would definitely |

### `prior_diff`
- **Type:** Numeric (derived)
- **Label:** Prior belief difference (vacc - placebo)
- **Range:** -6 to +6

---

## Post-Trial Estimates

### `post_trial`
- **Type:** Numeric (continuous)
- **Label:** Post-trial side effect estimate (0-100)
- **Description:** Consolidated from arm-specific variables; percentage estimate of side effect rate in vaccine group

### `post_c_trial`
- **Type:** Numeric (continuous)
- **Label:** Post-trial estimate: Control arm
- **Description:** Non-missing only for Control arm participants

### `post_i_trial`
- **Type:** Numeric (continuous)
- **Label:** Post-trial estimate: Industry arm
- **Description:** Non-missing only for Industry arm participants

### `post_a_trial`
- **Type:** Numeric (continuous)
- **Label:** Post-trial estimate: Academic arm
- **Description:** Non-missing only for Academic arm participants

### `post_p_trial`
- **Type:** Numeric (continuous)
- **Label:** Post-trial estimate: Personal arm
- **Description:** Non-missing only for Personal arm participants

---

## Posterior Beliefs

### `posterior_novacc`
- **Type:** Numeric (continuous, 0-100)
- **Label:** Posterior: SE probability without vaccine
- **Question:** "After seeing the information, what do you estimate is the probability of experiencing a side effect without the vaccine?"

### `posterior_vacc`
- **Type:** Numeric (continuous, 0-100)
- **Label:** Posterior: SE probability with vaccine
- **Question:** "After seeing the information, what do you estimate is the probability of experiencing a side effect with the vaccine?"

### `delta`
- **Type:** Numeric (derived)
- **Label:** Posterior difference (vacc - novacc)
- **Description:** posterior_vacc - posterior_novacc

---

## Trust & Relevance

### `trust_trial`
- **Type:** Categorical (0-10)
- **Label:** Trust in trial information

| Code | Label |
|------|-------|
| 0 | 0 |
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 4 | 4 |
| 5 | 5 |
| 6 | 6 |
| 7 | 7 |
| 8 | 8 |
| 9 | 9 |
| 10 | 10 |

### `relevant_trial`
- **Type:** Categorical (0-10)
- **Label:** Relevance of trial information

| Code | Label |
|------|-------|
| 0 | 0 |
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 4 | 4 |
| 5 | 5 |
| 6 | 6 |
| 7 | 7 |
| 8 | 8 |
| 9 | 9 |
| 10 | 10 |

### `trust_academic`
- **Type:** Categorical (0-10)
- **Label:** Trust in academic source
- **Description:** Asked only in Academic and Personal arms

| Code | Label |
|------|-------|
| 0 | 0 |
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 4 | 4 |
| 5 | 5 |
| 6 | 6 |
| 7 | 7 |
| 8 | 8 |
| 9 | 9 |
| 10 | 10 |

### `relevant_academic`
- **Type:** Categorical (0-10)
- **Label:** Relevance of academic source
- **Description:** Asked only in Academic and Personal arms

| Code | Label |
|------|-------|
| 0 | 0 |
| 1 | 1 |
| 2 | 2 |
| 3 | 3 |
| 4 | 4 |
| 5 | 5 |
| 6 | 6 |
| 7 | 7 |
| 8 | 8 |
| 9 | 9 |
| 10 | 10 |

---

## Vaccination Intentions

### `vacc_intentions`
- **Type:** Categorical
- **Label:** Flu vaccine intentions

| Code | Label |
|------|-------|
| 1 | No, do not intend |
| 2 | May or may not |
| 3 | Intend to get |
| 4 | Already got |

### `maybe`
- **Type:** Binary (derived)
- **Label:** Intends/already got vaccine
- **Description:** 1 if vacc_intentions in {3, 4}

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

---

## Link Clicks

### `link_click`
- **Type:** Binary (derived)
- **Label:** Any link clicked
- **Description:** 1 if any of link1-4 was clicked

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `link1_clicked`
- **Type:** Binary
- **Label:** Link 1 clicked

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `link2_clicked`
- **Type:** Binary
- **Label:** Link 2 clicked

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `link3_clicked`
- **Type:** Binary
- **Label:** Link 3 clicked

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `link4_clicked`
- **Type:** Binary
- **Label:** Link 4 clicked

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

---

## Demographics

### `age`
- **Type:** Categorical
- **Label:** Age group

| Code | Label |
|------|-------|
| 1 | Under 18 |
| 2 | 18-34 |
| 3 | 35-49 |
| 4 | 50-64 |
| 5 | 65+ |
| -99 | Prefer not to say |

### `gender`
- **Type:** Categorical
- **Label:** Gender

| Code | Label |
|------|-------|
| 1 | Male |
| 2 | Female |
| 3 | Other |
| -99 | Prefer not to say |

### `education`
- **Type:** Categorical
- **Label:** Education level

| Code | Label |
|------|-------|
| 1 | Less than HS |
| 2 | HS |
| 3 | Some college |
| 4 | 4-year degree |
| 5 | More than 4-year |
| -99 | Prefer not to say |

### `income`
- **Type:** Categorical
- **Label:** Household income

| Code | Label |
|------|-------|
| 1 | <$25k |
| 2 | $25-50k |
| 3 | $50-75k |
| 4 | $75-100k |
| 5 | >$100k |
| -99 | Prefer not to say |

### `race`
- **Type:** Categorical
- **Label:** Race

| Code | Label |
|------|-------|
| 1 | White |
| 2 | Black |
| 3 | Asian |
| 4 | Am Indian/Alaska Native |
| 5 | Other |
| -99 | Prefer not to say |

### `ethnicity`
- **Type:** Categorical
- **Label:** Hispanic/Latino

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |
| -99 | Prefer not to say |

### `polviews`
- **Type:** Categorical
- **Label:** Political views

| Code | Label |
|------|-------|
| 1 | Very liberal |
| 2 | Liberal |
| 3 | Slightly liberal |
| 4 | Moderate |
| 5 | Slightly conservative |
| 6 | Conservative |
| 7 | Very conservative |

---

## Open-Ended Responses

### `debrief_about`
- **Type:** String
- **Label:** Debrief: What survey was about
- **Question:** "What do you think this survey was about?"

### `comments`
- **Type:** String
- **Label:** Final comments

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
| attn_check | Numeric | Any (4419 = correct) |
| arm_n | Categorical | 0-3 |
| arm | String | control/industry/academic/personal |
| arm_control | Binary | 0, 1 |
| arm_industry | Binary | 0, 1 |
| arm_academic | Binary | 0, 1 |
| arm_personal | Binary | 0, 1 |
| prior_self_placebo | Categorical | 1-7 |
| prior_self_vacc | Categorical | 1-7 |
| prior_diff | Continuous | -6 to +6 |
| post_trial | Continuous | 0-100 |
| post_c_trial | Continuous | 0-100 |
| post_i_trial | Continuous | 0-100 |
| post_a_trial | Continuous | 0-100 |
| post_p_trial | Continuous | 0-100 |
| posterior_novacc | Continuous | 0-100 |
| posterior_vacc | Continuous | 0-100 |
| delta | Continuous | -100 to +100 |
| trust_trial | Categorical | 0-10 |
| relevant_trial | Categorical | 0-10 |
| trust_academic | Categorical | 0-10 |
| relevant_academic | Categorical | 0-10 |
| vacc_intentions | Categorical | 1-4 |
| maybe | Binary | 0, 1 |
| link_click | Binary | 0, 1 |
| link1_clicked | Binary | 0, 1 |
| link2_clicked | Binary | 0, 1 |
| link3_clicked | Binary | 0, 1 |
| link4_clicked | Binary | 0, 1 |
| age | Categorical | 1-5, -99 |
| gender | Categorical | 1-3, -99 |
| education | Categorical | 1-5, -99 |
| income | Categorical | 1-5, -99 |
| race | Categorical | 1-5, -99 |
| ethnicity | Categorical | 0, 1, -99 |
| polviews | Categorical | 1-7 |
| debrief_about | String | Open text |
| comments | String | Open text |
