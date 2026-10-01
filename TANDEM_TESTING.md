# Tandem closed beta branch

This branch is LoopKit/LoopWorkspace `dev` plus one commit that adds
[TandemKit](https://github.com/jwoglom/TandemKit) (branch `main`) as a pump
manager. This should be identical to the `dev` branch of Loop, but with the 
option to add **Tandem Mobi** as a pump. TandemKit is a **private repository** 
while we are in closed beta testing, so you will be unable to build unless
you follow the directions below. 

TandemKit is for EXPERIMENTAL USE ONLY.

## Before you start

This branch is for the use of those participating in a closed beta test of using the 
Tandem Mobi with Loop. If you are not a member of the Closed Beta group, you cannot build this branch.

In order to build using this branch, you must send your GitHub user name to Eric Jensen via Direct Message 
on ZulipChat with your request to be included. This is only for expert testers who are experienced with Loop. 
Please let Eric know how long you have used Loop, if you ever tested a new pump manager and if you both have 
a Tandem Mobi and know how to use it. If you don't provide that information, you will receive a rejection. 
If you are accepted to the closed beta group, you will get a reply to your DM with additional information.


## Building the app

Both of these routes end with version of Loop that can use the Tandem Mobi.  The browser
build version adds a `feat/tandem-closed-beta` branch on your fork. Pick whichever you prefer.

### Building in the browser

#### Creating and building the new branch

1. On your LoopWorkspace fork, follow the Loopdocs instructions under "[Check Current Branch](https://loopkit.github.io/loopdocs/browser/build-dev-browser/#check-current-branch)" to navigate to the branches page and click the "New branch" button. 
2. Then, follow the screenshots just below that in the docs to create a new branch named
   `feat/tandem-closed-beta`based on the LoopKit branch of the same name.
3. Finally, follow the Loopdocs "[Build Branch](https://loopkit.github.io/loopdocs/browser/build-dev-browser/#build-branch)" instructions to select and build your new branch. 


### Building locally using Xcode

Follow the overall guidance in the Loopdocs "[Build Other Branches](https://loopkit.github.io/loopdocs/build/build-dev-mac/#build-other-branches)" section to use the build select script to download, customize (if desired), and build the `feat/tandem-closed-beta` branch.

First, copy and run this command in Terminal: 

```bash
/bin/bash -c "$(curl -fsSL \
  https://raw.githubusercontent.com/loopandlearn/lnl-scripts/main/BuildLoop.sh)" \
   - feat/tandem-closed-beta
```

Optionally, run the customization-select script as outlined in the docs.  Since this branch only adds a new pump manager module and doesn't otherwise change Loop, customizations that work for `dev` should apply cleanly here as well. 

Finally, open `LoopWorkspace.xcworkspace`, select the **LoopWorkspace** scheme, and build as usual.

#### Signing

If you put your Apple Developer Team ID two directory levels above the workspace folder, Xcode picks it up and signs automatically. If you use the build select script as above, copy the `LoopConfigOverride.xcconfig` file from the LoopWorkspace folder and make a copy in two levels up in `~/Downloads/BuildLoop/`, editing it to add your Team ID on the line that looks like this: 
```
LOOP_DEVELOPMENT_TEAM = ABCDE12345
```
Be sure to remove the `#` comment symbol from the beginning of the line. 
