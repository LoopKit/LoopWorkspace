#!/bin/zsh

# Install the Lokalise command line tools from https://github.com/lokalise/lokalise-cli-2-go
# Generate an API Token (not an SDK Token!) following the instructions here: https://docs.lokalise.com/en/articles/1929556-api-tokens
# export LOKALISE_TOKEN="<yourtokenhere>"
# export GH_TOKEN="<githubtoken>"

set -e
set -u

: "$LOKALISE_TOKEN"
: "$GH_TOKEN"

date=`date`

# Fetch translations from Lokalise
lokalise2 \
    --token "$LOKALISE_TOKEN" \
    --project-id "8069387863cdd837d11dd0.82955128" \
    file download \
    --format xliff \
    --bundle-structure "%LANG_ISO%.%FORMAT%" \
    --original-filenames=false \
    --export-empty-as skip \
    --replace-breaks=false \
    --unzip-to ./xliff


# Build Loop
set -o pipefail && time xcodebuild -workspace Loop.xcworkspace -scheme 'Loop (Workspace)' build | xcpretty


# Apply translations
foreach file in xliff/*.xliff
  xcodebuild -workspace Loop.xcworkspace -scheme "Loop (Workspace)" -importLocalizations -localizationPath $file
end


# Generate branches, commit and push.
projects=(LoopKit:AmplitudeService:dev LoopKit:CGMBLEKit:dev LoopKit:G7SensorKit:main LoopKit:LogglyService:dev LoopKit:Loop:dev LoopKit:LoopKit:dev LoopKit:LoopOnboarding:dev LoopKit:LoopSupport:dev LoopKit:NightscoutAPIClient:master ps2:NightscoutService:dev LoopKit:OmniBLE:dev LoopKit:TidepoolKit:dev LoopKit:TidepoolService:dev LoopKit:dexcom-share-client-swift:dev ps2:rileylink_ios:dev)
for project in ${projects}; do
  echo "Working on $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  set +e
  git checkout -b translations
  git add .
  git commit -am "Updated translations from Lokalise on ${date}"
  git push -f
  pr=$(gh pr create -B $branch -R $user/$dir --fill 2>&1 | grep http)
  echo "PR = $pr"
  open $pr
  cd ..
done

