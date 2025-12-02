"""
Emit a structured audit-style log entry so you can confirm sinks/metrics.
Uses Application Default Credentials; run after applying Terraform.
"""

import argparse
import datetime
import json

from google.cloud import logging_v2


def write_log(project_id: str, label_value: str) -> None:
    client = logging_v2.Client(project=project_id)
    logger = client.logger("adventure-audit")
    payload = {
        "action": "trailhead_test",
        "label": label_value,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "source": "gcp_adventure",
    }
    logger.log_struct(payload, severity="NOTICE")
    print(f"Wrote structured log with label={label_value}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project", required=True, help="GCP project id")
    parser.add_argument(
        "--label",
        default="first-pass",
        help="Marker to find in BigQuery logs/alert tests",
    )
    args = parser.parse_args()
    write_log(project_id=args.project, label_value=args.label)


if __name__ == "__main__":
    main()
