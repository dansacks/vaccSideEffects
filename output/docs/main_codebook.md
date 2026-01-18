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
- **Summary Statistics (N=3,558):**

| Statistic | Value |
|-----------|-------|
| Mean | 412.2 |
| SD | 1,056.3 |
| Min | 35 |
| Median | 317 |
| Max | 56,447 |

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

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,518 (98.88%) |
| 1 | Yes | 40 (1.12%) |

### `failed_attn`
- **Type:** Binary
- **Label:** Failed attention check
- **Description:** 1 if attn_check != 4419

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,558 (100.00%) |
| 1 | Yes | - |

### `pid_mismatch`
- **Type:** Binary
- **Label:** Prolific PID mismatch

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,556 (99.94%) |
| 1 | Yes | 2 (0.06%) |

### `duplicate_pid`
- **Type:** Binary
- **Label:** Duplicate Prolific PID

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,558 (100.00%) |
| 1 | Yes | - |

### `attn_check`
- **Type:** Numeric
- **Label:** Attention check value (should be 4419)

---

## Treatment Assignment

### `arm_n`
- **Type:** Categorical
- **Label:** Treatment arm (numeric)

| Code | Label | N (%) |
|------|-------|-------|
| 0 | Control | 890 (25.01%) |
| 1 | Industry | 890 (25.01%) |
| 2 | Academic | 887 (24.93%) |
| 3 | Personal | 891 (25.04%) |

### `arm`
- **Type:** String
- **Label:** Treatment arm (string)
- **Values:** "control", "industry", "academic", "personal"

### `arm_control`
- **Type:** Binary
- **Label:** Treatment: Control arm

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,668 (74.99%) |
| 1 | Yes | 890 (25.01%) |

### `arm_industry`
- **Type:** Binary
- **Label:** Treatment: Industry arm

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,668 (74.99%) |
| 1 | Yes | 890 (25.01%) |

### `arm_academic`
- **Type:** Binary
- **Label:** Treatment: Academic arm

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,671 (75.07%) |
| 1 | Yes | 887 (24.93%) |

### `arm_personal`
- **Type:** Binary
- **Label:** Treatment: Personal arm

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,667 (74.96%) |
| 1 | Yes | 891 (25.04%) |

---

## Prior Beliefs

### `prior_self_placebo`
- **Type:** Categorical (7-point)
- **Label:** Prior belief: SE likelihood without vaccine
- **Question:** "Imagine you do NOT get the flu vaccine. How likely do you think you would be to experience a severe adverse event?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Would definitely not | 749 (21.05%) |
| 2 | Very unlikely | 1,353 (38.03%) |
| 3 | Somewhat unlikely | 529 (14.87%) |
| 4 | Neither likely nor unlikely | 238 (6.69%) |
| 5 | Somewhat likely | 446 (12.54%) |
| 6 | Very likely | 184 (5.17%) |
| 7 | Would definitely | 59 (1.66%) |

### `prior_self_vacc`
- **Type:** Categorical (7-point)
- **Label:** Prior belief: SE likelihood with vaccine
- **Question:** "Imagine you DO GET the flu vaccine. How likely do you think you would be to experience a severe adverse event?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Would definitely not | 98 (2.75%) |
| 2 | Very unlikely | 557 (15.65%) |
| 3 | Somewhat unlikely | 619 (17.40%) |
| 4 | Neither likely nor unlikely | 371 (10.43%) |
| 5 | Somewhat likely | 1,098 (30.86%) |
| 6 | Very likely | 594 (16.69%) |
| 7 | Would definitely | 221 (6.21%) |

### `prior_diff`
- **Type:** Numeric (derived)
- **Label:** Prior belief difference (vacc - placebo)
- **Summary Statistics (N=3,558):**

| Statistic | Value |
|-----------|-------|
| Mean | 1.5 |
| SD | 2.0 |
| Min | -6 |
| Median | 1 |
| Max | 6 |
- **Range:** -6 to +6

---

## Post-Trial Estimates

### `post_trial`
- **Type:** Numeric (continuous)
- **Label:** Post-trial side effect estimate (0-100)
- **Summary Statistics (N=3,539):**

