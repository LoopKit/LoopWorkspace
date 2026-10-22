#!/bin/zsh

set -e
set -u

# this script commits the changes to translations branch, pushes and opens PR

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo "  All differences for submodule files, including untracked files, will be committed."
echo "  If you did not just review all the changes, quit, execute command below and come back"
next_script "./Scripts/manual_review_translations.sh"

continue_or_quit ${0}

LOOPKIT_USER="LoopKit"
LOOPANDLEARN_USER="loopandlearn"
LAL_REMOTE="lal"

for project in ${PROJECTS}; do
    echo "Committing updates to $project"
    IFS=":" read user dir branch <<< "$project"
    cd $dir
        git add .
        # skip repositories with no changes
        if git commit -F "../${MESSAGE_FILE}"; then
            # push to origin for all repos now that Pete and Marion have access
            git push --set-upstream origin ${TRANSLATION_BRANCH}
            # If PR already exists, this just opens it
            pr=$(gh pr create -B $branch -R $user/$dir --fill 2>&1 | grep http)
            echo "PR = $pr"
            open $pr
        fi
    cd -
done

section_divider
echo "Review and get approvals for the submodule PRs"
echo "Once all are merged, then create/update the LoopWorkspace PR"
section_divider