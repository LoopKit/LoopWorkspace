#!/bin/zsh

set -e
set -u

# this script prepares a branch of LoopWorkspace based on current local branch.
# It brings in the tip of all the submodule branches which should have just
# been updated with the manual download, import, review and finalize scripts.
# After all those PR are merged and the translation branches trimmed,
# the next step is to prepare the PR to update LoopWorkspace dev branch

source Scripts/define_common.sh

section_divider

echo "You must be in the LoopWorkspace folder ready to bring in "
echo "  all the latest versions of the submodules which were "
echo "  just translated"
echo ""
echo "This script will prepare a PR to LoopWorkspace '${target_loopworkspace_branch}' branch"
echo ""
echo "1. If the branch name is not already '${translation_branch}', then"
echo "   that branch will be created and used for this PR"
echo "2. ./Scripts/update_submodule_refs.sh will be executed"
echo "3. The commit message in the ${message_file} will be used"
cat ${message_file}
echo "4. Once the PR is prepared, additional commits can be added as needed"

section_divider

echo "Enter y to proceed, any other character exits"
read query

if [[ ${query} == "y" ]]; then

    current_branch=$(git branch --show-current 2>/dev/null)
    echo "current_branch = $current_branch"

    if [[ "${current_branch}" == "${translation_branch}" ]]; then
            echo "already on $translation_branch, ok to continue"
    
    elif [ -n "$(git branch --list "$translation_branch")" ]; then
        echo "Local branch '$translation_branch' exists."
            echo "You are on '$current_branch' and '$translation_branch' already exists"
            echo "quitting"
            exit 1 # exit with failure
    
    else
        echo "Local branch $translation_branch does not exist,"
        echo "creating $translation_branch from the current branch, $current_branch."
        git switch -c "${translation_branch}"
    fi

    section_divider

    ./Scripts/update_submodule_refs.sh

    section_divider

    # only create a PR if there are changes
    if git commit -a -F "${message_file}"; then
        git push --set-upstream origin ${translation_branch}
        pr=$(gh pr create -B ${target_loopworkspace_branch} --fill 2>&1 | grep http)
        echo "PR = $pr"
        open $pr

        section_divider
        echo "After you review, ${pr}, get approvals and merge the PR"
        echo " be sure to trim the '${translation_branch}' branch,"
        echo " and then run the export and upload scripts again from the updated '${target_loopworkspace_branch}' branch"
        section_divider

    else
        section_divider
        echo "No changes were found, no PR created"
        section_divider
    fi

else
    section_divider
    echo "user opted to exit the script"
    section_divider
fi
