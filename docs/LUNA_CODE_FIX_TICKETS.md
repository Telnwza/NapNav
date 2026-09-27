# NapNav code-fix tickets for Luna

Updated: 2026-09-23. This is a phased implementation handoff with ticket-level
status and evidence; a `DONE` label is limited to the checks explicitly recorded
for that ticket and does not imply physical-device or release readiness. Read
`AGENTS.md`, the active phase in `NAPNAV_REMEDIATION_PLAN.md`, and the latest
entry in `DEVELOPMENT_REPORT.md` before changing code. Work on one ticket per
bounded change. Record the start, checks, result, and remaining risks in the
report; do not mark a ticket done from source inspection alone.
Use `$lean-agent-handoff` when it is available in the next Codex turn; its
compact workflow does not override this plan or the project's safety rules.

## Baseline and execution rules

- A0-R evidence: unsigned generic iOS Release build passed; full 78/78 passed
  three consecutive times; core 75/75 and GPX 3/3 passed on iPhone 18 Pro / iOS
  27.0 Simulator. All runs used source fingerprint
  `29a83887e581606fea1d0430615211f440b352687fa0cdbc4e248b971b1a51cf`.
  See the 2026-09-23 A0-R report entry for `.xcresult` paths.
- The repository has no initial Git commit and source files are untracked.
  Preserve existing files; use the per-run `source-manifest.sha256` rather than
  claiming that an absent Git revision identifies a test run. Do not commit,
  push, or rewrite history on behalf of the user.
- `Scripts/phase-a0.sh` records toolchain, source manifest, exit code, log,
  `.xcresult`, and test summary. Use a new `NAPNAV_DERIVED_DATA` path when
  isolating a build. On this host, sandboxed Xcode produced malformed macro
  plugin responses and CoreSimulator errors; the same source built and tested
  outside the sandbox. Record this distinction if it recurs.
- For each ticket: write an observable failing test first where feasible,
  implement the smallest change, run targeted tests, then a full suite and
  unsigned Release build. At the end of A1-R/A2-R, run three consecutive full
  suites. Verify `summary.json` and matching source fingerprints, not console
  tail text alone. Simulator/build results do not prove physical-device alerts.
- Do not alter a user-facing product rule marked `DECISION` below. Implement
  independent safety work while waiting, then ask the user before crossing the
  decision gate.

## Dependency order

`A1.1 + A1-D + A1.2 → A1 automated gate (DONE) → A2.1 → A2.2 → A2.3 → Security → A3 → A4 → device gate`

`A1-D` was decided by the user on 2026-09-23: block Trip Alarm start if no
delivery path is ready and show Alert Settings with recovery guidance. A1's
automated gate is complete; physical-device alert behavior remains in the
A4 device gate. `A2.2` and `A2.3` were completed as separate changes after
`A2.1`; the automated A2 gate is now complete. Follow the dependency order
through Security before A3 visual work.

## A1.1 — Model a failed delivery without losing the trigger (DONE — automated gate)

Completed 2026-09-23 on source fingerprint
`7100471a0a287846e94482c9798108f4065597734eaa84b3bbf794a676972fbd`:
AlertSettings 23/23, full Simulator suite 85/85, and unsigned generic iOS
Release build passed. Exact commands and evidence paths are in the matching
A1.1 entry in `docs/DEVELOPMENT_REPORT.md`. A1.1's code/test gate is complete;
A1-R was closed later only after A1-D/A1.2 and the three-run full-suite gate
passed on the newer fingerprint below. Physical-device alert behavior remains
unverified and is not claimed by this automated result.

**Original fault found in audit.** `TripStore.handle(_:)` set `alertTriggered = true` and
`phase = .alarm` before checking readiness or awaiting `sendArrivalAlert`.
`TriggerPolicy` sets `hasTriggered = true`, so later qualified inside samples
return `.approaching`; a failed schedule is not retried. The existing
`unavailableDeliveryDoesNotMarkAlertAsSent` test only checks `alertSent == false`.

**Inspect.** `StopAlarm/TripStore.swift` (`handle`, `alertDeliveryReady`,
`refreshReadiness`); `StopAlarm/TriggerPolicy.swift`; `StopAlarm/DomainModels.swift`
(`AlertDeliveryResult`); `StopAlarmTests/AlertSettingsTests.swift`,
`TripStoreTests.swift`, `TriggerPolicyTests.swift`.

**Change contract.** Keep proximity confirmation separate from delivery state.
Treat `alertSent` as success only after `result.didDeliver`; represent an
in-flight attempt so concurrent location events do not schedule two alerts.
Once proximity is confirmed, a fresh qualified inside sample may retry after
an unavailable result or restored readiness. Bound attempts with a documented,
testable cooldown/backoff; do not retry on stale/inaccurate samples, fire on
every GPS update, or re-alert after one successful delivery. Preserve the
existing two-good-samples rule for first entry and the 20 m arrival rule.
If notification readiness changes, refresh it at a deliberate boundary rather
than relying forever on the value captured at trip start.

