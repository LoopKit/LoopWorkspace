#!/bin/zsh

# This script creates the xliff files suitable to upload to lokalise

# You must be in the LoopWorkspace folder before executing with:
# ./Scripts/manual_export_localizations.sh

set -e
set -u

source Scripts/define_common.sh

argstring="${LANGUAGES[@]/#/-exportLanguage }"
IFS=" "; args=( $=argstring )

xcodebuild -scheme LoopWorkspace -destination 'generic/platform=iOS' -exportLocalizations -localizationPath xclocs $args

mkdir -p xliff_out
find xclocs -name '*.xliff' -exec cp {} xliff_out \;

if (( ${#FILE_ORIGINAL_PATHS_TO_REMOVE[@]} > 0 )); then
    echo ""
    echo "Removing phantom xliff sections..."
    python3 Scripts/remove_xliff_sections.py xliff_out "${FILE_ORIGINAL_PATHS_TO_REMOVE[@]}"
fi

echo ""
echo "Next step is to upload the xliff_out files to lokalise with"
echo "./Scripts/manual_upload_to_lokalise.sh"