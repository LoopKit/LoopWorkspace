#!/bin/zsh

# The purpose of this script is to update the loopandlearn forks to match the upstream repositories
# The script can only be run by someone with push privileges to the loopandlearn forks.

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo
echo "  This automatically updates the downstream loopandlearn forks at GitHub"
echo "    to match their upstream LoopKit counterparts."
echo "  Next, the forks that need to be manually managed will be opened so you"
echo "    can handle the process at GitHub."
echo
echo " The automated process only works with push privileges to loopandlearn."
echo " Running the script without privileges yields error messages; no harm occurs."

continue_or_quit ${0}


# define the TRIO_PROJECT_FORKS to be updated
#   these branches in loopandlearn should match the branches in the upstream repositories

# note that the OmniBLE pod-keep-alive branch is a temporary addition and must come
# before the nominal OmniBLE dev branch in the list below
TRIO_PROJECT_FORKS=( \
    LoopKit:OmniBLE:pod-keep-alive \
    LoopKit:CGMBLEKit:dev \
    LoopKit:dexcom-share-client-swift:dev \
    LoopKit:G7SensorKit:main \
    LoopKit:LibreTransmitter:main \
    LoopKit:MinimedKit:main \
    LoopKit:OmniBLE:dev \
    LoopKit:OmniKit:main \
    LoopKit:RileyLinkKit:dev \
    LoopKit:TidepoolService:dev \
)

# This script uses remotes with the indicated nickname for the downstream repository
#   If the proper remotes are not yet configured, they will be added later
DOWNSTREAM_GITHUB_NAME="loopandlearn"
DOWNSTREAM_NICKNAME="lal"

section_divider
echo "  ////////////// Automatically push updates from LoopKit to loopandlearn ////////////"
echo
for project in ${TRIO_PROJECT_FORKS}; do
  IFS=":" read user dir branch <<< "$project"
  echo "  Make sure $branch for $dir is up to date"
  cd $dir
  git switch $branch
  git pull
  # Ensure remote is configured
  if ! git remote get-url ${DOWNSTREAM_NICKNAME} &>/dev/null; then
    echo "   Adding remote ${DOWNSTREAM_NICKNAME} for $dir"
    git remote add ${DOWNSTREAM_NICKNAME} https://github.com/${DOWNSTREAM_GITHUB_NAME}/$dir
  fi

  echo "   Push this update downstream to ${DOWNSTREAM_GITHUB_NAME}/$dir:$branch"
  git push ${DOWNSTREAM_NICKNAME} $branch
  echo ""
  cd -
done

# LoopKit/LoopKit has commits used by Trio that require manual sync
# The other repositories use loopandlearn in .gitmodules
#   so must also be handled maually for both Loop and Trio.
# These URL for DanaKit, EversenseKit and MedtrumKit are the same for Loop and Trio.
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
echo "  If any updates were made by manual sync for DanaKit, EversenseKit and MedtrumKit"
echo "    follow up by running:"
echo "      ./Scripts/update_submodule_refs.sh"
echo "    This ensures the submodules used by LoopWorkspace are up to date"
section_divider
