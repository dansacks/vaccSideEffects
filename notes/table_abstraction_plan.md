# Plan: Table Generation Abstraction

## Overview

Create two reusable Stata ado-files for generating standardized LaTeX tables:
1. `balance_table` - Balance/summary tables showing means by group
2. `regression_table` - Regression results tables

Both will output .tex fragments (no `\begin{table}`, no headers, no vertical spacing) per
CLAUDE.md conventions.

## 1. balance_table Command

### Syntax
```stata
balance_table VARLIST [if], group(varname) [saving(filename) jointtest]
```

### Parameters
- `VARLIST` - Variables to include as rows (balance variables)
- `if` - Standard Stata if condition for sample restriction
- `group(varname)` - Grouping variable defining columns (e.g., treatment arm)
- `saving(filename)` - Output .tex file path (optional, default: balance_table.tex)
- `jointtest` - Include joint significance test row (optional)

### Output Format
```
varlabel & mean_g0 & mean_g1 & ... & mean_gK & pval \\
...
Joint test & \multicolumn{K}{c}{$\chi^2(df)=X.XX$} & p \\
N & n0 & n1 & ... & nK &
```

Note: No `\addlinespace` or other vertical spacing. Final row has no `\\`.

### Implementation Notes
- Auto-detect number of groups from `group()` variable
- Use variable labels for row names (fall back to varname if no label)
- F-test p-values from `regress var i.group, vce(robust)` then `testparm`
- Joint test via `suest` across all variables
- Use `marksample touse` for standard Stata if/in handling

### Key Design Decisions
1. Group variable can have any number of levels (not hardcoded to 4 arms)
2. Column order follows numeric order of group variable values
3. P-value column is always last
4. Missing values handled per Stata defaults (casewise deletion)

---

## 2. regression_table Command

### Syntax
```stata
regression_table YVARS [if], keyvars(varlist) [controls(varlist) saving(filename)]
```

### Parameters
- `YVARS` - Outcome variables (each becomes a column)
- `if` - Standard Stata if condition for sample restriction
- `keyvars(varlist)` - Variables whose coefficients to report (e.g., treatment indicators)
- `controls(varlist)` - Control variables (coefficients not reported)
- `saving(filename)` - Output .tex file path (optional, default: regression_table.tex)

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

Note: No `\addlinespace` or other vertical spacing. Final row has no `\\`.

### Implementation Notes
- Each column runs: `reg Y keyvars controls if touse, robust`
- Control mean = mean of Y where all keyvars == 0 (omitted category)
- Assumes first level of factor/indicator is omitted (control group)
- Store results in matrices, write row-by-row
- Use `marksample touse` for standard Stata if/in handling

### Key Design Decisions
1. keyvars must be simple variables (not factor notation) - user creates arm_industry etc.
2. Control mean assumes omitted category is the reference group
3. All regressions use robust standard errors
4. No R-squared row

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

### Test Case 1: balance_table - Deterministic 2 groups
```stata
clear
input group x1 x2
0 1.0 2.0
0 1.2 2.1
0 0.8 1.9
1 1.5 2.0
1 1.7 2.2
1 1.3 1.8
end
label var x1 "Variable One"
label var x2 "Variable Two"

balance_table x1 x2, group(group) saving(output/tables/test_balance_2group.tex)

* Expected output (test_balance_2group.tex):
* Variable One & 1.000 & 1.500 & 0.014 \\
* Variable Two & 2.000 & 2.000 & 1.000 \\
* N & 3 & 3 &
```

### Test Case 2: balance_table - 4 groups with joint test
```stata
clear
input arm x1 x2 x3
0 1.0 1.0 1.0
0 1.1 1.1 1.1
1 1.0 2.0 1.0
1 1.1 2.1 1.1
2 1.0 1.0 1.0
2 1.1 1.1 1.1
3 1.0 1.0 1.0
3 1.1 1.1 1.1
end
label var x1 "Balanced"
label var x2 "Imbalanced"
label var x3 "Also Balanced"

balance_table x1 x2 x3, group(arm) saving(output/tables/test_balance_4group.tex) jointtest

* Expected: x2 should have low p-value (imbalanced in arm 1)
* x1 and x3 should have p-value = 1.000 (identical across arms)
```

