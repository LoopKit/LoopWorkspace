#!/bin/zsh

# This script assists in reviewing translations for each submodule after running
# ./Scripts/manual_import_localizations.sh
# and before running
# ./Scripts/manual_finalize_translations.sh
# You must be in the LoopWorkspace folder

set -e
set -u

source Scripts/define_common.sh

echo "Each submodule will have git status displayed"
echo " Use a separate terminal of a given folder if you want to make adjustments"
echo "Hit return when ready"
read query

for project in ${projects}; do
  echo "Review diffs for ${translation_branch} branch for $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  if git switch ${translation_branch}; then
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

echo ""
echo "Continue by committing the updates and creating PR with"
echo "./Scripts/manual_finalize_translations.sh"