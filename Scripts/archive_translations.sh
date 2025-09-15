#!/bin/zsh

# archive previously created translation branches as a "reset" action
# you can edit branch names in Scripts/define_common.sh prior to running

set -e
set -u

source Scripts/define_common.sh

# use a common message with the time at which xliff files were downloaded from lokalise
if [[ -e "${MESSAGE_FILE}" ]]; then
    message_string=$(<"${MESSAGE_FILE}")
else
    message_string="message not defined"
fi
echo "message_string = ${message_string}"

for project in ${PROJECTS}; do
  echo "Archive ${TRANSLATION_BRANCH} branch for $project"
  IFS=":" read user dir branch <<< "$project"
  echo "parts = $user $dir $branch"
  cd $dir
  if git switch ${TRANSLATION_BRANCH}; then
    echo "in $dir, configure $ARCHIVE_BRANCH"
    git branch -D ${ARCHIVE_BRANCH} || true
    git switch -c ${ARCHIVE_BRANCH}
    git add .
    if git commit -m "${message_string}"; then
        echo "updated $dir with ${message_string} in ${ARCHIVE_BRANCH} branch"    
    fi
    git branch -D ${TRANSLATION_BRANCH}
  fi
  cd -
done

git submodule update
git status

echo "You may need to manually clean branches not in the project list"