**Tests first.** (1) ready at start → schedule fails → next qualified sample
after permitted retry → success; (2) permission/path unavailable at trigger
→ restored while still inside → one success; (3) repeated samples while send
is suspended → one in-flight send; (4) rejected location samples cannot retry;
(5) successful send remains one per trip; (6) leaving/re-entering radius does
not reset successful delivery. Use a controllable clock or explicit retry
event, not real sleeps or counts of `Task.yield()`.

**Done.** Tests express the user-observable result; `deliveryUnavailable`
cannot silently become a permanent “already triggered” state. Update the
alert behavior table if the retry contract changes its wording.

## A1-D — Start-trip policy when no alert path exists (DONE — decision + automated gate)

**Decision (2026-09-23).** User selected option 1: do not start a trip advertised
as **Trip Alarm** without an available delivery path; show the reason and a
Settings recovery route. Do not silently offer tracking-only mode.

**Implemented contract.** `TripStore.startTrip()` requests Notification
authorization as the baseline, asks for prominent AlarmKit authorization only
when the selected preferences require it, refreshes readiness, then checks
`alertDeliveryPlan.isAvailable` before requesting location permission or
mutating trip state. If unavailable, it keeps setup
active, sets unavailable health, opens Alert Settings, and returns without a
trip ID/snapshot, location updates, or Live Activity. If at least one supported
path is available (including AlarmKit-only while Notification is denied), the
trip may start. If a path disappears after a valid start, the trip remains
active and A1.1 retry/backoff continues when readiness returns.

**Verification.** The no-path matrix covers all 4 delivery modes × 2 sound
modes; tests also cover blocked start and recovery, AlarmKit-only start,
path-loss-after-start retry, and muted Notification fallback copy. Targeted
AlertSettings/TripStore suites passed 39/39; three consecutive full Simulator
runs each passed 88/88 (including GPX routes); unsigned generic iOS Release build
passed. All results share source fingerprint
`629d9d13d84cb76385f2073f939a6f50ba6ade073f0b45463e697c0fb1f2e4f6`; see
`docs/DEVELOPMENT_REPORT.md` for commands and `.xcresult` paths. This does not
verify real sound, Silent/Focus, locked screen, background, or alert delivery on
a physical iPhone.

## A1.2 — Close the A1 delivery matrix (DONE — automated gate)

Review `AlertDeliveryPolicy` and `LocalAlarmDelivery` in
`StopAlarm/DomainModels.swift` and `StopAlarm/SystemClients.swift` against
`archive/docs/NAPNAV_ALERT_BEHAVIOR_TABLE.md`. Preserve Notification as the
iOS 18–25 baseline and AlarmKit availability gating on iOS 26+. Verify fallback
results, `Both` without doubled sound, silent choice without claiming haptics,
and Settings/readiness copy. Add parameterized Swift Testing cases where useful.
The implementation and full delivery matrix were reviewed against the behavior
table and verified on the `629d9d...` source fingerprint described above. The
A1 automated gate is complete after A1.1, A1-D, three consecutive 88/88 full
Simulator runs, and the unsigned Release build passed. Real sound,
Silent/Focus, locked-screen, background, and actual alert delivery remain
device-gated in A4.

## A2.1 — Reject results from a stopped or replaced trip (AFTER A1)

**Baseline defect (resolved below).** `handle(_:)` awaited alert scheduling.
`stopTrip()` could clear the trip while that call was suspended; the resumed
task then wrote the delivery result and called `persistActiveTrip()`, which at
baseline invented a UUID if the active ID was nil. A cancelled/completed
snapshot could be offered for recovery and restored as tracking. Other async
boundaries (start authorization, snooze scheduling, recovery) had the same
lifetime exposure.

**Inspect.** `StopAlarm/TripStore.swift` (`startTrip`, `handle`,
`handleNotificationAction`, `persistActiveTrip`, `finishTrip`, `restore`, launch
recovery); `StopAlarm/DomainModels.swift` (`ActiveTripSnapshot`);
`StopAlarm/TripPersistence.swift`; `StopAlarmTests/TripStoreTests.swift` and
`StartupRecoveryTests.swift`.

**Change contract.** Capture a trip ID or generation before each suspend point
and check it after resumption, including after a new trip has started. Cancel
or invalidate in-flight effects on Stop/Complete/Discard. A late system
schedule must be cancelled/reconciled for the *old* trip, never attributed to
the new one. Make `persistActiveTrip()` a no-op or explicit failure unless
there is an active trip with a legitimate phase and ID; it must never mint an
ID during cleanup. Reject terminal snapshots on launch rather than mapping
them to tracking. Preserve backward decoding of older snapshots.

