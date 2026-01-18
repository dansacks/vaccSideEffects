#!/usr/bin/env python3
"""
Build Codebook with Summary Statistics

Reads statistics from Stata-generated CSV files and merges them into
the markdown codebook template.

Input (prescreen):
    - output/tables/stats_continuous.csv
    - output/tables/stats_categorical.csv
    - output/docs/prescreen_codebook.md (template)

Input (main):
    - output/tables/stats_main_continuous.csv
    - output/tables/stats_main_categorical.csv
    - output/docs/main_codebook.md (template)

Input (followup):
    - output/tables/stats_followup_continuous.csv
    - output/tables/stats_followup_categorical.csv
    - output/docs/followup_codebook.md (template)

Usage:
    python code/build_codebook.py              # defaults to prescreen
    python code/build_codebook.py prescreen    # prescreen data
    python code/build_codebook.py main         # main survey data
    python code/build_codebook.py followup     # followup survey data

Created by Dan + Claude Code
"""

import csv
import re
import sys
from pathlib import Path


def read_continuous_stats(filepath):
    """Read continuous variable statistics from CSV."""
    stats = {}
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            var = row['variable']
            stats[var] = {
                'n': int(float(row['n'])),
                'mean': float(row['mean']),
                'sd': float(row['sd']),
                'min': float(row['min']),
                'median': float(row['p50']),
                'max': float(row['max'])
            }
    return stats


