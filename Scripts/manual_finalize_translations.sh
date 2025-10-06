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

for project in ${PROJECTS}; do
    echo "Committing updates to $project"
    IFS=":" read user dir branch <<< "$project"
    cd $dir
    git add .
        # skip repositories with no changes
        if git commit -F "../${MESSAGE_FILE}"; then
            git push --set-upstream origin ${TRANSLATION_BRANCH}
            # Only open PR if the owner is LoopKit
            # the loopandlearn branch should be created or updated
            #   then manually create the PR to the source repository
            if [[ ${user} == ${LOOPKIT_USER} ]]; then
                # If PR already exists, this just opens it
                pr=$(gh pr create -B $branch -R $user/$dir --fill 2>&1 | grep http)
                echo "PR = $pr"
                open $pr
            else
                echo "Automatic PR creation is only provided for LoopKit"
                echo "  The branch ${TRANSLATION_BRANCH} was created or updated at $user/$dir"
                echo "  Create the appropriate PR to the source repository"
                echo "  After that PR is approved and merged, then sync $user/$dir"
            fi
        fi
    cd -
done

section_divider
echo "Review and get approvals for the submodule PRs"
echo "Once all are merged, then create/update the LoopWorkspace PR"
section_divider