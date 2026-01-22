# VaccSideEffects Project

## Lab Notebook
**Review `notes/lab_notebook.md` at the start of each session** for recent changes and context. Update it throughout sessions with significant changes, decisions, or issues encountered.

## Overview
Research study examining vaccine side effects. Uses Stata for data processing/analysis and Python for documentation generation.

## Directory Structure
```
VaccSideEffects/
├── code/           # Stata do-files and Python scripts
├── raw_data/       # Minimal raw data for replication (SPSS + Prolific demographics)
├── derived/        # All derived/cleaned data files (.dta)
├── output/
│   ├── logs/       # Stata log files
│   ├── tables/     # CSV output tables (counts, balance, treatment effects)
│   ├── docs/       # Generated codebooks (markdown)
│   └── figures/    # Generated figures
├── design_materials/
├── notes/
└── Makefile        # Build automation
```

## Assumptions and text
Do not make any assumptions about the meaning of variables. For example you once assumed that the personal arm meant "testimonial" and wrote that in table notes. It doesn't mean that - it is academic research with a framing to seem personally relevant. The table notes should provide context from the code for what is in the table (e.g. table shows regression coefficient from a regression of y on treatment arm indicators), but should not provide info beyond what's in the code.

## table formatting
We use stata to export .tex files containing tables, for example table.tex.  These are used 
in a larger document with an input command, as in this example:
\begin{table}
\begin{tabular}{l cc} \\ \toprule
Header row c1 & Header row c2 & Header row c3 \\ \midrule
\input{table.tex} \\ 
\end{tabular}
\end{table}
The input part should therefore not contain any environment information (no \begin{table}) and it should not include column headers (which might contain specification numbers or variable names). Those get created once in a latex document, not every time the code generates table.tex.

Do not include vertical space in the tables. In the final line of the table, do not include the delimiter \\ because tex wants to see it in the main doc, not the input file.

## Build System
The project uses Make for build automation. Works on both Windows (Git Bash) and macOS:

```bash
# Windows (Git Bash)
cd /c/Users/sacks/Box/VaccSideEffects && make all

# macOS (Terminal)
cd ~/Library/CloudStorage/Box-Box/VaccSideEffects && make all
```

Available targets:
```bash
make prescreen    # Clean prescreen data and build codebook
make main         # Clean main survey data and build codebook
make followup     # Clean followup data and build codebook
make counts       # Generate sample size counts
make balance      # Generate balance table
make all          # Run prescreen, main, followup, and prolific pipelines
make help         # Show available targets
```

### Stata Command Flags
When adding Stata commands to the Makefile, use `-e` only:
```makefile
$(STATA) -e do $(CODE)/your_script.do
```
- `-e` exits Stata when the do-file completes (or errors)
- Logging is handled by `_config.do` (logs to `output/logs/` in batch mode)

Without `-e`, Stata will hang waiting for user input on errors, blocking the build.

## Code Conventions

### Stata Do-Files
Do-files work in both batch mode (via Make) and interactive mode (Stata GUI):

```stata
clear all
global scriptname "my_script"
do "code/_config.do"

* ... your code ...

capture log close
```

- Set `global scriptname` before including `_config.do`
- `_config.do` handles:
  - `$projdir` global for the project root (auto-detects Windows vs macOS)
  - Batch mode settings (`set more off`, etc.)
  - Creates output directories if needed
  - Opens log file in batch mode (to `output/logs/{scriptname}.log`)
- End scripts with `capture log close` (handles both modes gracefully)
- Use forward slashes in paths (works on Windows and Unix)

When there are comments in the code, for example about observation counts, they should be enforced with an assert.
For example if the comment says "Note 40 obs have var1 missing" there should be a line 
count if missing(var1) 
assert r(N)==40

### Python Scripts
- Located in `code/`
- Used for post-processing (e.g., building codebooks from Stata output)

## Data Pipelines
Each survey has its own pipeline: prescreen, main, followup

### Prescreen Pipeline
1. `clean_prescreen.do` - Cleans raw SPSS export from raw_data/, outputs to derived/
2. `summary_stats_prescreen.do` - Generates summary statistics CSVs
3. `build_codebook.py prescreen` - Combines stats into markdown codebook

### Main Survey Pipeline
4-arm RCT (Control, Industry, Academic, Personal) examining vaccine information sources.

1. `clean_main.do` - Cleans raw SPSS export, creates treatment arm variables
2. `summary_stats_main.do` - Generates summary statistics CSVs
3. `build_codebook.py main` - Combines stats into markdown codebook

### Sample Selection
Final samples are defined as first attempt per PID passing all quality checks:
- **Prescreen**: consent + attention check + first attempt + hesitant (vacc_intent <= 2)
- **Main**: linked to prescreen final + consent + attention + non-missing delta + first attempt
- **Followup**: linked to main final + attention + non-missing outcome + first attempt

**Key variables:**
- `arm_n` (0-3): Treatment arm assignment
- `post_trial`: Post-treatment side effect estimate (0-100)
- `posterior_novacc`, `posterior_vacc`: Posterior beliefs
- `delta`: posterior_vacc - posterior_novacc
- `maybe`: Binary vaccination intention

## Key Files
- `code/_config.do` - Project configuration, include in all do-files
- `Makefile` - Build automation and dependency tracking
- `output/docs/prescreen_codebook.md` - Prescreen variable documentation
- `output/docs/main_codebook.md` - Main survey variable documentation
