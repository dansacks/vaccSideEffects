/*==============================================================================
    Control Variables Definition

    Include this file in do-files that run regressions with control variables.
    Sets globals: prior_beliefs, vacc_experience, demographics, controls
==============================================================================*/

* Prior beliefs from main survey
global prior_beliefs "i.prior_self_placebo i.prior_self_vacc"

* Vaccine experiences from prescreen
global vacc_experience "had_prior_covid_vacc had_prior_flu_vacc i.covid_vacc_reaction i.flu_vacc_reaction"

* Demographics from main survey
global demographics "i.age i.gender i.education i.income i.race i.ethnicity i.polviews"

* All controls combined
global controls "$prior_beliefs i.pre_vacc_intent $vacc_experience $demographics i.trust_govt cond_*"
