
use "derived/merged_all.dta" if main_sample, clear

gen both_correct = placebo_correct ==1 & vaccine_correct == 1
sum both_correct if ~missing(placebo_correct) & ~missing(vaccine_correct)