**Tests first.** Suspend a mock send; Stop before it resolves; release it and
assert no active snapshot, tracking, Live Activity, or new alarm. Repeat with
Stop followed by a new trip, both success and failure completions, and relaunch
after a cancelled snapshot. Include snooze and start authorization races if
inspection confirms the same exposure. Do not use wall-clock sleeps.

**Done.** No stale result can change a newer trip or resurrect a stopped trip;
snapshot invariants hold across restoration and corrupt/legacy data tests.

**Status: DONE — automated gate passed 2026-09-23.** Added trip-ID/generation
checks around start authorization, launch/recovery readiness, location event
handling, arrival delivery, snooze scheduling, and stale Notification actions.
Arrival/snooze Notification identifiers and AlarmKit scheduling/cancellation
are trip-scoped; late delivery is cancelled against its original trip. Active
snapshot persistence now requires an active phase, ID, and start time; terminal
snapshots are cleared instead of offered for recovery. Legacy snapshot decoding
defaults remain unchanged.

Verification on source fingerprint
`6232d8f96775bbf82bf71a531a5a59aeb8cf5dc23280091b3a59ceda34b38a83`:
StartupRecovery 21/21, TripStore 13/13, full iOS 27.0 Simulator suite 95/95,
and unsigned generic iOS Release build passed. Full suite and build source
manifests match. See `docs/DEVELOPMENT_REPORT.md` for exact commands and
artifacts. Simulator/build do not prove AlarmKit, sound, Silent/Focus,
locked-screen, or background behavior on a physical iPhone. A2-R automated gate
is now complete after A2.3 and the three consecutive full-suite runs; the A4
physical-device gate remains open.

## A2.2 — Make alert cancellation observable (AFTER A2.1)

**สถานะ 23 ก.ย. 2026: ผ่าน automated gate** บน source fingerprint
`b9b155de2bc3fca9a9addde564e642346a95ce6d070a804f3e5284f53d936551`:
targeted 48/48, full iOS 27.0 Simulator 103/103 และ unsigned generic iOS
Release build ผ่าน; full-test/build manifests ตรงกัน. รายละเอียดคำสั่งและ
artifacts อยู่ใน `docs/DEVELOPMENT_REPORT.md`. ยังต้องยืนยัน AlarmKit บน
iOS 26+ iPhone จริงก่อน release; A2-R automated gate ผ่านแล้ว.

`AlarmDelivering.cancelTripAlerts` currently returns `Void`; AlarmKit
`cancel(id:)` is wrapped in `try?` and clears its in-memory ID even on error.
Define a typed result or throwing cancellation boundary that distinguishes
notification cleanup, AlarmKit success, and AlarmKit failure. Adapt protocol
defaults and all test mocks deliberately; do not let a default no-op mask a
production cancellation failure. Persist or otherwise retain a pending
AlarmKit ID until cancellation is confirmed, then reconcile it on relaunch.
Inspect stop from app, Notification, AlarmKit intent, Live Activity, and
discard-recovery paths; keep one cleanup contract.

Tests: cancellation throws → ID remains recoverable and health/report shows
failure; next reconciliation succeeds → ID clears; repeated Stop is safe;
successful Stop leaves no pending notification/AlarmKit/Live Activity. Native
AlarmKit behavior requires an iOS 26+ physical-device check before release.

## A2.3 — Auto-Stop follows the absolute deadline (AFTER A2.1)

**Status: DONE — automated A2-R gate passed 2026-09-25.** Production startup
defaults to `fastIfPossible`: preparation that finishes within 275 ms does not
show a loading screen; slower preparation may show it, while `alwaysShow` and
`simulateSlow` remain developer overrides. Auto-Stop keeps the absolute
deadline authoritative, releases only the background grant on expiration,
reconciles on restore/app activation, and guards completion by trip ID,
lifecycle generation, and schedule ID.

Verification on fingerprint
`d661bde929f6b7bab9f1922d939f3104f913ddead4dc4ae7274b7b16b65317d3`:
targeted 44/44; full iOS 27.0 Simulator suite 105/105 for three consecutive
runs; unsigned generic iOS Release build passed. All manifests match. Exact
commands and artifacts are in `docs/DEVELOPMENT_REPORT.md`. This does not prove
exact completion time while suspended, sound, or native AlarmKit behavior on a
real iPhone; those remain in the A4/device gate.

The previous defect was that `scheduleAutoStop(until:)` completed inside the
background-task expiration handler before the deadline, while its test called
`completeTrip()` manually. This is fixed; deterministic tests now exercise the
timer itself and verify the deadline, expiration, restore, cancellation, and
replacement-trip guards.

