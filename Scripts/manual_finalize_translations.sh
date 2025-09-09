#!/bin/zsh

set -e
set -u

# this script commits the changes to translations branch, pushes and opens PR

source Scripts/define_common.sh

for project in ${projects}; do
    echo "Commiting $project"
    IFS=":" read user dir branch <<< "$project"
    echo "parts = $user $dir $branch"
    cd $dir
    git add .
        # skip repositories with no changes
        if git commit -F "../${message_file}"; then
            git push --set-upstream origin ${translation_branch}
            pr=$(gh pr create -B $branch -R $user/$dir --fill 2>&1 | grep http)
            echo "PR = $pr"
            open $pr
        fi
    cd -
done
