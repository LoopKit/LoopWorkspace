#!/bin/zsh

# archive previously created translation branches as a "reset" action
# you can edit branch names in Scripts/define_common.sh prior to running

set -e
set -u

source Scripts/define_common.sh

# use a common message with the time at which xliff files were downloaded from lokalise
if [[ -e "${message_file}" ]]; then
    message_string=$(<"${message_file}")
else
    message_string="message not defined"
fi
echo "message_string = ${message_string}"

for project in ${projects}; do
  echo "Archive ${translation_branch} branch for $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  if git switch ${translation_branch}; then
    echo "in $dir, configure $archive_branch"
    git branch -D ${archive_branch} || true
    git switch -c ${archive_branch}
    git add .
    if git commit -m "${message_string}"; then
        echo "updated $dir with ${message_string} in ${archive_branch} branch"    
    fi
    git branch -D ${translation_branch}
  fi
  cd -
done

git submodule update
git status

echo "You may need to manually clean branches not in the project list"

