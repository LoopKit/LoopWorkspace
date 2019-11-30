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
        let scheme = "Loop (Workspace)"
        let groups = ["Loopers"]
        let version = "2.0"
        let buildNumber = numberOfCommits()
        let changelog = """
Переработан код микроболюсов. На их работе не отразилось, кроме следующего момента:
    - Если текущая глюкоза ниже целевого диапазона, то микроболюсы ограничены 30 базальными минутами.

ВАЖНО! Необходимо зайти на экран микроболюсов и заново их настроить!

Исправлен баг с сохранением пустого Nightscout CGM.

Исправлено открытие экрана микроболюсов при редактировании углеводов.
"""

        incrementVersionNumber(versionNumber: version, xcodeproj: project)
        incrementBuildNumber(buildNumber: buildNumber, xcodeproj: project)
        buildApp(scheme: scheme, clean: true)
        uploadToTestflight(username: appleID, changelog: changelog, distributeExternal: true, groups: groups, teamId: itcTeam)
	}
}
