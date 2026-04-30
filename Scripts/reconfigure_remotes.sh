#!/bin/zsh

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo
echo "  This modifies your local clone if necessary."
echo "  No change happens if your local clone is already configured."
echo ""
echo "  Scripts need to have the remote named origin point to"
echo "  the correct upstream repository."
echo ""
echo " It is meant to be run once per local clone"
echo "   following a change in upstream paths for .gitmodules"
echo

continue_or_quit ${0}

# This ensures the remote named origin for each submodule matches
# the PROJECTS array upstream repo
for project in ${PROJECTS}; do
  echo
  echo "Row: $project"
  IFS=":" read user dir branch <<< "$project"
  echo "Checking configuration for $branch on $user/$dir"
  cd $dir
    git checkout $branch
    current_remote=$(git remote get-url origin 2>/dev/null)
    expected_remote="https://github.com/$user/$dir.git"
    if [[ "${current_remote%.git}" != "${expected_remote%.git}" ]]; then
      echo "  Updating origin: $current_remote -> $expected_remote"
      git remote remove origin
      git remote add origin "$expected_remote"
      git fetch origin
      git branch --set-upstream-to=origin/$branch $branch
    else
      echo "  Origin is correct: $current_remote"
    fi
    git branch --set-upstream-to=origin/$branch $branch
    git pull
  cd -
done
