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
            # push to origin for LoopKit and open the PR
            if [[ ${user} == ${LOOPKIT_USER} || ${user} == ${LOOPANDLEARN_USER} ]]; then
                git push --set-upstream origin ${TRANSLATION_BRANCH}
                # If PR already exists, this just opens it
                pr=$(gh pr create -B $branch -R $user/$dir --fill 2>&1 | grep http)
                echo "PR = $pr"
                open $pr
            else
                # Ensure remote is configured
                if ! git remote get-url ${LAL_REMOTE} &>/dev/null; then
                    echo "   Adding remote ${LAL_REMOTE} for $dir"
                    git remote add ${LAL_REMOTE} https://github.com/${LAL_GITHUB}/$dir
                fi
                # push the change to loopandlearn and then open the PR
                echo "   Push this update to ${LOOPANDLEARN_USER}/$dir:${TRANSLATION_BRANCH}"
                git push --set-upstream ${LAL_REMOTE} ${TRANSLATION_BRANCH}
                echo ""
                # If PR already exists, this just opens it
                pr=$(gh pr create -B $branch -R ${LAL_REMOTE}/$dir --fill 2>&1 | grep http)
                echo "PR = $pr"
                open $pr
            fi
        fi
    cd -
done

section_divider
echo "Review and get approvals for the submodule PRs"
echo "Once all are merged, then create/update the LoopWorkspace PR"
section_divider