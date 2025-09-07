#!/bin/zsh

set -e
set -u

# this script commits the changes to translations branch, pushes and opens PR
translation_dir="translations"

date="date"

projects=( \
    LoopKit:AmplitudeService:dev \
    LoopKit:CGMBLEKit:dev \
    LoopKit:dexcom-share-client-swift:dev \
    LoopKit:G7SensorKit:main \
    LoopKit:LibreTransmitter:main
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
    LoopKit:TidepoolService:dev)

for project in ${projects}; do
  echo "Commiting $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  git add .
  # if block skips repositories with no changes
  if git commit -am "Updated translations from Lokalise on ${date}"; then
    git push --set-upstream origin ${translation_dir}
    pr=$(gh pr create -B $branch -R $user/$dir --fill 2>&1 | grep http)
    echo "PR = $pr"
    open $pr
  fi
  cd -
done
