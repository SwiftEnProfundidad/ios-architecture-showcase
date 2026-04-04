#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required to regenerate the Xcode project." >&2
  exit 1
fi

xcodegen generate
pbxproj_path="iOSArchitectureShowcase.xcodeproj/project.pbxproj"
if ! git diff --quiet HEAD -- "$pbxproj_path"; then
  echo "error: $pbxproj_path is out of sync with project.yml (and possibly moved test sources)." >&2
  echo "Run \`xcodegen generate\` at the repo root and commit the updated project file." >&2
  git --no-pager diff -- "$pbxproj_path" >&2 || true
  exit 1
fi

swift build -c debug
swift test --parallel --enable-code-coverage
coverage_json_path="$(swift test --show-coverage-path)"
coverage_threshold="${COVERAGE_THRESHOLD:-85}"
python3 "$repo_root/scripts/coverage_gate.py" \
  --input-json "$coverage_json_path" \
  --threshold "$coverage_threshold"

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
