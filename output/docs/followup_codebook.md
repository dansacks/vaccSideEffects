# Follow-up Survey Codebook

**Dataset:** `data/followup_clean.dta`
**Source:** `data/flu_vacc_se_followup_January+8,+2026_18.39.xml`
**Analysis Sample:** `final_sample == 1` (consented + passed attention check + anonymous channel + no duplicate + not preview)

---

## Overview

This codebook documents all variables in the cleaned follow-up survey dataset. The follow-up survey was administered approximately one month after the main survey to assess actual vaccination behavior, recall of study information, and pharmacy shopping patterns.

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
- **Summary Statistics (N=3,078):**

| Statistic | Value |
|-----------|-------|
| Mean | 385.4 |
| SD | 3,403.1 |
| Min | 11 |
| Median | 233 |
| Max | 176,003 |

### `progress`
- **Type:** Numeric (continuous)
- **Label:** Survey progress (%)

---

## Quality Flags

### `consent`
- **Type:** Binary
- **Label:** Consent given

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | - |
| 1 | Yes | 3,078 (100.00%) |

### `final_sample`
- **Type:** Binary
- **Label:** Final analysis sample
- **Description:** 1 if consent==1 AND failed_attn==0 AND distribution channel=="anonymous" AND duplicate_pid==0 AND is_preview==0

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `incomplete`
- **Type:** Binary
- **Label:** Incomplete response

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,042 (98.83%) |
| 1 | Yes | 36 (1.17%) |

### `failed_attn`
- **Type:** Binary
- **Label:** Failed attention check
- **Description:** 1 if attn_check != 1163

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,078 (100.00%) |
| 1 | Yes | - |

### `pid_mismatch`
- **Type:** Binary
- **Label:** Prolific PID mismatch

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,054 (99.22%) |
| 1 | Yes | 24 (0.78%) |

### `duplicate_pid`
- **Type:** Binary
- **Label:** Duplicate Prolific PID

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,062 (99.48%) |
| 1 | Yes | 16 (0.52%) |

### `is_preview`
- **Type:** Binary
- **Label:** Preview/test response

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 3,078 (100.00%) |
| 1 | Yes | - |

### `attn_check`
- **Type:** Numeric
- **Label:** Attention check value (should be 1163)

---

## Pharmacy & Medicine Shopping

### `where_medicine`
- **Type:** String (multi-select)
- **Label:** Where get medicine (raw)
- **Question:** "Where do you usually get your prescription medicines?"

### `med_pharmacy_chain`
- **Type:** Binary
- **Label:** Gets medicine: Pharmacy chain
- **Description:** Selected "Pharmacy chain (CVS, Walgreens, Rite Aid, etc.)"

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 2,101 (68.26%) |

### `med_grocery`
- **Type:** Binary
- **Label:** Gets medicine: Grocery/superstore
- **Description:** Selected "Grocery store pharmacy or retail superstore pharmacy"

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 1,208 (39.25%) |

### `med_independent`
- **Type:** Binary
- **Label:** Gets medicine: Independent pharmacy

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 397 (12.90%) |

### `med_mail_order`
- **Type:** Binary
- **Label:** Gets medicine: Mail-order

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 279 (9.06%) |

### `med_online`
- **Type:** Binary
- **Label:** Gets medicine: Online pharmacy

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 228 (7.41%) |

### `med_provider`
- **Type:** Binary
- **Label:** Gets medicine: Healthcare provider

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 712 (23.13%) |

### `med_other`
- **Type:** Binary
- **Label:** Gets medicine: Somewhere else

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 16 (0.52%) |

### `med_none`
- **Type:** Binary
- **Label:** Gets medicine: Does not purchase

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 33 (1.07%) |
| 1 | Yes | 111 (3.61%) |

### `pharmacy_chain`
- **Type:** String (multi-select)
- **Label:** Pharmacy chains used (raw)

### `pharmacy_grocery`
- **Type:** String (multi-select)
- **Label:** Grocery pharmacies used (raw)

### `pharmacy_online`
- **Type:** String (multi-select)
- **Label:** Online pharmacies used (raw)

### `pharmacy_factor`
- **Type:** Categorical
- **Label:** Most important factor for pharmacy choice
- **Question:** "When choosing a pharmacy, which of the following is most important to you?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Price | 928 (31.68%) |
| 2 | Convenience | 1,578 (53.88%) |
| 3 | Quality/reputation | 341 (11.64%) |
| 4 | Pharmacist access | 54 (1.84%) |
| 5 | None important | 28 (0.96%) |

