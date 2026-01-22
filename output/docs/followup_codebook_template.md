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
- **Description:** 1 if consent==1 AND failed_attn==0 AND distribution channel=="anonymous" AND duplicate_pid==0 AND is_preview==0

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
- **Description:** 1 if attn_check != 1163

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

### `is_preview`
- **Type:** Binary
- **Label:** Preview/test response

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

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

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `med_grocery`
- **Type:** Binary
- **Label:** Gets medicine: Grocery/superstore
- **Description:** Selected "Grocery store pharmacy or retail superstore pharmacy"

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `med_independent`
- **Type:** Binary
- **Label:** Gets medicine: Independent pharmacy

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `med_mail_order`
- **Type:** Binary
- **Label:** Gets medicine: Mail-order

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `med_online`
- **Type:** Binary
- **Label:** Gets medicine: Online pharmacy

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `med_provider`
- **Type:** Binary
- **Label:** Gets medicine: Healthcare provider

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `med_other`
- **Type:** Binary
- **Label:** Gets medicine: Somewhere else

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `med_none`
- **Type:** Binary
- **Label:** Gets medicine: Does not purchase

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

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

| Code | Label |
|------|-------|
| 1 | Price |
| 2 | Convenience |
| 3 | Quality/reputation |
| 4 | Pharmacist access |
| 5 | None important |

### `price_compare`
- **Type:** Categorical
- **Label:** Compared prices at pharmacies
- **Question:** "In the past month, did you compare prices at different pharmacies?"

| Code | Label |
|------|-------|
| 1 | Yes, at least once |
| 2 | No |
| 3 | Did not shop for medicines |

### `use_coupons`
- **Type:** Categorical
- **Label:** Used coupons/deals like GoodRx
- **Question:** "In the past month, did you use coupons or discount programs like GoodRx?"

| Code | Label |
|------|-------|
| 1 | Yes, at least once |
| 2 | No |
| 3 | Did not shop for medicines |

---

## Vaccination Behavior

### `got_glp1`
- **Type:** Binary
- **Label:** Got GLP-1 prescription last month
- **Question:** "In the past month, did you get a prescription for a GLP-1 medication?"
- **Coding:** 0=No, 1=Yes, missing=Prefer not to answer

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `got_flu_vacc`
- **Type:** Binary
- **Label:** Got flu vaccine last month
- **Question:** "In the past month, did you get the flu vaccine?"
- **Coding:** 0=No, 1=Yes, missing=Prefer not to answer

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `got_covid_vacc`
- **Type:** Binary
- **Label:** Got COVID vaccine last month
- **Question:** "In the past month, did you get the COVID vaccine?"
- **Coding:** 0=No, 1=Yes, missing=Prefer not to answer

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

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

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `flu_why_side_effects`
- **Type:** Binary
- **Label:** Flu why not: Worried about side effects

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `flu_why_bad_flu`
- **Type:** Binary
- **Label:** Flu why not: Worried about bad flu
- **Description:** Worried about getting a bad case of the flu from the vaccine

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `flu_why_needles`
- **Type:** Binary
- **Label:** Flu why not: Don't like needles

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `flu_why_time`
- **Type:** Binary
- **Label:** Flu why not: Time concern

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `flu_why_location`
- **Type:** Binary
- **Label:** Flu why not: Location concern
- **Description:** No convenient location

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `flu_why_cost`
- **Type:** Binary
- **Label:** Flu why not: Cost concern

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `flu_why_none`
- **Type:** Binary
- **Label:** Flu why not: None relevant

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

---

## Study Recall

### `recall_study`
- **Type:** Categorical
- **Label:** Recalls participating in main study
- **Question:** "Do you remember participating in a study about flu vaccines about a month ago?"

| Code | Label |
|------|-------|
| 1 | Yes |
| 2 | No |
| 3 | Don't remember |

### `guess_placebo`
- **Type:** Numeric (continuous)
- **Label:** Guessed placebo arm SE rate
- **Question:** "What percentage of people in the placebo group experienced side effects?"
- **Range:** 0-100 (or -99 for prefer not to answer)

### `guess_vaccine`
- **Type:** Numeric (continuous)
- **Label:** Guessed vaccine arm SE rate
- **Question:** "What percentage of people in the vaccine group experienced side effects?"
- **Range:** 0-100 (or -99 for prefer not to answer)

### `placebo_correct`
- **Type:** Binary
- **Label:** Placebo guess within 1% of 3%
- **Description:** 1 if guess_placebo is between 2% and 4%

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `vaccine_correct`
- **Type:** Binary
- **Label:** Vaccine guess within 1% of 1.3%
- **Description:** 1 if guess_vaccine is between 0.3% and 2.3%

| Code | Label |
|------|-------|
| 0 | No |
| 1 | Yes |

### `recall_manufacturer`
- **Type:** Categorical
- **Label:** Recalls manufacturer/trial info
- **Question:** "Did the study tell you about trial results from a vaccine manufacturer?"

| Code | Label |
|------|-------|
| 1 | Yes |
| 2 | No |
| 3 | Don't remember study |

### `recall_university`
- **Type:** Categorical
- **Label:** Recalls university research info
- **Question:** "Did the study tell you about research from a university?"

| Code | Label |
|------|-------|
| 1 | Yes |
| 2 | No |
| 3 | Don't remember study |

### `recall_gavi`
- **Type:** Categorical
- **Label:** Recalls Gavi info
- **Question:** "Did the study tell you about Gavi, the Vaccine Alliance?"

| Code | Label |
|------|-------|
| 1 | Yes |
| 2 | No |
| 3 | Don't remember study |

### `found_trustworthy`
- **Type:** Categorical
- **Label:** Found study info trustworthy
- **Question:** "How trustworthy did you find the information in that study?"

| Code | Label |
|------|-------|
| 1 | Don't remember study |
| 2 | Trustworthy |
| 3 | Somewhat trustworthy |
| 4 | Not trustworthy |

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
