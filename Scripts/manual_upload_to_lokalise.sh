#!/bin/zsh

# This script will upload the xliff files from LoopWorkspace and submodules to lokalise

# Install the lokalise command line tools from https://github.com/lokalise/lokalise-cli-2-go
# Generate an API Token (not an SDK Token!) following the instructions here: https://docs.lokalise.com/en/articles/1929556-api-tokens
# export LOKALISE_TOKEN="<yourtokenhere>"

# The token must have read/write access or this script will fail

# This script should be run first:
# ./Scripts/manual_export_localizations.sh

# You must be in the LoopWorkspace folder before executing with:
# ./Scripts/manual_upload_to_lokalise.sh

set -e
set -u

: "$LOKALISE_TOKEN"

source Scripts/define_common.sh

section_divider
echo "You are running ${0}"
echo "  It will upload an xliff file for each language to lokalise"
echo "  from the xliff_out folder created by manual_export_localizations."
echo
echo "  Each uploaded file will be queued and processed"

continue_or_quit ${0}

cd xliff_out

foreach lang in $LANGUAGES

# modify the hyphen to underscore to support lokalise lang-iso expectation
lang_iso=$(sed "s/zh-Hans/zh_Hans/g; s/pt-BR/pt_BR/g" <<<"$lang")

lokalise2 \
    --token $LOKALISE_TOKEN \
    --convert-placeholders=false \
    --project-id 414338966417c70d7055e2.75119857 \
    file upload \
    --file ${lang}.xliff \
    --cleanup-mode \
    --lang-iso ${lang_iso}
end

section_divider
echo "Reminder: At lokalise, wait until all uploaded files are processed"
section_divider
