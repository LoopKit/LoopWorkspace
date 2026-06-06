#!/bin/zsh

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo
echo "  This modifies your local clone, in whatever branch is currently selected,"
echo "  so that every submodule is at the tip of the appropriate branch."
echo
current_branch=$(git branch --show-current 2>/dev/null)
echo "  The current LoopWorkspace branch is $current_branch"

continue_or_quit ${0}

for project in ${PROJECTS}; do
  echo
  echo "Updating to $project"
  IFS=":" read user dir branch <<< "$project"
  echo "Updating to $branch on $user/$project"
  cd $dir
  git checkout $branch
  git pull
  cd -
done
