/*==============================================================================
    PCA + Lasso + HTE by Predicted Trust/Relevance Index

    Input:  derived/merged_all.dta
    Outputs:
      output/tables/pca_quality.tex      - PCA eigenvalues and loadings
      output/tables/lasso_predictors.tex - Post-lasso OLS coefficients
      output/tables/hte_pca.tex          - HTE regressions with pca1_hat interactions
      output/figures/hte_pca.png         - 2-panel plot with 95% CI bands

    Section 3a: PCA on trust_trial and relevant_trial
    Section 3b: Lasso to predict pca1 from pre-experiment variables
    Section 3c: HTE estimation (regressions + table)
    Section 3d: Plot using lincom for correct 95% CIs

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "pca_lasso_hte"
do "code/_config.do"
do "code/_set_controls.do"

/*==============================================================================
    Section 3a: PCA on trust_trial and relevant_trial
==============================================================================*/

use "derived/merged_all.dta", clear

/*------------------------------------------------------------------------------
    3a.1 Compute PCA on main sample
------------------------------------------------------------------------------*/

pca trust_trial relevant_trial if main_sample == 1

* Extract PC1 scores for all obs (applies loadings to full dataset)
predict pca1 if main_sample == 1, score

/*------------------------------------------------------------------------------
    3a.2 Build PCA quality table manually
------------------------------------------------------------------------------*/

* Retrieve eigenvalues and loadings from stored matrices
matrix Ev = e(Ev)
matrix L  = e(L)

local ev1 = Ev[1, 1]
local ev2 = Ev[1, 2]
local tot = `ev1' + `ev2'
local pv1 = `ev1' / `tot'
local pv2 = `ev2' / `tot'
local cv1 = `pv1'
local cv2 = `pv1' + `pv2'

* Loadings for PC1: rows = variables (trust_trial, relevant_trial), col 1
local load_trust = L[1, 1]
local load_rel   = L[2, 1]