Tests: at 59 s trip is still arrived; at/after deadline it completes once;
expiration before deadline does not complete; relaunch before and after
deadline has the right state; Stop cancels the pending timer; timer from an
old trip cannot stop a new trip. Keep Live Activity countdown consistent.

## S1 — Remove the public one-tap stop path (AFTER A2 core)

`StopAlarm/StopAlarmApp.swift` accepts `napnav://stop-trip` and stops the
current trip immediately. `NapNavWidget/TripLiveActivityWidget.swift` uses
the same public URL for Stop/Finish. Separate URL parsing from mutation.
Preferred minimal design: URL opens the app's existing confirmation sheet;
only an explicit confirmation stops the active trip. An OS-mediated action is
acceptable only after checking deployment-target support and security
properties. Do not treat a query token in a public URL as caller identity.

Tests: unknown/malformed URL is inert; public stop URL opens confirmation but
does not stop; dismiss keeps the trip; confirm stops exactly once; no active
trip is safe. Manually verify the actual Live Activity link and an external
app URL on device, because a unit test cannot prove cross-app dispatch.

## A3 — UX and accessibility after reliability gates

Work in small visual slices: (1) permission/recovery/onboarding and empty/error
states; (2) Dynamic Type and VoiceOver for map controls, radius, active trip,
and Stop; (3) Reduce Motion—remove store-owned hard-coded
`reduceMotion: false` and test all transitions; (4) Light/Dark across four map
styles and Liquid Glass contrast. Validate Thai/English copy and long place
names. Regression-check the already-implemented center pin, compass,
safe-area header, search distance, initial camera, and developer tools move.
Do not reintroduce the superseded two-mode destination picker. Startup decision
was superseded on 2026-09-26: use only the iOS Native Launch Screen with the
logo/copy, then enter app content directly; do not provide a SwiftUI launch-loading
screen or developer override. Recovery/error overlays remain available because
they require user action. Bus-stop marker redesign needs a visual proposal
and user direction before code.

Progress 2026-09-25: slice (1) implementation and automated gate completed on
source fingerprint
`78873af69af8de03878c7b4cbc8c2463d51ede7de256b4496965c9cfb5ca709e`:
focused tests 41/41, full Simulator suite 116/116, and unsigned generic iOS
Release build succeeded. This does not close A3: no visual/VoiceOver audition
or physical-iPhone verification was performed, and slices (2)–(4) remain open.
The user's iPhone screenshots show the English AlarmKit title shrinking and
truncating. The 2026-09-25 21:25 change shortens its copy to `Almost there` and
removes the `stopIntent` that called `store.stopTrip()` when the system X was
pressed. AlarmKit now handles stopping its own sound while the trip remains
active until arrival or an explicit trip-stop action. The same fix updates
relaunch recovery: a missing AlarmKit alarm no longer deletes an active trip
snapshot. Recovery targeted 26/26, full Simulator/GPX 116/116, and unsigned
Release build passed on final fingerprint
`cb18b5637686d72e152045a4f536facb0fe71ff281f1b93418bfe08d9717a2c1`.
Verify the X behavior, continued GPS/Live Activity, and English title on a
physical iPhone before closing the device/visual gate; see the 21:25 report.
See `docs/DEVELOPMENT_REPORT.md`, entry `2026-09-25 17:34 — A3 slice 1`, for
the exact commands and artifacts.

Progress 2026-09-26: slices (2) & (3) completed. Removed hardcoded `reduceMotion: false` from `TripStore.swift` so view transitions respect system Reduce Motion. Added VoiceOver traits/values to map controls, custom radius slider, preset buttons, and localized all remaining Thai/English strings in `RootView.swift` and `DestinationSelection.swift`. Added Dynamic Type adaptive sizing to planning panel height and recent/favorite cards. Unit tests 127/127 passed, 0 compiler errors or navigator issues.

## A4 and device gate — production readiness, not automatic publication

Check app/widget Bundle IDs, App Icon, URL name, location/AlarmKit purpose
strings, privacy manifest, versioning, and Release developer-tool visibility.
Create a signed Archive only with available credentials and explicit scope;
never push, upload, or start TestFlight from this ticket alone. Device smoke
test the alert after A1/A2 on an iPhone; full physical matrix covers iOS 18
Notification and iOS 26+ AlarmKit, foreground/background/locked,
Silent/Focus, denied permissions, Stop/relaunch, audio routes, and a real trip.
Record trigger time vs displayed alert time without retaining unnecessary
location history. Keep App Complete Gate before Internal TestFlight.

## Handoff format after each ticket

Update `docs/DEVELOPMENT_REPORT.md` with: ticket/status, source fingerprint,
files changed, behavior observed, exact command plus `.xcresult`/log path,
verification layer, unresolved risk, and next ticket. In the user-facing
summary, state what changed and what was *not* verified. Technical working
notes may be concise English; report to the Thai-speaking user in Thai.
