# LoopWorkspace

## Clone

This repository uses git submodules to pull in the various workspace dependencies.

To clone this repo:

```
git clone --branch=<branch> --recurse-submodules https://github.com/LoopKit/LoopWorkspace
```

Replace `<branch>` with the initial LoopWorkspace repository branch you wish to checkout.

## Open

Change to the cloned directory and open the workspace in Xcode:

```
cd LoopWorkspace
xed .
```

## Input your development team

You should be able to build to a simulator without changing anything. But if you wish to build to a real device, you'll need a developer account, and you'll need to tell Xcode about your team id, which you can find at https://developer.apple.com/.

Select the LoopConfigOverride file in Xcode's project navigator, uncomment the `LOOP_DEVELOPMENT_TEAM`, and replace the existing team id with your own id.

## Build

Select the "Loop (Workspace)" scheme (not the "Loop" scheme) and Build, Run, or Test.

<a href="/docs/scheme-selection.png"><img src="/docs/scheme-selection.png?raw=true" alt="Image showing how to select the Loop (Workspace) scheme in Xcode" width="400"></a>

