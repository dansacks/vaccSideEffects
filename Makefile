#===============================================================================
# VaccSideEffects Project Makefile
#
# Usage:
#   make prescreen   - Clean prescreen data and build codebook
#   make main        - Clean main data and build codebook
#   make followup    - Clean followup data
#   make merge       - Merge prescreen and main data
#   make counts      - Generate sample size counts
#   make balance     - Generate main balance table
#   make balance-full - Generate balance tables by domain + omnibus test
#   make exhibits    - Compile exhibits.pdf (all tables/figures)
#   make all         - Run prescreen, main, and followup pipelines
#   make dirs        - Create output subdirectories
#   make clean-data  - Remove .dta files only (force rebuild)
#   make clean-all   - Remove all generated files
#   make help        - Show available targets
#
# Run from project directory: cd /path/to/VaccSideEffects && make all
#===============================================================================

# Configuration - OS detection and auto-detect project directory
UNAME_S := $(shell uname -s)
PROJDIR := $(CURDIR)
ifeq ($(UNAME_S),Darwin)
    # macOS
    STATA := /Applications/StataNow/StataSE.app/Contents/MacOS/stata-se
else
    # Windows (Git Bash)
    STATA := "/c/Program Files/Stata17/StataMP-64.exe"
endif
PYTHON := python3

# Directories
RAW_DATA := $(PROJDIR)/raw_data
DERIVED := $(PROJDIR)/derived
CODE := $(PROJDIR)/code
INCLUDE := $(CODE)/include
OUTPUT := $(PROJDIR)/output
OUT_LOGS := $(OUTPUT)/logs
OUT_TABLES := $(OUTPUT)/tables
OUT_DOCS := $(OUTPUT)/docs
OUT_FIGURES := $(OUTPUT)/figures

#-------------------------------------------------------------------------------
# Phony Targets (convenience commands)
#-------------------------------------------------------------------------------
.PHONY: all prescreen main followup merge prolific counts balance balance-full analysis beliefs exhibits dirs clean-data clean-all help

all: prescreen main followup prolific counts balance

help:
	@echo "Available targets:"
	@echo "  prescreen    - Clean prescreen data and build codebook"
	@echo "  main         - Clean main study data and build codebook"
	@echo "  followup     - Clean followup data and build codebook"
	@echo "  merge        - Merge prescreen, main, and followup data"
	@echo "  prolific     - Clean prolific demographic exports"
	@echo "  counts       - Generate sample size counts"
	@echo "  balance      - Generate main balance table"
	@echo "  balance-full - Generate balance tables by domain + omnibus test"
	@echo "  analysis     - Run treatment effects regressions"
	@echo "  beliefs      - Generate belief distribution figures"
	@echo "  exhibits     - Compile exhibits.pdf (all tables/figures)"
	@echo "  all          - Run prescreen, main, followup, and prolific pipelines"
	@echo "  dirs         - Create output subdirectories"
	@echo "  clean-data   - Remove .dta files only (force rebuild)"
	@echo "  clean-all    - Remove all generated files"

# Create output directories
dirs:
	mkdir -p $(OUT_LOGS) $(OUT_TABLES) $(OUT_DOCS) $(OUT_FIGURES) $(DERIVED)

#-------------------------------------------------------------------------------
# PRESCREEN PIPELINE
#-------------------------------------------------------------------------------
# Prescreen imports from SPSS in raw_data directory
PRESCREEN_SPSS := $(RAW_DATA)/vacc_se_prescreen_full_January+9,+2026_19.47.sav
PRESCREEN_CLEAN := $(DERIVED)/prescreen_clean.dta
PRESCREEN_STATS_CONT := $(OUT_TABLES)/stats_continuous.csv
PRESCREEN_STATS_CAT := $(OUT_TABLES)/stats_categorical.csv
PRESCREEN_CODEBOOK_TEMPLATE := $(OUT_DOCS)/prescreen_codebook_template.md
PRESCREEN_CODEBOOK := $(OUT_DOCS)/prescreen_codebook.md

prescreen: dirs $(PRESCREEN_CODEBOOK)

# Include files (shared across cleaning scripts)
INCLUDE_FILES := $(INCLUDE)/_rename_qualtrics_metadata.do $(INCLUDE)/_define_value_labels.do \
                 $(INCLUDE)/_create_quality_flags.do $(INCLUDE)/_report_sample_quality.do

