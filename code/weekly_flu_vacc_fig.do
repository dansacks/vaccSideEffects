
local flu_data "Weekly_Cumulative_Doses_(in_Millions)_of_Influenza_Vaccines_Distributed_by_Season,_United_States_20260128.csv"

import delimited using "raw_data/`flu_data'", clear 

gen date = date(substr(start_date, 1, 11), "YMD")
format date %td 

gen ns = real(substr(influenza_season, 1,4))
bysort influenza_season (date):  gen label = substr(influenza_season, 3,2) + "-" + substr(influenza_season,8,2) if _n==_N
list influenza_season date label if ~missing(label)

rename cumulative_flu_doses_distributed doses

# delimit ;
twoway
	(connected doses week_sort_order if ns == 2024, mlabel(label) mlabpos(3) 
		mlabsize(large) color(gs6%90) mlabcolor(gs6%90))
	(connected doses week_sort_order if ns == 2023, mlabel(label) mlabpos(3) 
		mlabsize(large) color(gs7%85) mlabcolor(gs7%85))
	(connected doses week_sort_order if ns == 2022, mlabel(label) mlabpos(3)
		mlabsize(large) color(gs8%80) mlabcolor(gs8%80))
	(connected doses week_sort_order if ns == 2021, mlabel(label) mlabpos(2) 
		mlabsize(large) color(gs9%75) mlabcolor(gs9%75))
	(connected doses week_sort_order if ns == 2020, mlabel(label) mlabpos(2) 
		mlabsize(large) color(gs10%70) mlabcolor(gs10%70))
	(connected doses week_sort_order if ns == 2025, mlabel(label) mlabpos(3) 
		mlabsize(large) color(stc2) mlabcolor(stc2))
	,
	legend(off)
	xtitle("Week of flu season", size(large)) 
	ytitle("") 
	title("Cumulative vaccine doses (millions), by season", span pos(11))
	xlabel(1 10 20 30 32)
	graphregion(margin(r+10))
	text(1 32 "Source: data.cdc.gov", place(w))
;


# delimit cr