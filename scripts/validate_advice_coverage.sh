#!/usr/bin/env bash
# Windows: use scripts/validate_advice_coverage.ps1
# Any OS: cd mobile && dart run tool/validate_advice_coverage.dart
set -euo pipefail
cd "$(dirname "$0")/../mobile"
dart run tool/validate_advice_coverage.dart
