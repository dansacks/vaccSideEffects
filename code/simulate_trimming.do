
/*
bootstrap idea:

1. load the relevant sample
2. undo cross arm mean effects
3. append many times to achieve n >= 1900

4. foreach bootstrap iteration
	- preserve
	- bsample
	- assign treatment at random 
	- assign simple treatment effect 
	- calc yuen t
	- return yuen t + p 
	
5. repeat many bootstraps, for effect size in {0,(0.5)5}
*/
* 3.75  4 4.25 4.5 4.75 5 5.25 5.5 5.75 6
local niter 1000
local tes 0 1 2 2.8 2.9 3 3.1 3.5 4 4.5 5 
local nte: word count `tes'
di `nte'
capture frame drop results
frame create results
frame results {
	set obs `nte'
	gen te = .
	local row = 0
	foreach te of local tes {
		local ++row
		replace te = `te' in `row'
	}
	expand `niter'
	bysort te: gen iter = _n
	
	gen yuen_t = .
	foreach trim in 1 10 20 25 _reg{
		gen p`trim' = .
		gen delta`trim'= . 
		gen reject`trim' = . 
	}
}
qui do code/calc_yuen
use "C:\Users\dwsacks\Box\VaccSideEffects\data\pilot_main_clean.dta" , clear
keep if vacc_intent >= 3

gen delta = posterior_vacc - posterior_novacc
sum delta

reg delta i.treatment
predict delta_res, residual
drop if missing(delta_res)
keep delta_res prior_self_vacc prior_self_placebo age gender education income race polviews

tempfile hesitant
save `hesitant', replace

forvalues n = 0/10 {
	append using `hesitant'
}

keep if _n<=1900


qui foreach te of numlist `tes' {
	
	forvalues iter = 1/`niter' {
		preserve
		
		gen treatment = runiform() <= 0.5 
		gen y = delta_res + `te'*treatment
		
		foreach trim in 1 10 20 25 {
			yuen_t y treatment, trim_rate(`trim')
			
			frame results {
				replace delta`trim' = r(delta) if iter==`iter' & te == `te'
				replace p`trim'= r(p) if iter==`iter' & te == `te'
				replace reject`trim' = p`trim' <=0.05
			}
		}
		
				
		reg y i.treatment i.prior_self_vacc i.prior_self_placebo ///
			i.age i.gender  i.education i.income i.race i.polviews, robust
		
		frame results {
			replace delta_reg = _b[1.treatment] if iter==`iter' & te == `te'
			replace p_reg= 2*(1-t(e(df_r), abs(_b[1.treatment]/_se[1.treatment]))) ///
				if iter==`iter' & te == `te'
			replace reject_reg = p_reg <=0.05
		}
		restore	
	}
}


frame results: table te, stat(mean reject1 reject10 reject20 reject25 reject_reg)

