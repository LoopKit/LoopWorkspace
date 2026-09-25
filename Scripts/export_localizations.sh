#!/bin/zsh

set -e
set -u

: "$LOKALISE_TOKEN"

LANGUAGES=(ar cs ru en zh-Hans nl fr de it nb pl es ja pt-BR vi da sv fi ro tr he sk hi)

argstring="${LANGUAGES[@]/#/-exportLanguage }"
IFS=" "; args=( $=argstring )

# SUPPORTS_MACCATALYST=NO: -exportLocalizations builds every target for all
# platforms it supports, including Mac Catalyst. Loop does not ship a Catalyst
# app, and under Xcode 27 the Catalyst builds fail (frameworks fall back to an
# unsupported macOS 10.15 deployment target), so skip Catalyst entirely.
xcodebuild -scheme LoopWorkspace -exportLocalizations -localizationPath xclocs SUPPORTS_MACCATALYST=NO $args

mkdir -p xliff_out
find xclocs -name '*.xliff' -exec cp {} xliff_out \;

