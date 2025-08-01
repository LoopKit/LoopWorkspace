#!/bin/zsh

# manually download and put the xliff files in the xliff_in folder
# this script imports the customization into the users local clone of LoopWorkspace

set -e
set -u

date=`date`

translation_dir="translations"

# Fetch translations from Lokalise manually before running this script
# They need to be in the xliff_in folder at the LoopWorkspace level

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

for project in ${projects}; do
  echo "Prepping $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  git checkout $branch
  git pull
  git branch -D ${translation_dir} || true
  git checkout -b ${translation_dir} || true
  cd -
done

# Build Loop
set -o pipefail && time xcodebuild -workspace LoopWorkspace.xcworkspace -scheme 'LoopWorkspace' build | xcpretty

# Apply translations
foreach file in xliff_in/*.xliff
  echo "**********************************"
  echo " importing ${file}"
  echo "**********************************"
  xcodebuild -workspace LoopWorkspace.xcworkspace -scheme "LoopWorkspace" -importLocalizations -localizationPath $file
end

## examine diffs before using the next script