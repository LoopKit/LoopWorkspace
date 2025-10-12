#!/bin/zsh

# This script deletes temporary files and directories created during the translation process
# You must be in the LoopWorkspace folder

# ensure you really want to do this before executing with:
# ./Scripts/manual_cleanup.sh

set -e
set -u

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo "  Be sure you are completely done with the translation process"
echo "  or that you want to discard all your work to date"
echo
echo " /////////// WARNING ///////////"
echo
echo " This deletes the xclocs, xliff_in, xliff_out folders"
echo " This deletes the file, ${MESSAGE_FILE}, with the lokalise download timestamp"
echo " This restores all submodules to their current branch (reset, clean)"
echo " If '${TRANSLATION_BRANCH}' branch exists and submodule is NOT on that branch:"
echo "    then '${TRANSLATION_BRANCH}' branch is deleted"

continue_or_quit ${0}

rm -rf xclocs
rm -rf xliff_in
rm -rf xliff_out
rm -f "${MESSAGE_FILE}"

for project in ${PROJECTS}; do
  IFS=":" read user dir branch <<< "$project"
  echo
  echo " *** Reset and clean $dir"
  cd $dir
  git reset --hard; git clean -fd;
  current_branch=$(git branch --show-current 2>/dev/null)
  if [[ "${current_branch}" == "${TRANSLATION_BRANCH}" ]]; then
    echo "  already on $TRANSLATION_BRANCH, take no action"
  elif [ -n "$(git branch --list "$TRANSLATION_BRANCH")" ]; then
    echo "  Local branch '$TRANSLATION_BRANCH' exists, deleting it."
    git branch -D "${TRANSLATION_BRANCH}"
  else
    echo "  no branch named $TRANSLATION_BRANCH exists, take no action"
  fi
  cd -
done


section_divider
echo "Temporary folders and ${MESSAGE_FILE} removed from LoopWorkspace"
echo "All folders in PROJECTS reset and cleaned"
section_divider
