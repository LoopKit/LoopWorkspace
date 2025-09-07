## Manual Localization Instructions

> This is work-in-progress. There are some open questions on how to deal with certain strings.

There are several scripts to automate the localization process. However, these localization scripts require access to tokens:

* export_localizations.sh
* import_localizations.sh

If access to these tokens is not available, but a user is a manager for the Loop project at lokalise, they can manually take those actions.

New scripts were created to provide a step-by-step manual process:

* manual_export_localizations.sh
* manual_import_localizations.sh
* manual_review_translations.sh
* manual_translations_finalize.sh

The summary action for these script is provided here, with details in the [Usage](#usage) section.

#### manual_export_localizations

* script to create xliff_out folder with xliff files in all languages suitable to drag and drop into lokalise

#### manual_import_localizations

* script to import from xliff_in folder
    * create `translations` branch for each project
    * command-line Xcode build before importing xliff files
    * command-line Xcode build for each language importing from the associated xliff file
    * after completion, LoopWorkspace has uncommitted changes in projects
    
#### manual_review_translations

* script to make it easy to review changes per submodule, shows diffs, and pause so manual modifications can be enacted if appropriate

#### manual_translations_finalize

* script to commit the change for each project folder (submodule)
    * if there are no changes, no action is taken
    * if there are changes
        * git add .; commit all with automated message
        * push the `translations` branch to origin
        * create a PR from `translations` branch to default branch for that repository
        * open the URL for the PR

## Usage

### Loop Dashboard at localise

When you log into the [lokalise portal](https://app.lokalise.com/projects) navigate to the Loop dashboard, you see all the languages and the % complete for translation.

#### Open questions

> Notes from Marion Barker:

##### Question 1:

I do not believe these keys should be included in the translation process:

* CFBundleGetInfoString
* CFBundleNames
* NSHumanReadableCopyright

These were almost all empty. I deleted these keys on 2025-07-27 on the lokalise site.

A few of them did have entries for some languages

* I have them archived locally and can restore them if they should have been kept

When uploading a new set of xliff_out files, they are recreated - so I think I'm missing a method to limit them.

Note that in the xliff files, these say translate="no", so why do they show up in the imported list on lokalise?

I will keep looking for help in the documentation, but if anyone knows - let me know.

Because of this uncertainty, I only modified the LibreTransmitter project so far because there is a hotfix needed for it.

##### Question 2:

A lot of the changes that were proposed were white space changes.

Here's an example:

```
diff --git a/RileyLinkKitUI/nb.lproj/Localizable.strings b/RileyLinkKitUI/nb.lproj/Localizable.strings
index fbfc31e..db53cbd 100644
--- a/RileyLinkKitUI/nb.lproj/Localizable.strings
+++ b/RileyLinkKitUI/nb.lproj/Localizable.strings
@@ -74,7 +74,7 @@
 "Name" = "Navn";
 
 /* Detail text when battery alert disabled.
-   Text indicating LED Mode is off */
+Text indicating LED Mode is off */
 "Off" = "Av";
 
 /* Text indicating LED Mode is on */
@@ -87,7 +87,7 @@
 "Signal Strength" = "Signalstyrke";
 
 /* The title of the section for orangelink commands
-   The title of the section for rileylink commands */
+The title of the section for rileylink commands */
 "Test Commands" = "Testkommandoer";
 
 /* The title of the cell showing Test Vibration */
```

I see no point in committing this kind of a change. There are other substantive changes in other projects, but there is so much noise from the white space changes, I would like to modify this so only translation updates are included.

##### Question 3:

Both OmniBLE and OmniKit seem to be adding new xx.lproj folders at the top level with the languages already being present in other folders. These have associated changes to the `pbxproj` file. I'm confused by this and wonder if this is something else that should be fixed.

### Export from LoopWorkspace

This section is used to update the strings in lokalise for translation.

First navigate to the LoopWorkspace directory in the appropriate branch. Make sure it is fully up to date with GitHub. Make sure the scripts are executable. You may need to apply `chmod +x` to the scripts.

Make sure the Xcode workspace is **not** open on your Mac or this will fail.

```
./Scripts/manual_export_localizations.sh
```

This creates an xliff_out folder filled with xliff files, one for each language, that contains all the keys and strings for the entire clone (including all submodules).


### Import into lokalise

This section requires the user have `manager` access to the Loop project.

Log into the [lokalise portal](https://app.lokalise.com/projects) and navigate to Loop.

Select [Upload](https://app.lokalise.com/upload/414338966417c70d7055e2.75119857/)

Drag the *.xliff files into the drag and drop location.

Be patient

* while each language is uploaded, the `uploading` indicator shows up under each language on the left side
* at the bottom of the list, the `Import Files` should be available when all have completed uploading
    * Tap on `Import Files`
* progress will show at upper right

When this is done, check the Loop lokalise dashboard again to see updated statistics.


### Translations

The translations are performed by volunteers. To volunteer, join [Loop zulipchat]() and send a direct message to Marion Barker with your email address and the language(s) you can translate.

### Export from lokalise

This section requires the user have `manager` access to the Loop project.

Log into the [lokalise portal](https://app.lokalise.com/projects) and navigate to Loop.

Select [Download](https://app.lokalise.com/download/414338966417c70d7055e2.75119857/)

* The default settings were adjusted to match those of the original script (import_localizations.sh)
* Click on the `Build and download` button at either the bottom of the screen or the top left


### Import into LoopWorkspace

When the download from lokalise completes, navigate to your ~/Download folder in finder:

* rename `Loop-Localizable.zip` to `xliff_in.zip`
* uncompress to create the xliff_in folder
* move the xliff_in folder to the top level of the LoopWorkspace folder

The default branch name used for all the submodules is `translations`. If you want to modify that, edit the script and change `translation_dir` before executing the script.

Confirm the list of `projects` in the script is up to date regarding owner, repository name, repository branch.

Execute this script:

```
./Scripts/manual_import_localizations.sh
```

### Commit Changes and Create PRs

Examine the diffs for each submodule to make sure they are appropriate.

There are some changes that are primarily white space, so I did not commit those.

See section on [Open questions](#open-questions).

Status on 2025-07-28:

* Previously LibreTransmitter translations were updated manually and that PR committed
* A hotfix is needed for LibreTransmitter to support European Libre 2 transmitters and it is ready to go
* A PR is merged to G7SensorKit that can be added along with the hotfix

Decided:

* Hotfix will include these prototype scripts and the modification listed above.
* Work will continue on the methodology to capture translations and bring them into Loop in the near future
* This instruction file will be updated as the learning process continues

### Utility Scripts

If you need to start over but don't want to lose prior work, edit this script for name of the branch to archive the translations and execute it.

* archive_translations.sh
    * internal names that can be edited:
        * archive_dir="test_translations"
        * translation_dir="translations"




