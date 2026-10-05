# NapNav phased UI implementation plan — October 4, 2026

## Status and authority

**UI1–UI5 work is implemented within its authorized scope. F1–F4 restores
original colors/Start sizing/fixed Settings placement and removes radius
checkmarks. Current Debug/test-product and unsigned Release builds passed;
previous F1–F4 source iOS tests passed 135/135. Selected F1–F4 Simulator acceptance
passed on small/large phones and iPad. UI6 is now implemented with concise
three-page onboarding; its UI6 verification snapshot passed 139/139 tests and
Debug/unsigned Release builds. English/Large and Thai/XL small-phone first-run/replay checks
passed. Physical sound/VoiceOver, extended visual and A3/A4 gates remain open.**

Saving this document originally authorized documentation only. The initial
implementation instruction authorized UI1. On October 5, 2026, the user authorized
sequential continuation through the remaining plan, with Simulator work deferred
until they return and explicitly permit it; unresolved design decisions remain open.

This document records the detailed UI improvement approach and implementation
batching discussed after the [SwiftUI Expert UI review](UI_REVIEW_2026-10-04.md).
It supplements the [remediation plan](NAPNAV_REMEDIATION_PLAN.md) and the active
[A3 ticket](LUNA_CODE_FIX_TICKETS.md#a3--ux-and-accessibility-after-reliability-gates).
It does not replace their reliability, device, security, or release gates.

- Source baseline at planning: `cf9238360c478de02eee9d05a7275d829cb266c9`.
- Supported targets: iPhone and iPad, iOS 18+.
- UI1–UI6 below are new planning identifiers, not the historical A3 slice numbers.
- Acceptance checkboxes remain open until verified. See the execution update below
  for UI1's implementation/build status.
- Reinspect relevant source/tests and record the current source fingerprint when
  implementation begins; this baseline is not permanent evidence of correctness.
- Before progressing with A3 implementation, confirm the A1/A2 alert-path device
  smoke prerequisite in the remediation plan. Historical automated passes do not
  establish that physical-device check.

## Recommended sequence

Work sequentially in five core batches, with an optional sixth product-design
batch. Review and verify each batch before starting the next.

| Batch | Scope | Work to keep together | Acceptance outcome |
| --- | --- | --- | --- |
| UI1 | Adaptive setup and tracking layouts | Layout, scalable typography, control placement | Start/Stop remain reachable; controls do not overlap |
| UI2 | Tutorial presentation | Presentation ownership, dismissal, first-run/replay modes | Tutorial opens and closes reliably without disrupting a trip |
| UI3 | Accessibility completion | Control semantics, labels, actions, touch bounds | Full destination-to-stop journey works with VoiceOver |
| UI4 | Reduce Motion | Camera, panel, swipe-row, onboarding transitions | Spatial motion is reduced while interactions remain complete |
| UI5 | Visual polish | Semantic colors, shared button styles, panel surfaces | Readable Light/Dark UI across map styles and OS fallbacks |
| UI6, optional | Onboarding content redesign | Approved copy and page order | Users understand the flow and limitations |

The recommended first implementation scope is **UI1 only**, with checkpoints
UI1A, UI1B, and UI1C. Do not combine it with color changes or onboarding redesign.

## Scope to preserve

- Preserve the map-first destination → radius → trip flow and fixed center pin.
- Preserve SwiftUI MV and existing dependency injection; no architecture rewrite.
- Preserve the native-only launch screen decision and recovery/error overlays.
- Preserve the no-alert-path start gate, Stop confirmation, alarm cancellation,
  recovery behavior, and Auto-Stop deadline contract.
- Keep bus-stop marker redesign and unresolved public URL behavior outside this
  UI plan; they retain their own decisions and gates.
- Do not add dependencies, transit data, dynamic radius, backend services, or
  Critical Alerts.
- Do not change permission-request behavior as an incidental UI fix.
- Git mutations, signing changes, publication, and TestFlight require their own
  explicit user instructions.

## Preparation for each batch

1. Read the remediation plan and development report, then only the relevant A3
   source/tests for the selected scope.
2. Record source fingerprint, working-tree state, toolchain, runtime, and device.
3. Start a development-report entry with the goal, baseline, expected files,
   verification approach, and open dependencies.
4. Prepare repeatable example states through existing injection/preview patterns;
   layout reproduction should not require an actual journey or alarm delivery.
5. Capture before/after views using the same data, language, text size, appearance,
   and map style. Preserve existing Simulator/user data.
6. Update the same report entry after each implementation/verification round.

Useful example states include short/long Thai and English place names, preset and
custom radius, location pending, normal tracking, warning text, arrival/countdown,
and Stop confirmation.

## UI1 — Adaptive layout and typography

**Priority:** First. Start clipping and control overlap were reproduced in the
review's Simulator build at AX5. They are usability findings, not merely polish.

**Primary file:** `NapNav/DestinationSelection.swift`.

### UI1A — Setup panel

The current fixed/clipped panel and non-scrolling radius content can hide Start
Trip. Replace the fixed extra allowance for accessibility sizes with a bounded
layout that accommodates growing content.

Recommended structure:

```text
Header: back action / destination
Scrollable content: explanation / presets / custom radius
Footer: Start Trip
```

- Use content-sized height where feasible and a maximum based on actual available
  space after safe areas and required controls.
- Keep the primary action outside the scrolling content, with wrapping text and
  adequate interactive bounds. Verify very short viewports explicitly.
- Reflow presets vertically when width or Dynamic Type makes a horizontal row
  unsuitable; retain the existing values and selection behavior.
- Reflow custom-radius label, slider, and value into separate rows when needed.
- Allow long destination text to wrap in accessible content rather than pushing
  the primary action outside the panel.
- Apply keyboard and bottom-safe-area handling once; avoid duplicate spacing.
- Preserve center-pin selection semantics and camera behavior. A layout change
  must not silently shift the coordinate interpreted as the destination.

Acceptance:

- [x] Start Trip is visible and tappable in the exercised standard/AX5 setups.
- [x] Preset/custom radius and long destination names work in the exercised layouts.
- [x] iPad portrait/landscape rotation retains destination and selected radius.
- [ ] iPad window resizing retains the selected radius and destination (deferred).
- [ ] Complete keyboard/safe-area matrix (deferred); small-phone Thai software-keyboard search was exercised before the final layout patch.
- [x] Existing starting/permission gates remain intact in source and automated tests; denied notification permission correctly showed the no-path explanation in Simulator.
- [x] Map/selection and start handlers are preserved; DestinationSelection regression tests passed. Full manual camera matrix remains extended QA.

### UI1B — Tracking layout

- Position map controls using a layout that reserves the trip-card space, or the
  card's actual bounds, instead of an assumed fixed tracking height.
- Arrange the distance region and Settings together so each reserves space.
- Reflow information at narrow widths and large text sizes.
- Include taller warning and arrival/countdown states when determining bounds.
- Use semantic fonts or `@ScaledMetric` for custom in-app distance typography.
  Keep distance prominent while status and destination remain readable.
- Do not rely on shrinking essential text to compensate for inaccessible layout.
- Treat Live Activity/Dynamic Island typography separately; the review did not
  render those surfaces and their constrained layouts need their own checks.

Acceptance:

- [x] Locate, map style, Settings, and Stop have separate visible regions in exercised layouts.
- [x] Simulator control interactions at AX5 opened Settings, changed map style, located the map and invoked Stop confirmation; physical touch verification remains open.
- [x] Exercised warning/arrival/countdown content leaves Stop/Finish visible.
- [x] Exercised distance, meter/kilometer and arrival states are readable; extra details scroll on the smallest AX5 viewport.
- [ ] Pending-location runtime layout (deferred).
- [x] Stop uses the existing confirmation; Continue keeps the trip active (AX5 sheet expanded).

### UI1C — Combined checkpoint

Verify UI1A/UI1B together with long Thai/English names, small and large iPhones,
iPad, keyboard, rotation, and accessibility sizes. Confirm map viewport/camera,
center pin, compass, search distance, and destination selection do not regress.

Typography belongs in UI1 because scaling changes the space that layout must
reserve. Add necessary labels/touch bounds while touching a control; UI3 audits
the complete accessibility journey afterward.

## UI2 — Tutorial presentation

**Files:** `NapNav/AlertSettingsView.swift`, `NapNav/DestinationSelection.swift`,
`NapNav/RootView.swift`, and `NapNav/OnboardingView.swift`.

Settings → Show Tutorial failed in Simulator. Competing sheet presentations are
the likely source explanation, not an instrumented root-cause conclusion.

Recommended approach: dismiss Settings, then present the existing root tutorial
after dismissal through one explicit handoff.

1. Record a pending tutorial request when its Settings action is selected.
2. Dismiss Settings.
3. In the Settings dismissal completion, consume the pending request and present
   onboarding through RootView.
4. Clear the request so ordinary later dismissals do not reopen the tutorial.

Do not use arbitrary delays to coordinate sheet animations. Distinguish modes:

| Mode | Required behavior |
| --- | --- |
| First run | Preserve the existing completion rules |
| Replay | Explicit Close action; return to the previous context |
| Developer reset | Same safe presentation route, preserving reset semantics |

Replay must not reset first-run completion or automatically request permissions
again. Preserve explicit permission actions until a separate behavior decision.

Acceptance:

- [x] Settings opens the tutorial reliably on repeated exercised attempts (including Thai replay and active tracking).
- [x] Closing returns to the appropriate destination/setup/tracking context in exercised attempts.
- [ ] Returned VoiceOver focus is correct (physical audition remains open).
- [x] An active trip continues throughout tutorial presentation; persisted ID, destination and radius matched.
- [x] No stuck/duplicate sheet or unexpected tutorial on exercised ordinary dismissal.
- [x] First run and developer reset retain mandatory completion; completion survives relaunch.

## UI3 — Accessibility completion

**Files:** `NapNav/DestinationSelection.swift`, `NapNav/OnboardingView.swift`,
related shared controls, and existing English/Thai localization files as needed.

- Give favorite/recent selection Button semantics; use sibling select/edit
  buttons rather than nested buttons.
- Provide explicit accessible expand/collapse actions and state for the panel
  handle; retain touch/drag interactions.
- Give star/edit and other custom controls adequate touch bounds; target at least
  44×44 points without requiring visually oversized icons.
- Localize map descriptions and state values in the active app language.
- Hide decorative symbols from VoiceOver; expose selected alert-mode state.
- Provide accessible equivalents for swipe-only actions.
- Group related information where useful without hiding distinct actions.

Acceptance:

- [ ] Complete select destination → configure radius → start → read status →
  Stop → cancel/confirm using VoiceOver on a physical device.
- [ ] No required operation depends solely on dragging or tapping a coordinate.
- [ ] English/Thai announcements, selected states, and focus order are correct.
- [ ] Custom touch controls do not have overlapping hit regions.

Localization tests establish string correctness, not VoiceOver usability.

## UI4 — Reduce Motion

**Files:** `NapNav/DestinationSelection.swift`, `NapNav/OnboardingView.swift`,
`NapNav/Motion.swift`, and affected transitions in `NapNav/RootView.swift`.

- Reuse existing MotionTokens rather than introducing another animation system.
- Review camera flights, panel expansion, swipe-row springs, onboarding page
  changes/indicators, transitions, and matched geometry.
- With Reduce Motion enabled, remove unnecessary long spatial movement,
  scale/morph effects, and camera flights; use immediate updates or brief fades
  where appropriate. Slower spatial movement alone is insufficient.
- Preserve action results, focus, selected coordinates, and gesture completion.

Acceptance:

- [ ] Runtime behavior visibly respects Reduce Motion across the full flow.
- [x] Exercised panel, map selection/recenter and tutorial forward/back/completion leave controls and sheets usable under Reduce Motion.
- [ ] Remaining transition/recovery/swipe-row motion and state audition.
- [ ] Map selection/recenter and swipe actions retain their intended results.

## UI5 — Visual polish

**Files:** `NapNav/TripActivityAttributes.swift` (AppTheme),
`NapNav/RootView.swift` (shared styles), and affected destination/onboarding views.

Choose the surface direction using comparable visual proposals before changing
shared styles broadly: a stable system-themed panel surface, or a more opaque
material panel. Use identical content/layout in both proposals.

- Preserve the green/mint identity; separate decorative accent, text, and primary
  button fill roles rather than changing one shared color indiscriminately.
- Use semantic primary/secondary text colors for general information.
- Reduce nested glass in search fields, rows, and radius controls inside panels.
- Review the existing floating glass controls; preserve iOS 18 fallback behavior.
- Make selection understandable through shape/checkmark/state as well as color.
- Retain clear destructive styling for Stop and destructive confirmations.

The review calculated primary emerald/white source contrast as 2.54:1. That is a
source-color calculation, not a measurement of every rendered glass control.

Acceptance:

- [ ] Actual rendered text and control states are readable in Light/Dark across
  every map style, including Increase Contrast and Reduce Transparency.
- [ ] iOS 18 fallback remains usable and readable.
- [ ] Selected/unselected, enabled/disabled, loading, and pressed states are clear.
- [ ] High-risk text/button combinations have rendered contrast evidence.

## UI6 — Concise onboarding content redesign

**Authorized October 5:** User requested UI6 with only necessary, short content.
Implementation and selected Simulator checks are complete. See the 09:37 UI6
entry in `DEVELOPMENT_REPORT.md` for same-source evidence and limits.

Approved direction, implemented as three pages:

1. Start a trip: choose a destination with search/fixed center pin, set alert
   distance, then Start Trip.
2. Choose an alert method: one-line descriptions and a brief location/Focus caveat.
3. Permissions: one-line purpose per permission and Privacy Policy link.

Removed map-style, battery, Live Activity and Auto-Stop feature paragraphs from
the tutorial. Thai/English copy is localized. The essential interaction copy is
“ค้นหาสถานที่ หรือเลื่อนแผนที่ให้จุดหมายอยู่ใต้หมุด”. User accepts Focus-on/screen-off
silence as a product limitation; this does not establish the cause/delivery path.

First-run automatic permission requests now run from the final permissions page.
Manual Request actions, permission APIs/set, replay policy and start gate remain
unchanged. Requests only for the selected delivery path remain a separate scope.

Acceptance:

- [x] Short Thai/English copy describes the actual interaction and limitations.
- [x] Three-page navigation/boundaries and final-page/replay request policy are tested.
- [x] English/Large and Thai/XL small-phone first-run/replay, Back, scroll and Close
  actions work; Thai/XL Reduce Motion replay works.
- [x] Native accessibility headings, selected values and actions are exposed.
- [x] Permission APIs/manual actions and start gate remain unchanged; moving the
  first-run request to the final page is intentional and tested.
- [ ] Spoken VoiceOver reading order/swipe navigation/focus return is verified.

Evidence: source fingerprint
`f163300459a410cd5a070273002fff6f4be720ae827a19301ea1b7da2df79f33`,
`/tmp/NapNav-UI6-20261005/`: focused 47/47, full 139/139, Debug/unsigned Release
passes, selected Simulator screenshots. No physical delivery or fresh-permission
matrix pass is implied. UI6 did not change app colors, Start shape or Settings placement.

### UI6 Location prompt follow-up — October 5

User found Location authorization appearing at launch. DestinationView still
requested it during initial load, scene activation and tutorial dismissal.
These passive fetches and search focus now use the existing non-requesting path;
unknown authorization returns before creating a location service session.
Explicit tutorial Request/Get Started, Show My Location and trip-start actions
remain available. Only DestinationSelection.swift changed.

User stopped Simulator work during baseline reproduction and requested source
inspection/fix only. Post-fix runtime timing and tests are deliberately unverified;
prior 139/139 belongs to UI6 snapshot `f163300...`, not this follow-up.
Follow-up source/static and build evidence belongs in the new development-report
entry and `/tmp/NapNav-UI6-Location-20261005/`.

## Sequential work and safe parallel preparation

Code changes should proceed UI1 → UI2 → UI3 → UI4 → UI5, with UI6 included only
after its decisions. Several batches share DestinationSelection, Onboarding,
RootView, and their styles; simultaneous edits make regressions harder to locate.

Preparation can run independently: example data, capture/check matrices, proposed
copy, and visual alternatives. Do not infer authorization to launch additional
agents or parallel implementation from this planning recommendation.

Per-batch loop: inspect → implement selected scope → review diff → build → run
relevant checks → capture interaction/visual evidence → update development report.

## Verification and release boundaries

Use proportional checks. Visual geometry needs screenshots and interaction;
do not add unit tests that merely assert a magic height. Add/update tests when
presentation state or meaningful behavior changes and existing suites fit.

Relevant existing suites include DestinationSelectionTests, AlertSettingsTests,
LocalizationTests, StartupRecoveryTests, and TripStoreTests. Select by actual
changed behavior; do not run every suite after each color/spacing adjustment.

| Evidence layer | Required approach |
| --- | --- |
| Source/static | Diff review, state ownership, localization, availability |
| Build | Debug Simulator build of the changed source |
| Focused tests | Existing suites covering changed state/behavior |
| Simulator visual/interaction | Same-state before/after, taps, scrolling, keyboard, resizing |
| Accessibility audition | VoiceOver and appearance/motion settings; real-device journey |
| Final automated gate | Full Simulator/GPX and unsigned Release build under the governing plan on the same source fingerprint |
| Physical device/release | A4 sound, Silent/Focus, locked screen, background, delivery, recovery, and release checks |

Do not repeat all final gate runs for each cosmetic edit. At final integration,
follow the governing gate's actual required runs; never substitute historical
pass counts for the current source.

Minimum risk-based matrix (not every possible Cartesian combination):

- Small and large supported iPhones; iPad portrait/landscape and narrow windows.
- Default text, large pre-accessibility sizes, AX1, AX3, and AX5.
- Thai/English, short/long names, preset/custom radius, software keyboard.
- Normal/pending/warning/arrival/countdown, recovery/error, Stop confirmation.
- Light/Dark and every map style.
- Reduce Motion, Reduce Transparency, Increase Contrast, and VoiceOver.
- iOS 18 fallback and the intended release runtime.

Each completed batch needs a reviewable diff, evidence tied to its source, and
explicit unverified items. A3/A4 checkboxes stay open until their actual acceptance
criteria are met. No signed Archive, publication, or TestFlight is included here.

## Evidence at original plan creation

The review's unchanged-source Debug Simulator build succeeded; AX5 setup/tracking
and tutorial issues were reproduced. No new build/tests/Simulator/device checks
were performed merely to save this plan. Review screenshots are referenced from
UI_REVIEW_2026-10-04.md and currently live in temporary storage.

## UI1 execution update — closed October 5, 2026

- **Authorization / closure:** User authorized UI1 implementation and Simulator testing, then requested finishing with no additional broad testing to preserve quota. UI1A/UI1B and the selected UI1C checkpoint are complete. The open items above remain extended QA; this closure does not certify the full matrix or A3/A4 release gates.
- **UI1A:** Scrollable setup with pinned Start, measured compact destination/setup sizing, preset/custom-radius reflow, and long destination wrapping.
- **UI1B:** Shared map-controls/trip-card stack, reserved Settings width, scalable distance/arrival fonts, readable distance viewport and scrollable trip information with pinned Stop/Finish.
- **Source:** Application changes are confined to `NapNav/DestinationSelection.swift`. One existing asynchronous test now waits for resolver registration before completion. Map camera/selection, start action, lifecycle, permissions and palette/materials are preserved.
- **Static:** Diff/whitespace and source-manifest checks passed. Final fingerprint over 51 tracked app/widget/test/project files: `3aad13935a59b3bfb38055397471d612bb5275abf1ed97fd5c7d26423211a2a8`.
- **Tests:** Final rebuilt suite passed **129/129**, zero failed/skipped, including GPX fixture/provider replay. Result: `/tmp/NapNav-UI1-20261004/full-UI1-final.xcresult`; log: `full-UI1-final.log` in that directory.
- **Build:** Final unsigned generic iOS **Release build passed**, exit 0. Log: `/tmp/NapNav-UI1-20261004/release-UI1-final.log`. No signed Archive was produced.
- **Simulator:** iOS 27.0; large iPhone setup/tracking/control interactions, small iPhone Thai setup/custom radius/permission warning, final small-phone distance and arrival/countdown/Finish, and final iPad long English name with radius retention through portrait/landscape rotation. AX5 was sampled to find/fix clipping; no further size matrix was run after the user's quota instruction. Final evidence images: `13-final-ipad-portrait-long-AX5.png`, `14-final-ipad-landscape-long-AX5.png`, `16-final-small-arrival-large.png` in `/tmp/NapNav-UI1-20261004/`.
- **Restoration:** Primary Simulator restored to Light, extra-large text, Explore, Berlin preset and portrait, with no active trip. Only the two isolated test Simulators were shut down; data retained.
- **Unverified:** iPad window resizing, complete keyboard/safe-area combinations, pending-location runtime, iOS 18 fallback, full VoiceOver and physical iPhone alert/background behavior. These remain open under extended A3/UI3/UI5/A4 checks as applicable. Temporary artifacts should be retained separately before system cleanup if needed.

**Next at UI1 closure:** UI1 was complete for the selected scope; later batches awaited a separate instruction (received October 5; see continuation below). Commands, snapshot-specific rounds and remaining limitations are recorded in [DEVELOPMENT_REPORT.md](DEVELOPMENT_REPORT.md).

## Autonomous continuation — October 5, 2026

User authorized proceeding sequentially through the remaining planned work while away. Run source/build and suitable host checks after each batch; fix failures before continuing. Defer all Simulator use, including Simulator-hosted test execution, until the user explicitly permits it after returning. Compile-only generic Simulator SDK targets do not launch a Simulator. Record implementation and verification separately; leave runtime acceptance open. Preserve UI1 work, product decision gates, Git/signing/publication boundaries. Execution order: UI2 → UI3 → UI4 → decision-independent UI5 preparation/fixes. UI6 and any unresolved shared-surface decision are deferred.

## UI2–UI5 execution checkpoint — October 5, 2026

| Batch | Implementation / available verification | Acceptance still open |
| --- | --- | --- |
| UI2 | One-shot handoff, first-run/replay/reset; policy/full tests and selected repeated, ordinary-dismissal, Thai and active-trip Simulator checks passed | Physical VoiceOver returned focus and fresh-permission-device audition |
| UI3 | Button semantics and contextual actions confirmed in native tree; panel actions, favorite edit/save/remove, recent select/remove, radius/Start/Stop exercised; full tests passed | Spoken announcements/focus, complete touch/keyboard matrix and physical VoiceOver journey |
| UI4 | Source checks/full tests passed; Reduce Motion enabled in native Settings, selected panel/camera/tutorial/custom-radius interactions completed | Frame-level motion comparison, swipe/recovery/complete gesture matrix and physical audition |
| UI5 | Color roles with original green and no radius checkmark, tests and unsigned Release passed; native selected setup in all 4 styles in Light/Dark with contrast/transparency settings inspected | Weak header/subtitle contrast over Satellite, comparable alternative native surfaces/choice, rendered numerical contrast/all states and iOS 18 fallback |
| UI6 | Unstarted | Approve optional copy/page order first |

Acceptance is limited to the checks actually exercised. User explicitly authorized
Simulator use on October 5. Current full-suite results below certify automated
execution on the integrated source; physical release evidence remains separate.

Latest F1–F4 source fingerprint:
`8a26f9c333ae9f3c35cb4e2999348a024bda0d7741ecb4aacd3193e435c177bf`.
Manifest, incremental patch, Debug/test-product compilation and unsigned Release
logs are in `/tmp/NapNav-Feedback-20261005/`. Current source passed 135/135
(`full-feedback.xcresult`); selected restored-control, setup/pending/tracking,
Large/XL, Thai/English, keyboard, accessibility-override and iPad rotation checks
are recorded in `/tmp/NapNav-Feedback-Sim-20261005/`. No application source changed
during this verification round.
The prior integrated fingerprint
`ea2b14e6479dfd7e8ee09d8257405a6b8d88f516be138f3ee915f0dbde9e0d9e`
passed 135/135 (`full-round2.xcresult`), with screenshots/trip evidence in
`/tmp/NapNav-UI2-UI5-Sim-20261005/`. Commands, limitations and current checks are
recorded in [DEVELOPMENT_REPORT.md](DEVELOPMENT_REPORT.md).

Prior UI5 source ratios on opaque reference colors: original emerald/white 2.54:1,
deep emerald/white 7.68:1, mint/#1C1C1E 13.27:1. These do not measure rendered
Liquid Glass, pressed/disabled states or map imagery. Existing panel material,
destructive red Stop, trip contracts and iOS 18 style fallbacks are preserved.
Review [the two surface proposals](UI5_SURFACE_PROPOSALS_2026-10-05.html) with
identical content in Light/Dark and two approximate backgrounds; they are browser
mockups, not native SwiftUI evidence. Broad shared-surface replacement waits for
native comparison. User's quota preference limits additional maximum-text testing.

## User feedback F1–F4 — implemented and selected Simulator acceptance passed

User explicitly requested holding changes while they collect more feedback
(October 5, 2026, 08:40 Bangkok), then authorized the combined revision at 08:46
and deferred Simulator testing. The subsequent instruction authorized remaining
Simulator checks. All four items below are implemented, compile-checked and
visually verified on the current source in the selected small/large-phone matrix;
iPad portrait/landscape setup was also verified. This closes these feedback
items, not the broader A3/A4 or release gates.

- [x] **F1 — Green button color:** User dislikes the darker green introduced in
  UI5 (`#065F46` primary fill versus the earlier `#10B981`). Restored `#10B981`
  for button fill/action roles, preserving explicit destructive red. The
  preferred green was confirmed in the revised Simulator build.
- [x] **F2 — Radius selection checkmark:** Remove the added visible checkmark from
  radius choice buttons, including the custom-distance selected state. The user's
  screenshot identifies the checkmark beside selected “1 km”; keep selection
  behavior and accessible selected-state semantics when revising its appearance.
- [x] **F3 — Start Trip shape:** Restore the Start Trip button's previous shape
  instead of the current pill appearance shown in the screenshot. Compare with
  the pre-change source/visual baseline before implementing; do not invent a new
  shape. Exact feedback: “ไม่เอาติ๊กถูก แล้วก็อยากได้รูปร่างปุ่ม start trip เหมือนเดิม”.
- [x] **F4 — Settings position:** Restore Settings to its original fixed upper
  corner across screens; do not place it beside the tracking distance card or let
  its position depend on that card's layout. UI1 moved it from the independent
  top overlay into the tracking HStack to reserve space for large text, causing
  the unwanted inward shift. Preserve the original normal-size arrangement when
  fixing overlap. User describes the original position as “ซ้ายบน”; inspected
  pre-change HEAD uses `.topTrailing`, so use the original visual/source baseline
  to establish the requested position rather than inventing another relocation.

Implementation notes: Start uses its original label frame, native prominent
style and large control size; the extra 44-point label minimum was removed.
The pinned/scrolling setup remains. Settings uses the original topTrailing
overlay and insets in every state; the tracking viewport reserves its control
footprint symmetrically instead of relocating the button. Preset/custom selected
accessibility traits remain without visible radius checkmarks.

Verified October 5, 2026: original green/native Start sizing/no radius checkmark;
fixed Settings in setup, pending and tracking on separate large/small phones;
small-phone Large/XL controls and Thai software-keyboard search; native
preset/custom selected traits; Start, active-trip tutorial replay, Stop cancel
and confirm; selected Dark/Satellite/accessibility overrides; iPad Asok/2 km
retention through actual portrait/landscape layout. Report entry 09:02 links
same-source tests and screenshots. Original-green text contrast remains a known
limitation; the approved visual preference was preserved.

Remaining extended checks: complete VoiceOver spoken/focus and gesture/keyboard
matrix, iPad narrow-window resizing (Device Hub Resize mode disabled and corner
drag produced no resize), iOS 18 fallback (runtime unavailable), and comparable
native surface/readability choice. User's sound observations are recorded in the
report: Focus on + screen off produces no sound; this remains unresolved physical
evidence and is not certified or diagnosed by Simulator checks.