| Statistic | Value |
|-----------|-------|
| Mean | 16.1 |
| SD | 19.1 |
| Min | 0 |
| Median | 6 |
| Max | 98 |
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
- **Summary Statistics (N=3,536):**

| Statistic | Value |
|-----------|-------|
| Mean | 12.6 |
| SD | 20.3 |
| Min | 0 |
| Median | 3 |
| Max | 100 |
- **Question:** "After seeing the information, what do you estimate is the probability of experiencing a side effect without the vaccine?"

### `posterior_vacc`
- **Type:** Numeric (continuous, 0-100)
- **Label:** Posterior: SE probability with vaccine
- **Summary Statistics (N=3,530):**

| Statistic | Value |
|-----------|-------|
| Mean | 25.7 |
| SD | 28.1 |
| Min | 0 |
| Median | 10 |
| Max | 100 |
- **Question:** "After seeing the information, what do you estimate is the probability of experiencing a side effect with the vaccine?"

### `delta`
- **Type:** Numeric (derived)
- **Label:** Posterior difference (vacc - novacc)
- **Summary Statistics (N=3,530):**

| Statistic | Value |
|-----------|-------|
| Mean | 13.2 |
| SD | 26.2 |
| Min | -96 |
| Median | 3 |
| Max | 100 |
- **Description:** posterior_vacc - posterior_novacc

---

## Trust & Relevance

### `trust_trial`
- **Type:** Categorical (0-10)
- **Label:** Trust in trial information

| Code | Label | N (%) |
|------|-------|-------|
| 0 | 0 | 196 (5.56%) |
| 1 | 1 | 82 (2.33%) |
| 2 | 2 | 189 (5.36%) |
| 3 | 3 | 231 (6.55%) |
| 4 | 4 | 287 (8.14%) |
| 5 | 5 | 804 (22.81%) |
| 6 | 6 | 448 (12.71%) |
| 7 | 7 | 519 (14.72%) |
| 8 | 8 | 479 (13.59%) |
| 9 | 9 | 178 (5.05%) |
| 10 | 10 | 112 (3.18%) |

### `relevant_trial`
- **Type:** Categorical (0-10)
- **Label:** Relevance of trial information

| Code | Label | N (%) |
|------|-------|-------|
| 0 | 0 | 483 (13.70%) |
| 1 | 1 | 153 (4.34%) |
| 2 | 2 | 222 (6.30%) |
| 3 | 3 | 230 (6.52%) |
| 4 | 4 | 211 (5.99%) |
| 5 | 5 | 578 (16.40%) |
| 6 | 6 | 386 (10.95%) |
| 7 | 7 | 447 (12.68%) |
| 8 | 8 | 362 (10.27%) |
| 9 | 9 | 232 (6.58%) |
| 10 | 10 | 221 (6.27%) |

### `trust_academic`
- **Type:** Categorical (0-10)
- **Label:** Trust in academic source
- **Description:** Asked only in Academic and Personal arms

| Code | Label | N (%) |
|------|-------|-------|
| 0 | 0 | 80 (4.54%) |
| 1 | 1 | 36 (2.04%) |
| 2 | 2 | 58 (3.29%) |
| 3 | 3 | 75 (4.26%) |
| 4 | 4 | 122 (6.93%) |
| 5 | 5 | 378 (21.47%) |
| 6 | 6 | 235 (13.34%) |
| 7 | 7 | 300 (17.04%) |
| 8 | 8 | 271 (15.39%) |
| 9 | 9 | 141 (8.01%) |
| 10 | 10 | 65 (3.69%) |

### `relevant_academic`
- **Type:** Categorical (0-10)
- **Label:** Relevance of academic source
- **Description:** Asked only in Academic and Personal arms

| Code | Label | N (%) |
|------|-------|-------|
| 0 | 0 | 275 (15.62%) |
| 1 | 1 | 74 (4.20%) |
| 2 | 2 | 102 (5.79%) |
| 3 | 3 | 117 (6.64%) |
| 4 | 4 | 112 (6.36%) |
| 5 | 5 | 261 (14.82%) |
| 6 | 6 | 197 (11.19%) |
| 7 | 7 | 215 (12.21%) |
| 8 | 8 | 207 (11.75%) |
| 9 | 9 | 107 (6.08%) |
| 10 | 10 | 94 (5.34%) |

