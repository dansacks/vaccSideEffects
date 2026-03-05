# Lab Notebook

Development log for VaccSideEffects project.

---

## 2026-03-05: HTE by Flu Experience, Balance Table Updates, PCA + Lasso HTE

### New file: `code/hte_flu_vacc_experience.do`
- 4-column table for `delta` only, stratified by `flu_vacc_reaction` (0=No vaccine, 1=No reaction, 2=Mild, 3=Severe)
- Outputs: `output/tables/het_flu_vacc_experience.tex` and `.md`
- Makefile target: `hte-flu-vacc`

### `code/balance_table.do` changes
- Relabeled `prior_vacc_likely`: "Adverse event at least likely if vaccinate"
- Added `age_50_64` = (age == 4), appears after `age_35_49` in all relevant tables
- Rearranged main table: `trust_govt_high follow_doc_high` now appear before demographic rows
- Renamed "Personal" → "Representative" in all three `labels(...)` calls
- `balance_table_slides_demo.tex` updated to include `age_50_64`

### New file: `code/pca_lasso_hte.do`
Three sections:
1. **PCA** on `trust_trial` and `relevant_trial` (main sample) → `pca1` scores + `output/tables/pca_quality.tex`
2. **Lasso** (CV, 10-fold, seed=12345) on control group to predict `pca1` from `$controls` plus info source frequency/reliability predictors. Structural missingness in `reliable_*` recoded to 0 "N/A". Post-lasso OLS → `output/tables/lasso_predictors.tex`. Predicted `pca1_hat` applied to full sample.
3. **HTE regressions** of `delta` and `main_intent` on treatment × pca1_hat interactions → `output/tables/hte_pca.tex` and 2-panel line plot → `output/figures/hte_pca.png`

### Makefile
- Added `hte-forest`, `hte-flu-vacc`, `pca-lasso-hte` targets and `.PHONY` entries

---

## 2026-03-04: HTE Forest Plot

**Goal:** Add a single-panel forest plot for HTE on `delta`, stacking all 8 subgroups × 3 arms (24 points) vertically.

### Changes Made

**New file:** `code/plot_hte_forest.do`
- Generates `output/figures/hte_forest.png`
- 8 subgroups from 3 sections: Prior belief (Low/High), Flu vacc experience (No vaccine/No reaction/Mild/Severe), Univ. reliable (Not reliable ≤2 / Reliable =3)
- Each subgroup runs `regress delta arm_industry arm_academic arm_personal $controls if <filter>, robust`
- Y positions computed programmatically (1-unit arm spacing, 0.5-unit extra gap between subgroups, 1.5-unit extra gap between sections)
- Subgroup labels on y-axis at academic (middle) row position
- Horizontal dividers between sections via `yline(7.75 22.75)`
- Colors/shapes match `plot_hte.do` (blue circle=Industry, orange diamond=Academic, green square=Personal)
- Export: 1750×2000 px

**Makefile:**
- Added `hte-forest` target and `HTE_FOREST` variable
- Added to `.PHONY` and help text

### Usage
```bash
make hte-forest
# or interactively:
do "code/plot_hte_forest.do"
```

---

## 2026-01-31: Appendix slides with HTE tables and navigation

**Goal:** Add an appendix section to slides with navigable HTE tables and a new HTE split by university info reliability.

### Changes Made

**`code/heterogeneous_treatment_effects.do`:**
- Added `reliable_uni` split: `reliable_university == 3` (Yes reliable) vs not
- Added to foreach loop, labels (row="Uni reliable", 0="No", 1="Yes")
- Generates `het_reliable_uni.tex` and `het_reliable_uni.md`

**`slides/qslides.qmd`:**
- Added slide IDs to treatment effects (`#te-slide`) and HTE polviews (`#het-polviews-slide`) slides
- Added "Appendix →" navigation buttons on those slides
- Added appendix section with TOC slide linking back to main slides
- Appendix includes: CDF by arm, HTE by prior, experience, trust, relevance, uni reliability
- Each appendix slide has "← Appendix" back button

**`slides/style.css`:**
- Added `.button` class for navigation links (gray background, small font, rounded)

### Next Steps
- Run `heterogeneous_treatment_effects.do` to generate `het_reliable_uni.md`
- Render slides with `quarto render slides/qslides.qmd`

---

## 2026-01-28: HTE Coefficient Plot

**Goal:** Create a 2×4 faceted coefficient plot visualizing heterogeneous treatment effects.

### Changes Made

**New file:** `code/plot_hte.do`
- Generates `output/figures/hte_coefplot.png`
- Uses `postfile` to collect regression coefficients from subgroup analyses
- 2 rows (Delta, Vacc Intent) × 4 columns (Prior, Experience, Trust, Relevance)
- 3 treatment arms per panel (Industry=blue, Academic=orange, Personal=green)
- Circle markers for Low subgroup, square markers for High subgroup
- 95% CIs shown as horizontal error bars
- Legend in bottom-right panel

**Makefile:**
- Added `hte-plot` target
- Added to `.PHONY` and help text

**analyze.do:**
- Added `do "code/plot_hte.do"` after HTE regressions

### Usage
```bash
make hte-plot
# or interactively:
do "code/plot_hte.do"
```

### Slide styling (`slides/style.css`)

Added CSS classes for slide formatting:
- `.center-large`: Vertically centered large text for statement slides
- `.hyp`: Hypothesis text styling (block display, indented, italic gray)

Updated `qslides.qmd` to use these classes for the opening statement and research questions slides.

---

## 2026-01-20: Stata Code Refactoring

**Goal:** Reduce duplication and improve maintainability of Stata do-files.

### Changes Made

**New include files** (`code/include/`):
- `_rename_qualtrics_metadata.do` - shared Qualtrics field renames
- `_define_value_labels.do` - all common label definitions
- `_create_quality_flags.do` - parameterized quality flag generation
- `_report_sample_quality.do` - standardized quality reporting

**Constants added** to `_config.do`:
- `$ATTN_CHECK_PRESCREEN`, `$ATTN_CHECK_MAIN`, `$ATTN_CHECK_FOLLOWUP`
- `$PREF_NOT_SAY` (-99)

**Dead code removed:**
- `quality_sample` variable (was duplicate of `final_sample`)
- No-op renames in `clean_main.do`

**Balance table refactored:**
- Created `calc_balance_stats` program to eliminate duplicate loops
- Single pass for CSV + LaTeX output

**Comprehensive balance tables** (`balance_tables_full.do`):
- Created domain-specific tables: prior beliefs, vaccination intent/experience, demographics, trust, health conditions
- Omnibus test (all domains): slight imbalance detected
- Omnibus test (excluding demographics): no imbalance
- **Note:** Demographics are collected *after* randomization, so excluding them from balance checks may be appropriate

**Infrastructure:**
- Makefile updated with include file dependencies
- Fixed `PYTHON` -> `python3`

### Verification
- `make clean-data && make all` completes successfully
- Balance table output verified correct

---
