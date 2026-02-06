/*==============================================================================
    Heterogeneous Treatment Effects Regressions

    Input:  derived/merged_all.dta
    Output: output/tables/het_*.tex, output/tables/het_*.md

    Estimates treatment effects by subgroup splits:
    - high_prior: Prior SE expectation >= 5 (somewhat likely+)
    - bad_experience: Prior flu vaccine reaction was severe or no prior vaccine
    - high_trust: Trust in clinical trial > 5 (median)
    - high_relevance: Trial relevance > 5 (median)
    - reliable_uni: University research reliable (== 3, "Yes")

    Each table has 6 columns grouped by subgroup:
    - post_trial (split=0), delta (split=0), main_maybe (split=0)
    - post_trial (split=1), delta (split=1), main_maybe (split=1)

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "heterogeneous_treatment_effects"
do "code/_config.do"
do "code/_set_controls.do"

/*------------------------------------------------------------------------------
    1. Load data and prepare variables
------------------------------------------------------------------------------*/

use "derived/merged_all.dta", clear
keep if main_sample==1

* Create heterogeneity splits
gen high_prior = prior_self_vacc >= 5
gen bad_experience = ~inlist(flu_vacc_reaction, 1, 2)
gen high_trust = trust_trial > 5
gen high_relevance = relevant_trial > 5
gen reliable_uni = (reliable_university == 3)
gen uses_cdc = info_cdc >=3 if ~missing(info_cdc)
gen uses_uni = info_university>=3 if ~missing(info_university)

* Label treatment indicators
label var arm_industry "Industry"
label var arm_academic "Academic"
label var arm_personal "Personal"

local keyvars arm_industry arm_academic arm_personal

/*------------------------------------------------------------------------------
    2. Define split labels for table headers
------------------------------------------------------------------------------*/

local high_prior_label0 "Low"
local high_prior_label1 "High"
local high_prior_rowlabel "Prior"

local flu_vacc_reaction_label0  "No vacc"
local flu_vacc_reaction_label1  "No rxn"
local flu_vacc_reaction_label2  "Mild"
local flu_vacc_reaction_label3  "Severe"
local flu_vacc_reaction_rowlabel  "Prior reaction"

local high_trust_label0 "Low"
local high_trust_label1 "High"
local high_trust_rowlabel "Trust"

local high_relevance_label0 "Low"
local high_relevance_label1 "High"
local high_relevance_rowlabel "Relevance"

local uses_cdc_label0 "No"
local uses_cdc_label1 "Yes"
local uses_cdc_rowlabel "Uses CDC for info"

local uses_uni_label0 "No"
local uses_uni_label1 "Yes"
local uses_uni_rowlabel "Uses Uni for info"

local reliable_uni_label0 "No"
local reliable_uni_label1 "Yes"
local reliable_uni_rowlabel "Uni reliable"

/*------------------------------------------------------------------------------
    3. Run regressions and create tables for each split
------------------------------------------------------------------------------*/

foreach split in reliable_uni high_prior high_trust high_relevance uses_cdc  flu_vacc_reaction {
    di as text ""
    di as text "=============================================="
    di as text "Split: `split'"
    di as text "=============================================="
		local ests "" 
    eststo clear

    foreach y in delta {
				qui sum `split'
        foreach splitval of numlist 0/`r(max)' {
            noi di as text ""
            noi di as text "--- `y', `split'=`splitval' ---"

            * Run regression
            regress `y' `keyvars' $controls if `split' == `splitval', robust

            * Get control mean
            sum `y' if arm_control==1 & `split'==`splitval'
            estadd scalar cm = r(mean)

            * Store with unique name
            eststo `y'_`splitval'
						local ests `ests' `y'_`splitval'
        }
    }

    * Get split labels
    local lab0 "``split'_label0'"
    local lab1 "``split'_label1'"
    local lab2 "``split'_label2'"
    local lab3 "``split'_label3'"
    local rowlab "``split'_rowlabel'"

    * Column titles for output (grouped by subgroup)
    local coltitles mtitles( "Delta" "Delta")
		if "`split'" == "flu_vacc_reaction" {
			local coltitles mtitles("Delta" "Delta" "Delta" "Delta")
		}
    * .tex output: esttab followed by split label row
    esttab `ests' ///
        using output/tables/het_`split'.tex, ///
        b(%9.3f) se(%9.3f) keep(`keyvars') label nostar ///
        stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
        fragment replace nomtitles nonotes nonumbers nolines nogaps

    * Append split label row to .tex file
    file open _het_tex using "output/tables/het_`split'.tex", write append
		if "`split'" ~= "flu_vacc_reaction"  {
			file write _het_tex "`rowlab' & `lab0' & `lab1' \\ _n"
		}
		if "`split'" == "flu_vacc_reaction" {
			 file write _het_tex "`rowlab' & `lab0' & `lab1' & `lab2' & `lab3' \\" _n
			
		}
    file close _het_tex

    * .md output: include column titles in header row, followed by split label row
    esttab `ests' ///
        using output/tables/het_`split'.md, ///
        b(%9.3f) se(%9.3f) keep(`keyvars') label nostar `coltitles' ///
        stats(cm N, labels("Control mean" "N") fmt(%9.3f %9.0fc)) ///
        fragment replace nonotes nonumbers
noi di "beep"
    * Append split label row to .md file
    file open _het_md using "output/tables/het_`split'.md", write append
    if "`split'" ~= "flu_vacc_reaction" {
			file write _het_md "| `rowlab' | `lab0' | `lab1' |" _n
		}  
    if "`split'" == "flu_vacc_reaction" {
		 file write _het_md "| `rowlab' | `lab0' | `lab1' | `lab2' | `lab3'" _n
		}
		file close _het_md

    di as text "Saved: output/tables/het_`split'.tex"
    di as text "Saved: output/tables/het_`split'.md"
}

capture log close