### Test Case 3: regression_table - Deterministic
```stata
clear
input arm_a arm_b y1 y2 x
0 0 10 5 1
0 0 10 5 1
1 0 12 6 1
1 0 12 6 1
0 1 11 4 1
0 1 11 4 1
end
label var arm_a "Treatment A"
label var arm_b "Treatment B"

regression_table y1 y2, keyvars(arm_a arm_b) controls(x) ///
    saving(output/tables/test_regression_basic.tex)

* Expected coefficients:
* y1: arm_a = 2.000, arm_b = 1.000, control mean = 10.000
* y2: arm_a = 1.000, arm_b = -1.000, control mean = 5.000
```

### Test Case 4: regression_table - With if condition
```stata
clear
input arm_a y1 insample
0 10 1
0 10 1
1 12 1
1 12 0
end
label var arm_a "Treatment A"

regression_table y1 if insample==1, keyvars(arm_a) saving(output/tables/test_regression_if.tex)

* Expected: N = 3 (one observation excluded)
* arm_a coefficient = 2.000
```

### Test Case 5: Replicate existing balance_table.do output
```stata
use "derived/merged_main_pre.dta", clear
* ... (create indicator variables as in balance_table.do)

balance_table prior_vacc_likely pre_no_intent ... college, ///
    group(arm_n) saving(output/tables/test_replicate_balance.tex) jointtest

* Compare with output/tables/balance_table.tex
```

### Test Case 6: Replicate existing treatment_effects.do output
```stata
use "derived/merged_all.dta", clear
do "code/_set_controls.do"

regression_table post_trial delta main_maybe link_click vacc_post, ///
    keyvars(arm_industry arm_academic arm_personal) ///
    controls($controls) saving(output/tables/test_replicate_treatment.tex)

* Compare with output/tables/treatment_effects.tex
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
5. **Vertical spacing**: No - no `\addlinespace` or similar commands
6. **Sample restriction**: Use standard Stata `if` syntax with `marksample touse`

## 7. Console Output

Both commands print a formatted table to the console for immediate inspection. Long lines are
truncated rather than wrapped to maintain readability. The full output is always in the .tex file.

**balance_table console output:**
```
Balance Table: group(arm_n)
------------------------------------------------------------------------------
Variable                    | Grp 0    Grp 1    Grp 2    Grp 3   P-value
----------------------------|---------------------------------------------
Prior: SE likely with vacc  |  0.551   0.541   0.533   0.529     0.794
Do not intend to vaccinate  |  0.655   0.666   0.674   0.662     0.870
...
----------------------------|---------------------------------------------
Joint test                  |         chi2(45) = 42.508           0.578
N                           |    885     885     882     886
------------------------------------------------------------------------------
Saved: output/tables/balance_table.tex
```

**regression_table console output:**
```
Regression Table
------------------------------------------------------------------------------
                            |    y1        y2        y3
----------------------------|---------------------------------------------
Industry                    |  -7.971   -3.303   -0.000
                            |  (0.853)  (1.022)  (0.012)
Academic                    |  -4.392   -2.857    0.031
                            |  (0.874)  (1.010)  (0.013)
Personal                    |  -4.728    0.387    0.024
                            |  (0.878)  (1.018)  (0.013)
----------------------------|---------------------------------------------
Control mean                |  20.193   15.410    0.069
N                           |   3,516    3,516    3,516
------------------------------------------------------------------------------
Saved: output/tables/regression_table.tex
```

## 8. Error Handling

### Missing Variables
- If a variable in VARLIST or keyvars doesn't exist: **exit with error**
- Standard Stata behavior - fail fast so user knows immediately

### Empty Groups
- If a group level has zero observations: **exit with error**
- Prevents misleading output with missing columns

### All-Missing Variable
- If a balance variable is entirely missing: **exit with error**
- User must fix data or remove variable from list

### Collinearity in Regression
- If keyvars are collinear: **warn but continue**
- Report coefficient as "." (missing) in output

### If Condition Drops All Observations
- If `if` condition results in zero obs: **exit with error**

### Invalid Group Variable
- If group variable is string: **exit with error**
- If group variable has more than 10 levels: **warn but continue**

### File Write Errors
- If saving() path is invalid or not writable: **exit with error**

### General Approach
- **Fail fast**: Check inputs at the start before any computation
- **Clear messages**: Error messages identify which variable/parameter caused the issue
- **Stata conventions**: Use standard Stata return codes where applicable
- **No silent failures**: Never produce partial or incorrect output without warning
