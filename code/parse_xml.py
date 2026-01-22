#!/usr/bin/env python3
"""
Parse Qualtrics XML Export to Stata Dataset

Usage: python parse_xml.py <survey_name> [xml_filename]

Arguments:
    survey_name: One of 'prescreen', 'main', 'followup'
    xml_filename: Optional specific XML filename (without path)

Examples:
    python parse_xml.py prescreen
    python parse_xml.py main
    python parse_xml.py followup
    python parse_xml.py prescreen vacc_se_prescreen_full_January+8,+2026_16.33.xml

Parses Qualtrics XML export and saves as Stata dataset.
- Preserves preview data (flagged with is_preview=1)
- Drops only true metadata (placeholder PIDs like {{%PROLIFIC_PID%}})
- Asserts no real data is lost

Created by Dan + Claude Code
"""

import pandas as pd
import xml.etree.ElementTree as ET
from pathlib import Path
import re
import sys
import argparse


# Default XML filenames for each survey
DEFAULT_XML_FILES = {
    'prescreen': 'vacc_se_prescreen_full_January+8,+2026_16.33.xml',
    'main': 'flu_survey_main_January+8,+2026_16.30.xml',
    'followup': 'flu_vacc_se_followup_January+8,+2026_18.39.xml',
}

# Output filenames
OUTPUT_FILES = {
    'prescreen': 'prescreen_raw.dta',
    'main': 'main_raw.dta',
    'followup': 'followup_raw.dta',
}


def parse_qualtrics_xml(xml_path):
    """Parse Qualtrics XML export into a DataFrame."""
    print(f"Parsing XML file: {xml_path}")

    tree = ET.parse(xml_path)
    root = tree.getroot()

    # Collect all responses
    responses = []
    for response in root.findall('Response'):
        row = {}
        for child in response:
            tag = child.tag
            row[tag] = child.text if child.text else ''
        responses.append(row)

    df = pd.DataFrame(responses)
    print(f"  Parsed {len(df)} responses with {len(df.columns)} columns")
    return df


def is_valid_prolific_id(pid):
    """Check if a string looks like a valid Prolific ID (24-char hex string)."""
    if pd.isna(pid) or pid == '':
        return False
    # Prolific IDs are 24-character hex strings
    return bool(re.match(r'^[a-f0-9]{24}$', str(pid).strip()))


def is_placeholder_pid(pid):
    """Check if a PID is a Qualtrics placeholder like {{%PROLIFIC_PID%}}."""
    if pd.isna(pid) or pid == '':
        return False
    return '{{%' in str(pid) or '%}}' in str(pid)


def classify_rows(df):
    """
    Classify rows into: real data, preview data, and metadata (to drop).

    Returns:
        is_preview: Boolean series - True for preview responses (keep, but flag)
        is_metadata: Boolean series - True for metadata to drop (placeholder PIDs)
    """
    # Check for preview distribution channel
    is_preview_channel = df['distributionChannel'] == 'preview'

    # Check for preview status
    is_preview_status = df['status'] == 'Survey Preview'

    # Check for placeholder PID (test entries with {{%PROLIFIC_PID%}})
    has_placeholder_pid = df['PROLIFIC_PID'].apply(is_placeholder_pid)

    # Preview rows: preview channel/status but NOT placeholder PIDs
    # These are real preview runs that should be kept but flagged
    is_preview = (is_preview_channel | is_preview_status) & ~has_placeholder_pid

    # Metadata rows: placeholder PIDs (these are templates, not real responses)
    is_metadata = has_placeholder_pid

    return is_preview, is_metadata


