#!/bin/zsh

# The purpose of this script is to open forks on GitHub in browser that require manual evaluation.

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo
echo "  This automatically opens forks that need to be manually managed in your browser so you"
echo "    can handle the process at GitHub."

# There are repositories that use loopandlearn in .gitmodules but the upstream forks come 
#   from the original authors. They are handled maually for both Loop and Trio.
# These URL are the same for Loop and Trio.
# At the moment, LoopKit/LoopKit has commits used by Trio that require manual sync
#   so it is added to the SPECIAL_PROJECT_FORKS list. (This is here for convenience.)
DOWNSTREAM_GITHUB_NAME="loopandlearn"

SPECIAL_PROJECT_FORKS=( \
    loopandlearn:LoopKit:dev:trio \
    bastiaanv:DanaKit:dev:dev \
    bastiaanv:EversenseKit:dev:dev \
    jbr7rr:MedtrumKit:dev:dev \
)

section_divider
echo "  ////////////// Use Browser for next step ////////////"
echo
echo "  Manually update these downstream repositories at ${DOWNSTREAM_GITHUB_NAME}"
echo "    Each URL will automatically open"
echo
for project in ${SPECIAL_PROJECT_FORKS}; do
  IFS=":" read user dir branch downstream_branch <<< "$project"
  echo "  Manually sync ${DOWNSTREAM_GITHUB_NAME}/$dir:$downstream_branch with $user/$dir:$branch"
  open https://github.com/${DOWNSTREAM_GITHUB_NAME}/$dir/tree/$downstream_branch
done

section_divider
echo "  ////////////// WARNING ////////////"
echo
echo "  If any updates were made by manual sync at GitHub,"
echo "    follow up by running:"
echo "      ./Scripts/update_submodule_refs.sh"
echo "    This ensures the submodules used in your local clone are up to date"
section_divider
