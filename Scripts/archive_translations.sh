#!/bin/zsh

# archive previously created translation branches as test_translations as a "reset" action

set -e
set -u

date=`date`

archive_dir="test_translations"
translation_dir="translations"

projects=(LoopKit:AmplitudeService:dev LoopKit:CGMBLEKit:dev LoopKit:G7SensorKit:main LoopKit:LogglyService:dev LoopKit:Loop:dev LoopKit:LoopKit:dev LoopKit:LoopOnboarding:dev LoopKit:LoopSupport:dev LoopKit:NightscoutRemoteCGM:dev LoopKit:NightscoutService:dev LoopKit:OmniBLE:dev LoopKit:TidepoolService:dev LoopKit:dexcom-share-client-swift:dev LoopKit:RileyLinkKit:dev LoopKit:OmniKit:main LoopKit:MinimedKit:main LoopKit:LibreTransmitter:main)

for project in ${projects}; do
  echo "Archive ${translation_dir} branch for $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  if git switch ${translation_dir}; then
    echo "in $dir, configure $archive_dir"
    git branch -D ${archive_dir} || true
    git switch -c ${archive_dir}
    git add .
    if git commit -am "Updated translations from Lokalise on ${date}"; then
        echo "updated $dir with new translations in ${archive_dir} branch"    
    fi
    git branch -D ${translation_dir}
  fi
  cd -
done

git submodule update
git status

echo "You may need to manually clean branches not in the project list"