def read_categorical_stats(filepath): 
    """Read categorical variable statistics from CSV."""
    stats = {}
    with open(filepath, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            var = row['variable']
            val = row['value']
            n = int(float(row['n']))
            pct = float(row['pct'])

            if var not in stats:
                stats[var] = {}

            # Handle missing values (represented as ".")
            if val == '.':
                stats[var]['missing'] = {'n': n, 'pct': pct}
            else:
                # Try to parse as int, fall back to float, then string
                try:
                    val_key = int(float(val))
                except ValueError:
                    val_key = val
                stats[var][val_key] = {'n': n, 'pct': pct}

    return stats


def format_n_pct(n, pct):
    """Format N and percentage as string like '4,413 (56.05%)'."""
    return f"{n:,} ({pct:.2f}%)"


def update_value_table(table_lines, var_stats):
    """
    Update a markdown value table to include N (%) column.

    Input table format:
    | Code | Label |
    |------|-------|
    | 0 | No |
    | 1 | Yes |

    Output table format:
    | Code | Label | N (%) |
    |------|-------|-------|
    | 0 | No | 4,413 (56.05%) |
    | 1 | Yes | 3,435 (43.63%) |
    """
    if len(table_lines) < 3:
        return table_lines  # Not enough lines for a table

    new_lines = []

    for i, line in enumerate(table_lines):
        if i == 0:  # Header row
            # Add N (%) column header
            new_lines.append(line.rstrip() + ' N (%) |')
        elif i == 1:  # Separator row
            # Add separator for new column
            new_lines.append(line.rstrip() + '-------|')
        else:
            # Data row - extract the code value and look up stats
            # Parse: | Code | Label |
            parts = line.split('|')
            if len(parts) >= 3:
                code_str = parts[1].strip()
                try:
                    code = int(code_str)
                except ValueError:
                    try:
                        code = float(code_str)
                    except ValueError:
                        code = code_str

                # Look up stats for this value
                if code in var_stats:
                    n_pct = format_n_pct(var_stats[code]['n'], var_stats[code]['pct'])
                else:
                    n_pct = '-'

                new_lines.append(line.rstrip() + f' {n_pct} |')
            else:
                new_lines.append(line)

    return new_lines


def find_and_update_tables(content, cat_stats):
    """
    Find value tables in markdown and update them with statistics.
    """
    lines = content.split('\n')
    new_lines = []
    i = 0

    # Pattern to match variable headers like ### `flu_vax_lastyear`
    var_pattern = re.compile(r'^### `(\w+)`')

    current_var = None

    while i < len(lines):
        line = lines[i]

        # Check if this is a variable header
        match = var_pattern.match(line)
        if match:
            current_var = match.group(1)
            new_lines.append(line)
            i += 1
            continue

        # Check if this starts a value table (| Code | Label |) that doesn't already have stats
        # Use exact match to avoid re-adding N (%) column on subsequent runs
        if line.strip() == '| Code | Label |' and current_var in cat_stats:
            # Collect all table lines
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith('|'):
                table_lines.append(lines[i])
                i += 1

            # Update the table with statistics
            updated_table = update_value_table(table_lines, cat_stats[current_var])
            new_lines.extend(updated_table)
            continue

        new_lines.append(line)
        i += 1

    return '\n'.join(new_lines)


def add_continuous_stats(content, cont_stats):
    """
    Add summary statistics for continuous variables.
    """
    for var, stats in cont_stats.items():
        # Find the variable section and add stats after the label line
        pattern = rf'(### `{var}`\n.*?- \*\*Label:\*\* [^\n]+)'

        stats_table = f"""
- **Summary Statistics (N={stats['n']:,}):**

| Statistic | Value |
|-----------|-------|
| Mean | {stats['mean']:,.1f} |
| SD | {stats['sd']:,.1f} |
| Min | {stats['min']:,.0f} |
| Median | {stats['median']:,.0f} |
| Max | {stats['max']:,.0f} |"""

        def add_stats(match):
            return match.group(1) + stats_table

        content = re.sub(pattern, add_stats, content, flags=re.DOTALL)

    return content


def update_binary_indicator_table(content, cat_stats):
    """
    Update the binary indicators table in Information Sources section.
    This table has a different format: | Variable | Label |
    """
    # Find the binary indicators table
    pattern = r'(\| Variable \| Label \|\n\|----------\|-------\|)'
    match = re.search(pattern, content)
    if match:
        # Find all source_* variables in the table
        source_vars = ['source_doctor', 'source_sm', 'source_podcasts',
                       'source_cdc', 'source_news', 'source_none']

        # Update the header
        new_header = '| Variable | Label | N (%) Yes |'
        new_sep = '|----------|-------|-----------|'

        content = content.replace('| Variable | Label |', new_header)
        content = content.replace('|----------|-------|', new_sep)

        # Update each row
        for var in source_vars:
            if var in cat_stats and 1 in cat_stats[var]:
                n_pct = format_n_pct(cat_stats[var][1]['n'], cat_stats[var][1]['pct'])
                old_pattern = rf'(\| `{var}` \| [^|]+ \|)'
                new_text = rf'\1 {n_pct} |'
                content = re.sub(old_pattern, new_text, content)

    return content


def main():
    # Parse command line argument
    dataset = sys.argv[1] if len(sys.argv) > 1 else 'prescreen'

    if dataset not in ['prescreen', 'main', 'followup']:
        print(f"Error: Unknown dataset '{dataset}'. Use 'prescreen', 'main', or 'followup'.")
        sys.exit(1)

    # Set up paths
    proj_dir = Path(__file__).parent.parent
    output_dir = proj_dir / 'output'

    # Set file paths based on dataset
    if dataset == 'prescreen':
        cont_stats_file = output_dir / 'tables/stats_continuous.csv'
        cat_stats_file = output_dir / 'tables/stats_categorical.csv'
        template_path = output_dir / 'docs/prescreen_codebook_template.md'
        codebook_path = output_dir / 'docs/prescreen_codebook.md'
    elif dataset == 'main':
        cont_stats_file = output_dir / 'tables/stats_main_continuous.csv'
        cat_stats_file = output_dir / 'tables/stats_main_categorical.csv'
        template_path = output_dir / 'docs/main_codebook_template.md'
        codebook_path = output_dir / 'docs/main_codebook.md'
    else:  # followup
        cont_stats_file = output_dir / 'tables/stats_followup_continuous.csv'
        cat_stats_file = output_dir / 'tables/stats_followup_categorical.csv'
        template_path = output_dir / 'docs/followup_codebook_template.md'
        codebook_path = output_dir / 'docs/followup_codebook.md'

    print(f"Building codebook for: {dataset}")

    # Read statistics
    print("Reading statistics from CSV files...")
    cont_stats = read_continuous_stats(cont_stats_file)
    cat_stats = read_categorical_stats(cat_stats_file)

    print(f"  Continuous variables: {len(cont_stats)}")
    print(f"  Categorical variables: {len(cat_stats)}")

    # Read markdown template
    print(f"Reading markdown codebook template from {template_path}...")
    with open(template_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Update tables with categorical statistics
    print("Updating categorical variable tables...")
    content = find_and_update_tables(content, cat_stats)

    # Update binary indicator table (prescreen only has this special table)
    if dataset == 'prescreen':
        print("Updating binary indicator tables...")
        content = update_binary_indicator_table(content, cat_stats)

    # Add continuous variable statistics
    print("Adding continuous variable statistics...")
    content = add_continuous_stats(content, cont_stats)

    # Write updated codebook
    print("Writing updated codebook...")
    with open(codebook_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print(f"\nDone! Updated codebook saved to: {codebook_path}")


if __name__ == '__main__':
    main()
