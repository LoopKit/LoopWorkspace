// This file contains the fastlane.tools configuration
// You can find the documentation at https://docs.fastlane.tools
//
// For a list of all available actions, check out
//
//     https://docs.fastlane.tools/actions
//

import Foundation

class Fastfile: LaneFile {
	func archiveLane() {
        desc("Archive")

        let project = "Loop/Loop.xcodeproj"
        let scheme = "Loop (Workspace)"
        let version = "2.1"
        let buildNumber = numberOfCommits()

        incrementVersionNumber(versionNumber: version, xcodeproj: project)
        incrementBuildNumber(buildNumber: buildNumber, xcodeproj: project)
        buildApp(scheme: scheme, clean: true, skipPackageIpa: true)
	}
}
