# Plan: Table Generation Abstraction

## Overview

Create two reusable Stata ado-files for generating standardized LaTeX tables:
1. `balance_table` - Balance/summary tables showing means by group
2. `regression_table` - Regression results tables

Both will output .tex fragments (no `\begin{table}`, no headers) per CLAUDE.md conventions.

## 1. balance_table Command

### Syntax
```stata
balance_table VARLIST, group(varname) [saving(filename) jointtest]
```

### Parameters
- `VARLIST` - Variables to include as rows (balance variables)
- `group(varname)` - Grouping variable defining columns (e.g., treatment arm)
- `saving(filename)` - Output .tex file path (optional, default: balance_table.tex)
- `jointtest` - Include joint significance test row (optional)

### Output Format
```
varlabel & mean_g0 & mean_g1 & ... & mean_gK & pval \\
...
\addlinespace
Joint test & \multicolumn{K}{c}{$\chi^2(df)=X.XX$} & p \\
\addlinespace
N & n0 & n1 & ... & nK &
```

### Implementation Notes
- Auto-detect number of groups from `group()` variable
- Use variable labels for row names (fall back to varname if no label)
- F-test p-values from `regress var i.group, vce(robust)` then `testparm`
- Joint test via `suest` across all variables
- Final row has no `\\` per CLAUDE.md

### Key Design Decisions
1. Group variable can have any number of levels (not hardcoded to 4 arms)
2. Column order follows numeric order of group variable values
3. P-value column is always last
4. Missing values handled per Stata defaults (casewise deletion)

---

## 2. regression_table Command

### Syntax
```stata
regression_table YVARS, keyvars(varlist) [controls(varlist) saving(filename) sample(varname)]
```

### Parameters
- `YVARS` - Outcome variables (each becomes a column)
- `keyvars(varlist)` - Variables whose coefficients to report (e.g., treatment indicators)
- `controls(varlist)` - Control variables (coefficients not reported)
- `saving(filename)` - Output .tex file path (optional, default: regression_table.tex)
- `sample(varname)` - Restrict sample to observations where varname==1

### Output Format
```
keyvar1_label  & coef_y1 & coef_y2 & ... \\
               & (se_y1) & (se_y2) & ... \\
keyvar2_label  & coef_y1 & coef_y2 & ... \\
               & (se_y1) & (se_y2) & ... \\
...
Control mean   & mean_y1 & mean_y2 & ... \\
N              & n_y1    & n_y2    & ...
```

### Implementation Notes
- Each column runs: `reg Y keyvars controls, robust`
- Control mean = mean of Y where all keyvars == 0 (omitted category)
- Assumes first level of factor/indicator is omitted (control group)
- Store results in matrices, write row-by-row
- Final row has no `\\` per CLAUDE.md

### Key Design Decisions
1. keyvars must be simple variables (not factor notation) - user creates arm_industry etc.
2. Control mean assumes omitted category is the reference group
3. All regressions use robust standard errors
4. No R-squared row by default (can add option later)

---

## 3. File Structure

```
code/
├── ado/
│   ├── balance_table.ado      # Balance table command
│   └── regression_table.ado   # Regression table command
├── test_balance_table.do      # Test cases for balance_table
└── test_regression_table.do   # Test cases for regression_table
```

Add to `_config.do`:
```stata
adopath + "$projdir/code/ado"
```

---

## 4. Test Cases

### Test Case 1: balance_table - Basic (2 groups)
```stata
* Create test data
clear
set seed 12345
set obs 200
gen group = runiform() > 0.5
gen x1 = rnormal(0, 1) + 0.1*group
gen x2 = rnormal(0.5, 1)
label var x1 "Outcome 1"
label var x2 "Outcome 2"

* Run balance table
balance_table x1 x2, group(group) saving(test_balance_2group.tex)

* Expected: 2 columns (group 0, group 1) + p-value column
* x1 should show ~0.1 difference, x2 should show ~0 difference
```

### Test Case 2: balance_table - 4 groups with joint test
```stata
* Create test data mimicking treatment arms
clear
set seed 12345
set obs 400
gen arm = floor(runiform() * 4)
gen x1 = rnormal(0, 1)
gen x2 = rnormal(0, 1) + 0.3*(arm==1)  // Industry effect
gen x3 = rnormal(0, 1)
label var x1 "Balanced var"
label var x2 "Imbalanced var"
label var x3 "Another balanced var"

balance_table x1 x2 x3, group(arm) saving(test_balance_4group.tex) jointtest

* Expected: x2 should have low p-value, x1 and x3 should have high p-values
* Joint test should detect imbalance
```

### Test Case 3: regression_table - Basic
```stata
* Create test data
clear
set seed 12345
set obs 500
gen arm_ind = runiform() > 0.75
gen arm_acad = runiform() > 0.75 & arm_ind==0
gen arm_pers = runiform() > 0.75 & arm_ind==0 & arm_acad==0
gen control = arm_ind==0 & arm_acad==0 & arm_pers==0
gen x = rnormal()
gen y1 = 10 + 2*arm_ind + 1*arm_acad + 0.5*arm_pers + x + rnormal()
gen y2 = 5 + 1*arm_ind - 0.5*arm_acad + 0*arm_pers + 0.5*x + rnormal()
label var arm_ind "Industry"
label var arm_acad "Academic"
label var arm_pers "Personal"

regression_table y1 y2, keyvars(arm_ind arm_acad arm_pers) controls(x) ///
    saving(test_regression.tex)

* Expected:
* - y1 column: Industry~2, Academic~1, Personal~0.5, Control mean~10
* - y2 column: Industry~1, Academic~-0.5, Personal~0, Control mean~5
```

