
use data/pilot_main_clean, clear

gen hesitant = vacc_intent >= 3 

** trust trial
forvalues h = 0/1 {
	foreach b in trust_trial relevant_trial trust_academic relevant_academic {
		histogram `b' if hesitant==`h', discrete  name(`b'`h', replace) ///
			title("Hesitant=`h'") xsize(3) ysize(3) 
	
	}
}
graph combine trust_trial0 trust_trial1 relevant_trial0 relevant_trial1, ///
	xsize(6) ysize(6.5) title("Trial: trust + relevance")
graph export figures/trial_trust_relevance.pdf, replace 

graph combine trust_academic0 trust_academic1 relevant_academic0 relevant_academic1, ///
	xsize(6) ysize(6.5) title("Academic: trust + relevance")
graph export figures/academic_trust_relevance.pdf, replace 

** priors
** posteriors
foreach v in prior_trial posterior_trial posterior_self_placebo posterior_self_vacc{
	forvalues h = 0/1 {
		
		sum posterior_trial if hesitant==`h', d
		local mean = string(r(mean),"%3.0f")
		local median = string(r(p50),"%3.0f")
		local p25 = string(r(p25),"%3.0f")
		local p75 = string(r(p75),"%3.0f")
		
		# delimit ;
		histogram posterior_trial if hesitant == `h', width(1) start(-0.5)
			name(h`h', replace ) title("Hesitant=`h'") percent
			xsize(3) ysize(3) 
			text(17.5 100 "Mean: `mean'" "p25: `p25'" "p50: `median'" "p75:`p75'",
				place(w) justification(right))
			xlabel(0(25)100)
			ylabel(0(10)30)
			xline(3)
			nodraw
		;
		# delimit cr
	}
	if "`v'" == "prior_trial" local total "Prior belief for vacc SE in trial"
	if "`v'" == "posterior_trial" local total "Posterior belief for vacc SE in trial"
	if "`v'" == "posterior_self_placebo" local total "Posterior belief for self placebo"
	if "`v'" == "posterior_self_vacc" local total "Posterior belief for self vacc"
	
	graph combine h0 h1 , cols(2) title("`trial'")
	graph export figures/`v'.pdf, replace 
}

** trust


ss

forvalues h = 0/1 {
	
	sum posterior_self_vacc if hesitant==`h', d
	local mean = string(r(mean),"%3.0f")
	local median = string(r(p50),"%3.0f")
	local p25 = string(r(p25),"%3.0f")
	local p75 = string(r(p75),"%3.0f")
	
	# delimit ;
	histogram posterior_self_vacc if hesitant == `h', width(1) 
		name(h`h', replace ) title("Hesitant=`h'") percent
		xsize(3) ysize(3) 
		text(17.5 60 "Mean: `mean'" "p25: `p25'" "p50: `median'" "p75:`p75'",
			place(w) justification(right))
		xlabel(0(20)80)
	;
	# delimit cr
}
graph combine h0 h1 , cols(2) title("Pooled posterior for placebo SE rate")
graph export figures/posterior_self_placebo.pdf, replace 
