#!/bin/zsh

# This script imports localizations from xliff files into the users local clone of LoopWorkspace
# You must be in the LoopWorkspace folder

# Fetch translations from lokalise before running this script
# ./Scripts/manual_download_from_lokalise.sh

# Then execute script:
# ./Scripts/manual_import_localizations.sh

set -e
set -u

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo "  You must be in the LoopWorkspace folder ready to bring in "
echo "  localizations from the xliff_in files downloaded from lokalise."
echo
echo "All submodules will use '${TRANSLATION_BRANCH}' as the branch name:"
echo "  If that branch does not exist, it will be created from current submodule branch."
echo "  If that branch exists, it will continue to be used."
echo
echo "You are responsible for configuring your clone before running ${0}."
echo "  Typically, you run ./Scripts/update_submodule_refs.sh before using this script."
echo "  You can also update in-progress submodule localization using '${TRANSLATION_BRANCH}'."
echo
echo "If you are not updating an in-progress localization, you can clean up with"
echo "  ./Scripts/manual_cleanup.sh"
echo "before running this script"
echo
echo "This script takes a long time to run. Wait to make sure there is not an early error."
echo "  Then take a break and return when all languages have been processed by Xcode"

continue_or_quit ${0}

for project in ${PROJECTS}; do
    echo "Prepping $project"
    IFS=":" read user dir branch <<< "$project"
    echo "parts = $user $dir $branch"
    cd $dir
    current_branch=$(git branch --show-current 2>/dev/null)
    echo "current_branch = $current_branch"
    if [[ "${current_branch}" == "${TRANSLATION_BRANCH}" ]]; then
            echo "already on $TRANSLATION_BRANCH"
    
    elif [ -n "$(git branch --list "$TRANSLATION_BRANCH")" ]; then
        echo "Local branch '$TRANSLATION_BRANCH' exists, switching to it."
        git switch "${TRANSLATION_BRANCH}"
    
    else
        echo "Local branch $TRANSLATION_BRANCH does not exist,"
        echo "creating $TRANSLATION_BRANCH from the current branch, $current_branch."
        git switch -c "${TRANSLATION_BRANCH}"
    fi

    cd -
done

# Build Loop
set -o pipefail && time xcodebuild -workspace LoopWorkspace.xcworkspace -scheme 'LoopWorkspace' build | xcpretty

# Apply translations
foreach file in xliff_in/*.xliff
  section_divider
  echo " importing ${file}"
  section_divider
  /usr/bin/time xcodebuild -workspace LoopWorkspace.xcworkspace -scheme "LoopWorkspace" -importLocalizations -localizationPath $file
end

section_divider
echo "Continue by reviewing the differences for each submodule with command:"
next_script "./Scripts/manual_review_translations.sh"
section_divider
