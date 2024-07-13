#!/usr/bin/swift sh

// Depends on swift-sh.  Install with: `brew install swift-sh`

import Foundation
import Cocoa

import AsyncSwiftGit // @bdewey
import OctoKit // nerdishbynature/octokit.swift == main

let createPRs = true

guard CommandLine.arguments.count == 3 else {
    print("usage: sync.swift <pull-request-title> <branch-name>")
    exit(1)
}
let pullRequestName = CommandLine.arguments[1]  // example: "LOOP-4688 DIY Sync"
let syncBranch = CommandLine.arguments[2]       // example: "ps/LOOP-4688/diy-sync"

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

struct Project {
    let project: String
    let branch: String
    let subdir: String

    init(_ project: String, _ branch: String, _ subdir: String = "") {
        self.project = project
        self.branch = branch
        self.subdir = subdir
    }

    var path: String {
        if subdir.isEmpty {
            return project
        } else {
            return subdir + "/" + project
        }
    }
}

let projects = [
   Project("Loop", "dev"),
   Project("LoopKit", "dev"),
   Project("TidepoolService", "dev"),
   Project("CGMBLEKit", "dev"),
   Project("dexcom-share-client-swift", "dev"),
   Project("RileyLinkKit", "dev"),
   Project("NightscoutService", "dev"),
   Project("LoopOnboarding", "dev"),
   Project("AmplitudeService", "dev"),
   Project("LogglyService", "dev"),
   Project("MixpanelService", "main"),
   Project("OmniBLE", "dev"),
   Project("NightscoutRemoteCGM", "dev"),
   Project("LoopSupport", "dev"),
   Project("G7SensorKit", "main"),
   Project("OmniKit", "main"),
   Project("MinimedKit", "main"),
   Project("LibreTransmitter", "main")
]

let fm = FileManager.default
let loopkit = URL(string: "https://github.com/LoopKit")!
let tidepool = URL(string: "https://github.com/tidepool-org")!
let incomingRemote = "tidepool"

let octokit = Octokit(TokenConfiguration(ghToken))

let credentials = Credentials.plaintext(username: ghUsername, password: ghToken)
let signature = try! Signature(name: ghCommitterName, email: ghCommitterEmail)

for project in projects {
    let dest = URL(string: fm.currentDirectoryPath)!.appendingPathComponent(project.path)
    let repository: AsyncSwiftGit.Repository
    if !fm.fileExists(atPath: dest.path) {
        print("Cloning \(project.project)")
        let url = loopkit.appendingPathComponent(project.project)
        repository = try await Repository.clone(from: url, to: dest)
        print("Cloned \(project.project)")
    } else {
        print("Already Exists: \(project.path)")
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
        try repository.createBranch(named: syncBranch, target: "origin/\(project.branch)")
    }
    try await repository.checkout(revspec: syncBranch)

    // Merge changes from tidepool to diy
    try await repository.merge(revisionSpecification: "\(incomingRemote)/\(project.branch)", signature: signature)

    let originTree = try repository.lookupTree(for: "origin/\(project.branch)")
    let diff = try repository.diff(originTree, repository.headTree)

    guard diff.count > 0 else {
        print("No incoming changes; skipping PR creation.")
	try await repository.checkout(revspec: project.branch)
        continue
    } 
    print("Found diffs: \(diff)")

    // Push changes up to origin
    let refspec = "refs/heads/" + syncBranch + ":refs/heads/" + syncBranch
    print("Pushing \(refspec) to \(project.project)")
    try await repository.push(remoteName: "origin", refspecs: [refspec], credentials: credentials)

    if createPRs {
      // Make sure a PR exists, or create it

      let prs = try await octokit.pullRequests(owner: "LoopKit", repository: project.project, base: project.branch, head:"LoopKit:" + syncBranch)
      let pr: PullRequest
      if prs.count == 0 {
          pr = try await octokit.createPullRequest(owner: "LoopKit", repo: project.project, title: pullRequestName, head: "LoopKit:" + syncBranch, base: project.branch, body: "")
          print("PR = \(pr)")
      } else {
          pr = prs.first!
      }
      if let url = pr.htmlURL {
          if NSWorkspace.shared.open(url) {
              print("default browser was successfully opened")
          }
      }
   } else {
     print("Skipping PR creation")
   }
}