# Step 1: Clean raw SPSS data (imports directly from .sav file)
$(PRESCREEN_CLEAN): $(PRESCREEN_SPSS) $(CODE)/clean_prescreen.do $(CODE)/_config.do $(INCLUDE_FILES)
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/clean_prescreen.do && mv clean_prescreen.log $(OUT_LOGS)/

# Step 2: Generate summary statistics (both outputs from single run)
$(PRESCREEN_STATS_CONT) $(PRESCREEN_STATS_CAT) &: $(PRESCREEN_CLEAN) $(CODE)/summary_stats_prescreen.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/summary_stats_prescreen.do && mv summary_stats_prescreen.log $(OUT_LOGS)/

# Step 3: Build codebook with statistics
$(PRESCREEN_CODEBOOK): $(PRESCREEN_STATS_CONT) $(PRESCREEN_STATS_CAT) $(PRESCREEN_CODEBOOK_TEMPLATE) $(CODE)/build_codebook.py
	cd $(PROJDIR) && $(PYTHON) $(CODE)/build_codebook.py prescreen

#-------------------------------------------------------------------------------
# MAIN STUDY PIPELINE
#-------------------------------------------------------------------------------
# Main imports from SPSS in raw_data directory
MAIN_SPSS := $(RAW_DATA)/flu_survey_main_January+9,+2026_08.08.sav
MAIN_CLEAN := $(DERIVED)/main_clean.dta
MAIN_STATS_CONT := $(OUT_TABLES)/stats_main_continuous.csv
MAIN_STATS_CAT := $(OUT_TABLES)/stats_main_categorical.csv
MAIN_CODEBOOK_TEMPLATE := $(OUT_DOCS)/main_codebook_template.md
MAIN_CODEBOOK := $(OUT_DOCS)/main_codebook.md

main: dirs $(MAIN_CODEBOOK)

# Step 1: Clean raw SPSS data (imports directly from .sav file)
$(MAIN_CLEAN): $(MAIN_SPSS) $(CODE)/clean_main.do $(CODE)/_config.do $(INCLUDE_FILES)
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/clean_main.do && mv clean_main.log $(OUT_LOGS)/

# Step 2: Generate summary statistics (both outputs from single run)
$(MAIN_STATS_CONT) $(MAIN_STATS_CAT) &: $(MAIN_CLEAN) $(CODE)/summary_stats_main.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/summary_stats_main.do && mv summary_stats_main.log $(OUT_LOGS)/

# Step 3: Build codebook with statistics
$(MAIN_CODEBOOK): $(MAIN_STATS_CONT) $(MAIN_STATS_CAT) $(MAIN_CODEBOOK_TEMPLATE) $(CODE)/build_codebook.py
	cd $(PROJDIR) && $(PYTHON) $(CODE)/build_codebook.py main

#-------------------------------------------------------------------------------
# MERGED DATA
#-------------------------------------------------------------------------------
MERGED_PRE := $(DERIVED)/merged_main_pre.dta
MERGED_ALL := $(DERIVED)/merged_all.dta
COUNTS := $(OUT_TABLES)/counts.csv
BALANCE_CSV := $(OUT_TABLES)/balance_table.csv
BALANCE_TEX := $(OUT_TABLES)/balance_table.tex

merge: $(MERGED_ALL)

# Step 1: Merge prescreen and main
$(MERGED_PRE): $(PRESCREEN_CLEAN) $(MAIN_CLEAN) $(CODE)/merge_prescreen_main.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/merge_prescreen_main.do && mv merge_prescreen_main.log $(OUT_LOGS)/

# Step 2: Merge followup with prescreen+main
$(MERGED_ALL): $(MERGED_PRE) $(FOLLOWUP_CLEAN) $(CODE)/merge_followup.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/merge_followup.do && mv merge_followup.log $(OUT_LOGS)/

# Count sample sizes (depends on prolific demographics for matching counts)
counts: $(COUNTS)

