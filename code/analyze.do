* analyze.do - Master script for analysis
* Run interactively: do "code/analyze.do"



do "code/balance_table.do"
do "code/balance_tables_full.do"

do "code/delta_predictors"

do "code/counts_by_arm.do"
do "code/treatment_effects.do"
do "code/trust_relevance_effects.do"
do "code/delta_predictors.do"
do "code/heterogeneous_treatment_effects"
do "code/hte_flu_vacc_experience"
do "code/pca_lasso_hte"



do "code/pca_lasso_hte"

do "code/explore_persistence.do"
do "code/explore_beliefs.do"
do "code/plot_beliefs_by_arm.do"

do "code/plot_info_by_hes.do"
do "code/plot_peds_flu_vacc.do"

** not used in paper:
do "code/te_by_polviews"
do "code/validate_polviews_delta"
