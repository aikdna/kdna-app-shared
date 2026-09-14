#!/usr/bin/env python3
"""Verify native builds, tests, public consumers and retired API exclusion."""
import argparse
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CONSUMER = r'''import Foundation
import KDNACore
import KDNAAppShared

@main
struct ConsumerCheck {
    static func main() async throws {
        let bytes = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        guard let snapshot = KDNACore.admitBytes(bytes).snapshot else { fatalError("Core admission failed") }
        let view = snapshot.inspect()
        let control = KDNATrustedReadControlProvider { ["admission_response_limit_bytes": 4096] }
        let host = KDNATrustedHostReadProvider(observe: { request, current in
            let inspected = current.inspect()
            return ["host_id": "consumer-host", "host_epoch": "consumer-epoch", "decision_id": "consumer-decision",
                "request_id": request["request_id"], "snapshot_id": inspected["snapshot_id"],
                "A": inspected["digests"]["A"]["observed"], "C": inspected["digests"]["C"]["observed"],
                "scope": .array(inspected["ir"]["nodes"].list.map { $0["id"] }),
                "issued_at": 900, "expires_at": 2000, "current_ms": 1000,
                "decision": "allow", "policy_id": "consumer-policy"]
        }, deliver: { _ in true })
        let request: KDNAValue = ["request_id": "consumer-request", "tuple": try KDNACore.versionTuple(),
            "budget_bytes": 1000000, "mode": "whole_asset", "selection": nil, "handle": nil]
        let raw = await KDNARead.readSnapshot(snapshot, request: request, control: control, host: host)
        precondition(raw["envelope"]["status"] == "ready")
        let display = KDNAReadPresentation.from(readResult: raw, assetTitle: "Consumer check")
        precondition(display.content == .available)
        precondition(display.assetID == view["asset"]["asset_id"].text)
        precondition(display.snapshotID == view["snapshot_id"].text)
        precondition(display.observedStates.actionAuthorization == "not_evaluated")
        let encoded = try JSONEncoder().encode(display)
        let object = try JSONSerialization.jsonObject(with: encoded) as! [String: Any]
        for key in ["closure", "method", "canLoadNow", "runtimeCapsule", "primaryActionTitle"] {
            precondition(object[key] == nil)
        }
        var zero = request; zero["budget_bytes"] = 0
        let withheld = await KDNARead.readSnapshot(snapshot, request: zero, control: control, host: host)
        precondition(withheld["channel"] == "no_body_control")
        precondition(KDNAReadPresentation.from(readResult: withheld).content == .withheld)
        let rejected = await KDNARead.readSnapshot(snapshot, request: ["unexpected": true], control: control, host: host)
        precondition(rejected["channel"] == "admission_rejection")
        precondition(KDNAReadPresentation.from(readResult: rejected).content == .withheld)
        let undelivered = await KDNARead.readSnapshot(snapshot, request: request, control: nil, host: nil)
        precondition(undelivered["channel"] == "transport_failure")
        precondition(KDNAReadPresentation.from(readResult: undelivered).content == .unavailable)
        var mixed = raw; mixed["envelope"]["contract"] = "unsupported"
        precondition(KDNAReadPresentation.from(readResult: mixed).content == .unavailable)
        precondition(ProviderID(normalizing: " OpenAI ") == .chatgpt)
        print("Public consumer passed: actual Read channels, exact identity, separate authority and no body copy.")
    }
}
'''
RETIRED = '''import KDNAAppShared
let oldInput: KDNALoadPlanPresentationInput? = nil
let oldPresentation: KDNAAuthorizationPresentation? = nil
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--work-dir', required=True, type=Path, help='New directory outside this package for isolated outputs')
    parser.add_argument('--ios', action='store_true', help='Compile the generic iOS device target with Xcode')
    args = parser.parse_args()
    work = args.work_dir.resolve()
    if work == ROOT or ROOT in work.parents:
        parser.error('--work-dir must be outside this package')
    work.mkdir(parents=True, exist_ok=False)
    for name in ['cache', 'config', 'security', 'modules', 'tmp']:
        (work / name).mkdir()
    env = dict(os.environ, TMPDIR=str(work / 'tmp'))
    def run(argv, cwd=ROOT):
        print('+ ' + ' '.join(str(item) for item in argv), flush=True)
        subprocess.run([str(item) for item in argv], cwd=cwd, env=env, check=True)
    def options(scratch):
        return ['--jobs', '1', '--scratch-path', work / scratch, '--cache-path', work / 'cache',
                '--config-path', work / 'config', '--security-path', work / 'security',
                '-Xcc', '-fmodules-cache-path=' + str(work / 'modules')]
    def consumer_package(folder, source):
        directory = work / folder
        (directory / 'Sources/ConsumerCheck').mkdir(parents=True)
        package = '''// swift-tools-version:5.9
import PackageDescription
let package = Package(name: "ConsumerCheck", platforms: [.macOS(.v13)],
    dependencies: [.package(name: "kdna-app-shared", path: REPO)],
    targets: [.executableTarget(name: "ConsumerCheck", dependencies: [.product(name: "KDNAAppShared", package: "kdna-app-shared")])])
'''.replace('REPO', json.dumps(str(ROOT)))
        (directory / 'Package.swift').write_text(package)
        (directory / 'Sources/ConsumerCheck/ConsumerCheck.swift').write_text(source)
        return directory

    run(['swift', '--version'])
    run(['swift', 'build', *options('debug')])
    run(['swift', 'build', '-c', 'release', *options('release')])
    run(['swift', 'test', *options('tests')])
    consumer = consumer_package('consumer', CONSUMER)
    for configuration in ['debug', 'release']:
        run(['swift', 'run', '-c', configuration, *options('consumer-build'), 'ConsumerCheck',
             ROOT / 'Tests/KDNAAppSharedTests/Fixtures/Components/full-trio.kdna'], cwd=consumer)
    negative = consumer_package('retired-consumer', RETIRED)
    command = ['swift', 'build', *options('retired-build')]
    print('+ Retired public symbols must fail after the current consumer passed.', flush=True)
    result = subprocess.run([str(item) for item in command], cwd=negative, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    print(result.stdout, flush=True)
    if result.returncode == 0 or any("cannot find type '" + name + "'" not in result.stdout for name in ['KDNALoadPlanPresentationInput', 'KDNAAuthorizationPresentation']):
        raise RuntimeError('Retired-symbol compilation did not fail with the expected missing-type diagnostics')
    if args.ios:
        run(['xcodebuild', '-version'])
        run(['xcodebuild', '-quiet', '-scheme', 'kdna-app-shared', '-destination', 'generic/platform=iOS',
             '-derivedDataPath', work / 'ios', '-clonedSourcePackagesDirPath', work / 'packages',
             '-packageCachePath', work / 'package-cache', '-disableAutomaticPackageResolution',
             '-onlyUsePackageVersionsFromResolvedFile', 'CODE_SIGNING_ALLOWED=NO',
             'CLANG_MODULE_CACHE_PATH=' + str(work / 'modules'), 'build'])
    print('Native verification passed' + (' including generic iOS compilation.' if args.ios else '; iOS compilation was not requested.'))


if __name__ == '__main__':
    main()