def main():
    parser = argparse.ArgumentParser(
        description='Parse Qualtrics XML export to Stata dataset'
    )
    parser.add_argument(
        'survey',
        choices=['prescreen', 'main', 'followup'],
        help='Survey name: prescreen, main, or followup'
    )
    parser.add_argument(
        'xml_file',
        nargs='?',
        default=None,
        help='Optional: specific XML filename (in data directory)'
    )

    args = parser.parse_args()

    # Set up paths
    proj_dir = Path(__file__).parent.parent
    data_dir = proj_dir / 'data'

    # Get input/output files
    xml_filename = args.xml_file or DEFAULT_XML_FILES[args.survey]
    xml_file = data_dir / xml_filename
    output_file = data_dir / OUTPUT_FILES[args.survey]

    if not xml_file.exists():
        print(f"ERROR: XML file not found: {xml_file}")
        sys.exit(1)

    # Parse XML
    df = parse_qualtrics_xml(xml_file)

    # Classify rows
    print("\nClassifying rows...")
    is_preview, is_metadata = classify_rows(df)

    n_preview = is_preview.sum()
    n_metadata = is_metadata.sum()
    n_real = len(df) - n_preview - n_metadata

    print(f"  Real data rows: {n_real}")
    print(f"  Preview rows (kept, flagged): {n_preview}")
    print(f"  Metadata rows (dropped): {n_metadata}")

    # Safety check: Ensure metadata rows don't have valid Prolific IDs
    metadata_rows = df[is_metadata]
    valid_pids_in_metadata = metadata_rows['PROLIFIC_PID'].apply(is_valid_prolific_id).sum()

    print(f"\n=== SAFETY CHECKS ===")
    print(f"Rows to be dropped (metadata): {n_metadata}")
    print(f"Valid Prolific IDs in metadata rows: {valid_pids_in_metadata}")

    if valid_pids_in_metadata > 0:
        print("\nERROR: Found valid Prolific IDs in rows marked as metadata!")
        print("These rows would be incorrectly dropped:")
        print(metadata_rows[metadata_rows['PROLIFIC_PID'].apply(is_valid_prolific_id)][
            ['_recordId', 'PROLIFIC_PID', 'distributionChannel', 'status']
        ])
        sys.exit(1)

    # Assert safety
    assert valid_pids_in_metadata == 0, \
        "Found valid Prolific IDs in metadata rows - would lose real data!"

    # Show what we're dropping
    if n_metadata > 0:
        print("\nMetadata rows being dropped:")
        print(metadata_rows[['_recordId', 'PROLIFIC_PID', 'distributionChannel', 'status']])

    # Drop only metadata rows (keep preview rows)
    df_clean = df[~is_metadata].copy()
    print(f"\nAfter dropping metadata: {len(df_clean)} rows")

    # Add is_preview flag
    is_preview_clean = is_preview[~is_metadata]
    df_clean['is_preview'] = is_preview_clean.astype(int)
    print(f"Preview rows flagged: {df_clean['is_preview'].sum()}")

    # Report on remaining rows without valid Prolific IDs (should only be previews)
    has_valid_pid = df_clean['PROLIFIC_PID'].apply(is_valid_prolific_id)
    invalid_pids_remaining = (~has_valid_pid).sum()
    invalid_non_preview = (~has_valid_pid & (df_clean['is_preview'] == 0)).sum()

    print(f"Rows with invalid Prolific ID: {invalid_pids_remaining}")
    print(f"  Of which are preview: {df_clean['is_preview'].sum()}")
    print(f"  Of which are NOT preview: {invalid_non_preview}")

    if invalid_non_preview > 0:
        print("\nWARNING: Non-preview rows with invalid Prolific IDs:")
        print(df_clean[(~has_valid_pid) & (df_clean['is_preview'] == 0)][
            ['_recordId', 'PROLIFIC_PID', 'distributionChannel', 'status']
        ].head(10))

    # Rename _recordId to response_id
    df_clean.columns = [col.replace('_recordId', 'response_id') for col in df_clean.columns]

    # Convert appropriate columns to numeric where possible
    print("\nConverting column types...")
    for col in ['progress', 'duration']:
        if col in df_clean.columns:
            df_clean[col] = pd.to_numeric(df_clean[col], errors='coerce')

    # Save to Stata format
    print(f"\nSaving to Stata format: {output_file}")
    df_clean.to_stata(output_file, write_index=False, version=118)

    print(f"\n=== COMPLETE ===")
    print(f"Saved {len(df_clean)} observations with {len(df_clean.columns)} variables")
    print(f"  Preview rows: {df_clean['is_preview'].sum()}")
    print(f"  Real data rows: {(df_clean['is_preview'] == 0).sum()}")
    print(f"Output: {output_file}")


if __name__ == '__main__':
    main()
