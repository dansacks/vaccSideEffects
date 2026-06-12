#!/usr/bin/env python3
"""
Classify open-ended survey responses using the Claude API.

Two modes are available:

  - Batch mode (--submit / --collect): 50% cheaper, best for the full
    dataset, but async (typically ~1 hour, up to 24 hours).

        # Step 1: submit
        python code/classify_open_responses.py \\
            --prompt code/classification_prompt.md \\
            --data path/to/responses.tsv \\
            --submit

        # Step 2: collect (run after batch completes)
        python code/classify_open_responses.py \\
            --prompt code/classification_prompt.md \\
            --data path/to/responses.tsv \\
            --collect \\
            [--output output/tables/debrief_classifications.csv]

  - Sync mode (--sync): classifies immediately, one request at a time.
    No batch discount; intended for small test runs.

        python code/classify_open_responses.py \\
            --prompt code/classification_prompt.md \\
            --data path/to/responses.tsv \\
            --sync \\
            [--output output/tables/debrief_classifications.csv]

Input TSV has two columns: study_id, debrief_about
Export from Stata: export delimited study_id debrief_about using "path.tsv", delimiter(tab) replace

Output CSV import into Stata:
    import delimited using "output/tables/debrief_classifications.csv", clear
"""

import argparse
import json
import sys
import pandas as pd
import anthropic
from pathlib import Path
from anthropic.types.message_create_params import MessageCreateParamsNonStreaming
from anthropic.types.messages.batch_create_params import Request

MODEL = "claude-haiku-4-5"

BATCH_ID_FILE = Path("output/tables/.debrief_batch_id")

# 7 binary fields; understood_intent is derived in Python after collection
CLASSIFICATION_SCHEMA = {
    "type": "object",
    "properties": {
        "about_flu":      {"type": "integer", "enum": [0, 1]},
        "about_attitude": {"type": "integer", "enum": [0, 1]},
        "about_info":     {"type": "integer", "enum": [0, 1]},
        "about_beliefs":  {"type": "integer", "enum": [0, 1]},
        "about_intent":   {"type": "integer", "enum": [0, 1]},
        "about_change":   {"type": "integer", "enum": [0, 1]},
        "unclear":        {"type": "integer", "enum": [0, 1]},
    },
    "required": [
        "about_flu", "about_attitude", "about_info", "about_beliefs",
        "about_intent", "about_change", "unclear",
    ],
    "additionalProperties": False,
}


def load_prompt(path: str) -> str:
    text = Path(path).read_text().strip()
    if not text:
        sys.exit(f"Prompt file is empty: {path}")
    return text


def load_data(path: str) -> pd.DataFrame:
    df = pd.read_csv(path, sep="\t", dtype={"study_id": str})
    missing = [c for c in ("study_id", "debrief_about") if c not in df.columns]
    if missing:
        sys.exit(f"Missing columns in data file: {missing}")
    n_before = len(df)
    df = df[df["debrief_about"].notna()].copy()
    n_dropped = n_before - len(df)
    print(f"Loaded {len(df)} responses" + (f" ({n_dropped} dropped: missing text)" if n_dropped else ""))
    return df


def _request_params(system_prompt: str, text: str) -> dict:
    return dict(
        model=MODEL,
        max_tokens=128,
        temperature=0,
        system=[{
            "type": "text",
            "text": system_prompt,
            "cache_control": {"type": "ephemeral"},
        }],
        messages=[{"role": "user", "content": text}],
        output_config={
            "format": {
                "type": "json_schema",
                "schema": CLASSIFICATION_SCHEMA,
            }
        },
    )


def submit_batch(df: pd.DataFrame, system_prompt: str) -> None:
    client = anthropic.Anthropic()

    requests = [
        Request(
            custom_id=row["study_id"],
            params=MessageCreateParamsNonStreaming(
                **_request_params(system_prompt, str(row["debrief_about"]))
            ),
        )
        for _, row in df.iterrows()
    ]

    batch = client.messages.batches.create(requests=requests)

    BATCH_ID_FILE.parent.mkdir(parents=True, exist_ok=True)
    BATCH_ID_FILE.write_text(batch.id)

    print(f"Submitted {len(requests)} requests")
    print(f"Batch ID: {batch.id}  (saved to {BATCH_ID_FILE})")
    print("Run --collect when done (usually within 1 hour).")


