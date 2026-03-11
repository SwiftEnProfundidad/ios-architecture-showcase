#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required to regenerate the Xcode project." >&2
  exit 1
fi

swift build -c debug
swift test --parallel --enable-code-coverage
coverage_json_path="$(swift test --show-coverage-path)"
coverage_threshold="${COVERAGE_THRESHOLD:-85}"
python3 "$repo_root/scripts/coverage_gate.py" \
  --input-json "$coverage_json_path" \
  --threshold "$coverage_threshold"
xcodegen generate

simulator_name="${IOS_SIMULATOR_NAME:-$(xcrun simctl list devices available | sed -n 's/^[[:space:]]*\(iPhone[^()]*\) (.*/\1/p' | head -n 1)}"

if [ -z "$simulator_name" ]; then
  echo "No available iOS simulator was found." >&2
  exit 1
fi

xcodebuild \
  -project iOSArchitectureShowcase.xcodeproj \
  -scheme iOSArchitectureShowcase \
  -destination "platform=iOS Simulator,name=$simulator_name" \
  build \
  test
