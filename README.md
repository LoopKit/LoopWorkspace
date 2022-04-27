# Attention please!

There are so many people who rely on the FreeAPS fork of Loop that it has been forked again to the loopnlearn github site. There are no guarantees as to how long this support can be maintained, but the loopnlearn team will do their best and are willing to accept pull requests.

With the advent of maintenance by loopnlearn, the [FreeAPS crowdin](https://crowdin.com/project/freeaps-settings) has been expanded to cover more strings.

Ivan - the originator of the FreeAPS project (ivalkou github site) has frozen his repository. All the forces of Ivan's team are aimed at developing a new project FreeAPS X based on OpenAPS.

# LoopWorkspace - Build Using Script

To simplify building FreeAPS, the loopnlearn team developed a script. It works for Loop and for FreeAPS and is documented in two places. (LoopDocs has more details and graphics - both sites have the same information.)

**If you have not already ensured your macOS and Xcode versions are consistent with your iPhone iOS, please use these links and follow the instructions.**

* Loop and Learn website: [Build Select Script](https://www.loopandlearn.org/build-select/)
* LoopDocs website: [LoopDocs Updating](https://loopkit.github.io/loopdocs/build/updating)

# LoopWorkspace - Manual Build

This section has the manual steps if you do not choose to use the script.

## Clone

This repository uses git submodules to pull in the various workspace dependencies.

To manually clone this repo (without using the script mentioned above):

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