def collect_results(df: pd.DataFrame, output_path: str) -> None:
    client = anthropic.Anthropic()

    if not BATCH_ID_FILE.exists():
        sys.exit(f"No batch ID found at {BATCH_ID_FILE}. Run --submit first.")
    batch_id = BATCH_ID_FILE.read_text().strip()

    batch = client.messages.batches.retrieve(batch_id)
    print(f"Batch {batch_id}: {batch.processing_status}")

    if batch.processing_status != "ended":
        c = batch.request_counts
        print(f"  processing={c.processing}  succeeded={c.succeeded}  errored={c.errored}")
        print("Not done yet — run --collect again later.")
        return

    results: dict[str, dict] = {}
    n_error = 0

    for result in client.messages.batches.results(batch_id):
        if result.result.type == "succeeded":
            message = result.result.message
            if message.stop_reason == "max_tokens":
                print(f"  Warning: hit max_tokens for study_id={result.custom_id} — increase max_tokens")
            text = next(
                (b.text for b in message.content if b.type == "text"), ""
            )
            try:
                results[result.custom_id] = json.loads(text)
            except json.JSONDecodeError:
                results[result.custom_id] = None
                print(f"  Warning: JSON parse failed for study_id={result.custom_id}: {text[:80]}")
                n_error += 1
        else:
            results[result.custom_id] = None
            print(f"  Warning: {result.result.type} for study_id={result.custom_id}")
            n_error += 1

    write_results(df, results, n_error, output_path)


def run_sync(df: pd.DataFrame, system_prompt: str, output_path: str) -> None:
    client = anthropic.Anthropic()

    results: dict[str, dict] = {}
    n_error = 0

    for i, (_, row) in enumerate(df.iterrows(), start=1):
        print(f"  [{i}/{len(df)}] study_id={row['study_id']}")
        try:
            message = client.messages.create(
                **_request_params(system_prompt, str(row["debrief_about"]))
            )
            if message.stop_reason == "max_tokens":
                print(f"  Warning: hit max_tokens for study_id={row['study_id']} — increase max_tokens")
            text = next((b.text for b in message.content if b.type == "text"), "")
            results[row["study_id"]] = json.loads(text)
        except Exception as e:
            results[row["study_id"]] = None
            print(f"  Warning: error for study_id={row['study_id']}: {e}")
            n_error += 1

    write_results(df, results, n_error, output_path)


def write_results(df: pd.DataFrame, results: dict, n_error: int, output_path: str) -> None:
    # Build classifications dataframe
    clf_rows = []
    for study_id, fields in results.items():
        if fields is not None:
            row = {"study_id": study_id, **fields}
            # Compute understood_intent from components
            row["understood_intent"] = int(
                fields["about_flu"] == 1
                and fields["about_info"] == 1
                and fields["about_change"] == 1
                and (
                    fields["about_attitude"] == 1
                    or fields["about_beliefs"] == 1
                    or fields["about_intent"] == 1
                )
            )
        else:
            row = {"study_id": study_id}  # all fields will be NaN after merge
        clf_rows.append(row)

    clf = pd.DataFrame(clf_rows)

    # Left-join back to original study_id list to preserve row order
    merged = df[["study_id"]].merge(clf, on="study_id", how="left")

    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    merged.to_csv(output_path, index=False)

    n_success = len(results) - n_error
    n_understood = merged["understood_intent"].sum() if "understood_intent" in merged.columns else 0
    pct = 100 * n_understood / n_success if n_success > 0 else 0

    print(f"\nResults: {n_success}/{len(results)} succeeded, {n_error} errors")
    print(f"understood_intent=1: {int(n_understood)} ({pct:.1f}% of classified)")
    print(f"Output: {output_path}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Classify open responses via the Claude API")
    parser.add_argument("--prompt", required=True, help="Path to classification prompt markdown file")
    parser.add_argument("--data", required=True, help="Path to TSV file with study_id and debrief_about")
    parser.add_argument("--output", default="output/tables/debrief_classifications.csv",
                        help="Output CSV path (collect/sync modes only)")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--submit", action="store_true", help="Create and submit the batch")
    group.add_argument("--collect", action="store_true", help="Collect results from a completed batch")
    group.add_argument("--sync", action="store_true",
                        help="Classify immediately, one request at a time (no batch discount)")
    args = parser.parse_args()

    system_prompt = load_prompt(args.prompt)
    df = load_data(args.data)

    if args.submit:
        submit_batch(df, system_prompt)
    elif args.collect:
        collect_results(df, args.output)
    else:
        run_sync(df, system_prompt, args.output)