file open _pca using "output/tables/pca_quality.tex", write replace
file write _pca "Component & Eigenvalue & Prop. var. & Cum. var. \\" _n
file write _pca "\midrule" _n
file write _pca "1 & " %6.3f (`ev1') " & " %6.3f (`pv1') " & " %6.3f (`cv1') " \\" _n
file write _pca "2 & " %6.3f (`ev2') " & " %6.3f (`pv2') " & " %6.3f (`cv2') " \\" _n
file write _pca "\midrule" _n
file write _pca "Loadings (Component 1) & & & \\" _n
file write _pca "Trust in trial & " %6.3f (`load_trust') " & & \\" _n
file write _pca "Relevance of trial & " %6.3f (`load_rel') " & &"
file close _pca

di as text "Saved: output/tables/pca_quality.tex"

/*==============================================================================
    Section 3b: Lasso to predict pca1 from pre-experiment variables
==============================================================================*/

/*------------------------------------------------------------------------------
    3b.1 Recode reliable_* for non-users (structural missingness)
         Missing means respondent never uses that source → code as 0 "N/A"
         reliable_university is asked of all respondents, so no imputation needed.
------------------------------------------------------------------------------*/

foreach src in doctor sm podcasts cdc news {
    replace reliable_`src' = 0 if missing(reliable_`src') & !missing(info_`src')
    assert !missing(reliable_`src') if !missing(info_`src')
    label define rel_`src'_lbl 0 "N/A" 1 "Not reliable" 2 "Somewhat" 3 "Yes", replace
    label values reliable_`src' rel_`src'_lbl
}

/*------------------------------------------------------------------------------
    3b.2 Recode info_* and follow_doctor: -1 means "No [source]" (a valid
         category) but Stata's i. factor notation requires non-negative values.
         Remap -1 → 0 so 0 = "No [source]" serves as the base dummy category.
------------------------------------------------------------------------------*/

foreach v in info_doctor info_sm info_podcasts info_cdc info_news info_university follow_doctor {
    replace `v' = 0 if `v' == -1
}

/*------------------------------------------------------------------------------
    3b.3 Define additional predictors and expand variable list
------------------------------------------------------------------------------*/

global lasso_extra "i.info_doctor i.info_sm i.info_podcasts i.info_cdc i.info_news"
global lasso_extra "$lasso_extra i.info_university i.reliable_doctor i.reliable_sm i.reliable_podcasts"
global lasso_extra "$lasso_extra i.reliable_cdc i.reliable_news i.reliable_university i.follow_doctor has_insurance"

* Expand factor notation to get full variable list (handles cond_* wildcard too)
fvexpand $controls $lasso_extra
local all_preds `r(varlist)'

/*------------------------------------------------------------------------------
    3b.4 Lasso: CV selection in control group (primary)
         rseed ensures reproducibility across runs.
------------------------------------------------------------------------------*/

lasso linear pca1 `all_preds' if arm_n == 0 & main_sample == 1, ///
    rseed(12345) selection(cv, folds(10))
di "CV-selected lambda: " e(lambda)
di "Selected variables: " `"`e(allvars_sel)'"'

local sel_vars `e(allvars_sel)'

/*------------------------------------------------------------------------------
    3b.5 Post-lasso OLS for standard errors (display table only)
------------------------------------------------------------------------------*/

regress pca1 `sel_vars' if arm_n == 0 & main_sample == 1, robust
eststo lasso_ols

esttab lasso_ols using output/tables/lasso_predictors.tex, ///
    b(%9.3f) se(%9.3f) label nostar ///
    stats(N, labels("N (control group)") fmt(%9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

di as text "Saved: output/tables/lasso_predictors.tex"

/*------------------------------------------------------------------------------
    3b.6 Predict pca1_hat using lasso coefficients (penalized)
         Re-run lasso to restore e() (cleared by regress above), then predict.
------------------------------------------------------------------------------*/

lasso linear pca1 `all_preds' if arm_n == 0 & main_sample == 1, ///
    rseed(12345) selection(cv, folds(10))
predict pca1_hat, xb

* Verify all main_sample obs have non-missing pca1_hat
count if missing(pca1_hat) & main_sample == 1
assert r(N) == 0

/*==============================================================================
    Section 3c: HTE estimation
==============================================================================*/

eststo clear

local hterhs "arm_industry arm_academic arm_personal c.pca1_hat"
local hterhs "`hterhs' c.pca1_hat#c.arm_industry c.pca1_hat#c.arm_academic c.pca1_hat#c.arm_personal"

foreach y in delta main_intent {
    regress `y' `hterhs' $controls if main_sample == 1, robust
    sum `y' if arm_control == 1 & main_sample == 1
    estadd scalar cm = r(mean)
    eststo m_`y'
}

local keep_vars "arm_industry arm_academic arm_personal pca1_hat"
local keep_vars "`keep_vars' c.pca1_hat#c.arm_industry c.pca1_hat#c.arm_academic c.pca1_hat#c.arm_personal"

esttab m_delta m_main_intent ///
    using output/tables/hte_pca.tex, ///
    b(%9.3f) se(%9.3f) keep(`keep_vars') label nostar ///
    stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
    fragment replace nomtitles nonotes nonumbers nolines nogaps

di as text "Saved: output/tables/hte_pca.tex"

/*==============================================================================
    Section 3d: Plot — lincom CIs over pca1_hat grid [-2, 2]

    For each arm k at grid point x:
      TE_k(x) = arm_k + x * (pca1_hat # arm_k)
    lincom computes this linear combination along with its SE, giving exact 95% CIs.
==============================================================================*/

tempfile plot_data
postfile phandle str10 arm str12 outcome float xval float te float ci_lo float ci_hi ///
    using `plot_data', replace

foreach outcm in delta main_intent {
    estimates restore m_`outcm'
    forvalues xi = 0/40 {
        local x = (`xi' - 20) / 10
        foreach arm in industry academic personal {
            lincom arm_`arm' + `x' * c.pca1_hat#c.arm_`arm'
            post phandle ("`arm'") ("`outcm'") (`x') ///
                (`r(estimate)') ///
                (`r(estimate)' - 1.96*`r(se)') ///
                (`r(estimate)' + 1.96*`r(se)')
        }
    }
}

postclose phandle

use `plot_data', clear

* 3x2 grid: columns = arms (Industry / Academic / Personal)
*            rows    = outcomes (Delta / Vaccination Intent)
* Each panel has one CI band + one line.

local color_industry "31 119 180"
local color_academic "255 127 14"
local color_personal "44 160 44"
local title_industry "Industry"
local title_academic "Academic"
local title_personal "Personal"

foreach outcm in delta main_intent {
    if "`outcm'" == "delta"       local ytitle "Effect on delta"
    if "`outcm'" == "main_intent" local ytitle "Effect on vacc. intent"

    foreach arm in industry academic personal {
        twoway ///
            (rarea ci_lo ci_hi xval if arm=="`arm'" & outcome=="`outcm'", ///
                color("`color_`arm''%30") lwidth(none)) ///
            (line te xval if arm=="`arm'" & outcome=="`outcm'", ///
                lcolor("`color_`arm''") lwidth(medthick)) ///
            , xline(0, lcolor(gray) lpattern(dash)) ///
              yline(0, lcolor(gray) lpattern(dash)) ///
              xlabel(-2(1)2, labsize(small)) ///
              ylabel(, labsize(small)) ///
              xtitle("") ///
              ytitle("`ytitle'", size(small)) ///
              title("`title_`arm''", size(small)) ///
              legend(off) ///
              graphregion(color(white)) ///
              name(p_`outcm'_`arm', replace)
    }
}

graph combine ///
    p_delta_industry    p_delta_academic    p_delta_personal ///
    p_main_intent_industry p_main_intent_academic p_main_intent_personal, ///
    cols(3) graphregion(color(white)) ///
    note("x-axis: predicted trust/relevance index (pca1_hat); shaded regions = 95% CI", ///
         size(vsmall))

graph export "output/figures/hte_pca.png", width(2400) height(1600) replace

di as text "Saved: output/figures/hte_pca.png"

capture log close
