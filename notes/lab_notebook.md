# Lab Notebook

Development log for VaccSideEffects project.

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