$(COUNTS): $(PRESCREEN_CLEAN) $(MAIN_CLEAN) $(FOLLOWUP_CLEAN) \
		$(PROLIFIC_PRE) $(PROLIFIC_MAIN) $(PROLIFIC_MAIN_MP) $(PROLIFIC_FU) \
		$(CODE)/count_sample_size.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/count_sample_size.do && mv count_sample_size.log $(OUT_LOGS)/

# Balance table (main)
balance: $(BALANCE_CSV)

$(BALANCE_CSV) $(BALANCE_TEX) &: $(MERGED_PRE) $(CODE)/balance_table.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/balance_table.do && mv balance_table.log $(OUT_LOGS)/

# Full balance tables by domain
BALANCE_PRIOR := $(OUT_TABLES)/balance_prior_beliefs.tex
BALANCE_INTENT := $(OUT_TABLES)/balance_vacc_intent.tex
BALANCE_VACC_EXP := $(OUT_TABLES)/balance_vacc_experience.tex
BALANCE_DEMO := $(OUT_TABLES)/balance_demographics.tex
BALANCE_TRUST := $(OUT_TABLES)/balance_trust_health.tex
BALANCE_OMNI := $(OUT_TABLES)/balance_omnibus.tex

balance-full: $(BALANCE_OMNI)

$(BALANCE_PRIOR) $(BALANCE_INTENT) $(BALANCE_VACC_EXP) $(BALANCE_DEMO) $(BALANCE_TRUST) $(BALANCE_OMNI) &: $(MERGED_PRE) $(CODE)/balance_tables_full.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/balance_tables_full.do && mv balance_tables_full.log $(OUT_LOGS)/
	@# Escape $ followed by digits for LaTeX (e.g., $25k -> \$25k)
	sed -i '' 's/\$$\([0-9]\)/\\$$\1/g' $(OUT_TABLES)/balance_demographics.tex

#-------------------------------------------------------------------------------
# FOLLOWUP PIPELINE
#-------------------------------------------------------------------------------
# Followup imports from SPSS in raw_data directory
FOLLOWUP_SPSS := $(RAW_DATA)/flu_vacc_se_followup_January+9,+2026_19.43.sav
FOLLOWUP_CLEAN := $(DERIVED)/followup_clean.dta
FOLLOWUP_STATS_CONT := $(OUT_TABLES)/stats_followup_continuous.csv
FOLLOWUP_STATS_CAT := $(OUT_TABLES)/stats_followup_categorical.csv
FOLLOWUP_CODEBOOK_TEMPLATE := $(OUT_DOCS)/followup_codebook_template.md
FOLLOWUP_CODEBOOK := $(OUT_DOCS)/followup_codebook.md

followup: dirs $(FOLLOWUP_CODEBOOK)

# Step 1: Clean raw SPSS data (imports directly from .sav file)
$(FOLLOWUP_CLEAN): $(FOLLOWUP_SPSS) $(CODE)/clean_followup.do $(CODE)/_config.do $(INCLUDE_FILES)
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/clean_followup.do && mv clean_followup.log $(OUT_LOGS)/

# Step 2: Generate summary statistics (both outputs from single run)
$(FOLLOWUP_STATS_CONT) $(FOLLOWUP_STATS_CAT) &: $(FOLLOWUP_CLEAN) $(CODE)/summary_stats_followup.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/summary_stats_followup.do && mv summary_stats_followup.log $(OUT_LOGS)/

# Step 3: Build codebook with statistics
$(FOLLOWUP_CODEBOOK): $(FOLLOWUP_STATS_CONT) $(FOLLOWUP_STATS_CAT) $(FOLLOWUP_CODEBOOK_TEMPLATE) $(CODE)/build_codebook.py
	cd $(PROJDIR) && $(PYTHON) $(CODE)/build_codebook.py followup

#-------------------------------------------------------------------------------
# PROLIFIC DEMOGRAPHICS
#-------------------------------------------------------------------------------
PROLIFIC_PRE_CSV := $(RAW_DATA)/prolific_demographic_export_692494f77a877e57e000eb60.csv
PROLIFIC_MAIN_CSV := $(RAW_DATA)/prolific_demographic_export_main.csv
PROLIFIC_MAIN_MP_CSV := $(RAW_DATA)/prolific_demographic_export_main_morepay.csv
PROLIFIC_FU_CSV := $(RAW_DATA)/prolific_demographic_export_followup.csv

