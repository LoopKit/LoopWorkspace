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
Повышена безопасность микроболюсов.

Микроболюсы будут работать, если:
- Текущее значение глюкозы выше порога остановки;
- Предсказанное значение глюкозы выше порога остановки;
- Текущее значение выше цели;
- Предсказанное значение выше цели.

На графики добавлена отметка текущего времени.

Возможно(!) исправлен баг со слетающими настройками после перезагрузки телефона.
"""

        incrementVersionNumber(versionNumber: version, xcodeproj: project)
        incrementBuildNumber(buildNumber: buildNumber, xcodeproj: project)
        buildApp(scheme: scheme, clean: true)
        uploadToTestflight(username: appleID, changelog: changelog, distributeExternal: true, groups: groups, teamId: itcTeam)
	}
}
