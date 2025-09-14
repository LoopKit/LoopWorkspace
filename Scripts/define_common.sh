#!/bin/zsh

# define parameters and arrays used by more than one script
#   These are always capitalized
#   First two can be replaced with arguments
#      TRANSLATION_BRANCH (arg 1)
#      TARGET_LOOPWORKSPACE_BRANCH (arg 2)
#      MESSAGE_FILE
#      ARCHIVE_BRANCH
#      PROJECTS
#      LANGUAGES

# include this file in each script using
#   source Scripts/define_commont.sh

# define the branch names used by the translation scripts
# Any script that uses define_common can be called with one or two optional arguments
#   first argument replaces default for TRANSLATION_BRANCH
#   second argument replaces default for TARGET_LOOPWORKSPACE_BRANCH
# Note: went for simplicity here - if you want to modify TARGET_LOOPWORKSPACE_BRANCH
#   via argument, you must also include TRANSLATION_BRANCH as an argument
DEFAULT_TRANSLATION_BRANCH="translations"
DEFAULT_TARGET_LOOPWORKSPACE_BRANCH="dev"

TRANSLATION_BRANCH=${1:-$DEFAULT_TRANSLATION_BRANCH}
TARGET_LOOPWORKSPACE_BRANCH=${2:-$DEFAULT_TARGET_LOOPWORKSPACE_BRANCH}

ARCHIVE_BRANCH="archive_translations"

# define name of file used to save the commit message and title for pull requests
MESSAGE_FILE="xlate_message_file.txt"

# define the languages used by the translation scripts
# matches lokalise order, en plus alphabetical order by language name in English
LANGUAGES=(en \
    ar \
    zh-Hans \
    cs \
    da \
    nl \
    fi \
    fr \
    de \
    he \
    hi ]
    it \
    ja \
    nb \
    pl \
    pt-BR \
    ro \
    ru \
    sk \
    es \
    sv \
    tr \
    vi \
)

# define the PROJECTS used by the translation scripts
PROJECTS=( \
    LoopKit:AmplitudeService:dev \
    LoopKit:CGMBLEKit:dev \
    LoopKit:dexcom-share-client-swift:dev \
    loopandlearn:DanaKit:dev \
    LoopKit:G7SensorKit:main \
    LoopKit:LibreTransmitter:main \
    LoopKit:LogglyService:dev \
    LoopKit:Loop:dev \
    LoopKit:LoopKit:dev \
    LoopKit:LoopOnboarding:dev \
    LoopKit:LoopSupport:dev \
    LoopKit:MinimedKit:main \
    LoopKit:NightscoutRemoteCGM:dev \
    LoopKit:NightscoutService:dev \
    LoopKit:OmniBLE:dev \
    LoopKit:OmniKit:main \
    LoopKit:RileyLinkKit:dev \
    LoopKit:TidepoolService:dev \
)

function section_divider() {
    echo -e ""
    echo -e "--------------------------------"
    echo -e ""
}

function continue_or_quit() {
    local script_name=$1
    section_divider
    echo "Enter y to proceed, any other character exits"
    read query

    if [[ ${query} != "y" ]]; then
        section_divider
        echo "User opted to exit ${script_name}."
        section_divider
        exit 1
    fi
}

function next_script() {
    local next_script_name=$1
    if [[ ${TRANSLATION_BRANCH} == ${DEFAULT_TRANSLATION_BRANCH} ]]; then
        echo "$next_script_name"
    else
        echo "$next_script_name ${TRANSLATION_BRANCH}"
    fi
}