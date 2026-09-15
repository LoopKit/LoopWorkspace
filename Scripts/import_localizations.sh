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
rm -rf xliff_in
lokalise2 \
    --token "$LOKALISE_TOKEN" \
    --project-id "414338966417c70d7055e2.75119857" \
    file download \
    --format xliff \
    --bundle-structure "%LANG_ISO%.%FORMAT%" \
    --original-filenames=false \
    --placeholder-format ios \
    --export-empty-as skip \
    --replace-breaks=false \
    --unzip-to ./xliff_in

# PROJECTS (and LANGUAGES) are defined in one place so this list cannot drift again.
# The copy that used to live here still named OmniBLE and OmniKit, which have not been
# submodules since they were replaced by OmnipodKit -- with `set -e`, `cd OmniBLE` aborted
# this script outright.
source Scripts/define_common.sh

for project in ${PROJECTS}; do
  echo "Prepping $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  git checkout $branch
  git pull
  git branch -D translations || true
  git checkout -b translations || true
  cd -
done

# Build Loop
set -o pipefail && time xcodebuild -workspace LoopWorkspace.xcworkspace -scheme 'LoopWorkspace' -destination 'generic/platform=iOS' build | xcpretty


# Apply translations
foreach file in xliff_in/*.xliff
  xcodebuild -workspace LoopWorkspace.xcworkspace -scheme "LoopWorkspace" -destination 'generic/platform=iOS' -importLocalizations -localizationPath $file
end


# Generate branches, commit and push.
for project in ${PROJECTS}; do
  echo "Commiting $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  git add .
  if git commit -am "Updated translations from Lokalise on ${date}"; then
    git push -f
    pr=$(gh pr create -B $branch -R $user/$dir --fill 2>&1 | grep http)
    echo "PR = $pr"
    open $pr
  fi
  cd -
done

# Reset 
#for project in ${PROJECTS}; do
#  echo "Commiting $project"
#  IFS=":" read user dir branch <<< "$project"
#  echo "parts = $user $dir $branch"
#  cd $dir
#  git checkout $branch
#  git pull
#  cd -
#done
