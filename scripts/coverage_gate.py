#!/usr/bin/env python3

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Optional


def write_stdout(message: str) -> None:
    sys.stdout.write(f"{message}\n")


def write_stderr(message: str) -> None:
    sys.stderr.write(f"{message}\n")


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Evaluate production source coverage from a SwiftPM exported coverage report."
    )
    parser.add_argument(
        "--input-json",
        dest="input_json",
        help="Path to the exported Swift coverage JSON. If omitted, the script resolves it with `swift test --show-coverage-path`."
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=85.0,
        help="Minimum required production coverage percentage."
    )
    return parser.parse_args()


def resolve_report_path(input_json: Optional[str]) -> Path:
    if input_json:
        return Path(input_json)

    command = ["swift", "test", "--show-coverage-path"]
    completed = subprocess.run(
        command,
        check=False,
        capture_output=True,
        text=True
    )
    if completed.returncode != 0:
        raise RuntimeError(completed.stderr.strip() or "Unable to resolve the Swift coverage report path.")

    resolved = completed.stdout.strip()
    if not resolved:
        raise RuntimeError("Swift did not return a coverage report path.")
    return Path(resolved)


def should_include(filename: str) -> bool:
    normalized = filename.replace("\\", "/")
    if "/Sources/" not in normalized:
        return False
    if "/Tests/" in normalized:
        return False
    if "/DerivedSources/" in normalized:
        return False
    if normalized.endswith("/resource_bundle_accessor.swift"):
        return False
    return True


def load_production_coverage(report_path: Path) -> tuple[float, int, int, int]:
    if report_path.exists() is False:
        raise RuntimeError(f"Coverage report not found at {report_path}")

    payload = json.loads(report_path.read_text())
    data = payload.get("data", [])
    if not data:
        raise RuntimeError("Coverage report does not contain any data blocks.")

    total_lines = 0
    covered_lines = 0
    production_files = 0

    for block in data:
        for file_entry in block.get("files", []):
            filename = file_entry.get("filename", "")
            if should_include(filename) is False:
                continue
            lines = file_entry.get("summary", {}).get("lines")
            if lines is None:
                continue
            total_lines += int(lines.get("count", 0))
            covered_lines += int(lines.get("covered", 0))
            production_files += 1

    if total_lines == 0 or production_files == 0:
        raise RuntimeError("Coverage report does not contain measurable production source files.")

    percentage = (covered_lines / total_lines) * 100
    return percentage, covered_lines, total_lines, production_files


def main() -> int:
    arguments = parse_arguments()

    try:
        report_path = resolve_report_path(arguments.input_json)
        percentage, covered_lines, total_lines, production_files = load_production_coverage(report_path)
    except RuntimeError as error:
        write_stderr(f"Coverage gate error: {error}")
        return 2

    summary = (
        f"Production coverage: {percentage:.2f}% "
        f"({covered_lines}/{total_lines} lines across {production_files} production files). "
        f"Required threshold: {arguments.threshold:.2f}%."
    )

    if percentage + 1e-9 < arguments.threshold:
        write_stdout(summary)
        write_stdout("Coverage gate failed: repository coverage is below the configured threshold.")
        return 1

    write_stdout(summary)
    write_stdout("Coverage gate passed: repository coverage meets or exceeds the configured threshold.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