---

## Vaccination Intentions

### `vacc_intentions`
- **Type:** Categorical
- **Label:** Flu vaccine intentions

| Code | Label | N (%) |
|------|-------|-------|
| 1 | No, do not intend | 2,198 (62.41%) |
| 2 | May or may not | 1,031 (29.27%) |
| 3 | Intend to get | 225 (6.39%) |
| 4 | Already got | 67 (1.90%) |

### `maybe`
- **Type:** Binary (derived)
- **Label:** Intends/already got vaccine
- **Description:** 1 if vacc_intentions in {3, 4}

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,230 (91.71%) |
| 1 | Yes | 292 (8.29%) |

---

## Link Clicks

### `link_click`
- **Type:** Binary (derived)
- **Label:** Any link clicked
- **Description:** 1 if any of link1-4 was clicked

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,511 (98.68%) |
| 1 | Yes | 47 (1.32%) |

### `link1_clicked`
- **Type:** Binary
- **Label:** Link 1 clicked

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,535 (99.35%) |
| 1 | Yes | 23 (0.65%) |

### `link2_clicked`
- **Type:** Binary
- **Label:** Link 2 clicked

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,537 (99.41%) |
| 1 | Yes | 21 (0.59%) |

### `link3_clicked`
- **Type:** Binary
- **Label:** Link 3 clicked

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,541 (99.52%) |
| 1 | Yes | 17 (0.48%) |

### `link4_clicked`
- **Type:** Binary
- **Label:** Link 4 clicked

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,547 (99.69%) |
| 1 | Yes | 11 (0.31%) |

---

## Demographics

### `age`
- **Type:** Categorical
- **Label:** Age group

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Under 18 | - |
| 2 | 18-34 | 1,185 (33.65%) |
| 3 | 35-49 | 1,405 (39.89%) |
| 4 | 50-64 | 777 (22.06%) |
| 5 | 65+ | 147 (4.17%) |
| -99 | Prefer not to say | 1 (0.03%) |

### `gender`
- **Type:** Categorical
- **Label:** Gender

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Male | 1,530 (43.44%) |
| 2 | Female | 1,949 (55.34%) |
| 3 | Other | 32 (0.91%) |
| -99 | Prefer not to say | - |

### `education`
- **Type:** Categorical
- **Label:** Education level

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Less than HS | 19 (0.54%) |
| 2 | HS | 517 (14.68%) |
| 3 | Some college | 1,171 (33.25%) |
| 4 | 4-year degree | 1,285 (36.48%) |
| 5 | More than 4-year | 517 (14.68%) |
| -99 | Prefer not to say | - |

### `income`
- **Type:** Categorical
- **Label:** Household income

| Code | Label | N (%) |
|------|-------|-------|
| 1 | <$25k | 489 (13.88%) |
| 2 | $25-50k | 787 (22.35%) |
| 3 | $50-75k | 743 (21.10%) |
| 4 | $75-100k | 558 (15.84%) |
| 5 | >$100k | 858 (24.36%) |
| -99 | Prefer not to say | - |

### `race`
- **Type:** Categorical
- **Label:** Race

| Code | Label | N (%) |
|------|-------|-------|
| 1 | White | 2,648 (75.18%) |
| 2 | Black | 478 (13.57%) |
| 3 | Asian | 25 (0.71%) |
| 4 | Am Indian/Alaska Native | 206 (5.85%) |
| 5 | Other | 6 (0.17%) |
| -99 | Prefer not to say | - |

### `ethnicity`
- **Type:** Categorical
- **Label:** Hispanic/Latino

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | - |
| 1 | Yes | 323 (9.17%) |
| -99 | Prefer not to say | - |

### `polviews`
- **Type:** Categorical
- **Label:** Political views

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Very liberal | 331 (9.40%) |
| 2 | Liberal | 618 (17.55%) |
| 3 | Slightly liberal | 428 (12.15%) |
| 4 | Moderate | 811 (23.03%) |
| 5 | Slightly conservative | 397 (11.27%) |
| 6 | Conservative | 638 (18.11%) |
| 7 | Very conservative | 260 (7.38%) |

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
