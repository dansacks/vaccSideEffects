
/* Yuen 1974, from Wilcoxon 2012
trim rate gamma
g_j : number of oservations trimmed from each tail
h_j = n_j - 2g_j : sample size after trimming
s^2_wj : winsorized variance

* steps:
1. Find within-group percentiles
2. trim and winsorize
3. find trim mean and winsorized variance
4. find d_j 
5. Find Yuen's T
6. Find df
7. calculate p-value / rejection region 


squared SE of X-bar-trimmed is  s^2_wj / { (1-2*gamma)^2*n}

Yuen uses 

d_j = (n_j-1)*s^2_wj / [h_j *(h_j-1)] 

for SE.

Yuen's T is 

T_y = (Mean_t1 - Mean_t2) / sqrt(d1 + d2)

null distribution of T_y is student's with DF

(d1+d2)^2  / [ d1^2/(h1-1) + d2^2/(h2-1) ]


*/


capture program drop yuen_t
program define yuen_t, rclass

	di "beep"
	syntax varlist(min=2) [if] [, trim_rate(real 20.0)]

	di "beep"
	// pull out the variables
	tokenize `varlist'
	local y     `1'
	local group `2'
	
	di "beep"

	// enforce gamma bounds (0 ≤ gamma ≤ 0.5)
	if (`trim_rate' < 0 | `trim_rate' >= 50) {
		di as err "trim_rate() must be between 0 and 50"
		exit 198
	}

	// mark sample
	marksample touse

	sort `group' `y'
	
	* 1. Find within-group percentiles
	tempvar low_pct high_pct
	by `group': egen `low_pct' = pctile(`y') if `touse', p(`trim_rate')
	by `group': egen `high_pct' = pctile(`y')  if `touse', p(`=100-`trim_rate'')
	
	
	* 2. trim and winsorize
	tempvar ytrim ywinsor 
	gen `ytrim' = `y' if inrange(`y', `low_pct', `high_pct') &  `touse'
	gen `ywinsor' = `ytrim'  
	replace `ywinsor' = `low_pct' if `y' <`low_pct' & `touse'
	replace `ywinsor' = `high_pct' if `y' >`high_pct' &  `touse'
	
	* 3. find trim mean and winsorized variance, and d_j
	forvalues j= 0/1 {
		sum `ytrim' if `group'==`j' & `touse'
		local mean_t`j' = r(mean)
		local h_`j' = r(N)
		
		sum `ywinsor' if `group' == `j' & `touse'
		local var_w`j' = r(Var)
		local n_`j' = r(N)
		
		local d`j' = (`n_`j''-1)*`var_w`j'' / (`h_`j''*(`h_`j''-1))
		
		
	}
	
	* 4. Find Yuen's t
	tempname delta
	scalar `delta' = `mean_t1' - `mean_t0'
	noi di "Delta = " `delta'
	noi di "mean t1 = `mean_t1', mean t0 = `mean_t0'"
	scalar yuen = `delta'/ sqrt(`d1' + `d0')

	* 5. Find df and p-value 
	
	scalar df = (`d1' + `d0')^2 / (`d1'^2/(`h_1'-1) + `d0'^2/(`h_0'-1)	)
	scalar p = 2*(1-t(df, abs(yuen)))
	
	* 6. Return d, yuen, df, p
	return scalar delta = `delta'
	return scalar yuen = yuen
	return scalar df = df
	return scalar p = p 
	
	
end 


