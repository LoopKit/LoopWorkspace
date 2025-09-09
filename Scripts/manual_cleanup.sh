#!/bin/zsh

# This script deletes temporary files and directories created during the translation process
# You must be in the LoopWorkspace folder

# ensure you really want to do this before executing with:
# ./Scripts/manual_cleanup.sh

set -e
set -u

echo " /////////// WARNING ///////////"
echo "Be sure you are completely done with the translations process or"
echo " that you want to discard all your work to date"
echo " This deletes the xclocs, xliff_in, xliff_out folders"
echo " This deletes the standard title for the PRs for submodules and LoopWorkspace"
echo ""
echo "Enter y return to continue, any other key to quit"
read query
echo ""

if [[ ${query} == "y" ]]; then

    rm -rf xclocs
    rm -rf xliff_in
    rm -rf xliff_out
    rm "${message_file}"
    echo "Temporary folders and ${message_file} removed from LoopWorkspace"

else
    echo "Exited without deleting folders and files"

fi
