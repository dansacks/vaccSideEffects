/*==============================================================================
    Rename Standard Qualtrics Metadata Variables

    This include file standardizes the renaming of Qualtrics metadata variables
    that are common across all survey exports (prescreen, main, followup).

    Must be called after import spss and before variable-specific cleaning.

    Usage: do "code/include/_rename_qualtrics_metadata.do"
==============================================================================*/

* Rename Qualtrics metadata to clean names
rename StartDate start_date
rename EndDate end_date
rename Duration__in_seconds_ duration_sec
rename Finished _finished
rename ResponseId response_id
rename IPAddress _ipaddress
rename LocationLatitude _lat
rename LocationLongitude _long
rename Status _status
rename RecordedDate _recordeddate
rename DistributionChannel _distchannel
rename UserLanguage _userlang

* Rename Progress if it exists (some surveys already have lowercase)
capture rename Progress progress
