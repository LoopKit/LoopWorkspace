#!/bin/zsh

# This script assists in reviewing translations for each submodule after running
# ./Scripts/manual_import_localizations.sh
# and before running
# ./Scripts/manual_finalize_translations.sh
# You must be in the LoopWorkspace folder

set -e
set -u

source Scripts/define_common.sh

NO_CHANGES="nothing to commit"

section_divider
echo "You are running ${0}"
echo "  Each submodule will have 'git status' displayed for the '${TRANSLATION_BRANCH}' branch"
echo "  Use a separate terminal in the submodule folder if you want to make adjustments"

continue_or_quit ${0}

for project in ${PROJECTS}; do
  section_divider
  IFS=":" read user dir branch <<< "$project"
  cd $dir
  current_branch=$(git branch --show-current 2>/dev/null)
  if [[ "${current_branch}" == "${TRANSLATION_BRANCH}" ]]; then
    echo "Review diffs for $dir"
    result=$(git status)
    echo "${result}"
    folder_path="${PWD}"
    echo ""
    echo "This folder is $folder_path"
    if [[ ${result} == *"$NO_CHANGES"* ]]; then
        cd -
        continue
    fi
    section_divider
    echo "  Hit return when ready to continue"
    read query
  else
    echo "  $dir does not have a ${TRANSLATION_BRANCH} branch"
  fi
  cd -
done

section_divider
echo "Done reviewing diffs by submodule"
echo
echo "Next step is to create/update PRs for each modified submodule by executing"
next_script "./Scripts/manual_finalize_translations.sh"
section_divider
