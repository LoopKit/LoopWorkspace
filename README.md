# Attention please!

There are so many people who rely on the FreeAPS fork of Loop that it has been forked again to the loopnlearn github site. There are no guarantees as to how long this support can be maintained, but the loopnlearn team will do their best and are willing to accept pull requests.

With the advent of maintenance by loopnlearn, the [FreeAPS crowdin](https://crowdin.com/project/freeaps-settings) has been expanded to cover more strings.

Ivan - the originator of the FreeAPS project (ivalkou github site) has frozen his repository. All the forces of Ivan's team are aimed at developing a new project FreeAPS X based on OpenAPS.

# LoopWorkspace - Build Using Script

To simplify building FreeAPS, the loopnlearn team developed a script. It works for Loop and for FreeAPS and is documented in two places. (LoopDocs has more details and graphics - both sites have the same information.)

You can use the copy buttons below on this page to access the same script if you choose.

**If you have not already ensured your macOS and Xcode versions are consistent with your iPhone iOS, please use these links and follow the instructions.**

* Loop and Learn website: [Build Select Script](https://www.loopandlearn.org/build-select/)
* LoopDocs website: [LoopDocs Updating](https://loopkit.github.io/loopdocs/build/updating)

There is a copy button located by hovering on the right-hand side of the text blocks below. Click on it, all the words in the block are copied into your paste buffer, and then you can paste the words into the terminal.

## Run Script - Answer the Questions

First time users should run the script and answer the questions. Copy and paste in a terminal.

``` title="Execute Utilities to Clean Profiles and Derived Data"
/bin/bash -c "$(curl -fsSL https://git.io/JImiE)"
```

## One-Step Actions

For experienced users who have already verified their macOS and Xcode versions, two one-step copy blocks are provided to perform the two actions required for a rebuild. Paste each set of commands into a terminal. Review output for errors - if there are errors, please use the LoopDocs link.


### Clean Profiles and Derived Data

This starts the script and answers the questions to run the utility to give you a full-year of the app if you have a paid Apple Developer ID and clean out Derived Data from previous Xcode activity on your computer.

``` title="Execute Utilities to Clean Profiles and Derived Data"
/bin/bash -c "$(curl -fsSL https://git.io/JImiE)"
1
3
3
```

### Download FreeAPS and Open Xcode

This starts the script and answers the questions to download the FreeAPS code (LoopWorkspace branch=freeaps).

Once downloaded (in the ~/Downloads/BuildLoop folder), the script:
* Opens Xcode in the correct directory
* Opens browser showing a helpful graphic of build steps

``` title="Download FreeAPS and Open Xcode"
/bin/bash -c "$(curl -fsSL https://git.io/JImiE)"
1
1
2
1
```

# LoopWorkspace - Manual Build

This section has the manual steps if you do not choose to use the script.

## Clone

This repository uses git submodules to pull in the various workspace dependencies.

To clone this repo:

```
git clone --branch=freeaps --recurse-submodules https://github.com/loopnlearn/LoopWorkspace
```


## Open

Change to the cloned directory and open the workspace in Xcode:

```
cd LoopWorkspace
xed .
```

## Build

Select the "Loop (Workspace)" scheme (not the "Loop" scheme) and Build, Run, or Test.

<a href="/docs/scheme-selection.png"><img src="/docs/scheme-selection.png?raw=true" alt="Image showing how to select the Loop (Workspace) scheme in Xcode" width="400"></a>
