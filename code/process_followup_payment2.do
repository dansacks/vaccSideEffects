global directory C:\Users\dwsacks\Box\VaccSideEffects

import delimited using $directory/data/reward_followup.csv, clear
keep v40
rename v40 prolific_pid 
duplicates drop
save $directory/data/reward_followup, replace
 
import delimited using "$directory/data/flu_vacc_se_followup_December+20,+2025_08.42.csv", clear varn(1)
keep if attention == "1163"

* destring 
replace placebo = "4" if placebo == "id say 4%"
replace placebo = "7" if placebo == ",7"
replace placebo = "3" if strpos(placebo, "I'm guessing here: 3")
replace placebo = subinstr(placebo, "%", "", .)

list placebo if missing(real(placebo)) & ~missing(placebo)
destring placebo, replace force

* vacc
rename q32 vacc
replace vacc = subinstr(vacc, "%", "", .)
replace vacc = "10" if vacc == ",10"
list vacc if missing(real(vacc)) & ~missing(vacc)
destring vacc, replace force

gen vg = abs(vacc-1.3)<=1
gen pg = abs(placebo-3)<=1
keep vg pg v41
rename v41 prolific_pid

keep if vg|pg
duplicates drop

merge 1:1 prolific_pid using $directory/data/reward_followup, keep(1) 
gen pay = "0.5" if (vg+pg)==1
replace pay = "1.0" if (vg+pg)==2



outsheet prolific_pid pay using $directory/data/reward_final2.csv, replace ///
	delimit(",") noquote


	

outsheet prolific_pid using $directory/data/reward_final2_ids.csv, replace ///
	delimit(",") noquote
