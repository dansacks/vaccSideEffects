# plot_to_csv Documentation

## Overview

`plot_to_csv` is a Stata ado file that exports the underlying data from an in-memory graph to a CSV file. This enables version control of plot data - the CSV can be committed to git, and diffs will show exactly what changed in the plotted values.

## Installation

The ado file is located at `code/include/plot_to_csv.ado`. The `code/_config.do` script adds this directory to Stata's adopath, making the command available in all project do-files that include `_config.do`.

## How It Works

When Stata creates a `twoway` graph, it stores the plotted data in internal structures called "sersets". The `plot_to_csv` command:

1. Verifies a graph exists in memory
2. Uses `serset dir` to find all sersets associated with the graph
3. Uses `serset use` to load each serset's data
4. Exports the data to CSV

For multi-series plots (e.g., `twoway (line y1 x) (line y2 x)`), each series is stored in a separate serset. By default, `plot_to_csv` exports all sersets and adds a `_serset` column to identify which series each row belongs to.

## Syntax

```stata
plot_to_csv using filename [, replace name(graphname) serset(#)]
```

### Required

- `using filename` - Path to output CSV file (must end in `.csv`)

### Options

| Option | Description |
|--------|-------------|
| `replace` | Overwrite existing file |
| `name(graphname)` | Export a specific named graph (default: current graph) |
| `serset(#)` | Export only serset number # (default: all sersets) |

## Examples

### Basic Usage

```stata
* Create a scatter plot
twoway scatter y x

* Export to CSV
plot_to_csv using "output/figures/scatter.csv", replace
```

### Multi-Series Plot

```stata
* Create multi-line plot
twoway (line y1 x) (line y2 x)

* Export all series (adds _serset column)
plot_to_csv using "output/figures/lines.csv", replace
```

Output CSV will have columns: `_serset`, `y1` (or `y2`), `x`

### Named Graph

```stata
* Create named graphs
twoway scatter y x, name(graph1, replace)
twoway scatter z x, name(graph2, replace)

* Export specific graph
plot_to_csv using "output/figures/graph1_data.csv", replace name(graph1)
```

### Export Single Series

```stata
* Multi-series plot
twoway (scatter y1 x) (scatter y2 x)

* Export only the first series
plot_to_csv using "output/figures/series1.csv", replace serset(1)
```

### With CDF Plots

```stata
* Create CDF
cumul myvar, gen(cdf)
sort myvar cdf
twoway line cdf myvar

* Export CDF data
plot_to_csv using "output/figures/cdf.csv", replace
```

## Error Conditions

| Error Code | Condition |
|------------|-----------|
| 198 | No graph in memory |
| 198 | Named graph doesn't exist |
| 198 | Invalid serset number |
| 198 | File path doesn't end in `.csv` |
| 602 | File exists and `replace` not specified |

## Notes

- The command preserves your current dataset - original data is unchanged after export
- Variable names in the CSV match those used in the graph
- For bar charts, the serset contains the bar heights and positions
- For histograms, sersets contain bin edges and frequencies

## Testing

Unit tests are in `code/test_plot_to_csv.do`. Run with:

```stata
do "code/test_plot_to_csv.do"
```

### Test Coverage

The test suite includes 14 tests covering:

1. **Value verification** - Exact integer values exported correctly
2. **Negative values** - Negative integers preserved
3. **Multi-series** - Multiple sersets exported with `_serset` column
4. **Named graphs** - Correct graph exported when multiple exist
5. **Single serset** - `serset()` option works correctly
6. **Data preservation** - Original dataset unchanged after export
7. **No graph error** - Proper error when no graph in memory
8. **Named graph error** - Proper error for non-existent graph name
9. **Extension error** - Rejects non-.csv files
10. **Replace error** - Requires `replace` for existing files
11. **Invalid serset error** - Proper error for out-of-range serset
12. **Single observation** - Works with n=1
13. **Large values** - Handles large integers correctly
14. **CDF plots** - Works with cumul-generated data

All tests use integer arithmetic where possible to avoid floating-point comparison issues.

## Version History

- v2.0.0 - Rewrote to use serset system for extracting actual plotted data
- v1.0.0 - Initial version (variable-based export)
