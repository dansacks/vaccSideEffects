/*==============================================================================
    Report Sample Quality Flags

    This include file provides standardized quality reporting for all surveys.
    Requires the following variables to exist:
    - final_sample, incomplete, failed_attn, pid_mismatch, duplicate_pid, is_preview

    Usage: do "code/include/_report_sample_quality.do"
==============================================================================*/

di ""
di "=== QUALITY FLAG SUMMARY ==="
count
di "Total observations: " r(N)
count if final_sample == 1
di "Final sample: " r(N)
count if incomplete == 1
di "Incomplete: " r(N)
count if failed_attn == 1
di "Failed attention check: " r(N)
count if pid_mismatch == 1
di "PID mismatch: " r(N)
count if duplicate_pid == 1
di "Duplicate PIDs: " r(N)
count if is_preview == 1
di "Preview responses: " r(N)
