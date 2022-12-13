# Using Github Actions + FastLane to deploy to TestFlight

These instructions allow you to build Loop without having access to a Mac. They also allow you to easily install Loop on phones that are not connected to your computer. So you can send builds and updates to those you care for easily, or have an easy to access backup if you run Loop for yourself. You do not need to worry about correct Xcode/Mac versions either. An app built using this method can easily be deployed to newer versions of iOS, as soon as they are available.

## Prerequisites.

You don't need much!

* A github account. The free level comes with plenty of storage and free compute time to build loop, multiple times a week, if you wanted to.
* A paid Apple Developer account. You may be able to use the free version, but that has not been tested.


## Apple Developer Steps

1. Sign in to the [Apple developer portal page](https://developer.apple.com/account/resources/certificates/list)
1. Copy the team id from the upper right of the screen. Record this as your `TEAMID`
1. Go to the [App Store Connect](https://appstoreconnect.apple.com/access/api) interface, click the "Keys" tab, and create a new key with "Admin" access. Give it a name like "FastLane API Key"
1. Record the key id; this will be used for `FASTLANE_KEY_ID`
1. Record the issuer id; this will be used for `FASTLANE_ISSUER_ID`
1. Download the API key itself, and open it in a text editor. The contents of this file will be used for `FASTLANE_KEY`
1. At the [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/bundleId/add/bundle) page, add a new app identifier.
  * Description: Loop
  * The Bundle ID will be explicit and in the form `com.TEAMID.loopkit.Loop`, where `TEAMID` is your the value you recorded above.
  * For capabilities, check "App Groups, "HealthKit", "SiriKit", and "Time Sensitive Notifications"
  * Then click "Continue", and "Register".
1. Go to the [apps list](https://appstoreconnect.apple.com/apps) on App Store Connect and create a New App.
  * Select "iOS"
  * Select a name: this will have to be unique, so you may have to try a few different names here, but it will not be the name you see on your phone, so it's not that important.
  * Select your primary language
  * Select the Bundle Id you created above.
  * SKU can be anything; e.g. "123"
  * Select "Full Access"
  * Click Create
  * You do not need to fill out the next form. That is for submitting to the app store.

## GitHub Configuration Steps

1. Create a new empty repository titled `Match-Secrets`
1. Fork https://github.com/LoopKit/LoopWorkspace into your account.
1. Create a [new personal access token](https://github.com/settings/tokens/new)
  * Enter a name for your token. Something like "FastLane Access Token".
  * 30 days is fine, or you can select longer if you'd like.
  * Select the `repo` permission scope.
  * Click "Generate token"
  * Copy the token and record it. It will be used below as `GH_PAT`
1. In the forked LoopWorkspace repo, go to Settings -> Secrets -> Actions
1. For each of the following secrets, tap on "New repository secret", then add the name of the secret, along with the value you recorded for it:
  * `TEAMID`
  * `FASTLANE_KEY_ID`
  * `FASTLANE_ISSUER_ID`
  * `FASTLANE_KEY`
  * `GH_PAT`
  * `MATCH_PASSWORD` - just make up a password for this

## Build Loop!

1. Click on the "Actions" tab of your LoopWorkspace repository.
1. Select "Build Loop"
1. Click "Run Workflow", select your branch, and tap the green button.
1. Wait, and your app should eventually appear on [App Store Connect](https://appstoreconnect.apple.com/apps)
1. For each phone/person you would like to support Loop on, send an invite to using the TestFlight 