### `price_compare`
- **Type:** Categorical
- **Label:** Compared prices at pharmacies
- **Question:** "In the past month, did you compare prices at different pharmacies?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Yes, at least once | 623 (20.53%) |
| 2 | No | 1,698 (55.95%) |
| 3 | Did not shop for medicines | 714 (23.53%) |

### `use_coupons`
- **Type:** Categorical
- **Label:** Used coupons/deals like GoodRx
- **Question:** "In the past month, did you use coupons or discount programs like GoodRx?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Yes, at least once | 607 (20.00%) |
| 2 | No | 1,736 (57.20%) |
| 3 | Did not shop for medicines | 692 (22.80%) |

---

## Vaccination Behavior

### `got_glp1`
- **Type:** Binary
- **Label:** Got GLP-1 prescription last month
- **Question:** "In the past month, did you get a prescription for a GLP-1 medication?"
- **Coding:** 0=No, 1=Yes, missing=Prefer not to answer

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,827 (93.64%) |
| 1 | Yes | 192 (6.36%) |

### `got_flu_vacc`
- **Type:** Binary
- **Label:** Got flu vaccine last month
- **Question:** "In the past month, did you get the flu vaccine?"
- **Coding:** 0=No, 1=Yes, missing=Prefer not to answer

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,836 (94.03%) |
| 1 | Yes | 180 (5.97%) |

### `got_covid_vacc`
- **Type:** Binary
- **Label:** Got COVID vaccine last month
- **Question:** "In the past month, did you get the COVID vaccine?"
- **Coding:** 0=No, 1=Yes, missing=Prefer not to answer

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,968 (98.34%) |
| 1 | Yes | 50 (1.66%) |

---

## Reasons for Not Getting Flu Vaccine

These variables are parsed from the multi-select question asked of those who did not get the flu vaccine.

### `flu_why_not`
- **Type:** String (multi-select)
- **Label:** Why no flu vaccine (raw)

### `flu_why_not_do`
- **Type:** String
- **Label:** Why no flu vaccine display order

### `flu_why_already`
- **Type:** Binary
- **Label:** Flu why not: Already got earlier
- **Description:** Already got flu shot earlier this season

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 95 (3.09%) |

### `flu_why_side_effects`
- **Type:** Binary
- **Label:** Flu why not: Worried about side effects

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 1,164 (37.82%) |

### `flu_why_bad_flu`
- **Type:** Binary
- **Label:** Flu why not: Worried about bad flu
- **Description:** Worried about getting a bad case of the flu from the vaccine

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 323 (10.49%) |

### `flu_why_needles`
- **Type:** Binary
- **Label:** Flu why not: Don't like needles

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 462 (15.01%) |

### `flu_why_time`
- **Type:** Binary
- **Label:** Flu why not: Time concern

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 175 (5.69%) |

### `flu_why_location`
- **Type:** Binary
- **Label:** Flu why not: Location concern
- **Description:** No convenient location

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 104 (3.38%) |

### `flu_why_cost`
- **Type:** Binary
- **Label:** Flu why not: Cost concern

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 196 (6.37%) |

### `flu_why_none`
- **Type:** Binary
- **Label:** Flu why not: None relevant

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 246 (7.99%) |
| 1 | Yes | 1,105 (35.90%) |

---

## Study Recall

### `recall_study`
- **Type:** Categorical
- **Label:** Recalls participating in main study
- **Question:** "Do you remember participating in a study about flu vaccines about a month ago?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Yes | 764 (25.24%) |
| 2 | No | 483 (15.96%) |
| 3 | Don't remember | 1,780 (58.80%) |

### `guess_placebo`
- **Type:** Numeric (continuous)
- **Label:** Guessed placebo arm SE rate
- **Summary Statistics (N=3,016):**

| Statistic | Value |
|-----------|-------|
| Mean | 16.3 |
| SD | 17.1 |
| Min | 0 |
| Median | 10 |
| Max | 100 |
- **Question:** "What percentage of people in the placebo group experienced side effects?"
- **Range:** 0-100 (or -99 for prefer not to answer)

### `guess_vaccine`
- **Type:** Numeric (continuous)
- **Label:** Guessed vaccine arm SE rate
- **Summary Statistics (N=3,019):**

