#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
dotnet run --project Tools/CoreChecks -c Release -- --exhaustive
dotnet run --project Tools/SyntaxChecks
