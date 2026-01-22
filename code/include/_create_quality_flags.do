/*==============================================================================
    Create Quality/Sample Flags

    This include file creates standard quality and sample flags used across
    all survey cleaning files. It requires the following globals to be set:

    - $attn_check_var: Name of attention check variable (e.g., favorite_number, attn_check)
    - $attn_check_val: Expected value for attention check (e.g., 1965, 4419, 1163)

    It also requires the following variables to exist:
    - progress: Survey progress (0-100)
    - _finished: Finished flag from Qualtrics
    - prolific_pid: Prolific ID from URL
    - prolific_id_entered: Prolific ID entered by respondent
    - _distchannel: Distribution channel from Qualtrics
    - is_preview: Preview flag (created earlier)
    - start_date: Survey start date

    Usage:
        global attn_check_var "favorite_number"
        global attn_check_val = $ATTN_CHECK_PRESCREEN
        do "code/include/_create_quality_flags.do"
==============================================================================*/

* Incomplete flag
gen incomplete = (progress != 100 | _finished != 1)
label var incomplete "Incomplete response"

* Failed attention check
* Attention check value from survey (set via $attn_check_val global)
* Use ${} syntax to expand macro as variable name
gen failed_attn = (${attn_check_var} != $attn_check_val) if !mi(${attn_check_var})
replace failed_attn = 1 if mi(${attn_check_var})
label var failed_attn "Failed attention check"

* PID mismatch
gen pid_mismatch = (prolific_pid != prolific_id_entered)
label var pid_mismatch "Prolific PID mismatch"

* Flag first attempt per PID (sort by start_date, keep first)
bysort prolific_pid (start_date): gen first_attempt = (_n == 1)
label var first_attempt "First survey attempt for this PID"

* Duplicate PID (for reference/reporting only)
duplicates tag prolific_pid, gen(duplicate_pid)
replace duplicate_pid = (duplicate_pid > 0)
label var duplicate_pid "Duplicate Prolific PID"
