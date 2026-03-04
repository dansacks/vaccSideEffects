

use "derived/merged_main_pre.dta", clear
keep if main_sample==1
count

use "derived/merged_all.dta", clear
keep if main_sample==1

* se_trial, delta, main_intent, 

tab arm_n
tab arm_n if ~missing()


gen c0 = ""
local c = 0 
foreach outcome in delta post_trial main_intent link_click got_flu_vacc {
	local ++c
	gen c`c' = ""
	local row = 0
	
	forvalues arm = 0/3 {
		if `arm' == 0 local name "Control"
		if `arm' == 1 local name "Industry"
		if `arm' == 2 local name "Academic" 
		if `arm' == 3 local name "Representative"
		
		local ++row
		replace c0 = "`name' & " in `row'
		
		count if arm_n==`arm' & ~missing(`outcome')
		replace c`c' = string(r(N), "%4.0fc") + " & " in `row'
		
		
	}
	local ++row
	replace c0 = "All &" in `row'
	count if ~missing(`outcome')
	replace c`c' = string(r(N), "%4.0fc")+ " & " in `row'
	
	
	
}

replace c`c' = subinstr(c`c', "&", "\\", .) in 1/`row'
replace c`c' = subinstr(c`c', "\\", "", .) in `row'

list c0-c`c' in 1/`row', noobs clean
outsheet c0-c`c' in 1/`row' using output/tables/counts_by_arm.tex, replace ///
	noquote nonames delimit(" ")
