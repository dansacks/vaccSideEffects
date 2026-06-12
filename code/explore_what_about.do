
clear all
global scriptname "explore_what_about"
do "code/_config.do"

/*------------------------------------------------------------------------------
    1. Load data and merge classifications
------------------------------------------------------------------------------*/
import delimited using output/tables/debrief_classifications.csv, clear
tempfile classifications
save `classifications'

use "derived/merged_all.dta", clear

merge 1:1 study_id using `classifications', assert(1 3)

* Responses not sent for classification are exactly those with missing/"n/a" debrief_about
assert _merge == 1 if missing(debrief_about) | debrief_about == "n/a"
assert _merge == 3 if !missing(debrief_about) & debrief_about != "n/a"
drop _merge

keep if main_sample == 1

/*------------------------------------------------------------------------------
    2. Treat unclassified responses (missing or "n/a") as unclear
------------------------------------------------------------------------------*/
count if missing(debrief_about) | debrief_about == "n/a"
assert r(N) == 13

local about_vars about_flu about_attitude about_info about_beliefs about_intent about_change
foreach v of local about_vars {
    replace `v' = 0 if missing(debrief_about) | debrief_about == "n/a"
}
replace unclear           = 1 if missing(debrief_about) | debrief_about == "n/a"
replace understood_intent = 0 if missing(debrief_about) | debrief_about == "n/a"

count
assert r(N) == 3525

/*------------------------------------------------------------------------------
    3. Figure: percent of responses in each category
------------------------------------------------------------------------------*/
preserve

local catvars about_flu about_attitude about_beliefs about_info about_intent unclear about_change understood_intent
local i = 0
foreach v of local catvars {
    local ++i
    qui sum `v', meanonly
    local pct`i' = r(mean) * 100
}

clear
set obs 8
gen cat = _n
gen pct = .
forvalues i = 1/8 {
    replace pct = `pct`i'' if cat == `i'
}

label define catlbl ///
    1 "Mentions flu or vaccine" ///
    2 "Mentions attitudes or opinions" ///
    3 "Side effects or effectiveness" ///
    4 "Mentions information or research" ///
    5 "Mentions vaccination intentions" ///
    6 "Unclear / unclassifiable" ///
    7 "Mentions changing behavior" ///
    8 "Understood study's intent"
label values cat catlbl

* Split into two series so "Understood study's intent" can be highlighted
* with a distinct, more intense color while the other categories are
* lightened -- distinguishable in both color and grayscale.
gen pct_other     = pct if cat <= 7
gen pct_highlight = pct if cat == 8

#delimit ;
graph hbar pct_other pct_highlight,
    over(cat, label(labsize(medium)))
    blabel(bar, format(%4.1f) size(medsmall))
    ytitle("Percent of main sample", size(medlarge))
    ylabel(0(20)100, labsize(medium))
    legend(off)
    bar(1, color(gs12))
    bar(2, color(navy))
    xsize(8) ysize(5)
;
#delimit cr

graph export "output/figures/debrief_what_about.png", replace width(2000) height(1250)

restore

/*------------------------------------------------------------------------------
    4. Table: example responses by understanding pattern
------------------------------------------------------------------------------*/

* Order of flag positions used for asserts below
local flagvars about_flu about_attitude about_info about_beliefs about_intent about_change unclear understood_intent

* Pattern 1: flu/vaccine only
local pat1_id 207
local pat1_lbl "Mentions flu or vaccine only"
local pat1_flags "1 0 0 0 0 0 . ."

* Pattern 2: attitudes/opinions only
local pat2_id 3464
local pat2_lbl "Mentions feelings, attitudes, or opinions only"
local pat2_flags "0 1 0 0 0 0 . ."

* Pattern 3: information/research only
local pat3_id 349
local pat3_lbl "Mentions information or research only"
local pat3_flags "0 0 1 0 0 0 0 0"

* Pattern 4: side effects/effectiveness only
local pat4_id 7441
local pat4_lbl "Mentions side effects or effectiveness only"
local pat4_flags "0 0 0 1 0 0 . ."