### Test Case 4: regression_table - With sample restriction
```stata
* Using test data from Test Case 3
gen followup = runiform() > 0.3

regression_table y1, keyvars(arm_ind arm_acad arm_pers) controls(x) ///
    sample(followup) saving(test_regression_sample.tex)

* Expected: N should be ~70% of full sample
```

### Test Case 5: Replicate existing balance_table.do output
```stata
* Load actual project data
use "derived/merged_main_pre.dta", clear

* Create same indicator variables as balance_table.do
* ... (variable creation code)

* Run new command
balance_table prior_vacc_likely pre_no_intent ... college, ///
    group(arm_n) saving(test_replicate_balance.tex) jointtest

* Compare output to existing output/tables/balance_table.tex
* Should match within floating point precision
```

### Test Case 6: Replicate existing treatment_effects.do output
```stata
* Load actual project data
use "derived/merged_all.dta", clear
do "code/_set_controls.do"

* Run new command
regression_table post_trial delta main_maybe link_click vacc_post, ///
    keyvars(arm_industry arm_academic arm_personal) ///
    controls($controls) saving(test_replicate_treatment.tex)

* Compare output to existing output/tables/treatment_effects.tex
* Should match within floating point precision
```

---

## 5. Implementation Order

1. Create `code/ado/` directory
2. Implement `balance_table.ado` with basic functionality
3. Run Test Cases 1-2, verify output
4. Implement `regression_table.ado` with basic functionality
5. Run Test Cases 3-4, verify output
6. Run Test Cases 5-6 to validate against existing outputs
7. Refactor existing do-files to use new commands (optional, after validation)

---

## 6. Design Decisions (Resolved)

1. **R-squared row**: No - not included
2. **Star significance**: No - not included
3. **CSV output**: No - .tex only
4. **Column headers**: No - user defines headers in the main .tex document

## 7. Console Output

Both commands print a formatted table to the console for immediate inspection. This mirrors the
.tex output but uses plain text formatting:

**balance_table console output:**
```
Balance Table: group(arm_n)
--------------------------------------------------------------------------------
Variable                    | Control  Industry  Academic  Personal   P-value
----------------------------|-------------------------------------------------------
Prior: SE likely with vacc  |   0.551     0.541     0.533     0.529     0.794
Do not intend to vaccinate  |   0.655     0.666     0.674     0.662     0.870
...
----------------------------|-------------------------------------------------------
Joint test                  |            chi2(45) = 42.508              0.578
N                           |     885       885       882       886
--------------------------------------------------------------------------------
Saved: output/tables/balance_table.tex
```

**regression_table console output:**
```
Regression Table
--------------------------------------------------------------------------------
                            |    y1        y2        y3
----------------------------|-------------------------------------------
Industry                    |   -7.971    -3.303    -0.000
                            |   (0.853)   (1.022)   (0.012)
Academic                    |   -4.392    -2.857     0.031
                            |   (0.874)   (1.010)   (0.013)
Personal                    |   -4.728     0.387     0.024
                            |   (0.878)   (1.018)   (0.013)
----------------------------|-------------------------------------------
Control mean                |   20.193    15.410     0.069
N                           |    3,516     3,516     3,516
--------------------------------------------------------------------------------
Saved: output/tables/regression_table.tex
```

## 8. Error Handling

### Missing Variables
- If a variable in VARLIST or keyvars doesn't exist: **exit with error**
  ```
  variable xyz not found
  r(111);
  ```
- Standard Stata behavior - fail fast so user knows immediately

### Empty Groups
- If a group level has zero observations: **exit with error**
  ```
  no observations for group == 2
  r(2000);
  ```
- Prevents misleading output with missing columns

### All-Missing Variable
- If a balance variable is entirely missing: **exit with error**
  ```
  variable xyz has no non-missing observations
  r(2000);
  ```
- User must fix data or remove variable from list

### Collinearity in Regression
- If keyvars are collinear: **warn but continue**
  ```
  warning: arm_personal omitted due to collinearity
  ```
- Report coefficient as "." (missing) in output
- This can happen legitimately (e.g., if sample restriction drops a group)

### Sample Restriction Drops All Observations
- If `sample()` restriction results in zero obs: **exit with error**
  ```
  no observations after sample restriction
  r(2000);
  ```

### Invalid Group Variable
- If group variable is string: **exit with error**
  ```
  group() variable must be numeric
  r(109);
  ```
- If group variable has more than 10 levels: **warn but continue**
  ```
  warning: group variable has 15 levels - table may be very wide
  ```

### File Write Errors
- If saving() path is invalid or not writable: **exit with error**
  ```
  cannot write to file: /invalid/path/table.tex
  r(603);
  ```

### General Approach
- **Fail fast**: Check inputs at the start before any computation
- **Clear messages**: Error messages identify which variable/parameter caused the issue
- **Stata conventions**: Use standard Stata return codes where applicable
- **No silent failures**: Never produce partial or incorrect output without warning
