#!/bin/zsh

set -e
set -u

: "$LOKALISE_TOKEN"

LANGUAGES=(ar cs ru en zh-Hans nl fr de it nb pl es ja pt-BR vi da sv fi ro tr he sk hi)

argstring="${LANGUAGES[@]/#/-exportLanguage }"
IFS=" "; args=( $=argstring )

xcodebuild -scheme LoopWorkspace -exportLocalizations -localizationPath xclocs $args

mkdir -p xliff_out
find xclocs -name '*.xliff' -exec cp {} xliff_out \;

