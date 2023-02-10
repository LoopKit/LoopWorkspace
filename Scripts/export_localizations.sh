#!/bin/zsh

LANGUAGES=(ar es ru en zh-Hans nl fr de it nb pl ru es ja pt-BR vi da sv fi ro tr he sk)

argstring="${LANGUAGES[@]/#/-exportLanguage }"
IFS=" "; args=( $=argstring )

xcodebuild -exportLocalizations -localizationPath xlocs $args

#mkdir -p xliff
#find xclocs -name '*.xliff' -exec cp {} xliff \;
#
#cd xliff
#
#foreach lang in $LANGUAGES
#  echo lokalise2 \
#    --token $LOKALISE_TOKEN \
#    --project-id 8069387863cdd837d11dd0.82955128 \
#    file upload \
#    --file ${lang}.xliff \
#    --lang-iso ${lang}
#end
