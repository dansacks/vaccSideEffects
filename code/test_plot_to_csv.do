/*==============================================================================
    Unit Tests for plot_to_csv.ado

    Tests the plot_to_csv utility that exports plotted data from in-memory
    Stata graphs to CSV files using the serset system.

    Each test:
    1. Creates known data
    2. Clears sersets with `serset drop _all`
    3. Creates a graph
    4. Exports using plot_to_csv
    5. Verifies the CSV contains the exact plotted values

    Usage:
        do "code/test_plot_to_csv.do"

    Created by Dan + Claude Code
==============================================================================*/

clear all
global scriptname "test_plot_to_csv"
do "code/_config.do"

* Test output directory
local testdir "output/figures"

di _n "=========================================="
di "Testing plot_to_csv.ado"
di "==========================================" _n

local tests_passed = 0
local tests_failed = 0

*------------------------------------------------------------------------------
* Test 1: Simple scatter plot - verify exact integer values
*------------------------------------------------------------------------------
di "Test 1: Simple scatter plot (x=_n, y=2*x)..."

clear
set obs 10
gen int x = _n
gen int y = 2 * x

serset drop _all
twoway scatter y x

plot_to_csv using "`testdir'/test1.csv", replace

preserve
import delimited "`testdir'/test1.csv", clear
local test_pass = 1

count
if r(N) != 10 {
    di as error "  Wrong row count: `r(N)' (expected 10)"
    local test_pass = 0
}

forvalues i = 1/10 {
    if x[`i'] != `i' {
        di as error "  Row `i': x=`=x[`i']' (expected `i')"
        local test_pass = 0
    }
    if y[`i'] != 2*`i' {
        di as error "  Row `i': y=`=y[`i']' (expected `=2*`i'')"
        local test_pass = 0
    }
}

if `test_pass' {
    di as text "  PASSED: Values (1,2), (2,4), ..., (10,20) verified"
    local ++tests_passed
}
else {
    local ++tests_failed
}
restore
graph drop _all

*------------------------------------------------------------------------------
* Test 2: Line plot with negative integers
*------------------------------------------------------------------------------
di "Test 2: Line plot with negative integers..."

clear
set obs 5
gen int x = _n - 3
gen int y = x * x * x

serset drop _all
twoway line y x

plot_to_csv using "`testdir'/test2.csv", replace

preserve
import delimited "`testdir'/test2.csv", clear
local test_pass = 1

local expected_x -2 -1 0 1 2
local expected_y -8 -1 0 1 8

forvalues i = 1/5 {
    local ex : word `i' of `expected_x'
    local ey : word `i' of `expected_y'

    if x[`i'] != `ex' {
        di as error "  Row `i': x=`=x[`i']' (expected `ex')"
        local test_pass = 0
    }
    if y[`i'] != `ey' {
        di as error "  Row `i': y=`=y[`i']' (expected `ey')"
        local test_pass = 0
    }
}

if `test_pass' {
    di as text "  PASSED: Negative values (-2,-8), (-1,-1), (0,0), (1,1), (2,8) verified"
    local ++tests_passed
}
else {
    local ++tests_failed
}
restore
graph drop _all

*------------------------------------------------------------------------------
* Test 3: Multi-series plot exports all variables
*------------------------------------------------------------------------------
di "Test 3: Multi-series plot (two scatter series)..."

clear
set obs 5
gen int x = _n
gen int y1 = x
gen int y2 = x * 10

serset drop _all
twoway (scatter y1 x) (scatter y2 x)

plot_to_csv using "`testdir'/test3.csv", replace

preserve
import delimited "`testdir'/test3.csv", clear
local test_pass = 1

* Multi-series plots store all variables in one serset
count
if r(N) != 5 {
    di as error "  Wrong row count: `r(N)' (expected 5)"
    local test_pass = 0
}

* Check all variables exist
capture confirm variable x y1 y2
if _rc != 0 {
    di as error "  Missing expected variables"
    local test_pass = 0
}

if `test_pass' {
    di as text "  PASSED: Multi-series data exported with all variables"
    local ++tests_passed
}
else {
    local ++tests_failed
}
restore
graph drop _all

*------------------------------------------------------------------------------
* Test 4: Named graph export
*------------------------------------------------------------------------------
di "Test 4: Export named graph..."

clear
set obs 3
gen int x = _n * 100
gen int y = _n * 100

serset drop _all
twoway scatter y x, name(mygraph, replace)

plot_to_csv using "`testdir'/test4.csv", replace name(mygraph)

preserve
import delimited "`testdir'/test4.csv", clear
local test_pass = 1

count
if r(N) != 3 {
    di as error "  Wrong row count: `r(N)' (expected 3)"
    local test_pass = 0
}

forvalues i = 1/3 {
    if x[`i'] != `i'*100 | y[`i'] != `i'*100 {
        di as error "  Row `i': wrong values"
        local test_pass = 0
    }
}

