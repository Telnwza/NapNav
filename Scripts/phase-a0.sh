#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="$ROOT_DIR/StopAlarm.xcodeproj"
SCHEME="StopAlarm"
DESTINATION="${NAPNAV_DESTINATION:-platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0}"
RESULTS_ROOT="${NAPNAV_A0_RESULTS_DIR:-$ROOT_DIR/.a0-results}"
DERIVED_DATA="${NAPNAV_DERIVED_DATA:-/tmp/NapNav-A0-DerivedData}"

usage() {
    printf '%s\n' \
        "Usage: $0 <command>" \
        "" \
        "Commands:" \
        "  release-build  Release build for a generic iOS device without signing" \
        "  test-core      Run all unit tests except the GPX route suite" \
        "  test-gpx       Run only the GPX route suite" \
        "  test-full      Run the complete test suite once" \
        "  test-full-3    Run the complete test suite three consecutive times" \
        "  summary PATH   Read a test summary from an existing .xcresult bundle" \
        "" \
        "Overrides:" \
        "  NAPNAV_DESTINATION='platform=iOS Simulator,name=...,OS=...'" \
        "  NAPNAV_A0_RESULTS_DIR=/path/to/results" \
        "  NAPNAV_DERIVED_DATA=/path/to/DerivedData"
}

new_run_directory() {
    local label="$1"
    local timestamp
    timestamp="$(date '+%Y%m%d-%H%M%S')"
    RUN_DIRECTORY="$RESULTS_ROOT/$timestamp-$label"
    mkdir -p "$RUN_DIRECTORY"
    record_source_manifest "$RUN_DIRECTORY"
}

record_source_manifest() {
    local output_dir="$1"
    find \
        "$ROOT_DIR/StopAlarm" \
        "$ROOT_DIR/NapNavWidget" \
        "$ROOT_DIR/StopAlarmTests" \
        "$ROOT_DIR/TestRoutes" \
        "$ROOT_DIR/Scripts" \
        "$ROOT_DIR/StopAlarm.xcodeproj/project.pbxproj" \
        -type f ! -name '.DS_Store' -print0 \
        | xargs -0 shasum -a 256 \
        | LC_ALL=C sort > "$output_dir/source-files.sha256"
    shasum -a 256 "$output_dir/source-files.sha256" > "$output_dir/source-manifest.sha256"
}

record_metadata() {
    local output="$1"
    {
        printf 'date: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
        printf 'destination: %s\n' "$DESTINATION"
        printf 'project: %s\n' "$PROJECT"
        printf 'scheme: %s\n' "$SCHEME"
        printf 'derived_data: %s\n' "$DERIVED_DATA"
        printf 'git_head: %s\n' "$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || printf 'none')"
        printf 'git_status:\n'
        git -C "$ROOT_DIR" status --short
        printf 'iphoneos_sdk: %s\n' "$(xcrun --sdk iphoneos --show-sdk-version)"
        printf 'iphonesimulator_sdk: %s\n' "$(xcrun --sdk iphonesimulator --show-sdk-version)"
        xcodebuild -version
    } > "$output"
}

write_test_summary() {
    local result_bundle="$1"
    local summary_file="$2"
    if [[ -d "$result_bundle" ]]; then
        xcrun xcresulttool get test-results summary \
            --path "$result_bundle" > "$summary_file" || true
    fi
}

run_test() {
    local label="$1"
    shift
    local result_bundle
    local log_file
    local status

    new_run_directory "$label"
    result_bundle="$RUN_DIRECTORY/tests.xcresult"
    log_file="$RUN_DIRECTORY/xcodebuild.log"
    record_metadata "$RUN_DIRECTORY/environment.txt"

    set +e
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination "$DESTINATION" \
        -derivedDataPath "$DERIVED_DATA" \
        -resultBundlePath "$result_bundle" \
        "$@" \
        test 2>&1 | tee "$log_file"
    status=${PIPESTATUS[0]}
    set -e

    printf '%s\n' "$status" > "$RUN_DIRECTORY/exit-code.txt"
    write_test_summary "$result_bundle" "$RUN_DIRECTORY/summary.json"
    printf 'Artifacts: %s\n' "$RUN_DIRECTORY"
    return "$status"
}

run_release_build() {
    local result_bundle
    local log_file
    local status

    new_run_directory "release-build"
    result_bundle="$RUN_DIRECTORY/build.xcresult"
    log_file="$RUN_DIRECTORY/xcodebuild.log"
    record_metadata "$RUN_DIRECTORY/environment.txt"

    set +e
    xcodebuild \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -configuration Release \
        -destination 'generic/platform=iOS' \
        -derivedDataPath "$DERIVED_DATA" \
        -resultBundlePath "$result_bundle" \
        CODE_SIGNING_ALLOWED=NO \
        build 2>&1 | tee "$log_file"
    status=${PIPESTATUS[0]}
    set -e

    printf '%s\n' "$status" > "$RUN_DIRECTORY/exit-code.txt"
    printf 'Artifacts: %s\n' "$RUN_DIRECTORY"
    return "$status"
}

command="${1:-}"
case "$command" in
    release-build)
        run_release_build
        ;;
    test-core)
        run_test "core" '-skip-testing:StopAlarmTests/GPXReleaseRouteTests'
        ;;
    test-gpx)
        run_test "gpx" '-only-testing:StopAlarmTests/GPXReleaseRouteTests'
        ;;
    test-full)
        run_test "full"
        ;;
    test-full-3)
        run_test "full-1"
        run_test "full-2"
        run_test "full-3"
        ;;
    summary)
        if [[ $# -ne 2 ]]; then
            usage
            exit 2
        fi
        xcrun xcresulttool get test-results summary --path "$2"
        ;;
    *)
        usage
        exit 2
        ;;
esac
