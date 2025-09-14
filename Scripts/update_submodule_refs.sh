#!/bin/zsh

source Scripts/define_common.sh

for project in ${PROJECTS}; do
  echo "Updating to $project"
  IFS=":" read user dir branch <<< "$project"
  echo "Updating to $branch on $user/$project"
  cd $dir
  git checkout $branch
  #git branch -D tidepool-sync
  git pull
  cd -
done