if `test_pass' {
    di as text "  PASSED: Correctly exported named graph 'mygraph'"
    local ++tests_passed
}
else {
    local ++tests_failed
}
restore
graph drop _all

*------------------------------------------------------------------------------
* Test 5: Original data unchanged after export
*------------------------------------------------------------------------------
di "Test 5: Original data preserved after export..."

clear
set obs 10
gen int x = _n
gen int y = x * 2
gen int z = x * 3

local orig_n = _N
local orig_z5 = z[5]

serset drop _all
twoway scatter y x

plot_to_csv using "`testdir'/test5.csv", replace

local test_pass = 1

if _N != `orig_n' {
    di as error "  Observation count changed"
    local test_pass = 0
}

capture confirm variable z
if _rc != 0 {
    di as error "  Variable z was dropped"
    local test_pass = 0
}

if z[5] != `orig_z5' {
    di as error "  Value of z[5] changed"
    local test_pass = 0
}

if x[1] != 1 | y[1] != 2 {
    di as error "  Original values changed"
    local test_pass = 0
}

if `test_pass' {
    di as text "  PASSED: Original data intact"
    local ++tests_passed
}
else {
    local ++tests_failed
}
graph drop _all

*------------------------------------------------------------------------------
* Test 6: Error when no graph in memory
*------------------------------------------------------------------------------
di "Test 6: Error when no graph in memory..."

clear
graph drop _all
serset drop _all

set obs 5
gen x = _n
gen y = x

capture plot_to_csv using "`testdir'/test6.csv", replace
if _rc == 198 {
    di as text "  PASSED: Correctly errored with no graph"
    local ++tests_passed
}
else {
    di as error "  FAILED: Should error when no graph (rc=`_rc')"
    local ++tests_failed
}

*------------------------------------------------------------------------------
* Test 7: Error when named graph doesn't exist
*------------------------------------------------------------------------------
di "Test 7: Error when named graph doesn't exist..."

clear
set obs 5
gen x = _n
gen y = x
serset drop _all
twoway scatter y x, name(existinggraph, replace)

capture plot_to_csv using "`testdir'/test7.csv", replace name(nonexistent)
if _rc == 198 {
    di as text "  PASSED: Correctly errored for non-existent graph name"
    local ++tests_passed
}
else {
    di as error "  FAILED: Should error for non-existent graph (rc=`_rc')"
    local ++tests_failed
}
graph drop _all

*------------------------------------------------------------------------------
* Test 8: Error on non-csv extension
*------------------------------------------------------------------------------
di "Test 8: Error on non-csv extension..."

clear
set obs 5
gen x = _n
gen y = x
serset drop _all
twoway scatter y x

capture plot_to_csv using "`testdir'/test8.txt", replace
if _rc == 198 {
    di as text "  PASSED: Correctly rejected .txt extension"
    local ++tests_passed
}
else {
    di as error "  FAILED: Should reject non-csv extension (rc=`_rc')"
    local ++tests_failed
}
graph drop _all

*------------------------------------------------------------------------------
* Test 9: Error when replace not specified for existing file
*------------------------------------------------------------------------------
di "Test 9: Error when replace not specified..."

clear
set obs 5
gen x = _n
gen y = x
serset drop _all
twoway scatter y x

plot_to_csv using "`testdir'/test9.csv", replace

capture plot_to_csv using "`testdir'/test9.csv"
if _rc == 602 {
    di as text "  PASSED: Correctly required replace option"
    local ++tests_passed
}
else {
    di as error "  FAILED: Should require replace (rc=`_rc')"
    local ++tests_failed
}
graph drop _all

*------------------------------------------------------------------------------
* Test 10: Single observation plot
*------------------------------------------------------------------------------
di "Test 10: Single observation plot..."

clear
set obs 1
gen int x = 42
gen int y = 84
serset drop _all
twoway scatter y x

plot_to_csv using "`testdir'/test10.csv", replace

preserve
import delimited "`testdir'/test10.csv", clear
local test_pass = 1

count
if r(N) != 1 {
    di as error "  Wrong row count: `r(N)' (expected 1)"
    local test_pass = 0
}

if x[1] != 42 | y[1] != 84 {
    di as error "  Values incorrect: x=`=x[1]', y=`=y[1]' (expected 42, 84)"
    local test_pass = 0
}

if `test_pass' {
    di as text "  PASSED: Single observation (42, 84) exported"
    local ++tests_passed
}
else {
    local ++tests_failed
}
restore
graph drop _all

*------------------------------------------------------------------------------
* Summary
*------------------------------------------------------------------------------
di _n "=========================================="
di "Test Summary"
di "=========================================="
di as text "Tests passed: `tests_passed'"
di as text "Tests failed: `tests_failed'"

if `tests_failed' > 0 {
    di as error _n "SOME TESTS FAILED"
    error 1
}
else {
    di as text _n "ALL TESTS PASSED"
}

* Clean up test files
forvalues i = 1/10 {
    capture erase "`testdir'/test`i'.csv"
}

capture log close
