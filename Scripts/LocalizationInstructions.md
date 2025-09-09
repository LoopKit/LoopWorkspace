# Manual Localization Instructions

Table of Contents:

* [Overview](#overview)
    * [Overview: From lokalise to LoopWorkspace](#overview-from-lokalise-to-loopworkspace)
    * [Overview: From LoopWorkspace to lokalise](#overview-from-loopworkspace-to-lokalise)
* [Loop Dashboard at lokalise](#loop-dashboard-at-lokalise)
* Script Usage
* Translations
* From lokalise to LoopWorkspace
    * [Download from lokalise](#download-from-lokalise)
    * [Import xliff files into LoopWorkspace](#import-xliff-files-into-loopworkspace)
    * [Review Differences](#review-differences)
    * [Commit Submodule Changes and Create PRs](#commit-submodule-changes-and-create-prs)
    * [Review the Open PR and merge](#review-the-open-pr-and-merge)
* [Finalize with PR to LoopWorkspace](#finalize-with-pr-to-loopworkspace)
* From LoopWorkspace to lokalise
    * [Prepare xliff_out folder](#prepare-xliff_out-folder)
    * [Update lokalise strings](#update-lokalise-strings)
* [Utility Scripts](#utility-scripts)
* [Questions and notes](#questions-and-notes)

## Overview

Translations for Loop are performed by volunteers at [lokalise](https://app.lokalise.com/projects). 
Several scripts were added to assist in bringing those translations into the repositories and updating keys when strings are added or modified.

To volunteer, join [Loop zulipchat](https://loop.zulipchat.com/) and send a direct message to Marion Barker with your email address and the language(s) you can translate.

The first set of scripts were created in 2023 to automate the localization process. (Refer to these as the original scripts.)

* Scripts/import_localizations.sh
* Scripts/export_localizations.sh

About the naming:

* The "import" in the original script name refered to importing xliff files from lokalise to provide updated localization strings for LoopWorkspace and associated submodules
    * This script was used to bring in new translations into the LoopWorkspace submodules and autocreate PR
* The "export" in the original script name refered to exporting localization from LoopWorkspace and associated submodules into xliff files and uploading them to the lokalise site
    * This script was used to upload the strings in any of the workspace submodules

New scripts were created in 2025 to provide smaller steps and to allow review before the modifications are committed and PR are opened.

These new scripts have "manual" in the script name.

### Overview: From lokalise to LoopWorkspace

For details, see [From lokalise to LoopWorkspace](#from-lokalise-to-loopworkspace)

These scripts break the original import_localizations script into smaller components:

* manual_download_from_lokalise.sh
* manual_import_localizations.sh
* manual_review_translations.sh
* manual_finalize_translations.sh

### Overview: From LoopWorkspace to lokalise

For details, see [From LoopWorkspace to lokalise](#from-loopworkspace-to-lokalise)

This script prepares xliff files for each language (for all repositories) from LoopWorkspace suitable to be uploaded to lokalise:

* manual_export_localizations.sh
* manual_upload_to_lokalise.sh
 
## Loop Dashboard at lokalise

When you log into the [lokalise portal](https://app.lokalise.com/projects), navigate to the Loop dashboard, you see all the languages and the % complete for translation.

## Translations

The translations are performed by volunteers. To volunteer, join [Loop zulipchat](https://loop.zulipchat.com/) and send a direct message to Marion Barker with your email address and the language(s) you can translate.

## Script Usage

Some scripts require a LOKALISE_TOKEN. 

When the user is a manager for the Loop project at lokalise, they create a LOKALISE_TOKEN (API token) with read/write privileges.

* API tokens can be created and recovered by going to : https://app.lokalise.com/profile/?refresh6656#apitokens

Once the token is created, export the token, e.g.,

```
export LOKALISE_TOKEN=<token>
```

Make sure the scripts are executable. If not, apply `chmod +x` to the scripts.

## From lokalise to LoopWorkspace

This has been broken into 4 separate scripts to allow review at each step.

### Download from lokalise

The `manual_download_from_lokalise.sh` script requires a LOKALISE_TOKEN with at least read privileges, see [Script Usage](#script-usage).

This script:

* deletes any existing xliff_in folder
* downloads the localization information from lokalise into a new xliff_in folder
* generates a temporary `xlate_pr_title.txt` file used for the commit message and titles for PRs to the submodules and LoopWorkspace

If you get a warning: `Warning: Project too big for sync export. Please use our async export endpoint instead`
just try again and it will work on another attempt.

### Import xliff files into LoopWorkspace

**Bullet summary** of the `manual_import_translations.sh` script:

* create `translations` branch for each submodule (project)
* command-line Xcode build before importing xliff files
* command-line Xcode build for each language importing from the associated xliff file
* after completion, LoopWorkspace may have uncommitted changes in submodules

**Descriptive summary** of the  `manual_import_translations.sh` script.

The `manual_import_translations.sh` script pulls the most recent tip from each submodule, creates a `translations` branch at that level in preparation for importing the localizations from xliff_in into LoopWorkspace and all the submodules.

> Warning: this deletes any existing `translations` branch from each submodule. If you need to "save your work", check out [Utility Scripts](#utility-scripts).

It then goes through each language and brings in updates from the xliff_in folder.

The result is that any updated localizations shows up as a diff in each submodule.

> The default branch name used for all the submodules is `translations`. If you want to modify that, edit Scripts/define_common.sh and change `translation_branch` before executing the script. This change will then be reflected in 3 scripts: import, review and finalize. In general, it is best to stick with `translations` as the branch name.

Before running this script:

* Confirm the list of `projects` in Scripts/define_common.sh  is up to date regarding owner, repository name, repository branch
* Trim any branches on GitHub with the name `translations`
    * The trimming should have happened when the last set of translations PR were merged
    * If not, do it now

Execute this script:

```
./Scripts/manual_import_localizations.sh
```

### Review Differences

The `InfoPlist.strings` may already be included in some cases. Don't worry about those. But do not add new ones.

* If there is a change to the *.xcodeproj/project.pbxproj - it is probably duplicates of strings in files already included in the pbxproj file
    * make sure that any new strings in the new files are handled in the existing Localizable.strings files for each language that has a new lproj folder added at the top level
    * git restore the pbxproj file
    * rm the new folders that contain those strings
    * verify that LoopWorkspace still builds correctly
* Note - when there already duplicates of the same string in more than one lproj folder
    * save doing clean up for later
    * just do not add to the confusion for now

Use the `manual_review_translations.sh` script in one terminal and open another terminal if you want to look in detail at a particular submodule:

```
./Scripts/manual_review_translations.sh
```

After each submodule, if any differences are detected, the script pauses with the summary of files changed and allows time to do detailed review (in another terminal). Hit return when ready to continue the script.

Examine the diffs for each submodule to make sure they are appropriate.

### Commit Submodule Changes and Create PRs

> Before running this script, ensure that code builds using Mac-Xcode GUI.

**Bullet summary** of action for each submodule by the `manual_finalize_translations.sh` script:

* if there are no changes, no action is taken
* if there are changes
    * git add .; commit all with automated message
    * push the `translations` branch to origin
    * create a PR from `translations` branch to default branch for that repository
    * open the URL for the PR

**Descriptive summary** of action for each submodule by the `manual_finalize_translations.sh` script.

You should have trimmed any `translations` branches on any GitHub repositories before running the import script. If not, do it before running the `manual_finalize_translations.sh` script.

Once all the diffs have been reviewed and you are ready to proceed, run this script:

```
./Scripts/manual_finalize_translations.sh
```

Assuming the permission are ok for each repository that is being changed, this should run without errors, create the PRs and open each one.

If the person running the script does not have appropriate permissions to push the branch, the commits are already made for that repository before attempting to push, so the user can just run the script again to proceed to the next repository.

The missing PR need to be handled separately. But really the person running the script should have permissions to open new PR.

If an error is seen with this hint - you need to go to GitHub and trim the translations branch and then push and create the pr manually:

> Updates were rejected because the tip of your current branch is behind its remote counterpart.

### Review the Open PR and merge

At this point, get someone to approve each of the open PR and merge them. Be sure to trim the `translations` branch once the PR are merged.

## Finalize with PR to LoopWorkspace

Once all the translations branches for submodules are merged, run the script to prepare the PR to update LoopWorkspace.

> Normally, this script is run starting with dev branch

> For the case with script modifications, use a working branch from dev with the Scripts folder properly updated

**Bullet summary** `manual_LoopWorkspace_prepare_pr.sh` script:

* create translations branch (or use it if it already exists)
* execute update_submodule_refs.sh to bring in the tip of every submodule
* there should be changes for any updated submodules, if so
    * git commit -a using the automated commit message
    * push the `translations` branch to origin
    * create a PR from `translations` branch to dev branch for LoopWorkspace
    * open the URL for the PR

Make sure the new translations branch builds. Update the version number and add that commit to the PR.

```
./Scripts/manual_LoopWorkspace_prepare_pr.sh
```

## From LoopWorkspace to lokalise

### Prepare xliff_out folder

The `manual_export_translations.sh` script is used to prepare xliff files to be uploaded to lokalise for translation.

It is normally required for any code updates that add or modify the strings that require localization.

First navigate to the LoopWorkspace directory in the appropriate branch, normally this is the `dev` branch. Make sure it is fully up to date with GitHub.

Make sure the Xcode workspace is **not** open on your Mac or this will fail.

```
./Scripts/manual_export_localizations.sh
```

This creates an xliff_out folder filled with xliff files, one for each language, that contains all the keys and strings for the entire clone (including all submodules).

### Update lokalise strings

This script requires Read/Write token for lokalise. It uploads the xliff file for each language in the Xliff_out folder.

```
./Scripts/manual_upload_to_lokalise.sh
```

## Utility Scripts

Once the import and export process is completed, you can delete temporary files and folders using:

```
./Scripts/manual_cleanup.sh
```

The define_common.sh is used by other scripts to provide a single source for the list of:

* filename with message indicating download time from lokalise for commit messages and PR titles
* branch names used by some of the scripts for output and input
* LANGUAGES (list of all languages to be included)
* projects (all the submodules for LoopWorkspace with owners and branches)

If you need to start over but don't want to lose prior work, use archive_translations.sh. This is suitable for use after manual_import_localizations and manual_review_translations and before manual_finalize_translations.

If you want to change paths for translations and archived translations, edit Scripts/define_common.sh before running.

* archive_translations.sh
    * internal names that can be edited in define_common.sh:
        * archive_branch="test_translations"
        * translation_branch="translations"

## Questions and notes

Most of the questions were worked through while developing the new scripts.

#### Keys uploaded that not require translation

**Answer** Mark them as not visible to translators.

**Details**

The current method uploads some keys that do not need to be translated. Initially, a few keys were deleted from lokalise, but on the next upload, they were restored. So the next modification was to mark the keys as not visible to the translators.

Items already translated are brought down one time - go on and include those diffs and then next cycle, these should no longer be a problem.

Keys that were deleted on 2025-07-27, then later are restored as empty:

* CFBundleGetInfoString
* CFBundleNames
* NSHumanReadableCopyright

After the initial testing, some additional keys were marked as not visible. These were mostly identified when one or two translators were very thorough.

#### White space changes

**Answer** Accept these as a one-time change.

**Details**

A lot of the keys have different white space than the 2023 downloads. 
I discussed this with Pete and we agreed to do the one time change to all the repositories for the keys.

#### Downloaded Translations duplicated in Xcode

**Answer** Manual cleanup when doing the review until this duplication is figured out.

**Details**

LoopKit, OmniBLE and OmniKit seem to be adding new ll.lproj folders at the top level with the languages already being present in other folders. These have associated changes to the `pbxproj` file.

I spot checked and found the new Localize.strings in the new ll.lproj folders have the same translations in the other locations where those translations are placed by Xcode.

Essentially, when doing the review:

```
git restore ***.xcodeproj/project.pbxproj 
rm -rf ll.lproj

where *** is replaced by the submodule name
and ll is replaced by the language code
```

For the DanaKit module, rely on the repository owner to maintain the translations with crowdin (for now). Do not add extra files to the repository as was already done for OmniBLE and OmniKit. 

#### Status on 2025-08-10

Updated the LocalizationInstructions.md file after running through the sequence documented in this file:

1. Download from lokalise (manual_download_from_lokalise.sh)
2. Import into LoopWorkspace (manual_import_localizations.sh)
3. Review Differences (manual_review_translations.sh)
4. Commit Submodule Changes and Create PRs (manual_finalize_translations.md)

Only 4 PR were opened for this test, which were subsequently closed without merging. They helped with the testing process.

#### Status on 2025-08-24

Additional changes were made to the scripts and translations were merged into PR for 15 repositories from the download on 2025-08-24.

#### Status on 2025-08-30

Another cycle was completed, that included an upload to lokalise from the in-progress translations changes. Then a new download was processed.

The final step to test is the creation of the PR for LoopWorkspace dev branch. To do this, the final script will be tested.

