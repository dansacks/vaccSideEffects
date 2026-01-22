* build.do - Master script for data cleaning and merging
* Run interactively: do "code/build.do"

do "code/clean_prescreen.do"
do "code/clean_main.do"
do "code/clean_followup.do"
do "code/clean_prolific_demographics.do"
do "code/merge_prescreen_main.do"
do "code/merge_followup.do"
