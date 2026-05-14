# Contributing to Loop

Thank you for your interest in contributing to Loop.

Loop is a community effort, and contributions of all kinds are welcome. This document outlines some guidelines, good practices, and expectations for contributing to the project, with the goal of making collaboration and review as smooth as possible.

Whether you are helping other users, improving documentation, translating the app, testing builds, reviewing code, or contributing new features and fixes, your work matters.

Loop is built using the LoopWorkspace repository. The primary source for the app is at https://github.com/LoopKit/LoopWorkspace.

## Ways to contribute

There are many ways to support the Loop community:

- **Help others** by answering questions and guiding users in support communities.
- Improve the **documentation** by updating or expanding LoopDocs.
- Improve the **app** by contributing code, fixes, features, or tests.
- Help with **translation and localization** through Loop lokalise.
- Support **testing and feedback** by validating changes and reporting issues clearly.

### Pay it forward

If Loop has helped you manage your diabetes successfully, consider paying it forward by helping others. Answering questions in [Loop Zulipchat](https://loop.zulipchat.com/) or the [Loop and Learn](https://www.facebook.com/groups/LOOPandLEARN) Facebook group can make a real difference for someone getting started.

### Translate

Loop is translated into multiple languages to make it easier to understand and use around the world. Translation for the submodules that make up the Loop app is managed through the [Loop lokalise project](https://loopkit.github.io/loopdocs/faqs/app-translation/#code-translation) and does not require programming experience.

If your preferred language is missing, or you would like to improve an existing translation, please sign up as a translator following the directions in the link above.

### Develop

Do you work with Swift? UI/UX? Testing? API optimization? Data storage?

Loop is a collaborative project, and contributions of all kinds are welcome. Whether you are writing code, improving the user experience, testing builds, helping with documentation, or contributing in other ways, your help matters.

## General principles

- Start small. Smaller, focused contributions are easier to review, test, and merge.
- For larger changes or new features, open or reference an issue first so there is a clear place for discussion and progress tracking.
- Reach out early if you are planning to work on something substantial, especially if it may overlap with work already in progress.
- Keep discussions constructive, respectful, and focused on improving Loop for the community.
- Remember that Loop is part of a wider open source AID ecosystem. Collaboration and maintainability matter just as much as shipping features.

## Development guidelines

### Coding conventions

- Use Xcode and follow the existing formatting and style used throughout the codebase.
- Keep indentation and formatting consistent in every file you change.
- Format your code before committing.
- Avoid unrelated formatting-only changes in files you are not otherwise modifying.
- Choose clear, readable code over clever or overly compact solutions.
- Follow existing naming, file organization, and architectural patterns unless there is a good reason not to.

### Strings and localization

- Add new user-facing strings in the appropriate localization mechanism used by the app.
- Provide English source strings only unless the contribution is specifically about translations.
- Translation and localization for other languages should go through the [Loop lokalise project](https://loopkit.github.io/loopdocs/faqs/app-translation/#code-translation).

### Documentation

- Update docstrings when your change affects setup, configuration, behavior, workflows, or troubleshooting.
- Keep documentation changes clear and practical.
- ocumentation contributions are just as valuable as code contributions.

## Branches, commits, and pull requests

### Getting started

The example below is for the Loop repository. Similar contributions can be made to other respositories as needed.

1. Fork the `dev` branch of the [Loop repository](https://github.com/LoopKit/Loop) on GitHub.
1. Create a separate branch for each feature or fix with an [appropriate name](#branch-names).
1. Branch from the most recent appropriate development branch (typically `dev`).
1. Commit your changes to your fork.
1. When ready, open a pull request against the upstream repository (`LoopKit/Loop`).

### Before opening a pull request

- Rebase or otherwise sync your branch with the latest target branch.
- Make sure your change is focused and does not include unrelated edits.
- Test your changes as thoroughly as you reasonably can.
- Update relevant documentation when needed.
- Double-check for debug code, commented-out code, accidental version changes, or temporary workarounds left behind.

### Pull request guidance

- Keep pull requests as small and focused as practical.
- Use a clear title and description.
- Explain **what** changed and **why**.
- Link the relevant issue when applicable.
- Mention any areas that need particular review attention.
- Be open to feedback and follow-up changes during review.
- Use AI tools, if at all, as a support for small, well-understood tasks rather than to generate large parts of a contribution
- Do not submit AI-heavy or "vibe-coded" pull requests; we welcome thoughtful use of tooling, but contributions need to be intentionally designed.

## Naming conventions

### Branch names

Use short, descriptive branch names that make the purpose of the change obvious. For example:

- `fix/watchstate-sync`
- `feature/onboarding-target-behavior`
- `refactor/therapy-editor`

### Pull request titles

Use concise, descriptive pull request titles. Good titles usually start with the type of change, for example:

- `Fix watch state sync timing issue`
- `Add onboarding step for target behavior`
- `Update build documentation`

## Communication and coordination

For new ideas, larger features, or work that may affect multiple parts of the app, **discuss it with the community first** — reach out to the contributor core on [Loop Zulipchat](https://loop.zulipchat.com/). This helps reduce duplicate work, avoid merge conflicts, and improve the final design.

## Review expectations

Please remember that Loop is maintained by contributors with limited time. Reviews may take time, and some pull requests may require iteration before they are ready to merge.

To help keep reviews efficient:

- Keep the scope narrow.
- Explain your reasoning clearly.
- Respond to review comments directly.
- Avoid force-pushing large unexplained rewrites during active review unless necessary.
- AI-assisted work is welcome for limited, well-understood tasks, but contributions should remain author-driven and must be code you fully understand, and can explain.

We do not accept pull requests that are largely AI-generated or submitted without careful engineering judgment, testing, and alignment with Loop’s existing patterns.

## Final note

Loop exists because people choose to contribute their time, knowledge, and care to a shared effort. Thank you for helping improve the project and support the broader open source AID community.