| Statistic | Value |
|-----------|-------|
| Mean | 14.1 |
| SD | 17.3 |
| Min | -99 |
| Median | 7 |
| Max | 100 |
- **Question:** "What percentage of people in the vaccine group experienced side effects?"
- **Range:** 0-100 (or -99 for prefer not to answer)

### `placebo_correct`
- **Type:** Binary
- **Label:** Placebo guess within 1% of 3%
- **Description:** 1 if guess_placebo is between 2% and 4%

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,429 (78.91%) |
| 1 | Yes | 649 (21.09%) |

### `vaccine_correct`
- **Type:** Binary
- **Label:** Vaccine guess within 1% of 1.3%
- **Description:** 1 if guess_vaccine is between 0.3% and 2.3%

| Code | Label | N (%) |
|------|-------|-------|
| 0 | No | 2,702 (87.78%) |
| 1 | Yes | 376 (12.22%) |

### `recall_manufacturer`
- **Type:** Categorical
- **Label:** Recalls manufacturer/trial info
- **Question:** "Did the study tell you about trial results from a vaccine manufacturer?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Yes | 973 (38.38%) |
| 2 | No | 648 (25.56%) |
| 3 | Don't remember study | 914 (36.06%) |

### `recall_university`
- **Type:** Categorical
- **Label:** Recalls university research info
- **Question:** "Did the study tell you about research from a university?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Yes | 1,287 (50.77%) |
| 2 | No | 340 (13.41%) |
| 3 | Don't remember study | 908 (35.82%) |

### `recall_gavi`
- **Type:** Categorical
- **Label:** Recalls Gavi info
- **Question:** "Did the study tell you about Gavi, the Vaccine Alliance?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Yes | 274 (10.81%) |
| 2 | No | 1,141 (45.01%) |
| 3 | Don't remember study | 1,120 (44.18%) |

### `found_trustworthy`
- **Type:** Categorical
- **Label:** Found study info trustworthy
- **Question:** "How trustworthy did you find the information in that study?"

| Code | Label | N (%) |
|------|-------|-------|
| 1 | Don't remember study | 856 (33.77%) |
| 2 | Trustworthy | 585 (23.08%) |
| 3 | Somewhat trustworthy | 951 (37.51%) |
| 4 | Not trustworthy | 143 (5.64%) |

---

## Open-Ended Responses

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
| is_preview | Binary | 0, 1 |
| attn_check | Numeric | Any (1163 = correct) |
| where_medicine | String | Multi-select |
| med_pharmacy_chain | Binary | 0, 1 |
| med_grocery | Binary | 0, 1 |
| med_independent | Binary | 0, 1 |
| med_mail_order | Binary | 0, 1 |
| med_online | Binary | 0, 1 |
| med_provider | Binary | 0, 1 |
| med_other | Binary | 0, 1 |
| med_none | Binary | 0, 1 |
| pharmacy_chain | String | Multi-select |
| pharmacy_grocery | String | Multi-select |
| pharmacy_online | String | Multi-select |
| pharmacy_factor | Categorical | 1-5 |
| price_compare | Categorical | 1-3 |
| use_coupons | Categorical | 1-3 |
| got_glp1 | Binary | 0, 1, . |
| got_flu_vacc | Binary | 0, 1, . |
| got_covid_vacc | Binary | 0, 1, . |
| flu_why_not | String | Multi-select |
| flu_why_not_do | String | Display order |
| flu_why_already | Binary | 0, 1 |
| flu_why_side_effects | Binary | 0, 1 |
| flu_why_bad_flu | Binary | 0, 1 |
| flu_why_needles | Binary | 0, 1 |
| flu_why_time | Binary | 0, 1 |
| flu_why_location | Binary | 0, 1 |
| flu_why_cost | Binary | 0, 1 |
| flu_why_none | Binary | 0, 1 |
| recall_study | Categorical | 1-3 |
| guess_placebo | Continuous | 0-100, -99 |
| guess_vaccine | Continuous | 0-100, -99 |
| placebo_correct | Binary | 0, 1 |
| vaccine_correct | Binary | 0, 1 |
| recall_manufacturer | Categorical | 1-3 |
| recall_university | Categorical | 1-3 |
| recall_gavi | Categorical | 1-3 |
| found_trustworthy | Categorical | 1-4 |
| comments | String | Open text |
