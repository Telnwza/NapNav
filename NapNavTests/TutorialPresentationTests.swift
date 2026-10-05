import Testing
@testable import NapNav

@Suite("Tutorial presentation")
struct TutorialPresentationTests {
    @Test("Ordinary Settings dismissal does not request a tutorial")
    func ordinaryDismissal() {
        var handoff = TutorialHandoff()
        #expect(handoff.consumeAfterDismissal() == nil)
    }

    @Test("Tutorial requests are consumed once after dismissal", arguments: [OnboardingMode.firstRun, .replay])
    func consumesRequestOnce(mode: OnboardingMode) {
        var handoff = TutorialHandoff()
        handoff.request(mode)
        #expect(handoff.consumeAfterDismissal() == mode)
        #expect(handoff.consumeAfterDismissal() == nil)
    }

    @Test("Repeated tutorial replay requests remain independent")
    func repeatedReplay() {
        var handoff = TutorialHandoff()
        for _ in 0..<3 {
            handoff.request(.replay)
            #expect(handoff.consumeAfterDismissal() == .replay)
            #expect(handoff.consumeAfterDismissal() == nil)
        }
    }

    @Test("Replay neither requires first-run completion nor requests permissions on Continue")
    func replayPolicy() {
        #expect(!OnboardingMode.replay.requiresCompletion)
        #expect(!OnboardingMode.replay.requestsPermissionsOnContinue)
    }

    @Test("First run and developer reset retain completion and permission behavior")
    func firstRunPolicy() {
        #expect(OnboardingMode.firstRun.requiresCompletion)
        #expect(OnboardingMode.firstRun.requestsPermissionsOnContinue)
    }

    @Test("First run requests permissions only on the final page")
    func finalPagePermissions() {
        #expect(!OnboardingMode.firstRun.requestsPermissions(on: .destination))
        #expect(!OnboardingMode.firstRun.requestsPermissions(on: .alertMethod))
        #expect(OnboardingMode.firstRun.requestsPermissions(on: .permissions))
    }

    @Test("The first-run pre-alert has only a Continue action; replay can close or go back")
    func permissionPageActions() {
        #expect(OnboardingMode.firstRun.primaryButtonTitleKey(on: .permissions) == "ดำเนินการต่อ")
        #expect(!OnboardingMode.firstRun.showsBackButton(on: .permissions))
        #expect(OnboardingMode.firstRun.showsBackButton(on: .alertMethod))
        #expect(!OnboardingMode.firstRun.showsBackButton(on: .destination))
        #expect(OnboardingMode.replay.primaryButtonTitleKey(on: .permissions) == "ปิดแนะนำการใช้งาน")
        #expect(OnboardingMode.replay.showsBackButton(on: .permissions))
        for language in [AppLanguage.thai, .english] {
            #expect(AppLocalization.string(OnboardingMode.firstRun.primaryButtonTitleKey(on: .permissions), language: language)
                == (language == .thai ? "ดำเนินการต่อ" : "Continue"))
        }
    }

    @Test("Replay never requests permissions automatically", arguments: OnboardingPage.allCases)
    func replayPagePermissions(page: OnboardingPage) {
        #expect(!OnboardingMode.replay.requestsPermissions(on: page))
    }

    @Test("Tutorial navigation follows three pages and stops at both boundaries")
    func pageNavigation() {
        #expect(OnboardingPage.allCases == [.destination, .alertMethod, .permissions])
        #expect(OnboardingPage.destination.previous == nil)
        #expect(OnboardingPage.destination.next == .alertMethod)
        #expect(OnboardingPage.alertMethod.previous == .destination)
        #expect(OnboardingPage.alertMethod.next == .permissions)
        #expect(OnboardingPage.permissions.previous == .alertMethod)
        #expect(OnboardingPage.permissions.next == nil)
    }
}
