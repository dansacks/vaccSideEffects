use "C:\Users\dwsacks\Box\VaccSideEffects\data\pilot_main_clean.dta" , clear

gen delta = posterior_vacc - posterior_novacc
sum delta if vacc_intent >= 3

* baseline within-arm sd : 30.6, mean 19.6


reg delta i.treatment if vacc_intent >= 3
local sd_unadj = e(rmse)
 
reg delta i.treatment i.prior_self_vacc i.prior_self_placebo  i.age i.gender  ///
	i.education i.income i.race i.polviews if vacc_intent>=3
	
local sd_adj = sqrt( (1-e(r2_a))*`sd_unadj'^2) 
di "SD Unadjusted: `sd_unadj'"
di "SD Adjusted: `sd_adj' "


power twomeans 0, n(950) power(0.9)
local mde = r(delta) 
local mde_unadj = `mde'*`sd_unadj'
local mde_adj = `mde'*`sd_adj'

di "MDE unadj: `mde_unadj'"
di "MDE adj: `mde_adj'"


qui do code/calc_yuen


yuen_t delta treatment, trim_rate(20)

return list 


keep if vacc_intent<= 3
bysort treatment: egen low_pct = pctile(delta), p(20)
bysort treatment: egen high_pct = pctile(delta), p(80)
gen  ytrim = delta if inrange(delta, low_pct, high_pct)
sum ytrim

gen ywinsor = delta
replace ywinsor = low_pct if ytrim < low_pct
replace ywinsor = high_pct if ytrim > high_pct
sum ywinsor
ss

gen `ytrim' = `y' if inrange(`y', `low_pct', `high_pct') &  `touse'
gen `ywinsor' = `ytrim'  
replace `ywinsor' = `low_pct' if `y' <`low_pct' & `touse'
replace `ywinsor' = `high_pct' if `y' >`high_pct' &  `touse'