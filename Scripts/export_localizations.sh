#!/bin/zsh

set -e
set -u

: "$LOKALISE_TOKEN"

LANGUAGES=(ar cs ru en zh-Hans nl fr de it nb pl ru es ja pt-BR vi da sv fi ro tr he sk)

argstring="${LANGUAGES[@]/#/-exportLanguage }"
IFS=" "; args=( $=argstring )

xcodebuild -scheme LoopWorkspace -exportLocalizations -localizationPath xclocs $args

mkdir -p xliff_out
find xclocs -name '*.xliff' -exec cp {} xliff_out \;

cd xliff_out

foreach lang in $LANGUAGES

  lang_iso=$(sed "s/zh-Hans/zh_Hans/g; s/pt-BR/pt_BR/g" <<<"$lang")

  lokalise2 \
    --token $LOKALISE_TOKEN \
    --convert-placeholders=false \
    --project-id 414338966417c70d7055e2.75119857 \
    file upload \
    --file ${lang}.xliff \
    --cleanup-mode \
    --lang-iso ${lang_iso}
end