* Pattern 5: vaccination intentions only
local pat5_id 6894
local pat5_lbl "Mentions vaccination intentions only"
local pat5_flags "0 0 0 0 1 0 . ."

* Pattern 6: changing behavior/attitudes/beliefs only
local pat6_id 2993
local pat6_lbl "Mentions changing behavior, attitudes, or beliefs only"
local pat6_flags "0 0 0 0 0 1 . ."

* Pattern 7: flu/vaccine + attitudes
local pat7_id 61
local pat7_lbl "Mentions flu/vaccine and feelings/attitudes"
local pat7_flags "1 1 0 0 0 0 . ."

* Pattern 8: flu/vaccine + information
local pat8_id 1329
local pat8_lbl "Mentions flu/vaccine and information"
local pat8_flags "1 0 1 0 0 0 . ."

* Pattern 9: flu/vaccine + side effects/effectiveness
local pat9_id 126
local pat9_lbl "Mentions flu/vaccine and side effects/effectiveness"
local pat9_flags "1 0 0 1 0 0 . ."

* Pattern 10: flu/vaccine + attitudes + information
local pat10_id 1118
local pat10_lbl "Mentions flu/vaccine, feelings/attitudes, and information"
local pat10_flags "1 1 1 0 0 0 . ."

* Pattern 11: flu/vaccine + change, without information
local pat11_id 3370
local pat11_lbl "Mentions flu/vaccine and changing behavior, without information"
local pat11_flags "1 0 0 0 0 1 . ."

* Pattern 12: understood study's intent
local pat12_id 89
local pat12_lbl "Understood study's intent (flu/vaccine, information, change, and attitudes, side effects/effectiveness, or intentions)"
local pat12_flags "1 . 1 . . 1 0 1"

* Pattern label and row order for each of the 12 example responses
gen str200 pattern_label = ""
gen byte  pattern_order  = .

forvalues p = 1/12 {
    local sid = `pat`p'_id'

    qui count if study_id == `sid'
    assert r(N) == 1

    * Verify this study_id matches the labeled pattern
    forvalues j = 1/8 {
        local ev : word `j' of `pat`p'_flags'
        if "`ev'" != "." {
            local vn : word `j' of `flagvars'
            qui sum `vn' if study_id == `sid', meanonly
            assert r(mean) == `ev'
        }
    }

    replace pattern_label = "`pat`p'_lbl'" if study_id == `sid'
    replace pattern_order = `p'           if study_id == `sid'
}

keep if !missing(pattern_order)
sort pattern_order
assert _N == 12

* Build LaTeX-ready response text on the string variable itself (not a local
* macro): apostrophes in responses (e.g. "aren't") break Stata's
* compound-quote macro expansion if round-tripped through locals.
local oq = char(96) + char(96)
local cq = char(39) + char(39)

gen strL example_text = debrief_about

* Normalize embedded newlines / <NL> tokens to a single space
replace example_text = subinstr(example_text, char(10), " ", .)
replace example_text = subinstr(example_text, " <NL> ", " ", .)
replace example_text = subinstr(example_text, "<NL>", " ", .)

* LaTeX-escape special characters
replace example_text = subinstr(example_text, "&", "\&", .)
replace example_text = subinstr(example_text, "%", "\%", .)
replace example_text = subinstr(example_text, "$", "\$", .)
replace example_text = subinstr(example_text, "#", "\#", .)
replace example_text = subinstr(example_text, "_", "\_", .)

* Collapse repeated whitespace introduced by newline normalization
forvalues r = 1/5 {
    replace example_text = subinstr(example_text, "  ", " ", .)
}
replace example_text = strtrim(example_text)
replace example_text = "`oq'" + example_text + "`cq'"

capture file close whatabout
file open whatabout using "output/tables/debrief_examples.tex", write replace
forvalues p = 1/12 {
    if `p' < 12 {
        file write whatabout (pattern_label[`p']) " & " (example_text[`p']) " \\" _n
    }
    else {
        file write whatabout (pattern_label[`p']) " & " (example_text[`p'])
    }
}
file close whatabout

capture log close
