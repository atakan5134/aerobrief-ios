#!/bin/bash
# Regenerates AeroBriefAI.xcodeproj/project.pbxproj from project.yml using XcodeGen.
#
# WHY THIS EXISTS:
# On 2026-07-01 the app's Assets.xcassets (containing the app icon) was added
# to disk but never added to project.pbxproj. Because pbxproj had been hand
# edited/generated out of band instead of via `xcodegen generate`, the asset
# catalog silently never got compiled into the app bundle. This caused every
# TestFlight/App Store Connect upload to be rejected with "missing app icon" /
# "missing CFBundleIconName" errors, and was only caught by manually diffing
# project.pbxproj against project.yml.
#
# RULE: project.pbxproj is a generated file. Never hand-edit it. If you add,
# remove, or rename files/targets, update project.yml and re-run this script.
#
# Requires XcodeGen: https://github.com/yonaskolb/XcodeGen
#   brew install xcodegen

set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen not found. Install it with: brew install xcodegen" >&2
  exit 1
fi

xcodegen generate
echo "project.pbxproj regenerated from project.yml."
