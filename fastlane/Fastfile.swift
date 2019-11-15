// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
	func betaLane() {
	desc("Push a new beta build to TestFlight")
        let project = "Loop/Loop.xcodeproj"
        let buildNumber = numberOfCommits()

        incrementVersionNumber(versionNumber: "2.0", xcodeproj: project)
        incrementBuildNumber(buildNumber: buildNumber, xcodeproj: project)
        buildApp(scheme: "Loop (Workspace)", clean: true)
        uploadToTestflight(username: appleID, distributeExternal: true, teamId: teamID)
	}
}
