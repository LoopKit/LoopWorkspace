#!/bin/zsh

set -e
set -u

# this script prepares a PR for LoopWorkspace based on current local branch

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo "  You must be in the LoopWorkspace folder ready to commit changes to"
echo "  tracked files in this clone, see 'git status' results below:"
section_divider
git status
section_divider
echo "This script will prepare a PR to LoopWorkspace '${TARGET_LOOPWORKSPACE_BRANCH}' branch"
echo 
echo "1. If the local clone LoopWorkspace branch name is not already '${TRANSLATION_BRANCH}', then"
echo "   that branch will be created and used for this PR"
echo "2. The commit message in the ${MESSAGE_FILE} will be used"
cat ${MESSAGE_FILE}
echo "3. Once the PR is prepared, additional commits can be added as needed"

continue_or_quit ${0}

current_branch=$(git branch --show-current 2>/dev/null)
echo "current_branch = $current_branch"

if [[ "${current_branch}" == "${TRANSLATION_BRANCH}" ]]; then
        echo "already on $TRANSLATION_BRANCH, ok to continue"

elif [ -n "$(git branch --list "$TRANSLATION_BRANCH")" ]; then
    echo "Local branch '$TRANSLATION_BRANCH' exists."
        echo "You are on '$current_branch' and '$TRANSLATION_BRANCH' already exists"
        echo "quitting"
        exit 1 # exit with failure

else
    echo "Local branch $TRANSLATION_BRANCH does not exist,"
    echo "creating $TRANSLATION_BRANCH from the current branch, $current_branch."
    git switch -c "${TRANSLATION_BRANCH}"
fi

continue_or_quit ${0}

# only create a PR if there are changes
if git commit -a -F "${MESSAGE_FILE}"; then
    git push --set-upstream origin ${TRANSLATION_BRANCH}
    pr=$(gh pr create -B ${TARGET_LOOPWORKSPACE_BRANCH} --fill 2>&1 | grep http)
    echo "PR = $pr"
    open $pr

    section_divider
    echo "After you review, ${pr}, get approvals and merge the PR"
    echo " be sure to trim the '${TRANSLATION_BRANCH}' branch,"
    echo " and then run the export and upload scripts again from the updated '${TARGET_LOOPWORKSPACE_BRANCH}' branch"
    section_divider

else
    section_divider
    echo "No changes were found, no PR created"
    section_divider
fi
