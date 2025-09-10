#!/bin/zsh

# This script will import the latest translations from lokalise and
# generate a standard commit message for subsequent pull requires

# Install the lokalise command line tools from https://github.com/lokalise/lokalise-cli-2-go
# Generate an API Token (not an SDK Token!) following the instructions here: https://docs.lokalise.com/en/articles/1929556-api-tokens
# export LOKALISE_TOKEN="<yourtokenhere>"

# You must be in the LoopWorkspace folder before executing with:
# ./Scripts/manual_download_from_lokalise.sh

set -e
set -u

: "$LOKALISE_TOKEN"

date=`date`

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo "  This requests localization files from lokalise"

# Fetch translations from lokalise
rm -rf xliff_in
lokalise2 \
    --token "$LOKALISE_TOKEN" \
    --project-id "414338966417c70d7055e2.75119857" \
    file download \
    --async\
    --format xliff \
    --bundle-structure "%LANG_ISO%.%FORMAT%" \
    --original-filenames=false \
    --placeholder-format ios \
    --export-empty-as skip \
    --replace-breaks=false \
    --unzip-to ./xliff_in

# create xlate_pr_title.txt using the date of the import from localize
# this overwrites any existing file because we want to capture the date of the latest download

section_divider
echo "Updated translations from lokalise on ${date}" > "${MESSAGE_FILE}"
echo "The standard translation commit message is stored in ${MESSAGE_FILE}"

section_divider
echo "To import from the xliff_in folder for each submodule, execute"
echo "./Scripts/manual_import_localizations.sh"
echo
echo "If you prefer to use a path other than '${DEFAULT_TRANSLATION_BRANCH}',"
echo " add that as the first argument on the import script"
section_divider
