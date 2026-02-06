

use "derived/prescreen_clean.dta", clear 
keep if final_sample==1

gen hes = vacc_intent<=3 

local n = 0
foreach source in doctor cdc univ news  sm podcasts  {
	local ++n
	gen st`n' = info_`source'>= 3 if ~missing(info_`source')
	gen rel`n' = reliable_`source' == 3 if ~missing(reliable_`source')
}



foreach v in trust_govt follow_doc {
	replace `v' = 3*`v' - (hes==0) + (hes==1)
	format `v' %6.3f
}




collapse (mean) st1-rel6 ,by(hes)
reshape long st rel , i(hes) j(source)


replace source = 2*source 
replace source = source - .45 if hes==0
replace source = source + .45 if hes == 1

# delimit ;
twoway 
	(bar st source if hes == 0 ,  barwidth(.9) fcolor(stc1%60))
	(bar st source if hes == 1 , barwidth(.9) color(stc2%0))
	,
	ytitle("") title("% getting health care info from source", span pos(11))
	legend(ring(0) pos(2) cols(1) 
		order(1 "Not vaccine hesitant"))
	ylabel(0(0.25)1)
	xtitle("") 
	xlabel(2 "Doctor" 4 "CDC" 6 "University" 8 "News" 10 "Social Media" 12 "Podcasts")
	xsize(7) ysize(4)
	name(ui1, replace)
;
graph export output/figures/use_info1.png, replace width(1750) height(1000);

# delimit ;
twoway 
	(bar st source if hes == 0 ,  barwidth(.9) fcolor(stc1%60))
	(bar st source if hes == 1 & source <= 9, barwidth(.9) fcolor(stc2%60))
	(bar st source if hes == 1, barwidth(.9) color(stc2%0))
	,
	ytitle("") title("% getting health care info from source", span pos(11))
	legend(ring(0) pos(2) cols(1) 
		order(1 "Not vaccine hesitant" 2 "Vaccine hesitant"))
	ylabel(0(0.25)1)
	xtitle("") 
	xlabel(2 "Doctor" 4 "CDC" 6 "University" 8 "News" 10 "Social Media" 12 "Podcasts")
	xsize(7) ysize(4)
	name(ui2, replace)
;
graph export output/figures/use_info2.png, replace width(1750) height(1000);

# delimit ;
twoway 
	(bar st source if hes == 0 ,  barwidth(.9) fcolor(stc1%60))
	(bar st source if hes == 1 , barwidth(.9) fcolor(stc2%60))
	,
	ytitle("") title("% getting health care info from source", span pos(11))
	legend(ring(0) pos(2) cols(1) 
		order(1 "Not vaccine hesitant" 2 "Vaccine hesitant"))
	ylabel(0(0.25)1)
	xtitle("") 
	xlabel(2 "Doctor" 4 "CDC" 6 "University" 8 "News" 10 "Social Media" 12 "Podcasts")
	xsize(7) ysize(4)
	name(ui3, replace)
;
graph export output/figures/use_info3.png, replace width(1750) height(1000);

# delimit ;
twoway 
	(bar rel source if hes == 0 ,  barwidth(.9) fcolor(stc1%60))
	(bar rel source if hes == 1 , barwidth(.9) fcolor(stc2%60))
	,
	ytitle("") title("% saying source is reliable  vs. somewhat or not reliable", 
		span pos(11))
	legend(ring(0) pos(2) cols(1) 
		order(1 "Not vaccine hesitant" 2 "Vaccine hesitant"))
	ylabel(0(0.25)1)
	xtitle("") 
	xlabel(2 "Doctor" 4 "CDC" 6 "University" 8 "News" 10 "Social Media" 12 "Podcasts")
	xsize(7) ysize(4)
	text(.99 1 "(Conditional on using source)", place(e) size(large) )
;


graph export output/figures/reliable_info.png, replace width(1750) height(1000);

