#!/bin/zsh

# archive previously created translation branches as test_translations as a "reset" action

set -e
set -u
translation_dir="translations"

projects=( \
    LoopKit:AmplitudeService:dev \
    LoopKit:CGMBLEKit:dev \
    LoopKit:dexcom-share-client-swift:dev \
    LoopKit:G7SensorKit:main \
    LoopKit:LibreTransmitter:main \
    LoopKit:LogglyService:dev \
    LoopKit:Loop:dev \
    LoopKit:LoopKit:dev \
    LoopKit:LoopOnboarding:dev \
    LoopKit:LoopSupport:dev \
    LoopKit:MinimedKit:main \
    LoopKit:NightscoutRemoteCGM:dev \
    LoopKit:NightscoutService:dev \
    LoopKit:OmniBLE:dev \
    LoopKit:OmniKit:main \
    LoopKit:RileyLinkKit:dev \
    LoopKit:TidepoolService:dev \
    )

echo "Each submodule will have git status displayed"
echo " Use a separate terminal of a given folder if you want to make adjustments"
echo "Hit return when ready"
read query

for project in ${projects}; do
  echo "Review diffs for ${translation_dir} branch for $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  if git switch ${translation_dir}; then
    git status
    folder_path="${PWD}"
    echo ""
    echo "This folder is $folder_path"
    echo "  Hit return when ready to continue"
    read query
  fi
  cd -
done

echo "Done reviewing diffs"
