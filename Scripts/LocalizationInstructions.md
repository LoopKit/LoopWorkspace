# Manual Localization Instructions

Table of Contents:

* [Overview](#overview)
    * [Overview: From lokalise to LoopWorkspace](#overview-from-lokalise-to-loopworkspace)
    * [Overview: From LoopWorkspace to lokalise](#overview-from-loopworkspace-to-lokalise)
* [Loop Dashboard at lokalise](#loop-dashboard-at-lokalise)
* [Script Usage](#script-usage)
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

* The "import" in the original script name refers to importing xliff files from lokalise to provide updated localization strings for LoopWorkspace and associated submodules
    * This script was used to bring in new translations into the LoopWorkspace submodules and autocreate PR
* The "export" in the original script name refers to exporting localization from LoopWorkspace and associated submodules into xliff files and uploading them to the lokalise site
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

Many scripts import parameters from Scripts/define_common.sh. These are always capitalized. The first two can be replaced with arguments
* TRANSLATION_BRANCH (optional arg 1)
* TARGET_LOOPWORKSPACE_BRANCH (optional arg 2)
* MESSAGE_FILE
* ARCHIVE_BRANCH
* PROJECTS
* LANGUAGES

The PROJECTS array lists all the submodules that are handled by these import/export scripts.

The LANGUAGES array lists all the languages that are handled by the Loop project.

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
* final message provides information about next script to execute

|   |   |
|:--|:--|
 |**Optional arguments**: | none |
| **Products**: | `xliff_in` folder with xliff files and `xlate_pr_title.txt` with download timestamp |
| **Warnings**: | the previous `xliff_in` folder and `xlate_pr_title.txt` file are replaced |
|   |   |

### Import xliff files into LoopWorkspace

**Bullet summary** of the `manual_import_translations.sh` script:

* create `translations` branch for each submodule (project) if it does not already exist
* command-line Xcode build for each language importing from the associated xliff file
* after completion, LoopWorkspace may have uncommitted changes in submodules
* final message provides information about next script to execute
* this script can be repeated with a fresh download from localize to add to an existing translation session

|   |   |
|:--|:--|
 |**Optional arguments**: | the name of the `translations` branch can be modified with an optional argument |
| **Products**: | any of the submodules associated with LoopWorkspace may be modifed if any new translations are imported for that submodule |
| **Warnings**: | - The first time you run this for a given translation session, be sure you start from version of LoopWorkspace you want to update<br>- Subsequent runs will add additional translations to the same branch names |
|   |   |

**Descriptive summary** of the  `manual_import_translations.sh` script.

Typically, when preparing to update from LoopWorkspace dev, Script/update_submodule_ref.sh is run to prepare the submodules so each one is configured for the subsequent submodules PRs to bring in the translations back to GitHub.

However, the script can be repeated for more than one download. In this case, the new import is added on top of existing changes.

The `manual_import_translations.sh` script goes through each submodule in the PROJECTS list.

Each submodule branch is examined and set to the `translations` branch:
* if the branch does not exist it is created from the current branch

Then an xcodebuild command is executed to import each language in turn. This can take a very long time, so be patient.

The result is that any updated localizations shows up as a diff in each submodule.

Execute this script:

```
./Scripts/manual_import_localizations.sh <optional-string-for-specific-branch-name>
```

The final message from the script includes the command needed to execute the next script.
* if this script was called with an optional argument, the next script suggestion includes the same argument for you to copy and paste.


### Review Differences

Use the `manual_review_translations.sh` script in one terminal and open another terminal if you want to look in detail at a particular submodule:

|   |   |
|:--|:--|
 |**Optional arguments**: | the name of the `translations` branch can be changed to the first argument |
| **Products**: | there are no changes - this is used to review changes before committing them |
| **Warnings**: | none |
|   |   |

Execute this script:

```
./Scripts/manual_review_translations.sh <optional-string-for-specific-branch-name>
```

For each submodule, if any differences are detected, the script pauses with the summary of files changed (`git status`) and allows time to do detailed review (`git diff`) (in another terminal). Hit return when ready to continue the script.

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

|   |   |
|:--|:--|
 |**Optional arguments**: | the name of the `translations` branch can be changed to the first argument |
| **Products**: | a PR will be opened, or updated, for every submodule for which new localizations are imported |
| **Warnings**: | If there are out-of-date `translations` branches on submodule GitHub repositories from an older translation session, you will get an error<br>**However**, current branches can be used and will accept updated commits if more than one download is used for this session. |
|   |   |

**Descriptive summary** of action for each submodule by the `manual_finalize_translations.sh` script.

Once all the diffs have been reviewed and you are ready to proceed, run this script:

```
./Scripts/manual_finalize_translations.sh <optional-string-for-specific-branch-name>
```

Assuming the permission are ok for each repository that is being changed, this should run without errors, create the PRs and open each one.

If the person running the script does not have appropriate permissions to push the branch or if the branch exists at GitHub and is out of date, the commits are already made for that repository before attempting to push, so the user can just run the script again to proceed to the next repository.

The skipped PR need to be handled separately. But really the person running the script should have permissions to open new PR and the `translations` branches should all be trimmed when the PR are merged so there won't be a conflict next time.

If an error is seen with this hint - you need to go to GitHub and trim the translations branch and then push and create the pr manually:

> Updates were rejected because the tip of your current branch is behind its remote counterpart.

### Review the Open PR and merge

At this point, get someone to approve each of the open PR and merge them. Be sure to trim the `translations` branch once the PR are merged.

## Finalize with PR to LoopWorkspace

Once all the PR submodules are merged, prepare your local LoopWorkspace clone to use the submodule PR that were just merged; `Scripts/update_submodules_ref.sh` can do this for you. 

* The only changes to LoopWorkspace when running this script should be the localization changes in the submodules
* You can include additional changes, but they need to be committed either before or after running this script

> Before running this script, ensure that code builds using Mac-Xcode GUI.

Run the script to prepare the PR to update LoopWorkspace. 

**Bullet summary** `manual_LoopWorkspace_prepare_pr.sh` script:

* create `translations` branch for LoopWorkspace (if one does not exist)
* commit all changes in tracked files for LoopWorkspace and prepare
    * `git commit -a -F` using the automated commit message file
    * push the `translations` branch to origin
    * create a PR from `translations` branch to `dev` branch for LoopWorkspace
    * open the URL for the PR

Update the version number and add that commit to the PR before merging.

Allow time for testing and be sure Mac Xcode Build and Browser Build are successful.

|   |   |
|:--|:--|
 |**Optional arguments**: | - the name of the `translations` branch can be changed to the first argument<br>- the name of the target branch (`dev`) can be changed to the second argument|
| **Products**: | a PR will be opened with the modified version of LoopWorkspace with all modified submodules updated |
| **Warnings**: | this should be run only once after all submodule PRs are merged and LoopWorkspace diffs should be limited to submodule updates<br>Additional changes should be pushed as separate commit |
|   |   |

```
./Scripts/manual_LoopWorkspace_prepare_pr.sh  <optional-string-for-specific-branch-name>  <optional-string-to replace-dev-for-PR-target>
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
* PROJECTS (all the submodules for LoopWorkspace to localize with owners and branches)

If you need to start over but don't want to lose prior work, use archive_translations.sh. However, this is probably no longer necessary with the optional arguments available with the manual scripts.

## Questions and notes

Most of the questions were worked through while developing the new scripts.

#### Keys uploaded that not require translation

* **Answer** Mark them as not visible to translators.

* **Details**

    > The current method uploads some keys that do not need to be translated. Initially, a few keys were deleted from lokalise, but on the next upload, they were restored. So the next modification was to mark the keys as not visible to the translators.

    > Items already translated are brought down one time - go on and include those diffs and then next cycle, these should no longer be a problem.

    > Keys that were deleted on 2025-07-27, then later are restored as empty, CFBundleGetInfoString, CFBundleNames,  NSHumanReadableCopyright

#### White space changes

* **Details** removed from this file

* **Follow up** This is no longer an issue with String Catalogs.

#### Downloaded Translations duplicated in Xcode

* **Details** removed from this file

* **Follow up** This is no longer an issue with String Catalogs.

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

#### Status on 2025-09-07

The transition to String Catalogs is in process using the branch name `convert_to_xcstrings`.  Several commits will be added to the submodules PRs before they are finally merged.

While doing that work, a temporary LoopWorkspace branch is in use for testing. Once completed, this branch will be trimmed.
* https://github.com/LoopKit/LoopWorkspace/commits/prepare_workspace_convert_to_xcstrings/

**Summary**:
1. The uploaded files to lokalise have all been converted to String Catalogs.

2. The duplicate finder tool was run at lokalise to capture translations that already existed by linking terms.

3. Some additional strings were identified (or removed from) localization for the Loop submodule and added to the in-process PR.

4. Some additional Xcode settings may be required and will also be added to the open PRs.