PROLIFIC_PRE := $(DERIVED)/prolific_demographics_prescreen.dta
PROLIFIC_MAIN := $(DERIVED)/prolific_demographics_main.dta
PROLIFIC_MAIN_MP := $(DERIVED)/prolific_demographics_main_morepay.dta
PROLIFIC_FU := $(DERIVED)/prolific_demographics_followup.dta

prolific: $(PROLIFIC_PRE) $(PROLIFIC_MAIN) $(PROLIFIC_MAIN_MP) $(PROLIFIC_FU)

# All four outputs from single run
$(PROLIFIC_PRE) $(PROLIFIC_MAIN) $(PROLIFIC_MAIN_MP) $(PROLIFIC_FU) &: \
		$(PROLIFIC_PRE_CSV) $(PROLIFIC_MAIN_CSV) $(PROLIFIC_MAIN_MP_CSV) $(PROLIFIC_FU_CSV) \
		$(CODE)/clean_prolific_demographics.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/clean_prolific_demographics.do && mv clean_prolific_demographics.log $(OUT_LOGS)/

#-------------------------------------------------------------------------------
# ANALYSIS
#-------------------------------------------------------------------------------
TREATMENT_EFFECTS := $(OUT_TABLES)/treatment_effects.tex

analysis: $(TREATMENT_EFFECTS)

$(TREATMENT_EFFECTS): $(MERGED_ALL) $(CODE)/treatment_effects.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/treatment_effects.do && mv treatment_effects.log $(OUT_LOGS)/

#-------------------------------------------------------------------------------
# BELIEF ANALYSIS FIGURES
#-------------------------------------------------------------------------------
BELIEFS_POOLED := $(OUT_FIGURES)/beliefs_pooled.png
BELIEFS_VACC := $(OUT_FIGURES)/delta_by_vacc_reaction.png
BELIEFS_TRUST := $(OUT_FIGURES)/delta_by_trust.png
BELIEFS_BY_ARM := $(OUT_FIGURES)/belief_cdf_by_arm.png

beliefs: $(BELIEFS_POOLED) $(BELIEFS_BY_ARM)

# explore_beliefs.do produces pooled CDF, vaccine reaction, and trust figures
$(BELIEFS_POOLED) $(BELIEFS_VACC) $(BELIEFS_TRUST) &: $(MERGED_PRE) $(CODE)/explore_beliefs.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/explore_beliefs.do && mv explore_beliefs.log $(OUT_LOGS)/

# plot_beliefs_by_arm.do produces CDF by treatment arm
$(BELIEFS_BY_ARM): $(MERGED_PRE) $(CODE)/plot_beliefs_by_arm.do $(CODE)/_config.do
	cd $(PROJDIR) && $(STATA) -e do $(CODE)/plot_beliefs_by_arm.do && mv plot_beliefs_by_arm.log $(OUT_LOGS)/

#-------------------------------------------------------------------------------
# EXHIBITS DOCUMENT
#-------------------------------------------------------------------------------
EXHIBITS_TEX := $(OUTPUT)/exhibits.tex
EXHIBITS_PDF := $(OUTPUT)/exhibits.pdf

exhibits: $(EXHIBITS_PDF)

$(EXHIBITS_PDF): $(EXHIBITS_TEX) $(BALANCE_TEX) $(BALANCE_OMNI) $(TREATMENT_EFFECTS) $(BELIEFS_POOLED) $(BELIEFS_BY_ARM)
	cd $(OUTPUT) && pdflatex exhibits.tex && pdflatex exhibits.tex

#-------------------------------------------------------------------------------
# Clean targets
#-------------------------------------------------------------------------------

# Remove only .dta files to force full rebuild
clean-data:
	rm -f $(DERIVED)/prescreen_clean.dta
	rm -f $(DERIVED)/main_clean.dta
	rm -f $(DERIVED)/merged_main_pre.dta
	rm -f $(DERIVED)/merged_all.dta
	rm -f $(DERIVED)/followup_clean.dta
	rm -f $(DERIVED)/prolific_demographics_*.dta

# Full clean (use sparingly - removes all generated outputs)
clean-all: clean-data
	rm -f $(OUT_TABLES)/*.csv
	rm -f $(OUT_DOCS)/*.md $(OUT_DOCS)/*.html
