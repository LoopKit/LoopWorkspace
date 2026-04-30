#!/bin/zsh

# The purpose of this script is to update the loopandlearn forks to match the upstream repositories
# The script can only be run by someone with push privileges to the loopandlearn forks.

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo
echo "  This automatically updates the downstream loopandlearn forks at GitHub"
echo "    to match their respective upstream counterparts at LoopKit, bastiaanv and jbr7rr."
echo "  Next, the forks that need to be manually managed will be opened so you"
echo "    can handle the process at GitHub."
echo
echo " The automated process only works with push privileges to loopandlearn."
echo " Running the script without privileges yields error messages; no harm occurs."

continue_or_quit ${0}

# define the TRIO_PROJECT_FORKS to be updated
#   these branches in loopandlearn should match the branches in the upstream repositories
TRIO_PROJECT_FORKS=( \
    LoopKit:CGMBLEKit:dev \
    LoopKit:dexcom-share-client-swift:dev \
    LoopKit:G7SensorKit:main \
    LoopKit:LibreTransmitter:main \
    LoopKit:MinimedKit:main \
    LoopKit:OmniBLE:dev \
    LoopKit:OmniKit:main \
    LoopKit:RileyLinkKit:dev \
    LoopKit:TidepoolService:dev \
    bastiaanv:DanaKit:dev \
    bastiaanv:EversenseKit:dev \
    jbr7rr:MedtrumKit:dev \
)

# This script uses remotes with the indicated nickname for the downstream repository
#   If the proper remotes are not yet configured, they will be added later
DOWNSTREAM_GITHUB_NAME="loopandlearn"
DOWNSTREAM_NICKNAME="lal"

section_divider
echo "  ////////////// Automatically push updates from upstream repository to loopandlearn ////////////"
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

# The next script is called automatically to enable manual evaluation for 
#   additional pump and cgm manager repositories.

source Scripts/open_selected_url.sh