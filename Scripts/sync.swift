#!/usr/bin/swift sh

// Depends on swift-sh.  Install with: `brew install swift-sh`

import Foundation
import Cocoa

import AsyncSwiftGit // @bdewey
import OctoKit // /Users/pete/dev/octokit.swift

struct Project {
    let project: String
    let branch: String

    init(_ project: String, _ branch: String) {
        self.project = project
        self.branch = branch
    }
}

let projects = [
   Project("Loop", "dev"),
   Project("LoopKit", "dev"),
   Project("CGMBLEKit", "dev"),
   Project("dexcom-share-client-swift", "dev"),
   Project("RileyLinkKit", "dev"),
   Project("NightscoutService", "dev"),
   //Project("TrueTime.swift", "dev"),
   Project("LoopOnboarding", "dev"),
   Project("AmplitudeService", "dev"),
   Project("LogglyService", "dev"),
   Project("OmniBLE", "dev"),
   Project("NightscoutRemoteCGM", "dev"),
   Project("LoopSupport", "dev"),
   Project("G7SensorKit", "dev"),
   Project("TidepoolService", "dev"),
   Project("TidepoolKit", "dev"),
   Project("OmniKit", "main"),
   Project("MinimedKit", "main")
]

let fm = FileManager.default
let loopkit = URL(string: "https://github.com/LoopKit")!
let tidepool = URL(string: "https://github.com/tidepool-org")!
let syncBranch = "tidepool-sync"
let incomingRemote = "tidepool"

enum EnvError: Error {
    case missing(String)
}

func getEnv(_ name: String) throws -> String {
    guard let value = ProcessInfo.processInfo.environment[name] else {
        throw EnvError.missing(name)
    }
    return value
}

let ghUsername = try getEnv("GH_USERNAME")
let ghToken = try getEnv("GH_TOKEN")
let ghCommitterName = try getEnv("GH_COMMITTER_NAME")
let ghCommitterEmail = try getEnv("GH_COMMITTER_EMAIL")

let octokit = Octokit(TokenConfiguration(ghToken))

let credentials = Credentials.plaintext(username: ghUsername, password: ghToken)
let signature = try! Signature(name: ghCommitterName, email: ghCommitterEmail)

for project in projects {
    let dest = URL(string: fm.currentDirectoryPath)!.appendingPathComponent(project.project)
    let repository: AsyncSwiftGit.Repository
    if !fm.fileExists(atPath: project.project) {
        print("Cloning \(project.project)")
        let url = loopkit.appendingPathComponent(project.project)
        repository = try await Repository.clone(from: url, to: dest)
        print("Cloned \(project.project)")
    } else {
        print("Already Exists: \(project.project)")
        repository = try Repository(openAt: dest)
    }

    let incomingRemoteURL = tidepool.appendingPathComponent(project.project)

    // Add remote if it doesn't exist, and fetch latest changes
    if (try? repository.remoteURL(for: incomingRemote)) == nil {
        try repository.addRemote(incomingRemote, url: incomingRemoteURL)
    }
    try await repository.fetch(remote: incomingRemote)

    // Create and checkout the branch where sync changesets will go ("tidepool-sync")
    if !(try repository.branchExists(named: syncBranch)) {
        try repository.createBranch(named: syncBranch, target: project.branch)
    }
    try await repository.checkout(revspec: syncBranch)

    // Merge changes from tidepool to diy
    try await repository.merge(revisionSpecification: "\(incomingRemote)/\(project.branch)", signature: signature)

    // Push changes up to origin
    let refspec = "refs/heads/" + syncBranch + ":refs/heads/" + syncBranch
    print("Pushing \(refspec) to \(project.project)")
    try await repository.push(remoteName: "origin", refspecs: [refspec], credentials: credentials)

    // Make sure a PR exists, or create it
    let prs = try await octokit.listPullRequests(owner: "LoopKit", repo: project.project, base: project.branch, head:"LoopKit:tidepool-sync")
    let pr: PullRequest
    if prs.count == 0 {
        pr = try await octokit.createPullRequest(owner: "LoopKit", repo: project.project, title: "Tidepool Sync", head: "LoopKit:" + syncBranch, base: project.branch, body: "")
        print("PR = \(pr)")
    } else {
        pr = prs.first!
    }
    if let url = pr.htmlURL {
        if NSWorkspace.shared.open(url) {
            print("default browser was successfully opened")

        }
    }
}

extension Octokit {
    func createPullRequest(owner: String,
                           repo: String,
                           title: String,
                           head: String,
                           headRepo: String? = nil,
                           base: String,
                           body: String? = nil,
                           maintainerCanModify: Bool? = nil,
                           draft: Bool? = nil) async throws -> PullRequest
    {
        return try await withCheckedThrowingContinuation { continuation in
            octokit.pullRequest(owner: owner, repo: repo, title: title, head: head, headRepo: headRepo, base: base, body: body, maintainerCanModify: maintainerCanModify, draft: draft)
            { response in
                continuation.resume(with: response)
            }
        }
    }

    func listPullRequests(owner: String,
                          repo: String,
                          base: String? = nil,
                          head: String? = nil,
                          state: Openness = .open,
                          sort: SortType = .created,
                          direction: SortDirection = .desc) async throws -> [PullRequest]
    {
        return try await withCheckedThrowingContinuation { continuation in
            octokit.pullRequests(owner: owner, repository: repo, base: base, head: head, state: state, sort: sort, direction: direction)
            { response in
                continuation.resume(with: response)
            }
        }
    }
}
