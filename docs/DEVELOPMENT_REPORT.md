## 2026-09-30 23:50 — Repository: commit and push reviewed documentation

- **Status:** Complete
- **Goal:** Commit the completed NapNav documentation updates and push them to `main`, as explicitly authorized by the user.
- **Baseline:** Read `docs/NAPNAV_REMEDIATION_PLAN.md` and this report first. Branch is `main` at `db7937f`, tracking `origin/main` at the same commit. Seven tracked documentation files are modified: `AGENTS.md`, `README.md`, `docs/A1_D_A1_2_HANDOFF.md`, this report, `docs/LUNA_CODE_FIX_TICKETS.md`, `docs/NAPNAV_REMEDIATION_PLAN.md`, and `docs/app-store-metadata.md`. `NapNav.xcodeproj/xcshareddata/xcodecloud/manifest.json` is untracked and outside this documentation change.
- **Expected files:** The seven tracked documentation files listed above.
- **Changes:** Committed the seven reviewed documentation files as `2e9b84e` (`docs: sync NapNav review docs and handoff guidance`). `git push origin main` exited 0 and updated `main` from `db7937f` to `2e9b84e`.
- **Test evidence:** `git diff --check` and `git diff --cached --check` exited 0. `git diff --cached --name-only` listed exactly the seven expected files. After push, `git rev-parse --short HEAD` and `git rev-parse --short origin/main` both returned `2e9b84e`; `git status --short --branch` showed `main` aligned with `origin/main`. An initial combined `git rev-parse --short HEAD origin/main` query returned `fatal: Needed a single revision`; separate checks succeeded. No app tests or build were run for this documentation change.
- **Risks / open items:** The pre-existing untracked Xcode Cloud manifest remains untouched. No signing, release, or App Store Connect state was changed.
- **Next:** None for this documentation commit/push.

## 2026-09-30 23:47 — Documentation: English report and handoff preference

- **Status:** Complete
- **Goal:** Record the user's global preference for English reports and handoffs, preserving Thai where the Thai wording or context itself matters.
- **Baseline:** Read `docs/NAPNAV_REMEDIATION_PLAN.md` and this report first, as required by `AGENTS.md`. `HEAD=db7937f`; pre-existing local modifications are present in `README.md`, this report, `docs/A1_D_A1_2_HANDOFF.md`, `docs/LUNA_CODE_FIX_TICKETS.md`, `docs/NAPNAV_REMEDIATION_PLAN.md`, and `docs/app-store-metadata.md`; `NapNav.xcodeproj/xcshareddata/xcodecloud/manifest.json` is untracked. These changes are outside this task and must be preserved.
- **Files changed:** `AGENTS.md`, this report, and `/Users/te/.codex/memories/extensions/ad_hoc/notes/2026-09-30-2347-english-report-handoff-preference.md`.
- **Changes:** Added an English-by-default rule to `AGENTS.md` and created a global memory note with the same preference; both preserve Thai when exact wording or context matters.
- **Test evidence:** Read back the memory note and inspected the repo guidance. `git diff --check` exited 0. No app source, build, Simulator/GPX, or iPhone tests are in scope for this documentation-only change.
- **Risks / open items:** None for this preference update. The existing unrelated local edits and untracked Xcode Cloud manifest remain untouched.
- **Next:** None. No commit or push was made.

## 2026-09-30 23:23 — A4: ซิงก์สถานะ push และตรวจเอกสาร Markdown

- **สถานะ:** เสร็จสำหรับการซิงก์สถานะและ audit เอกสาร; App Review/release gates ยังเปิดตามแผน
- **เป้าหมาย:** ยืนยันสถานะ commit/push ที่ผู้ใช้แจ้ง แล้วตรวจว่าแผน, development report และ Markdown ปัจจุบัน/เก่าระบุสถานะหรือข้อเท็จจริงที่ยังใช้ได้ตรงกันหรือไม่
- **baseline:** อ่าน `docs/NAPNAV_REMEDIATION_PLAN.md` และรายงานนี้ก่อนเริ่มตรวจไฟล์อื่น. `HEAD=origin/main=db7937f37f062daf0ec9e91954a2a767b9f954c0`; branch `main` clean เมื่อเทียบกับ remote; มี untracked `NapNav.xcodeproj/xcshareddata/xcodecloud/manifest.json` ซึ่งไม่เกี่ยวกับงานนี้. แผนระบุอัปเดต 25 ก.ย. 2026 และมี A4/device/release gates เปิด; รายงานรายการล่าสุดยังบอกว่า push ถูกปฏิเสธก่อนรัน ซึ่งถูกต้องตามเวลารายการนั้นแต่ต้องเพิ่มสถานะล่าสุด
- **ไฟล์ที่เปลี่ยน:** `README.md`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md`, `docs/A1_D_A1_2_HANDOFF.md`, `docs/app-store-metadata.md` และรายงานนี้. ไม่แก้ `archive/docs/` หรือ untracked Xcode Cloud manifest
- **การเปลี่ยนแปลง:** ซิงก์แผนให้สะท้อน push ที่ผู้ใช้ทำเองและสถานะ security/A3 จริง; ระบุ S1 automated `stop-trip` กับสิ่งค้างของ `stop-alarm`/iPhone; ปรับ ticket/handoff source paths จาก `StopAlarm/` เป็น source folders ปัจจุบัน; ทำ handoff เดิมให้ระบุว่า A2.1–A2.3 เสร็จแล้ว; แก้ README ให้เป็น iOS 18/Swift 6/Xcode 16 และเอา static `126/126` badge/ข้ออ้าง alert/accessibility ที่เกินหลักฐานออก; คง App Name, Subtitle, Promotional Text และ keyword strings ตามเดิม พร้อมทำเครื่องหมาย keyword byte-limit/duplicate, screenshot specs และ What’s New first-version status
- **หลักฐานทดสอบ:** ณ baseline `HEAD` และ local `origin/main` ชี้ `db7937f`; `git status --short --branch` ยืนยัน branch ไม่มี ahead/behind และแสดงเฉพาะ 6 Markdown ที่แก้ในงานนี้กับ untracked Xcode Cloud manifest. `rg --files -g '*.md'` เทียบ `git ls-files '*.md'` พบ 24 ไฟล์ครบ; `git diff --check` exit 0. ตรวจ source settings ยืนยัน iOS 18, Swift 6, iPhone+iPad; source route ยืนยัน `stop-trip` ใช้ confirmation ส่วน `stop-alarm` ยังสั่ง `handleStopAlarm()` โดยตรง. ตรวจ Apple App Store Connect Help ปัจจุบันเรื่อง 100-byte keywords, 170-character Promotional Text, What’s New และ screenshot sizes; link อ้างอิงอยู่ใน metadata draft
- **Build/Simulator/GPX/iPhone:** ไม่รัน tests, build, Simulator/GPX หรือ iPhone เพราะรอบนี้แก้เฉพาะเอกสาร. Test `126/126` และ unsigned Release build ที่บันทึกใน audit 21:26 เป็นหลักฐานของ source fingerprint `a8ae7...` ในเวลานั้น ไม่ใช่หลักฐานของ copy/localization snapshot ที่ commit `db7937f`; ไม่มีการยืนยัน test/build ใหม่หลังการคืนคำโปรยล่าสุด
- **ความเสี่ยง/สิ่งค้าง:** Thai keywords มี 246 UTF-8 bytes เกิน 100 และมีคำซ้ำชื่อ; English มี `stop` ซ้ำชื่อ. ต้องให้ผู้ใช้เลือกคำค้นใหม่ก่อนกรอก. Screenshot files จริงยังไม่ได้ตรวจ/จัดทำสำหรับ iPhone+iPad. Live privacy/support URLs ลองเปิดผ่าน web tool แล้วแต่ไม่ accessible; deploy/HTTP ยังไม่ยืนยัน. App Store Connect category/privacy/reviewer metadata และ processed binary ยังไม่มีหลักฐาน; `napnav://stop-alarm` route/security กับ iPhone checks ยังเปิด. เอกสารใน `archive/docs/` และ artwork boards เป็นบันทึกของช่วงเวลานั้น ไม่ใช่ release status ปัจจุบัน
- **งานถัดไป:** ปรับ keyword draft โดยรักษาความหมายที่ผู้ใช้เลือก, ตรวจ URL จาก browser/hosting, สร้าง screenshots ตาม target iPhone+iPad, ทบทวน App Store Connect fields/processed build, ปิด `stop-alarm` decision และ manual iPhone/device gates; คง A4/release status เปิดจนมีหลักฐานครบ

## 2026-09-30 23:09 — A4: บันทึก Promotional Text ตามฉบับผู้ใช้

- **สถานะ:** commit อยู่ในเครื่องแล้ว; push ถูก auto-review ปฏิเสธก่อนรันคำสั่ง
- **เป้าหมาย:** บันทึกข้อความไทย/อังกฤษตรงตามต้นฉบับที่ผู้ใช้ให้ โดยไม่ใช้ถ้อยคำปรับใหม่ของผู้ช่วย แล้ว commit/push การเปลี่ยนแปลง App Review ที่เกี่ยวข้อง
- **baseline:** `HEAD=cd65a4e`, branch `main` ติดตาม `origin/main`; `docs/app-store-metadata.md` ยังไม่มี Promotional Text. Working tree มีการเปลี่ยนแปลงจาก App Review audit และคำโปรยในรอบก่อน รวมทั้ง `NapNav/DestinationSelection.swift` และ untracked `NapNav.xcodeproj/xcshareddata/xcodecloud/manifest.json` ที่มีอยู่ก่อนและไม่เกี่ยวกับ copy รอบนี้
- **ไฟล์ที่เปลี่ยน:** `docs/app-store-metadata.md` และรายงานนี้; stage การเปลี่ยนแปลง tracked ทั้ง 11 ไฟล์ใน working tree ตามคำสั่งผู้ใช้; untracked `NapNav.xcodeproj/xcshareddata/xcodecloud/manifest.json` คงไว้และไม่ stage
- **การเปลี่ยนแปลง:** เพิ่ม Promotional Text 107 ตัวอักษรไทยและ 137 ตัวอักษรอังกฤษ พร้อมอ้างอิงเพดาน 170 ตัวอักษรของ Apple; ไม่ใช้ฉบับปรับสำนวนของผู้ช่วย
- **หลักฐานทดสอบ:** ตรวจความยาวด้วย Unicode code points: ไทย 107, อังกฤษ 137; `git diff --check` และ `git diff --cached --check` exit 0. สร้าง local commit แล้ว. ไม่มี tests/build เพิ่มสำหรับการแก้เอกสาร/คำโปรย
- **ความเสี่ยง/สิ่งค้าง:** `git push origin main` ถูก auto-review ปฏิเสธก่อนรัน เพราะเป็น push ตรงเข้า default `main` และยังยืนยันไม่ได้ว่า remote เป็นของผู้ใช้; จึงไม่มีหลักฐานว่ามีการเปลี่ยน remote. ยังไม่มีการอ่าน metadata สดจาก App Store Connect
- **งานถัดไป:** รอการอนุมัติที่ระบุเป้าหมาย `origin/main` อย่างชัดเจนหรือหลักฐานยืนยัน remote ownership ก่อน push; App Store Connect live metadata ยังคงเป็น gate แยกต่างหาก

## 2026-09-30 23:02 — A4: ซิงก์ชื่อแอปและ subtitle ตามค่าปัจจุบัน

- **สถานะ:** เสร็จระดับ metadata draft; ไม่ได้แก้ App Store Connect หรือค่า display name ใน binary
- **เป้าหมาย:** ให้ตาราง App Store metadata แสดงชื่อแอปและ subtitle ปัจจุบันตามข้อความที่ผู้ใช้ให้มาทั้งไทยและอังกฤษ
- **baseline:** `HEAD=cd65a4e`; `docs/app-store-metadata.md` ยังมีชื่อเดิม `NapNav - ปลุกเตือนตามพิกัด` / `NapNav - GPS Transit Alarm` และ subtitle จากร่างก่อนหน้า. ถือค่าปัจจุบันตามข้อมูลผู้ใช้; ไม่มีหลักฐาน App Store Connect ใน workspace เพื่ออ่านค่าที่เผยแพร่โดยตรง
- **การเปลี่ยนแปลง:** อัปเดตเฉพาะตาราง App Name และ Subtitle เป็น `NapNav - Wake at Your Stop` / `NapNav - หลับไม่เลยป้าย` และ `Rest on the way, stay aware` / `พักระหว่างทางได้อุ่นใจ`; ไม่แตะคำโปรยยาวหรือ source binary
- **ไฟล์ที่เปลี่ยน:** `docs/app-store-metadata.md` และรายงานนี้
- **หลักฐานทดสอบ:** ตรวจความยาวด้วย Unicode code points: ชื่อ 26/23 และ subtitle 27/22 ตัวอักษร (English/Thai); ทั้งหมดไม่เกิน 30. `git diff --check` exit 0; ไม่มี tests/build สำหรับการแก้เอกสาร
- **ความเสี่ยง/สิ่งค้าง:** การแก้ตารางทำให้ draft ตรงกับค่าที่ผู้ใช้แจ้ง แต่ยังไม่ยืนยัน metadata ที่เผยแพร่จริงใน App Store Connect. English keywords ยังมีคำ `wake` และ `stop` ซ้ำกับชื่อแอป ซึ่งอาจทำให้เสียพื้นที่คำค้น; ยังไม่ได้เปลี่ยนในงานนี้
- **งานถัดไป:** เมื่อมี App Store Connect metadata export หรือภาพหน้าจอ ให้เทียบกับ draft ก่อนส่งเวอร์ชันใหม่

## 2026-09-30 22:53 — A3: คืนคำโปรยหลักของ NapNav

- **สถานะ:** เสร็จระดับข้อความและ source/static check; ไม่ได้รัน test suite, build, Simulator หรือ iPhone จริง
- **เป้าหมาย:** คืนสารหลักเรื่องพักระหว่างเดินทางและมีตัวช่วยเตือนก่อนถึงป้าย ใน subtitle และ onboarding โดยไม่เปลี่ยนรายละเอียดข้อเท็จจริงเรื่อง GPS, สิทธิ์, iOS, แบตเตอรี่ และการส่งข้อมูลให้ Apple ที่แก้ในรอบ App Store audit
- **baseline:** `HEAD=cd65a4e`; ใช้ข้อความเดิมใน `git show HEAD` เทียบกับ copy ปัจจุบันหลัง App Store Review Audit. ตรวจ A3 ใน `docs/LUNA_CODE_FIX_TICKETS.md` เพราะงานนี้เป็นการปรับข้อความ/ภาษา ไม่เปลี่ยนพฤติกรรมผลิตภัณฑ์. ชื่อแอปยังเป็นค่าเดิม; subtitle และ onboarding headline เป็นจุดที่ถูกปรับจนความหมายหลักจางลง
- **การเปลี่ยนแปลง:** คืน App Store subtitle เป็น `งีบหลับสบาย ไม่ต้องกลัวเลยป้าย` / `Wake up before your stop`; คืนประโยคเปิดคำอธิบายและภาพเล่าเรื่องหลักให้สื่อการงีบระหว่างเดินทาง, ปรับประโยคอธิบายต่อให้คงข้อจำกัดเรื่องตำแหน่ง/สิทธิ์/iOS, คืน onboarding destination/live-activity headline และปรับ localization resources กับ assertions ใน `NapNavTests/LocalizationTests.swift` ให้ตรง. คงรายละเอียดเตือนตามรัศมี, ข้อจำกัด AlarmKit/Live Activity, battery และ privacy ตามรอบ audit
- **ไฟล์ที่เปลี่ยน:** `docs/app-store-metadata.md`, `NapNav/OnboardingView.swift`, `NapNav/th.lproj/Localizable.strings`, `NapNav/en.lproj/Localizable.strings`, `NapNavTests/LocalizationTests.swift` และรายงานนี้
- **หลักฐานทดสอบ:** `git diff --check` exit 0; ค้นหา obsolete onboarding keys แล้วไม่พบ; App Store subtitle ยาว 30/24 Unicode code points (ไทย/อังกฤษ). ไม่รัน tests/build ตามขอบเขต copy-only
- **ความเสี่ยง/สิ่งค้าง:** headline เดิมใช้ถ้อยคำ “ไม่ต้องกลัวเลยป้าย” และ “wake up on time”; คำอธิบายยาวยังชี้แจงว่าตำแหน่งและการส่งเตือนอาจล่าช้าหรือไม่พร้อมใช้งาน. การคืนคำโปรยไม่ได้ยืนยันผล App Review และยังต้องให้ metadata ที่กรอกจริงตรงกับ binary/พฤติกรรม
- **งานถัดไป:** ตรวจร่างคำโปรยที่คืนแล้วก่อนกรอก App Store Connect; คง A4/device/release gates ตามรายการตรวจเดิม

## 2026-09-30 21:26 — App Store Review Audit: A4 production readiness

- **สถานะ:** กำลังทำ — metadata draft และ active onboarding/permission copy ปรับตามความสามารถจริงแล้ว; full Simulator suite 126/126 และ unsigned Release build ผ่านบน source manifest เดียวกัน; A4 ยังเปิดเพราะ live App Store Connect/processed binary, published URLs และ physical iPhone gate ยังไม่มีหลักฐาน
- **เป้าหมาย:** ตรวจความเสี่ยงที่เกี่ยวข้องกับ App Review Guidelines ทั้ง 5 หมวดสำหรับ NapNav v1.0 โดยแยก source/static, unsigned Release build, Simulator/GPX, iPhone จริง และ App Store Connect/processed binary; ทำให้ privacy disclosure, permission/reviewer copy และ API usage ตรงกับ source
- **baseline:** `HEAD=cd65a4d` (`main...origin/main`). Working tree ก่อนเริ่มมี user edits ที่ `NapNav/DestinationSelection.swift`, `NapNav/OnboardingView.swift`, `NapNav/en.lproj/Localizable.strings`, `NapNav/th.lproj/Localizable.strings` และ untracked `NapNav.xcodeproj/xcshareddata/xcodecloud/`; เก็บทั้งหมดไว้และแก้เฉพาะข้อความ/บรรทัดที่เกี่ยวข้อง. แผน A4 ยังเปิดและ checkout ปัจจุบันใช้ `NapNav/` โดย project alias `StopAlarm.xcodeproj` ชี้ไป project เดียวกัน
- **การเปลี่ยนแปลง:** อัปเดต `docs/privacy.html` ให้บอกการใช้ MapKit/Geocoder กับ Apple, Favorites/Recents (สูงสุด 10 รายการ), active-trip snapshot, วิธีลบ/เพิกถอน permission; แก้ `docs/support.html` ให้ตรง When In Use และใส่ข้อจำกัด GPS/แบตเตอรี่/ระบบพักแอป; ปรับ `docs/app-store-metadata.md` รวม reviewer steps, App Privacy draft, ข้อความไม่รับประกันผลเตือน และนับชื่อ/คำค้นใหม่; เปลี่ยน onboarding TH/EN ให้ไม่อ้างว่าไม่มีข้อมูลออกจากเครื่อง; เอา deprecated `.timeSensitive` ออกจาก `requestAuthorization(options:)` แต่คง `.timeSensitive` ใน notification content และ entitlement. ในการตรวจซ้ำ ปรับ localization ที่อ้างเตือนผ่าน Silent/Focus, “ไม่พลาด”, GPS แม่นยำ และปลุกตรงเวลา; ปรับ active onboarding map-pin/live/location/notification permission copy ให้ไม่สื่อความแม่นยำหรือรับประกันเวลาเตือน; ลบเฉพาะ legacy localization keys ที่ไม่มี source call site; อัปเดต `NapNavTests/LocalizationTests.swift` ให้ตรวจข้อความ TH/EN ที่ active; เก็บ user edits อื่นทั้งหมด; ไม่แก้ signing, bundle IDs, Xcode Cloud files หรือส่ง build ออกนอกเครื่อง
- **สถานะเนื้อหาเพิ่มเติม:** metadata draft ปรับ subtitle/description/storyboard จากคำที่สื่อ “ไม่ต้องกลัวเลยป้าย”, “Precise GPS” และ “right on time”; onboarding map/live/location/notification permission copy ปรับตามความสามารถจริง; ลบเฉพาะ legacy keys ที่ไม่มี source call site. `plutil -lint` TH/EN localization exit 0; scan user-facing docs/source ไม่พบ stale claims; subtitle Thai/English = 23/30 Unicode code points; full Simulator suite และ unsigned Release build รอบ source นี้ผ่าน
- **หลักฐานทดสอบ:**
  - **สถานะหลักฐานปัจจุบัน:** full Simulator suite และ unsigned Release build ผ่านบน source manifest เดียวกันหลังแก้ metadata/onboarding/permission copy
  - **Source/static รอบล่าสุด:** `git diff --check` exit 0; `plutil -lint` app/widget Info.plist, privacy manifest, entitlements, TH/EN `InfoPlist.strings`/`Localizable.strings` และ project exit 0; Python `HTMLParser` ตรวจ local links ใน privacy/support/index ไม่พบ link ขาด; scan ไม่พบข้อความเก่าที่รับประกันเวลาปลุก, GPS แม่นยำ, หรือไม่พลาด; subtitle Thai/English = 23/30 Unicode code points
  - **Unsigned Release build รอบล่าสุด (current source):** `NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-AppReview-Audit-20260930/current-results NAPNAV_DERIVED_DATA=/tmp/NapNav-AppReview-Audit-20260930/retry-DerivedData Scripts/phase-a0.sh release-build` exit 0, `BUILD SUCCEEDED`; log `/tmp/NapNav-AppReview-Audit-20260930/current-results/20260930-222921-release-build/xcodebuild.log`, `.xcresult` `/tmp/NapNav-AppReview-Audit-20260930/current-results/20260930-222921-release-build/build.xcresult`, source-manifest SHA-256 `a8ae7cf9e99926706b264946aa4d842b11b4c2a6540605f05cd27196112deacf`, ตรงกับ full test suite รอบล่าสุด; log scan ไม่พบ warning/error. เป็น unsigned local build ไม่ใช่ archive หรือ processed upload
  - **Source/static:** `plutil -lint` app/widget Info.plist, privacy manifest, entitlements, TH/EN InfoPlist/Localizable.strings และ project.pbxproj ผ่าน; `git diff --check` exit 0; Python `HTMLParser` อ่าน privacy/support/index และไม่พบ local link ขาด; source scan ไม่พบ URLSession/Firebase/StoreKit/AdSupport/ATT/analytics SDK หรือ media permission keys; ไม่มี `.timeSensitive` ใน `requestAuthorization(options:)` แต่ยังตั้ง `UNNotificationContent.interruptionLevel = .timeSensitive`. App name Thai/EN = 26/26, subtitle Thai/EN = 30/24, keywords Thai/EN = 94/97 Unicode code points
  - **Unsigned Release build:** คำสั่ง `NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-AppReview-Audit-20260930/retry-results NAPNAV_DERIVED_DATA=/tmp/NapNav-AppReview-Audit-20260930/retry-DerivedData Scripts/phase-a0.sh release-build` exit 0; log `/tmp/NapNav-AppReview-Audit-20260930/retry-results/20260930-215255-release-build/xcodebuild.log`, `.xcresult` `/tmp/NapNav-AppReview-Audit-20260930/retry-results/20260930-215255-release-build/build.xcresult`, source-manifest `2be70e288be33fce1eab216a6f93599a336944d1f0252694295c0906e7c1cdcd`. Build product ยืนยัน app `com.techin.NapNav` และ widget `com.techin.NapNav.Widget`, version `1.0.0 (12)`, minimum iOS 18, URL scheme `napnav`, iPhone/iPad family, privacy manifest embedded, purpose strings และ `ITSAppUsesNonExemptEncryption=false`; ทั้ง app/widget มี generated `UIRequiredDeviceCapabilities=['arm64']`
  - **Simulator/GPX fixture:** รอบแรกบน iPhone Air Simulator iOS 27.0 พบ assertion เก่าที่ `NapNavTests/LocalizationTests.swift:170` แล้ว `xcodebuild` ค้างหลังแสดงผล, `.xcresult` ไม่มี `Info.plist`; หยุดเฉพาะ PID 53766 หลัง 3:42 นาที (exit 143). อัปเดต assertions และ permission/onboarding localization แล้ว rerun สำเร็จบน source ล่าสุด: `126/126 tests`, 12 suites, `TEST SUCCEEDED`, exit 0. Log `/tmp/NapNav-AppReview-Audit-20260930/current-results/20260930-222826-full/xcodebuild.log`, `.xcresult` `/tmp/NapNav-AppReview-Audit-20260930/current-results/20260930-222826-full/tests.xcresult`, source-manifest SHA-256 `a8ae7cf9e99926706b264946aa4d842b11b4c2a6540605f05cd27196112deacf`. Log ไม่พบ `warning:`/`error:`. Suite `GPX release routes` เป็น policy tests จาก GPX fixtures ไม่ใช่การจำลอง Core Location/AlarmKit จริง
  - **iPhone จริง/App Store Connect:** ไม่ได้ทดสอบ iPhone จริง; Web tool เปิด live Privacy/Support URL ไม่ได้ จึงยังยืนยัน HTTP/deploy ไม่ได้; ยังไม่มี processed build หรือ metadata จาก App Store Connect ให้ตรวจ
- **ความเสี่ยง/สิ่งค้าง:** Apple เป็นผู้ตัดสิน review จึงรับประกันว่า reject ไม่ได้ไม่ได้. Built local bundle แสดง `UIRequiredDeviceCapabilities=['arm64']`; ประเด็นเดียวกันเคยเกิดกับ build 9 แต่ต้องเทียบ processed binary ของ build ที่ส่งจริงก่อนสรุปรากเหตุ และ build ปัจจุบันยังเป็น unsigned product ไม่ใช่ archive. Draft category ระบุ Navigation/Travel ขณะที่ local plist build มี `LSApplicationCategoryType=travel`; ต้องยืนยันหมวดจริงใน App Store Connect. ยังไม่ตรวจ App Store Connect/live metadata และความพร้อมของ privacy/support URLs; เสียง, Silent/Focus, locked-screen/background behavior และการกู้คืนทริปหลัง relaunch ต้องยืนยันบน iPhone. เพิ่มเติม: custom scheme `napnav://stop-alarm` เรียก `handleStopAlarm()` เพื่อจบทริปโดยตรง ส่วน `stop-trip` ใช้ confirmation; URL scheme ตรวจ route แต่ไม่ยืนยันแอปผู้เรียก จึงเป็น external-action/safety surface ที่ควรตัดสินใจเรื่อง confirmation/การแยกทาง Siri ก่อนส่ง
- **งานถัดไป:** เทียบ App Store Connect category, App Privacy answers, reviewer notes, published privacy/support URLs และ processed binary กับ draft/local bundle; ตัดสินใจ guard สำหรับ custom deep-link ที่เริ่ม/จบทริปโดยไม่ทำให้ Siri shortcut ผิดความคาดหมาย; ทดสอบ iPhone จริงสำหรับ AlarmKit sound, Silent/Focus, locked/background, arrival/Auto-Stop, stop/relaunch recovery และ supported devices; คง A4/device/release gates เปิดจนมีหลักฐานครบ โดยไม่ push/upload/TestFlight

## 2026-09-26 20:33 — Assets: ติดตั้ง App Icon จาก NapNav Exports (Default, Dark, Tinted)

- **สถานะ:** สำเร็จ — Asset Catalog compile AppIcon สำเร็จ, Build และ Unit tests ผ่าน 26/26 tests
- **เป้าหมาย:** นำไฟล์ไอคอนที่ผู้ใช้ออกแบบและ Export จาก Icon Composer มาตั้งค่าเป็น App Icon หลักของ NapNav
- **การดำเนินการ:**
  1. สร้าง `StopAlarm/Assets.xcassets/AppIcon.appiconset/`
  2. ติดตั้งไฟล์ภาพความละเอียด 1024x1024:
     - Default (Light): `NapNav-iOS-Default-1024@1x.png`
     - Dark Appearance: `NapNav-iOS-Dark-1024@1x.png`
     - Tinted Appearance: `NapNav-iOS-TintedDark-1024@1x.png`
  3. กำหนด `Contents.json` รองรับระบบ iOS Universal 1024x1024 พร้อมการปรับสีตาม appearance (Default, Dark, Tinted)
  4. ตั้งค่า Build Setting `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;` ใน target `StopAlarm`
- **หลักฐานทดสอบ:**
  - `BuildProject` สำเร็จ exit 0 โดย `actool` ทำการประมวลผลและสร้าง `AppIcon60x60@2x.png`, `AppIcon76x76@2x~ipad.png` ลงใน `NapNav.app`
  - `xcodebuild build` และ `xcodebuild test` บน iPhone 18 Pro Simulator ผ่าน 26/26 tests (TEST SUCCEEDED)
- **ไฟล์ที่เปลี่ยนแปลง:**
  - `StopAlarm/Assets.xcassets/AppIcon.appiconset/` (ไฟล์รูปภาพ + `Contents.json`)
  - `StopAlarm.xcodeproj/project.pbxproj`
  - `docs/DEVELOPMENT_REPORT.md`

## 2026-09-26 20:25 — UX: ปรับหน้าจอเริ่มต้น (Launch & Startup Screen) ให้เป็นหน้าจอเดียวแบบ Seamless Launch

- **สถานะ:** สำเร็จ — Build ผ่านฉลุย, Unit tests ชุด StartupRecoveryTests ผ่าน 26/26 tests
- **เป้าหมาย:** แก้ปัญหาผู้ใช้พบหน้าจอ Loading 2 หน้าจอซ้อนกัน (iOS Native Launch Screen และ SwiftUI StartupView) โดยรวมเป็นอันเดียวกัน: เปิดเข้าหน้าแผนที่หลักทันทีหลัง Launch Screen โดยไม่แสดง StartupView มาแทรกในรอบการเปิดปกติ
- **การเปลี่ยนแปลง:**
  1. `StopAlarm/TripStore.swift`: ในโหมด `.fastIfPossible` (ค่าเริ่มต้นของแอป) นำ reveal task ดีเลย์ 275ms ออก เพื่อไม่ให้ `StartupView` ถูกสั่งแสดงแทรกขึ้นมาเมื่อเตรียมข้อมูลเสร็จ ทำให้เข้าหน้าแผนที่หลักทันที โดยสงวน `StartupView` ไว้เฉพาะกรณีพบทริปค้างที่ต้องกู้คืน (`.awaitingTripRecovery`) หรือเกิดข้อผิดพลาด (`.failed`)
  2. `StopAlarm/Assets.xcassets/LaunchLogo.imageset/LaunchLogo.svg`: ปรับสีตัวอักษร "NapNav" จากสีฟ้าเก่า (#1677D2) เป็นสี Modern Emerald (#10B981) ตาม Theme ปัจจุบันของแอป เพื่อให้หน้า Launch Screen กลมกลืนกับหน้าจอหลัก
  3. `StopAlarm/DomainModels.swift` & `Localizable.strings` (th/en): อัปเดตข้อความตัวเลือกโหมด `.fastIfPossible` เป็น "เข้าหน้าหลักทันที (ค่าเริ่มต้น)" / "Instant Launch (Default)"
- **หลักฐานทดสอบ:**
  - BuildProject สำเร็จ exit 0, elapsed 5.58s
  - `xcodebuild test` บน iPhone 18 Pro Simulator สำหรับ `StopAlarmTests/StartupRecoveryTests` ผ่าน 26/26 tests (TEST SUCCEEDED)
- **ไฟล์ที่เปลี่ยนแปลง:**
  - `StopAlarm/TripStore.swift`
  - `StopAlarm/DomainModels.swift`
  - `StopAlarm/Assets.xcassets/LaunchLogo.imageset/LaunchLogo.svg`
  - `StopAlarm/en.lproj/Localizable.strings`
  - `StopAlarm/th.lproj/Localizable.strings`
  - `docs/DEVELOPMENT_REPORT.md`

## 2026-09-26 15:12 — Phase A3: UX, Accessibility, VoiceOver, Dynamic Type, Reduce Motion & Localization (Slices 2 & 3)

- **สถานะ:** สำเร็จ (0 compiler errors, 0 issues ใน Xcode Issue Navigator, automated tests 127/127 passed, รันแอปบน iPhone 18 Pro Simulator สำเร็จ)
- **เป้าหมาย:** ทำงานตามแผน Phase A3 (Slices 2 & 3) ต่อเนื่องจาก Slice 1:
  1. **Reduce Motion (Slice 3):** เอา store-owned hardcoded `reduceMotion: false` ออกจาก `StopAlarm/TripStore.swift` ทั้ง 5 จุด (launchState transition, useSelectedDestination, startTrip, finishTrip) เพื่อให้การเปลี่ยนสถานะและอนิเมชันเคารพการตั้งค่า `accessibilityReduceMotion` ของผู้ใช้จาก Environment ของ SwiftUI View อย่างสมบูรณ์
  2. **VoiceOver & Accessibility Localization (Slice 2):**
     - ใน `StopAlarm/RootView.swift`: Localize accessibility labels ของ Map compass (`"รีเซ็ตทิศเหนือของแผนที่"`), ปุ่มค้นหาตำแหน่ง (`"แสดงตำแหน่งของฉัน"`), รูปแบบแผนที่ (`"รูปแบบแผนที่ ปัจจุบันแบบ%@"`) และเพิ่ม accessibility hint สำหรับการแตะเปลี่ยนแบบแผนที่
     - ใน `StopAlarm/DestinationSelection.swift`: Localize ข้อความภาษาไทยที่ยังค้างอยู่ (`"กำลังรอตำแหน่ง"`, `"ถึง %@"`, `"เลือกจุดหมายนี้"`, `"กลับไปเลือกจุดหมาย"`, `"เปิด Settings"`, `"ให้ปลุกตอนเหลือระยะเท่าไร?"`, `"กำหนดระยะเอง"`, `"ระยะที่เลือก"`, `"เริ่มเดินทาง"`)
     - เพิ่ม accessibility traits (`.isSelected`) ให้ปุ่มเลือกระยะเตือน preset และ `.accessibilityValue` ให้กับตัวเลื่อนระยะกำหนดเอง (`radiusSlider`)
  3. **Dynamic Type & Layout Flexibility (Slice 2):**
     - ปรับปรุง `planningPanelHeight(in:)` ให้ปรับความสูงตาม `dynamicTypeSize.isAccessibilitySize` ป้องกันการล้นหรือถูกตัดทอนเมื่อผู้ใช้ตั้งค่าขนาดตัวอักษรใหญ่พิเศษ
     - ปรับ `lineLimit` ของการ์ดสถานที่โปรดและประวัติการเดินทาง (`favoriteCard`, `recentCard`) ให้ขยายเป็น 2 บรรทัดเมื่ออยู่ในโหมด Accessibility Dynamic Type
     - ปรับ `distanceCard` จาก fixed `.frame(height: 48)` เป็น `.frame(minHeight: 48)`
  4. **Automated Testing & Verification:**
     - เพิ่ม unit test ใน `StopAlarmTests/LocalizationTests.swift` สำหรับตรวจสอบการแปล Accessibility labels ทั้งภาษาไทยและภาษาอังกฤษ
- **หลักฐานทดสอบ:**
  - Build: `BuildProject` สำเร็จ 0 errors (ใช้เวลา 8.25s)
  - Issue Navigator: `XcodeListNavigatorIssues` 0 issues
  - Unit & UI Tests: `RunAllTests` ผ่านครบ 127/127 tests (0 failed, 0 skipped)
  - Simulator: `RunProject` บน iPhone 18 Pro Simulator สำเร็จ (PID 21800)

## 2026-09-26 13:56 — Refinement: ปรับโทนสีเขียวให้อ่อนลง สบายตาและทันสมัยขึ้นเป็น Modern Emerald / Mint (#10B981)

- **สถานะ:** สำเร็จ (0 compiler errors, automated tests 126/126 passed, ติดตั้งและรันบน Simulator สำเร็จ)
- **เป้าหมาย:** ปรับค่าสีของ Theme เขียวให้อ่อนลงและสดใสขึ้นตามความต้องการของผู้ใช้ จากเดิม `#16A34A` เป็น Modern Emerald/Mint `#10B981` เพื่อลดความเข้มทึบ เพิ่มความสบายตาและความชัดเจนบนหน้าจอ
- **การเปลี่ยนแปลง:**
  - ปรับค่าสีหลักใน `AppTheme` (`TripActivityAttributes.swift`):
    - Primary: `#10B981` (RGB: 16, 185, 129)
    - Dark: `#065F46` (RGB: 6, 95, 70)
- **หลักฐานทดสอบ:**
  - Build: `BuildProject` สำเร็จ 0 errors
  - Issue Navigator: 0 issues
  - Unit & UI Tests: `RunAllTests` ผ่านครบ 126/126 tests
  - Simulator: `RunProject` บน iPhone 18 Pro Simulator สำเร็จ (PID 17663)

## 2026-09-26 13:35 — Feature: อัปเดต Theme หลักของแอปเป็นโทนสีเขียวมรกต (Emerald Green Palette)

- **สถานะ:** สำเร็จ (0 compiler errors, automated tests 126/126 passed, รันแอปบน iPhone 18 Pro Simulator สำเร็จ)
- **เป้าหมาย:** เปลี่ยนสีหลักและโทน UI ของ NapNav จากสีฟ้าเดิม เป็นชุดสี Emerald Green ตามที่ผู้ใช้กำหนด:
  - Primary: `#16A34A` (Emerald Green หลัก สำหรับปุ่ม action, หมุดแผนที่, เส้นขอบ, selection)
  - Secondary: `#A7F3D0` (Soft Mint สำหรับพื้นหลังวงกลมรัศมี, badge, subtle accents)
  - Dark: `#064E3B` (Deep Forest Green สำหรับคอนทราสต์ตัวอักษร, dark gradient)
  - Background: `#ECFDF5` (Soft Mint Wash สำหรับโทนพื้นหลัง)
- **การเปลี่ยนแปลง:**
  1. สร้าง `AppTheme` namespace กลางใน `TripActivityAttributes.swift` เพื่อให้ใช้งานได้ร่วมกันทั้งใน Main App และ `NapNavWidget`
  2. กำหนด `.tint(AppTheme.primary)` ใน `StopAlarmApp.swift` เพื่อให้ระบบ SwiftUI ทั้งหมด (ปุ่ม Prominent, Stepper, Slider, Toggle, System Actions) ใช้งานสีเขียว `#16A34A`
  3. ปรับสี UI องค์ประกอบต่างๆ ใน `DestinationSelection.swift`, `RootView.swift`, `AlertSettingsView.swift`, `StartupView.swift`, `OnboardingView.swift`, `SystemClients.swift`, และ `TripLiveActivityWidget.swift`
- **หลักฐานทดสอบ:**
  - Build: `BuildProject` สำเร็จ 0 errors
  - Issue Navigator: 0 issues
  - Unit & UI Tests: `RunAllTests` 126/126 tests passed (0 failures)
  - Simulator: `RunProject` สำเร็จ (PID 15479)

## 2026-09-26 13:25 — Fix: แก้ไขปัญหา Type Checker Timeout และข้อผิดพลาดใน Issue Navigator ใน DestinationSelection.swift

- **สถานะ:** สำเร็จ (0 errors ใน Xcode Issue Navigator, automated tests 126/126 passed, รันแอปบน Simulator สำเร็จ)
- **เป้าหมาย:** แก้ไขปัญหาการคำนวณ type check ของคอมไพเลอร์ที่ใช้เวลานานเกินไป ("The compiler is unable to type-check this expression in reasonable time") และข้อผิดพลาด cascading ใน Xcode Issue Navigator (จำนวน 34 รายการ)
- **การเปลี่ยนแปลง:**
  1. Refactor `DestinationView.body` ใน `DestinationSelection.swift` โดยแตก expression ยักษ์ใน `ZStack` ออกเป็น `@ViewBuilder` subviews ย่อย ได้แก่ `mapView`, `trackingDistanceOverlay`, `mapControlsOverlay`, และ `settingsButtonOverlay`
  2. ปรับ `DestinationView.store` จาก `@Bindable var store: TripStore` เป็น `var store: TripStore` ปกติ และใช้ explicit `Binding(get:set:)` สำหรับจุดที่ต้องใช้ binding 2 ทิศทาง (`mapDisplayStyle`, `showsSettings`, `selectedRadiusMeters`) ขจัดปัญหา `@dynamicMemberLookup` ambiguity ที่ทำให้คอมไพเลอร์รายงาน dynamic member errors บน method/property ของ `TripStore`
- **หลักฐานทดสอบ:**
  - Build: `BuildProject` สำเร็จ (BUILD SUCCEEDED) ใช้เวลา 8.92 วินาที, errors: 0
  - Navigator Issues: `XcodeListNavigatorIssues` ตรวจพบ 0 issues (ลดลงจากเดิม 34 issues)
  - Unit & UI Tests: `RunAllTests` ผ่านครบ 126/126 tests, 0 failures, 0 skipped
  - Simulator: `RunProject` บน iPhone 18 Pro Simulator สำเร็จ (PID 13972)

# NapNav — รายงานการพัฒนาแบบต่อเนื่อง

รายงานนี้บันทึกสิ่งที่ทำจริงแยกจากแผนและผลทดสอบเก่า ทุก agent ต้องเพิ่มหรือ
อัปเดตรายการระหว่างทำงานตาม `AGENTS.md` พร้อมคำสั่ง ผลลัพธ์ และ path หลักฐาน
สถานะที่ใช้: `กำลังทำ`, `ผ่าน`, `ติดขัด`, `รอตัดสินใจ`

## 2026-09-26 13:00 — แก้ไขบัค layout ของ swipe row ใน Favorites และ Recents

- **สถานะ:** ผ่าน
- **เป้าหมาย:** แก้ไข layout glitch ของ `AppleSwipeRow` ใน `DestinationSelection.swift` ที่ทำให้ปุ่ม Favorite และ Delete แสดงค้างอยู่ตลอดเวลา และบีบการ์ดสถานที่จนผิดสัดส่วน
- **Baseline:** ใน `DestinationSelection.swift` ตัว `AppleSwipeRow` จัดวาง `leadingAction`, `content`, และ `trailingAction` ไว้ใน `HStack` เดียวกัน ทำให้ `content` ถูกบีบพื้นที่ และปุ่ม action แสดงผลออกมาตลอดเวลาในหน้าจอ
- **ไฟล์ที่เปลี่ยน:** `StopAlarm/DestinationSelection.swift`
- **การเปลี่ยนแปลง:**
  - ปรับสถาปัตยกรรม layout ของ `AppleSwipeRow`: ให้ `content` ครอบครองพื้นที่แถวเต็ม 100% (`frame(maxWidth: .infinity)`)
  - ย้าย `trailingAction` และ `leadingAction` ไปอยู่ที่ `.overlay(alignment: .trailing)` และ `.overlay(alignment: .leading)` โดยเลื่อนตำแหน่งไว้ด้านข้างของการ์ด พร้อมตั้งค่า opacity เป็น 0 เมื่อไม่ได้ swipe
  - เมื่อ swipe การ์ดจะเลื่อนพร้อมเผยปุ่ม action ออกมาอย่างลื่นไหล และเมื่อปล่อยนิ้วจะ snap หรือ fade กลับอย่างถูกต้อง
  - เพิ่ม `.contentShape(.rect)` ที่ปุ่ม action เพื่อให้กดติดง่ายและแม่นยำ
- **หลักฐานทดสอบ:**
  - BuildProject สำเร็จ (exit 0, errors 0)
  - RunAllTests ผ่านครบ 126/126 การทดสอบ (0 failed)
- **ความเสี่ยง/สิ่งค้าง:** ไม่มี
- **งานถัดไป:** นำส่งผลการแก้ไขให้ผู้ใช้

## 2026-09-26 12:52 — A4 artwork: สำรวจโลโก้ใหม่โดยไม่ใช้สัญลักษณ์เดิม

- **สถานะ:** ผ่านระดับบอร์ด concept; รอผู้ใช้ชี้แนวที่ชอบก่อนเก็บรูปทรง
- **เป้าหมาย:** สร้างบอร์ดแนวคิดขาวดำจำนวนมากที่สื่อการเดินทาง การเข้าใกล้จุดหมาย และการปลุก โดยไม่เริ่มจากหมุด ตัว N เส้นทาง หรือธง
- **Baseline:** ผู้ใช้ให้รื้อแนวคิดเดิมทิ้ง; concept รอบก่อนอยู่ใน `docs/artwork/` และยังไม่ใช่ AppIcon. แผน A4 icon gate ยังเปิด
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** ชุด SVG concept ใหม่และบอร์ดแสดงผลใน `docs/artwork/`; รายงานนี้. ไม่แก้ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม SVG concept ขาวดำ 12 แบบ `docs/artwork/concepts/napnav-fresh-*.svg`, บอร์ดรวม `docs/artwork/napnav-fresh-board.svg`/`.png` และคำวิจารณ์ `docs/artwork/napnav-fresh-board-notes.md`. ทั้งชุดรื้อหมุด/N/เส้นทาง/ธงจากรอบก่อน. ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout` 12 concept และ board SVG exit 0; `rg -n '<(image|text|use|filter)|url\(https?://'` บน concept exit 1 (ไม่มี raster/font/filter ภายนอก); `git diff --check` exit 0; `rsvg-convert` ส่งออกบอร์ด PNG 1200×1040 และ concept ที่ 32/16 px. การทำบอร์ดด้วย Python/Pillow รอบแรกหยุดที่ `ModuleNotFoundError: No module named 'PIL'`; เปลี่ยนเป็น SVG board และ render สำเร็จโดยไม่ติดตั้ง dependency. ตรวจบอร์ด PNG ด้วยตา. Build: ไม่รันเพราะไม่แตะ source แอพ; Simulator/GPX: ไม่รัน; iPhone จริง: ยังไม่ยืนยัน
- **ความเสี่ยง/สิ่งค้าง:** หลายแบบยังใกล้สัญลักษณ์ทั่วไป; ยังไม่ได้ทำ competitor/trademark check หรือทดสอบบน Home Screen จริง
- **งานถัดไป:** ให้ผู้ใช้เลือกความรู้สึก/รูปทรงที่ชอบจากบอร์ด แล้วทำรอบปรับความจำเพาะและตรวจขนาดเล็ก ก่อนลง Forest/Linen

## 2026-09-26 12:49 — A4 artwork: เริ่มแนวคิดโลโก้ใหม่

- **สถานะ:** ผ่านระดับ concept exploration; เหลือ 01/04 ให้ผู้ใช้เทียบก่อนทำรอบละเอียด
- **เป้าหมาย:** ร่างแนวคิดโลโก้ NapNav ใหม่หลายทิศทางเป็น SVG ขาวดำ โดยเทียบความหมายและการอ่านที่ขนาดไอคอนก่อนลงสี
- **Baseline:** ผู้ใช้ชอบทิศทางหมุด/เส้นทาง N/Forest-Linen แต่พบว่า R4B ที่เก็บรายละเอียดแล้วยังแข็ง; concept เดิมอยู่ใน `docs/artwork/concepts/` และยังไม่ใช่ AppIcon. แผน A4 icon gate ยังเปิด
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** SVG concept ใหม่และบอร์ดเปรียบเทียบใน `docs/artwork/`; รายงานนี้. ไม่แตะ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม SVG ขาวดำ 4 แบบ `docs/artwork/concepts/napnav-new-01-shelter.svg` ถึง `napnav-new-04-ribbon.svg` และบอร์ดคำวิจารณ์ `docs/artwork/napnav-new-logo-board.md`. คัด 02/03 ออกเพราะเส้นชนและรายละเอียดปลายทางไม่อ่านเมื่อย่อ; 01 อ่านชัดสุด; 04 มีไอเดียแต่ต้องแก้สัดส่วน. ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout docs/artwork/concepts/napnav-new-*.svg` exit 0; `rg -n '<(image|text|use|filter)|url\(https?://'` exit 1 (ไม่มี asset/font/filter ภายนอก); `git diff --check` exit 0. `rsvg-convert` render ทั้งสี่แบบที่ 512/32/16 px รวม 12 ไฟล์ `/tmp/napnav-new-*-{512,32,16}.png`; ตรวจด้วยตาที่ 512/32 px. Build: ไม่รันเพราะไม่แตะ source แอพ; Simulator/GPX: ไม่รัน; iPhone จริง: ยังไม่ยืนยัน
- **ความเสี่ยง/สิ่งค้าง:** 01 ยังใกล้รหัสหมุดทั่วไป; 04 ยังอ่านเป็นธงเล็กที่ 32 px; ยังไม่ตรวจความคล้ายเครื่องหมายอื่นหรือดู Home Screen จริง
- **งานถัดไป:** ให้ผู้ใช้เลือกว่าจะพัฒนา 01 ที่อ่านชัดหรือ 04 ที่มีบุคลิกกว่า แล้วแก้รูปทรงก่อนลง Forest/Linen

## 2026-09-26 12:46 — A4 artwork: เก็บความโค้งของ Forest/Linen

- **สถานะ:** ผ่านระดับ artwork refinement; รอผู้ใช้ดูรูปทรงก่อนทำ AppIcon
- **เป้าหมาย:** ปรับ R4B ที่ผู้ใช้ชอบให้เส้นทาง หมุด และธงดูนุ่มและมีจังหวะขึ้น โดยยังอ่านเป็นหมุด เส้น N และจุดหมายเมื่อย่อ
- **Baseline:** ผู้ใช้ชอบ `docs/artwork/concepts/napnav-r4b-p1-forest-linen.svg` และ dark pair แต่เห็นว่ายังแข็ง; ทั้งคู่เป็น SVG สองสี ยังไม่ใช่ AppIcon ในแอพ. แผน A4 icon gate ยังเปิด
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** SVG concept ใหม่ใน `docs/artwork/concepts/` และรายงานนี้; ไม่แก้ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม `docs/artwork/concepts/napnav-r4b-forest-linen-soft.svg` และ `napnav-r4b-forest-linen-soft-dark.svg`; รักษาหมุด เส้นทาง N ธง และสี Forest/Linen เดิม แต่ทำปลายหมุดมนขึ้น เส้น N โค้งต่อเนื่องขึ้น และธงมีขอบโค้งอ่อน ๆ. เก็บไฟล์ R4B/P1 เดิมไว้เพื่อเทียบ ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout` สอง SVG exit 0; `rg -n '<(image|text|use|filter)|url\(https?://'` exit 1 (ไม่มี asset/font/filter ภายนอก); `git diff --check` exit 0. `rsvg-convert` render light/dark ที่ 512/64/32/16 px รวม 8 ไฟล์ `/tmp/napnav-r4b-forest-linen-soft*-{512,64,32,16}.png`; ตรวจด้วยตาที่ 512, 32 และ 16 px และเทียบไฟล์เดิมที่ 512 px. Build: ไม่รันเพราะไม่แตะ source แอพ; Simulator/GPX: ไม่รัน; iPhone จริง: ยังไม่ยืนยัน
- **ความเสี่ยง/สิ่งค้าง:** ที่ 16 px ธงเป็นเพียงสัญญาณทิศทางเล็ก ๆ; ยังไม่ได้ดูบน Home Screen จริงหรือแพ็กเกจ AppIcon
- **งานถัดไป:** ให้ผู้ใช้เทียบเวอร์ชันที่เก็บความโค้งกับของเดิม แล้วปรับจุดที่ยังขัดตาก่อนทำ SVG master/AppIcon

## 2026-09-26 12:24 — A4 artwork: Forest/Linen dark appearance

- **สถานะ:** ผ่านระดับ artwork concept; รอผู้ใช้ตรวจ light/dark pair ก่อนแพ็กเกจ AppIcon
- **เป้าหมาย:** ทำ SVG dark appearance ของ R4B/P1 ที่ผู้ใช้ชอบ โดยรักษารูปทรงและสองสีเดิม แล้วตรวจความชัดเมื่อย่อ
- **Baseline:** `docs/artwork/concepts/napnav-r4b-p1-forest-linen.svg` เป็นคู่สีที่ผู้ใช้ชอบ; ยังไม่ได้ติดตั้ง AppIcon. แผน A4 icon gate ยังเปิด; ไม่แก้ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม `docs/artwork/concepts/napnav-r4b-p1-forest-linen-dark.svg`; แก้คำอธิบายสีใน light SVG ที่ยังระบุธงส้มจาก template; อัปเดต `docs/artwork/napnav-r4b-palettes.md`. Dark สลับสองสีเดิม: พื้น forest `#164449`, หมุด linen `#EEE7D8`, เส้น/ธง forest; geometry เหมือน light ทุกจุด. ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout` สำหรับ light/dark SVG exit 0; `rg` ไม่พบ raster/font/external asset (exit 1 เพราะไม่มี match); `git diff --check` exit 0. ใช้ `rsvg-convert` ส่งออก dark ที่ 512/64/32/16 px ใน `/tmp/napnav-r4b-p1-forest-linen-dark-*.png` และตรวจด้วยตา; Python XML audit รอบแรก assert ผิดเพราะอ่าน `fill="none"` เป็นสีของเส้นแทน `stroke` (exit 1), แก้ audit แล้ว exit 0 ยืนยัน geometry เหมือนกันและสีสลับตำแหน่งตรงทุก path. Contrast คู่สีเดิม 8.72:1. Build/Simulator/iPhone: ไม่รันเพราะไม่มี source แอพเปลี่ยน
- **ความเสี่ยง/สิ่งค้าง:** ยังไม่ได้ดูบน iPhone Home Screen จริงหรือเชื่อมเข้า Xcode dark appearance; artwork pair ยังรอผู้ใช้ตรวจ
- **งานถัดไป:** แสดง light/dark คู่กัน แล้วหลังผู้ใช้เลือกค่อยเก็บ optical alignment และทำ AppIcon package

## 2026-09-26 12:21 — A4 artwork: คู่สีของ R4B

- **สถานะ:** ผ่านระดับ color concept; รอผู้ใช้เลือกคู่สี
- **เป้าหมาย:** ทำ R4B รูปทรงเดียวกันหลายคู่สีแบบใช้สองสีจริง เพื่อให้ผู้ใช้เลือกอารมณ์ภาพโดยไม่ปนความต่างของ geometry
- **Baseline:** ผู้ใช้เลือก R4B ในรอบก่อน; source อยู่ที่ `docs/artwork/concepts/napnav-r4b-destination-flag.svg` มีพื้นครีม หมุดเขียว เส้นมิ้นต์ ธงส้ม รวม 4 สี. ยังไม่ใช่ AppIcon ใน Xcode; ไม่แก้ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม SVG 5 คู่สี `docs/artwork/concepts/napnav-r4b-p1-forest-linen.svg` ถึง `napnav-r4b-p5-pine-lime.svg` และ `docs/artwork/napnav-r4b-palettes.md`; ทุกรูปใช้ path geometry ของ R4B เดิมและมีเพียงสองสี. ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout docs/artwork/concepts/napnav-r4b-p*.svg` exit 0; Python XML audit ยืนยัน geometry เหมือนกันทั้ง 5 และแต่ละไฟล์มีสี 2 ค่า; `rg` ไม่พบ raster/font/external asset (exit 1 เพราะไม่มี match); `git diff --check` exit 0. ใช้ `rsvg-convert` ส่งออกภาพตรวจที่ 512/64/32/16 px เป็น `/tmp/napnav-r4b-p*-*.png` แล้วดูด้วยตา; อัตรา contrast ของคู่สี P1–P5 ตามลำดับ 8.72, 11.51, 9.67, 4.76, 9.49 ต่อ 1. Build/Simulator/iPhone: ไม่รันเพราะไม่มี source แอพเปลี่ยน
- **ความเสี่ยง/สิ่งค้าง:** P4 contrast ต่ำกว่าทางเลือกอื่น แม้ภาพย่อยังอ่านได้; ยังไม่ได้ดูบน Home Screen จริงในบริบท wallpaper/Light/Dark หรือทำ collision/trademark clearance. ยังไม่ใช่ final AppIcon
- **งานถัดไป:** ส่งคู่สีทั้งห้าให้ผู้ใช้เลือก แล้วเก็บ optical alignment/ระยะธงก่อนทำ SVG master

## 2026-09-26 12:18 — A4 artwork: แก้จุดกลมใน R4

- **สถานะ:** ผ่านระดับ concept refinement; รอผู้ใช้เลือกปลายเส้น
- **เป้าหมาย:** รักษาเส้นทางโค้งของ R4 ที่ผู้ใช้ชอบ แต่แทนจุดกลมต้น/ปลายที่ยังไม่สื่อความหมายด้วยปลายเส้นที่บอกทิศทางหรือจุดหมายชัดขึ้น
- **Baseline:** `docs/artwork/concepts/napnav-r4-trail.svg` เป็น concept ที่ผู้ใช้ชอบ แต่ทักว่าจุดกลมไม่สื่ออะไร; ยังไม่ใช่ AppIcon. แผน A4 ยังเปิด และไม่แตะ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม `docs/artwork/concepts/napnav-r4a-arrow.svg` และ `napnav-r4b-destination-flag.svg` พร้อม `docs/artwork/napnav-r4-endpoints.md`. ทั้งคู่ตัดวงกลมต้นทาง; R4A ให้เส้นจบที่หัวลูกศร, R4B ให้เส้นจบที่ธงจุดหมาย. ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout docs/artwork/concepts/napnav-r4{a,b}-*.svg` exit 0; `rg` ไม่พบ `<image>`, `<text>`, `<use>`, `<filter>` หรือ external URL (exit 1 เพราะไม่มี match); `git diff --check` exit 0. ใช้ `rsvg-convert` ส่งออกภาพตรวจ 512/32/16 px ใน `/tmp/napnav-r4{a,b}-*.png` และภาพขาวดำชั่วคราว `/tmp/napnav-r4{a,b}-*-mono.png`; ตรวจภาพด้วยตาแล้วเส้น N/หมุดยังอ่านได้. Build/Simulator/iPhone: ไม่รันเพราะไม่มี source แอพเปลี่ยน
- **ความเสี่ยง/สิ่งค้าง:** ที่ 16 px สัญลักษณ์ปลายทางเล็กมาก; R4A อาจสื่อการนำทางทั่วไป, R4B มีรายละเอียดเพิ่ม. ยังไม่ตรวจบน iPhone Home Screen หรือทำเครื่องหมายการค้า; ยังไม่ใช่ final AppIcon
- **งานถัดไป:** ให้ผู้ใช้เลือกปลายเส้น แล้วเก็บ optical alignment/ขนาดสัญลักษณ์ก่อนทำ SVG master

## 2026-09-26 12:08 — A4 artwork: เส้นทางแทน N ในหมุด

- **สถานะ:** ผ่านระดับ concept exploration; รอผู้ใช้เลือก route-N direction
- **เป้าหมาย:** ตอบข้อสังเกตผู้ใช้ว่า C1–C4 ยังโล่งและ N เป็นตัวอักษรตรง ๆ โดยออกแบบ SVG ที่ใช้เส้นทางจริงสร้างรูป N พร้อมจุดเริ่ม/เลี้ยว/จุดหมาย
- **Baseline:** C1–C4 อยู่ใน `docs/artwork/concepts/` และรายงานรอบ 12:04; ยังไม่มี AppIcon ติดตั้ง. แผน A4 ยังเปิด และงานนี้ไม่แตะ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม `docs/artwork/concepts/napnav-r1-waypoints.svg`, `napnav-r2-curved-route.svg`, `napnav-r3-active-route.svg`, `napnav-r4-trail.svg` และ `docs/artwork/napnav-route-n-variants.md`. R1 ใช้จุดเริ่ม/จุดจบบน N ตรงเดิม, R2 ทำ N เป็นทางโค้ง, R3 แสดงเส้นความคืบหน้าบนทาง N, R4 ให้เส้นทางสีอ่อนโค้งในหมุดสีเข้ม. คัด R1 ออกจาก shortlist เพราะยังดูนิ่งแบบเดิม; ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout docs/artwork/concepts/napnav-r{1,2,3,4}-*.svg` exit 0; `rg` ไม่พบ `<image>`, `<text>`, `<use>`, `<filter>` หรือ external URL (exit 1 เพราะไม่มี match); `git diff --check` exit 0. ใช้ `rsvg-convert` ทำภาพชั่วคราวที่ 512, 64, 32, 16 px ใน `/tmp/napnav-r*-{512,64,32,16}.png` แล้วตรวจด้วยตา; สร้าง SVG/PNG สีเดียวชั่วคราว `/tmp/napnav-r*-mono.*` เพื่อตรวจ silhouette. Build/Simulator/iPhone: ไม่รันเพราะไม่มี source แอพเปลี่ยน
- **ความเสี่ยง/สิ่งค้าง:** จุดเริ่ม/ปลายและเส้น progress จางลงหรือหายไปที่ 16 px; silhouette หมุดและ N ยังอ่านได้. ยังไม่ตรวจบน iPhone Home Screen หรือความคล้ายทางเครื่องหมายการค้า; ยังไม่ใช่ final AppIcon
- **งานถัดไป:** ให้ผู้ใช้เทียบ R2–R4; หลังเลือกแล้วเก็บ optical alignment, สีเดียว/reversed และ SVG master ก่อนแพ็กเกจ AppIcon

## 2026-09-26 12:04 — A4 artwork: แตกแบบ C เป็นหลาย SVG

- **สถานะ:** ผ่านระดับ concept exploration; รอผู้ใช้เลือก variant ก่อนเก็บ final master
- **เป้าหมาย:** ต่อยอดแนว C ที่ผู้ใช้เลือก โดยลองสัดส่วนหมุด ช่อง N และน้ำหนักสีหลายแบบ แล้วคัดตามความชัดเมื่อย่อและการใช้สีเดียว
- **Baseline:** `docs/artwork/concepts/napnav-c-pin-path.svg` เป็น SVG แบบ C ที่ผู้ใช้ชอบ; ยังไม่ใช่ AppIcon ใน Xcode. แผน A4 ยังเปิด icon gate และ workspace มีงาน source อื่นค้างอยู่; งานนี้จะไม่แก้ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม `docs/artwork/concepts/napnav-c1-compact.svg`, `napnav-c2-outline.svg`, `napnav-c3-tapered.svg`, `napnav-c4-warm.svg` และ `docs/artwork/napnav-c-variants.md`; เปลี่ยนสัดส่วนหมุด โครงแบบทึบ/เส้น และโทนสีโดยรักษา N กับจุดปลายทาง. ไม่แก้ source แอพ
- **หลักฐานทดสอบ:** source/static: `xmllint --noout docs/artwork/concepts/napnav-c{1,2,3,4}-*.svg` exit 0; `rg` ไม่พบ `<image>`, `<text>`, `<use>`, `<filter>` หรือ external URL (exit 1 เพราะไม่มี match); `git diff --check` exit 0. ใช้ `rsvg-convert` ส่งออกทุกแบบที่ 512, 64, 32 และ 16 px เป็น `/tmp/napnav-c*-{512,64,32,16}.png` และตรวจภาพด้วยตา; ส่งออกขาวดำชั่วคราว `/tmp/napnav-c*-mono.svg` และ `/tmp/napnav-c*-mono.png` เพื่อตรวจรูปทรง. Build/Simulator/iPhone: ไม่รันเพราะไม่มี source แอพเปลี่ยน
- **ความเสี่ยง/สิ่งค้าง:** จุดสีเน้นจางลงมากที่ 16 px; หมุดกับ N ยังเป็นความหมายหลัก. ยังรอผู้ใช้เลือก variant, ไม่ได้ตรวจ Home Screen บน iPhone จริงหรือทำ collision/trademark clearance; ยังไม่ใช่ AppIcon
- **งานถัดไป:** ส่ง C1–C4 ให้ผู้ใช้เทียบ; หลังเลือกแล้วปรับ optical alignment และทำ SVG master/เวอร์ชันสีเดียวก่อนแพ็กเกจ AppIcon

## 2026-09-25 23:39 — A4 artwork: เริ่มแนวทางไอคอนใหม่ด้วย logo-design-board

- **สถานะ:** ผ่านระดับ concept exploration; รอผู้ใช้เลือกทิศทาง B หรือ C ก่อนทำ final SVG/AppIcon
- **เป้าหมาย:** สร้างไอคอน SVG หลายแนวทางที่ต่างกันจริงสำหรับ NapNav แล้วเทียบความชัดเมื่อย่อและเมื่อใช้สีเดียว ก่อนให้ผู้ใช้เลือกแบบ
- **Baseline:** ต้นแบบ `docs/artwork/napnav-pin-alarm.svg` ยังไม่ถูกเลือก/ติดตั้ง; แผน A4 ยังระบุ icon เป็นงานเปิด. ตรวจ App Store ของแอพ location alarm พบไอคอนหมุดผสมนาฬิกา/กระดิ่งหลายตัว จึงถือว่าแนวเดิมมีความเสี่ยงเรื่องความคล้าย. Workspace มี source edits เดิมค้างอยู่ตาม `git status --short`; จะไม่แตะ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม `docs/artwork/concepts/napnav-a-arrival-zone.svg`, `napnav-b-route-n.svg`, `napnav-c-pin-path.svg` และ `docs/artwork/napnav-icon-board.md`; ไม่แก้ source แอพ. A เป็นแนววงเขตและเส้นทาง, B เป็น N ที่ปลายเส้นเป็นจุดหมาย, C เป็นหมุดที่มี N เป็นช่องว่าง. ภาพย่อและสีเดียวทำให้เห็นว่า A คล้ายแว่นขยาย จึงตัดจาก shortlist
- **หลักฐานทดสอบ:** source/static: `xmllint --noout docs/artwork/concepts/*.svg` exit 0; `rg` ตรวจแล้วไม่มี `<image>`, `<text>`, `<use>`, `<filter>` หรือ external URL ใน SVG. ใช้ `rsvg-convert` ส่งออกภาพชั่วคราวที่ 512, 32 และ 16 px ทุก concept ใน `/tmp/napnav-*-{512,32,16}.png` แล้วตรวจด้วยตา; ทำ SVG สีเดียวชั่วคราว `/tmp/napnav-*-mono.svg` และภาพ `/tmp/napnav-*-mono.png` เพื่อตรวจรูปร่าง. Build/Simulator/iPhone: ไม่รันเพราะยังไม่มีการเปลี่ยนแอพ
- **ความเสี่ยง/สิ่งค้าง:** B ยังอาจสื่อฟังก์ชันเตือนไม่ชัดโดยไม่มีชื่อ; C ยังใช้รูปหมุดที่พบในแอพแผนที่ทั่วไป. ยังไม่ได้ทำ collision/trademark clearance หรือดูไอคอนบน Home Screen ของ iPhone จริง; ยังไม่ใช่ final AppIcon
- **งานถัดไป:** ให้ผู้ใช้เลือก B หรือ C แล้วปรับ optical alignment, สี และเวอร์ชันสีเดียว ก่อนใช้ `app-icon-gen` ทำชุดไฟล์สำหรับ Xcode

## 2026-09-25 23:29 — A4 artwork: ต้นแบบไอคอนหมุดปลุก

- **สถานะ:** ผ่านระดับต้นแบบ artwork; รอผู้ใช้ตรวจและเลือกทิศทางก่อนนำไปใช้ในแอพ
- **เป้าหมาย:** ทำต้นแบบ SVG แบบเวกเตอร์ของไอคอน NapNav พร้อมสี รูปทรง และการอ่านออกเมื่อย่อเล็ก เพื่อให้ผู้ใช้ตรวจทิศทางภาพก่อนนำไปใส่แอพ
- **Baseline:** แผน A4 ระบุว่า icon ยังเป็นงานเตรียมปล่อยแอพ; `StopAlarm/Assets.xcassets` มี `LaunchLogo.svg` แบบข้อความและยังไม่มี `AppIcon.appiconset`; `git status --short` พบงานเดิมค้างอยู่ใน workspace จึงไม่แตะ source แอพ
- **การเปลี่ยนแปลง:** เพิ่ม `docs/artwork/napnav-pin-alarm.svg` ขนาดพิกัด 1024×1024 ใช้หมุดฟ้า หน้าปัดขาว เข็มกรมท่า และจุดเน้นส้มบนพื้นน้ำเงินเข้ม; SVG ใช้รูปทรงเวกเตอร์ ไม่มีฟอนต์หรือภาพ raster ภายใน และไม่ได้แก้ source แอพ
- **หลักฐานทดสอบ:** `xmllint --noout docs/artwork/napnav-pin-alarm.svg` exit 0; `rsvg-convert -w 512 -h 512 ... -o /tmp/napnav-pin-alarm-512.png` และ `-w 64 -h 64 ... -o /tmp/napnav-pin-alarm-64.png` exit 0 ทั้งคู่; ตรวจภาพทั้งสองขนาดด้วยตาแล้วเห็นหมุดและหน้าปัดชัด. `sips` แปลง SVG ไม่ได้ (exit 13) จึงใช้ `rsvg-convert` ที่ติดตั้งอยู่; `python3` ไม่มี `cairosvg` ไม่จำเป็นต้องติดตั้งเพิ่ม. ไม่รัน build/Simulator/iPhone เพราะยังไม่ได้แก้แอพ
- **ความเสี่ยง/สิ่งค้าง:** ยังไม่ได้ติดตั้งเป็น AppIcon, ตรวจใน iPhone หรือผ่านการอนุมัติทิศทางจากผู้ใช้; สีและรายละเอียดอาจปรับหลังเห็นในบริบทหน้าจอจริง
- **งานถัดไป:** ส่งต้นแบบ SVG ให้ผู้ใช้ดูและรับข้อคิดเห็นก่อนส่งออก AppIcon สำหรับ Xcode

## 2026-09-25 21:25 — A3: ปิดเสียง AlarmKit แล้วทริปต้องเดินต่อ

- **สถานะ:** ผ่านระดับ source/static, automated Simulator/GPX tests และ unsigned Release build บน source snapshot หลังแก้ทั้งปุ่ม X และ recovery; รอยืนยันพฤติกรรมจริงบน iPhone
- **เป้าหมาย:** เมื่อกด X บน AlarmKit alert ให้หยุดเสียง/alert เท่านั้น รักษาการติดตาม GPS และทริปไว้จนยืนยันว่าถึงจุดหมายหรือผู้ใช้กดหยุดทริปในแอป; ใช้ภาพ `IMG_4093.PNG` และ `IMG_4092.PNG` เป็นหลักฐานอาการและตรวจข้อความภาษาอังกฤษที่ถูกตัด
- **Baseline:** `shasum -a 256 -c /tmp/NapNav-A3-results/20260925-175518-full/source-files.sha256` ผ่าน exit 0 สำหรับ source snapshot ล่าสุด; fingerprint `78873af69af8de03878c7b4cbc8c2463d51ede7de256b4496965c9cfb5ca709e`. ก่อนแก้ full Simulator tests 116/116 และ unsigned Release build ผ่านตามรายการ A3 slice 1 ด้านล่าง; `git status --short` แสดง source ทั้งโปรเจกต์เป็น untracked อยู่ก่อนเริ่มงานนี้
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/SystemClients.swift`, `StopAlarm/StopAlarmApp.swift`, `StopAlarm/TripStore.swift`, `StopAlarm/en.lproj/Localizable.strings`, `StopAlarmTests/TripStoreTests.swift`, `StopAlarmTests/StartupRecoveryTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md` และรายงานนี้
- **สิ่งที่ตรวจพบ:** `scheduleProminentAlarm` ส่ง `StopTripAlarmIntent` ให้ `stopIntent`; intent นี้เรียก `AlarmTripActionBridge.requestStop()` และ handler ใน `NapNavApp` เรียก `store.stopTrip()` จึงยกเลิก GPS/Live Activity และล้างทริปเมื่อกด X. AlarmKit มี stop control ของระบบอยู่แล้วและ `stopIntent` เป็น optional callback เพิ่มเติม. English alert title ปัจจุบัน `NapNav: Approaching Destination` ยาวจนถูกตัดในภาพ
- **ตรวจเพิ่ม (2026-09-25 21:36 +07:00):** `TripStore.performLaunchPreparation()` ยังลบ active-trip snapshot หาก `prominentAlarmExists` เป็น false; test `missingPersistedAlarmCleansUpInsteadOfRestoring` ยืนยันพฤติกรรมเดิมนี้. เมื่อกด X แล้ว AlarmKit หายจากระบบ การ relaunch จะลบทริปทันที แม้ไม่มี stop intent แล้ว จึงต้องแก้ recovery path และกลับทิศ regression test ก่อนปิดงาน
- **การเปลี่ยนแปลง (อัปเดต 2026-09-25 21:26 +07:00):** `StopAlarm/SystemClients.swift` ตั้ง `stopIntent: nil` ให้ AlarmKit จัดการปุ่ม X เพื่อหยุด alarm โดยไม่มี callback ที่จบทริป และลบ `StopTripAlarmIntent`/`AlarmTripActionBridge` ที่ใช้เพื่อจบทริปเท่านั้น; `StopAlarm/StopAlarmApp.swift` เลิกติดตั้ง handler ที่เรียก `store.stopTrip()`. ปุ่มหยุดทริปโดยตรงยังผ่าน flow เดิม. ย่อ English AlarmKit title เป็น `Almost there` เพราะภาพแสดง title เดิมถูกตัดและเล็กกว่าภาษาไทย. แทน test ของ bridge ที่ถูกลบด้วย regression test ของ notification dismiss ซึ่งต้องคง GPS/ทริปไว้จนยืนยัน arrival ใน `StopAlarmTests/TripStoreTests.swift`
- **การเปลี่ยนแปลงเพิ่ม (อัปเดต 2026-09-25 21:38 +07:00):** `StopAlarm/TripStore.swift` ไม่ใช้การมีอยู่ของ alarm เป็นเกณฑ์ลบ active-trip snapshot ตอน launch; snapshot ที่ยังเป็น active phase จะเสนอกู้คืนแม้ผู้ใช้กด X หยุดเสียงแล้ว. เปลี่ยน test เดิมใน `StopAlarmTests/StartupRecoveryTests.swift` ที่คาดให้ลบทริป เป็นการพิสูจน์ว่า snapshot ยังอยู่, resume แล้ว GPS เริ่มอีกครั้ง และรับตำแหน่งต่อจนถึง arrival โดยไม่ส่ง alarm ซ้ำ. ผล targeted/full/Release ของ fingerprint `e23df0dd…` ข้างล่างเป็นรอบก่อนการแก้ส่วนนี้ ต้องรันใหม่
- **ไฟล์ที่เปลี่ยนแล้ว:** `StopAlarm/SystemClients.swift`, `StopAlarm/StopAlarmApp.swift`, `StopAlarm/TripStore.swift`, `StopAlarm/en.lproj/Localizable.strings`, `StopAlarmTests/TripStoreTests.swift`, `StopAlarmTests/StartupRecoveryTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md` และรายงานนี้
- **Recovery targeted (อัปเดต 2026-09-25 21:39 +07:00):** `xcodebuild -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' -derivedDataPath /tmp/NapNav-A3AlarmDismiss-DerivedData -resultBundlePath /tmp/NapNav-A3AlarmDismiss-recovery-targeted-20260925.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/StartupRecoveryTests CODE_SIGNING_ALLOWED=NO test` ผ่าน exit 0, 26/26 ใน 1 suite รวมกรณี AlarmKit ถูกปิดแล้ว relaunch/resume/arrival
- **Full test หลังแก้ recovery (อัปเดต 2026-09-25 21:39 +07:00):** `NAPNAV_DESTINATION='platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' NAPNAV_DERIVED_DATA=/tmp/NapNav-A3AlarmDismiss-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A3AlarmDismiss-results Scripts/phase-a0.sh test-full` ผ่าน exit 0, 116/116, 0 failed/0 skipped ใน 12 suites รวม GPX; artifacts `/tmp/NapNav-A3AlarmDismiss-results/20260925-213848-full/summary.json`, `tests.xcresult`, `xcodebuild.log`, `source-files.sha256`, `source-manifest.sha256`; fingerprint ใหม่ `cb18b5637686d72e152045a4f536facb0fe71ff281f1b93418bfe08d9717a2c1`
- **หลักฐานทดสอบ (อัปเดต 2026-09-25 21:31 +07:00):** `rg` ไม่พบ `AlarmTripActionBridge`/`StopTripAlarmIntent` หลงเหลือ; พบ `stopIntent: nil` จุดเดียว. `plutil -lint StopAlarm/en.lproj/Localizable.strings` ผ่าน. Targeted `xcodebuild ... -only-testing:StopAlarmTests/TripStoreTests -only-testing:StopAlarmTests/NotificationDelegateTests CODE_SIGNING_ALLOWED=NO test` ใน sandbox จบ exit 70 ก่อนเริ่ม tests เพราะ CoreSimulatorService `Connection refused` และหา Simulator destination ไม่พบ; result bundle `/tmp/NapNav-A3AlarmDismiss-targeted-20260925.xcresult`. รันคำสั่งเดียวกันใน Xcode execution context ที่เข้าถึง Simulator ได้ (เปลี่ยน result path เป็น `/tmp/NapNav-A3AlarmDismiss-targeted-elevated-20260925.xcresult`) ผ่าน exit 0, 22/22 tests ใน 2 suites บน iPhone 18 Pro iOS 27.0 Simulator; รวม test ใหม่ที่ปิด notification แล้วทริปยังติดตามต่อจนถึงจุดหมาย. Full suite คำสั่ง `NAPNAV_DESTINATION='platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' NAPNAV_DERIVED_DATA=/tmp/NapNav-A3AlarmDismiss-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A3AlarmDismiss-results Scripts/phase-a0.sh test-full` ผ่าน exit 0, 116/116, 0 failed/0 skipped ใน 12 suites รวม GPX; artifacts `/tmp/NapNav-A3AlarmDismiss-results/20260925-213012-full/summary.json`, `tests.xcresult`, `xcodebuild.log`, `source-files.sha256`, `source-manifest.sha256`; source fingerprint `e23df0dda3a9584a51bd6f5a8a2c254fdcad3cc26d52a73196c7e9bb83e3840b`
- **Source/static (อัปเดต 2026-09-25 21:40 +07:00):** Apple AlarmKit ระบุว่า system stop button หยุด alarm เอง และ `stopIntent` เป็น callback เพิ่มเติม; source สุดท้ายส่ง `nil` และลบ intent/bridge ที่เคยจบทริป. Recovery ใช้ validity/phase ของ trip snapshot โดยไม่ตีความว่า alarm ที่ถูกปิดเท่ากับทริปจบ. `plutil -lint` ผ่านสำหรับ English strings; Release app bundle มี `"NapNav ใกล้ถึงจุดหมาย" = "Almost there"`. `source-files.sha256` ของ full test กับ Release build เทียบด้วย `cmp -s` แล้วตรงกัน; `shasum -a 256 -c` กับ source ปัจจุบันผ่าน exit 0. Fingerprint สุดท้ายทั้งคู่ `cb18b5637686d72e152045a4f536facb0fe71ff281f1b93418bfe08d9717a2c1`
- **Build:** `NAPNAV_DERIVED_DATA=/tmp/NapNav-A3AlarmDismiss-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A3AlarmDismiss-results Scripts/phase-a0.sh release-build` ได้ `BUILD SUCCEEDED`, exit 0 แบบ unsigned generic iOS บน source สุดท้าย; artifacts `/tmp/NapNav-A3AlarmDismiss-results/20260925-213921-release-build/build.xcresult`, `xcodebuild.log`, `source-files.sha256`, `source-manifest.sha256`. รอบ `/tmp/NapNav-A3AlarmDismiss-results/20260925-213107-release-build/` เป็นผลก่อนแก้ recovery เท่านั้น
- **Simulator/GPX:** targeted notification/TripStore 22/22 ของ source รอบแรกที่ `/tmp/NapNav-A3AlarmDismiss-targeted-elevated-20260925.xcresult`; หลังแก้ recovery targeted 26/26 ที่ `/tmp/NapNav-A3AlarmDismiss-recovery-targeted-20260925.xcresult` และ full suite บน source สุดท้ายผ่าน 116/116 ใน 12 suites รวม GPX, 0 failed/0 skipped บน iPhone 18 Pro iOS 27.0 Simulator; summary `/tmp/NapNav-A3AlarmDismiss-results/20260925-213848-full/summary.json` และ `tests.xcresult` ใน directory เดียวกัน
- **iPhone จริง:** `xcrun devicectl list devices` ใน sandbox จบ exit 1 เพราะ CoreDeviceService initialize ไม่ทัน; รันใน context ที่เข้าถึง CoreDevice ได้พบ iPhone 17 เชื่อมต่ออยู่ และ `xcrun devicectl device info apps --device 00008150-00023D6E1E98401C` พบ NapNav `com.example.StopAlarm` รุ่น 0.1.0 บนเครื่อง. ยังไม่ได้ติดตั้ง build ใหม่นี้ทับแอปที่ใช้อยู่หรือกด X เพื่อยืนยันว่าเสียงหยุดแต่แผนที่/ตำแหน่งยังทำงานจนถึงจุดหมาย; ยังไม่ได้ดูภาพ English title หลังย่อข้อความ
- **ความเสี่ยง/สิ่งค้าง:** ปุ่มของระบบ AlarmKit และการหยุดเสียงจริงต้องยืนยันบน iPhone; Simulator/unit tests พิสูจน์ได้เฉพาะ app state และ build. A3 slices 2–4 และ S1 device verification ยังค้างตามแผนเดิม
- **งานถัดไป:** เมื่อติดตั้ง build ใหม่บน iPhone ในช่วงที่ไม่มีทริปกำลังทำงาน ให้เริ่มทริปและรอ AlarmKit เตือน จากนั้นกด X ตรวจว่าเสียงหยุด แต่ทริป/Live Activity/GPS ยังอยู่จนถึง arrival; ปิดและเปิดแอปใหม่ระหว่างทางเพื่อยืนยัน recovery และตรวจ English title หลังย่อข้อความ แล้วบันทึกผลในรายการนี้

## 2026-09-25 17:34 — A3 slice 1: permission recovery และ localization

- **สถานะ:** ผ่านสำหรับ A3 slice 1 ในระดับ source/static, automated Simulator tests และ unsigned Release build; ยังไม่ใช่การปิด A3 ทั้ง phase. S1 ยังรอ manual verification บน iPhone
- **เป้าหมาย:** ทำให้ permission detail และข้อความ privacy ใช้ภาษาไทย/อังกฤษตามที่เลือก, refresh สถานะเมื่อกลับจาก iPhone Settings, อัปเดตปุ่ม action ของ Notification หลังเปลี่ยนภาษา และอธิบาย Time Sensitive ว่าจัดการจาก Settings ของ iPhone
- **Baseline:** source fingerprint ปัจจุบัน `9c81e1dd2434f6d72b79b053a379abf8bc7172bd076d21f7593c7a25ebdb37d9` คำนวณด้วย source manifest procedure ใน `Scripts/phase-a0.sh`; Xcode 27.0 (27A266a); `git status --short` แสดง project files เป็น untracked ตั้งแต่ก่อนเริ่ม. A2.3 fingerprint เก่า `d661bde...` ยังไม่ใช้ยืนยัน checkout ปัจจุบัน
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/AlertSettingsView.swift`, `StopAlarm/DestinationSelection.swift`, `StopAlarm/PlaceSearchService.swift`, `StopAlarm/SystemClients.swift`, `StopAlarm/DomainModels.swift` (เฉพาะเพื่อแยก enabled/disabled/not-supported), `StopAlarm/en.lproj/Localizable.strings`, `StopAlarm/th.lproj/Localizable.strings`, localized `InfoPlist.strings` สองภาษา, `StopAlarm.xcodeproj/project.pbxproj`, `StopAlarmTests/LocalizationTests.swift`, tests ที่เกี่ยวข้อง, remediation plan, Luna ticket และรายงานนี้
- **การเปลี่ยนแปลง (อัปเดต 2026-09-25 17:53 +07:00):** เพิ่ม `NotificationSettingState` เพื่อแสดง `.notSupported` แยกจาก `.disabled`; permission detail แปลหัวข้อ/สถานะไทย–อังกฤษ และแสดงคำแนะนำตามจริง—สถานะที่จัดการได้ให้ไป iPhone Settings, แต่ `.notSupported` ไม่ชวนให้หาสวิตช์ที่ไม่มี; Alert Settings refresh readiness เมื่อ scene กลับ `.active`; notification action category สร้างตามภาษาและลงทะเบียนซ้ำเมื่อเลือกภาษาใหม่; เพิ่ม `InfoPlist.strings` en/th พร้อม copy ตำแหน่งและ AlarmKit ที่ไม่พูดถึง testing; search results แยก loading/empty/failure, แสดง error แม้ยังมี suggestion และมี retry. ไม่เพิ่ม onboarding ใหม่ เพราะ flow ขอ location ตอนเริ่มทริปและ recovery/resume/discard มีอยู่แล้ว
- **ไฟล์ที่เปลี่ยนแล้ว:** `StopAlarm/AlertSettingsView.swift`, `StopAlarm/DestinationSelection.swift`, `StopAlarm/PlaceSearchService.swift`, `StopAlarm/SystemClients.swift`, `StopAlarm/DomainModels.swift`, `StopAlarm/Info.plist`, `StopAlarm/en.lproj/Localizable.strings`, `StopAlarm/th.lproj/Localizable.strings`, `StopAlarm/en.lproj/InfoPlist.strings`, `StopAlarm/th.lproj/InfoPlist.strings`, `StopAlarm.xcodeproj/project.pbxproj`, `StopAlarmTests/AlertSettingsTests.swift`, `StopAlarmTests/LocalizationTests.swift`, `StopAlarmTests/DestinationSelectionTests.swift`, `StopAlarmTests/TripStoreTests.swift`, `StopAlarmTests/LiveActivityTests.swift`, `StopAlarmTests/StartupRecoveryTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md` และ `docs/DEVELOPMENT_REPORT.md`
- **หลักฐาน source/static (อัปเดต 2026-09-25 17:55 +07:00):** `plutil -lint` ผ่าน 6/6 สำหรับ Info.plist, InfoPlist.strings ไทย/อังกฤษ, Localizable.strings ไทย/อังกฤษ และ project file; `comm -3` ของ key ไทย/อังกฤษไม่มีรายการต่าง และตรวจ duplicate keys แล้วไม่พบ. Built app มี localized `InfoPlist.strings` ทั้ง `en.lproj` และ `th.lproj`; ตรวจค่า privacy copy ที่คอมไพล์ลง app แล้ว. Baseline app bundle ก่อนแก้ยืนยันว่า `NSAlarmKitUsageDescription` เดิมยังเป็น “เพื่อทดสอบ”. Source fingerprint คือ `78873af69af8de03878c7b4cbc8c2463d51ede7de256b4496965c9cfb5ca709e`
- **สิ่งที่ตรวจพบก่อนแก้:** Permission details มีหัวข้อ literal ภาษาอังกฤษและ Time Sensitive ยังเป็นอังกฤษใน resource ไทย; `NSAlarmKitUsageDescription` ใช้คำว่า “เพื่อทดสอบ”; notification action categories ลงทะเบียนตอน launch ครั้งเดียว; Alert Settings refresh readiness เฉพาะตอนแสดงหน้า ไม่ refresh ตอนกลับจาก Settings; error ของ MapKit search ถูกซ่อนใน search-results branch และแทนด้วยหน้าว่าง “ไม่พบผลลัพธ์”. Startup มีหน้า recovery/error ที่กู้คืน/ลองใหม่/ทิ้งทริปได้อยู่แล้ว และขอ location ตอนผู้ใช้กดเริ่มทริป จึงยังไม่เพิ่ม onboarding แยกที่อาจซ้ำกับ system prompt. Apple API ปัจจุบันให้ `timeSensitiveSetting` เป็นค่าที่อ่านได้อย่างเดียว และ authorization option เก่าถูก deprecated; จะไม่เพิ่ม toggle/entitlement โดยไม่มีสิทธิ์หรือ product decision
- **หลักฐานทดสอบ:** restricted baseline จบ exit 70 ก่อนเริ่ม tests เพราะ CoreSimulatorService `Connection refused` และหา iPhone 18 Pro iOS 27.0 destination ไม่พบ (`/tmp/NapNav-A3-baseline-20260925.xcresult`). Baseline targeted ผ่าน 33/33 บน iPhone 18 Pro / iOS 27.0 Simulator; summary `/tmp/NapNav-A3-baseline-elevated-20260925.xcresult`. หลังแก้และรวม conditional `.notSupported` copy, focused `LocalizationTests` + `AlertSettingsTests` + `DestinationSelectionTests` ผ่าน 41/41, 0 failed/0 skipped; summary `/tmp/NapNav-A3-focused-final-20260925.xcresult`. Full suite คำสั่ง `NAPNAV_DESTINATION='platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' NAPNAV_DERIVED_DATA=/tmp/NapNav-A3-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A3-results Scripts/phase-a0.sh test-full` ผ่าน exit 0, 116/116, 0 failed/0 skipped, 12 suites บน iPhone 18 Pro / iOS 27.0 Simulator; artifacts `/tmp/NapNav-A3-results/20260925-175518-full/summary.json`, `tests.xcresult`, `xcodebuild.log`, `source-files.sha256`, `source-manifest.sha256`. Unsigned generic iOS Release build คำสั่ง `NAPNAV_DERIVED_DATA=/tmp/NapNav-A3-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A3-results Scripts/phase-a0.sh release-build` จบ `BUILD SUCCEEDED`, exit 0; artifacts `/tmp/NapNav-A3-results/20260925-175616-release-build/build.xcresult`, `xcodebuild.log`, `source-files.sha256`, `source-manifest.sha256`. Full-test และ Release-build มีรายการ `source-files.sha256` ตรงกัน และ fingerprint เดียวกัน `78873af69af8de03878c7b4cbc8c2463d51ede7de256b4496965c9cfb5ca709e`
- **บันทึกผล (อัปเดต 2026-09-25 18:01 +07:00):** อัปเดตสถานะ slice 1 หลังยืนยัน full test และ Release build ใช้ source manifest เดียวกัน; เพิ่มความคืบหน้าและขอบเขตที่ยังไม่พิสูจน์ไว้ใน `docs/NAPNAV_REMEDIATION_PLAN.md` กับ `docs/LUNA_CODE_FIX_TICKETS.md`. ไม่แก้ source หลัง fingerprint ที่ทดสอบ
- **ขอบเขตหลักฐาน:** มี source/static checks, focused/full Simulator tests และ unsigned Release build; ตรวจ localized privacy strings ใน Debug และ Release app bundles แล้ว. ยังไม่มี visual screenshot review, VoiceOver audition หรือ physical-iPhone verification; automated/UI build ไม่ยืนยันพฤติกรรมเสียง, Silent/Focus, locked screen หรือ background. Time Sensitive เปิด/ปิดหรือรองรับได้ขึ้นกับสิทธิ์และ Settings ของ iOS; S1 ยังต้องแตะ Live Activity และเรียก URL จากแอปอื่นบน iPhone ตามรายการก่อนหน้า
- **ความเสี่ยง/สิ่งค้าง:** A3 slices 2–4 (Dynamic Type/VoiceOver, Reduce Motion, Light/Dark/maps/Liquid Glass) ยังไม่เริ่ม; S1 device verification ยังค้างแยกต่างหาก. บัคที่ผู้ใช้รายงานว่า English typography บน AlarmKit alert เล็กกว่าไทยยังไม่ถูก reproduce หรือแก้: code ส่ง localized title/button ให้ `AlarmPresentation.Alert` แต่ยังไม่มีภาพ/ผลบน iPhone เพื่อระบุว่าแก้ได้จาก app หรือมาจาก system UI
- **งานถัดไป:** ทำ A3 slice 2: Dynamic Type และ VoiceOver ของ map controls, radius, active trip และ Stop; คง A3 slices 3–4 และ S1 manual iPhone verification ไว้เปิด

## 2026-09-25 09:13 — Security S1: ยกเลิก URL สาธารณะแบบหยุดทริปทันที

- **สถานะ:** กำลังทำ — automated checks ผ่าน; รอ manual verification บน iPhone ตาม ticket
- **เป้าหมาย:** parse เฉพาะ NapNav deep link ที่รองรับ; URL หยุด/จบทริปต้องเปิด confirmation และจะเปลี่ยนสถานะได้หลังผู้ใช้ยืนยันเท่านั้น. รักษาการกด Stop/Finish จาก Live Activity แต่ให้ผ่าน confirmation เดียวกัน
- **Baseline:** `NapNavApp.onOpenURL` ใน `StopAlarm/StopAlarmApp.swift` หยุดหรือจบทริปทันทีตาม `store.phase`; Live Activity Stop/Finish ใช้ `napnav://stop-trip`; confirmation sheet ปัจจุบันถูกถือ state ใน `DestinationView`; ยังไม่มี regression test สำหรับ URL parser/flow. A2.3 report อ้าง fingerprint `d661bde929f6b7bab9f1922d939f3104f913ddead4dc4ae7274b7b16b65317d3` แต่ยังไม่ได้ยืนยันกับ snapshot ปัจจุบัน
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/StopAlarmApp.swift`, `StopAlarm/RootView.swift`, `StopAlarm/DestinationSelection.swift`, `StopAlarm/DomainModels.swift`, `StopAlarm/TripStore.swift`, Thai/English `Localizable.strings`, `StopAlarmTests/TripStoreTests.swift`, `StopAlarmTests/StartupRecoveryTests.swift`, `StopAlarmTests/LocalizationTests.swift` และรายงานนี้
- **การเปลี่ยนแปลง (อัปเดต 2026-09-25 09:20 +07:00):** ย้าย URL handling มาที่ RootView และ parse เฉพาะ `napnav://trip` กับ `napnav://stop-trip` แบบไม่มี path/query/fragment/userinfo/port; URL stop ที่มาระหว่าง launch จะคิวไว้จน restore เสร็จ. เพิ่ม confirmation request ผูกกับ trip UUID; ปุ่มยกเลิก sheet ไม่เรียก mutation; confirm ตรวจ ID/action ก่อน stop/finish และรองรับ pending recovery snapshot โดยต้องยืนยันก่อน discard. Live Activity ใช้ URL เดิมและเข้าหน้ายืนยันเดียวกัน; เพิ่ม copy ไทย/อังกฤษสำหรับ Finish
- **หลักฐานทดสอบ (อัปเดต 2026-09-25 09:30 +07:00):** restricted `xcrun simctl list devices available` exit 1 เพราะ CoreSimulatorService `Connection refused`; restricted targeted `xcodebuild test` หา destination ไม่พบ (exit 70). Restricted `build-for-testing` exit 65 ด้วย `sandbox_apply: Operation not permitted`/Swift macro plugin malformed response (`/tmp/NapNav-S1-build-for-testing-20260925.log`). Elevated targeted รอบแรกพบ compile error จาก implicit `switch` return ใน `NapNavDeepLink.route` (exit 65; `.xcresult` `/tmp/NapNav-S1-targeted-elevated-20260925.xcresult`); เพิ่ม explicit returns แล้ว rerun ผ่าน exit 0, 52 tests/3 suites (`/tmp/NapNav-S1-targeted-retry-20260925.log`, `.xcresult` `/tmp/NapNav-S1-targeted-retry-20260925.xcresult`). Suite S1 ที่ตัวกรองตามไฟล์ไม่รวมถูกรันแยกผ่าน 5/5 (`/tmp/NapNav-S1-deeplink-retry-20260925.log`, `.xcresult` `/tmp/NapNav-S1-deeplink-retry-20260925.xcresult`). Full test ผ่าน exit 0, 112/112 ใน 12 suites รวม GPX บน iPhone 18 Pro / iOS 27.0 Simulator (`/tmp/NapNav-S1-full-20260925.log`, `.xcresult` `/tmp/NapNav-S1-full-20260925.xcresult`). Unsigned generic iOS Release build ผ่าน exit 0, `BUILD SUCCEEDED` (`/tmp/NapNav-S1-release-build-20260925.log`, `.xcresult` `/tmp/NapNav-S1-release-build-20260925.xcresult`); Xcode 27.0 (27A266a)
- **คำสั่งที่ผ่าน:** targeted `xcodebuild ... -only-testing:StopAlarmTests/TripStoreTests -only-testing:StopAlarmTests/StartupRecoveryTests -only-testing:StopAlarmTests/LocalizationTests CODE_SIGNING_ALLOWED=NO test` และ suite S1 `xcodebuild ... -only-testing:StopAlarmTests/PublicStopLinkTests CODE_SIGNING_ALLOWED=NO test`; full `xcodebuild -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -derivedDataPath /tmp/NapNav-S1-Elevated-DerivedData -resultBundlePath /tmp/NapNav-S1-full-20260925.xcresult -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO test`; Release `xcodebuild -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'generic/platform=iOS' -configuration Release -derivedDataPath /tmp/NapNav-S1-Elevated-DerivedData -resultBundlePath /tmp/NapNav-S1-release-build-20260925.xcresult CODE_SIGNING_ALLOWED=NO build`
- **Source/static:** URL parser แยก route ก่อน state mutation; confirmation request เก็บ UUID ของทริปและ action ณ เวลาขอ; confirm ตรวจ UUID/phase/action ซ้ำ จึงไม่ใช้ URL เป็น caller identity และ request เก่าหยุดทริปใหม่ไม่ได้
- **Build:** unsigned generic iOS Release, `BUILD SUCCEEDED`, exit 0; `/tmp/NapNav-S1-release-build-20260925.log` และ `.xcresult` `/tmp/NapNav-S1-release-build-20260925.xcresult`
- **Simulator/GPX:** targeted 57 tests รวมชุด S1 5/5, recovery/localization 52/52; full suite 112/112, 12 suites, 0 failures
- **iPhone จริง:** ยังไม่ได้ยืนยันแตะ Live Activity Stop/Finish หรือเปิด `napnav://stop-trip` จากแอปอื่นบน iPhone; เป็นหลักฐาน manual ที่ ticket S1 กำหนด
- **ความเสี่ยง/สิ่งค้าง:** ต้องคงการยืนยันตัวทริปเดิมก่อน commit stop/finish และรองรับ URL ที่มาถึงระหว่าง cold launch/recovery; การแตะ Live Activity จริงและการเรียก URL จากแอปอื่นต้องตรวจบน iPhone เพราะ unit test ยืนยัน cross-app dispatch ไม่ได้
- **งานถัดไป:** บน iPhone จริง แตะ Live Activity Stop/Finish แล้วตรวจว่าเปิด confirmation, ยกเลิกแล้วทริปยังอยู่, ยืนยันแล้วจบทริปเดิมหนึ่งครั้ง; ทดสอบเปิด `napnav://stop-trip` จากแอปอื่นและกรณี cold launch/recovery. บันทึกผลแล้วจึงปิด S1 และกลับไปทำ A3

## 2026-09-25 07:59 — A3: เตรียมแก้สิทธิ์และ localization (พักก่อนแก้ source)

- **สถานะ:** กำลังทำ — ผู้ใช้ขอพักงานก่อนเริ่มแก้ source; รอบถัดไปให้ทำ S1 ก่อน
- **เป้าหมาย:** แก้ slice แรกของ A3 เรื่องคำอธิบาย/สถานะสิทธิ์และภาษาไทย–อังกฤษ พร้อม regression tests โดยไม่เปลี่ยน product decision หรือ signing
- **Baseline:** อ่านแผนและรายงานก่อนเริ่ม ตรวจ source ที่เกี่ยวข้องใน `StopAlarm/StopAlarmApp.swift`, `StopAlarm/AlertSettingsView.swift`, `StopAlarm/SystemClients.swift`, `StopAlarm/Info.plist`, localization resources และ project file แล้ว; รายงาน A2.3 เดิมอ้าง fingerprint `d661bde929f6b7bab9f1922d939f3104f913ddead4dc4ae7274b7b16b65317d3` แต่ยังไม่ได้ยืนยัน fingerprint ของ snapshot สำหรับ A3 รอบนี้
- **ไฟล์ที่คาดว่าจะเปลี่ยนเมื่อกลับมาทำ A3:** `StopAlarm/StopAlarmApp.swift`, `StopAlarm/AlertSettingsView.swift`, `StopAlarm/SystemClients.swift`, `StopAlarm/Info.plist`, localized `InfoPlist.strings`/`Localizable.strings`, `StopAlarm.xcodeproj/project.pbxproj`, tests localization/notification และรายงานนี้
- **การเปลี่ยนแปลง:** ไม่มีการแก้ source หรือ tests ในรอบนี้; บันทึกสถานะพักตามคำขอเท่านั้น. ยังไม่ได้แก้ entitlement/signing
- **หลักฐานทดสอบ:** ไม่มีการรันทดสอบหรือ build; ตรวจ source แบบอ่านอย่างเดียวเพื่อเตรียมขอบเขต
- **ความเสี่ยง/สิ่งค้าง:** S1 ยังเปิดตามแผน; ความพร้อมจริงของ Time Sensitive entitlement และหน้าจอระบบยังไม่ยืนยัน. A3 ส่วน Dynamic Type, VoiceOver, Reduce Motion และ Light/Dark ยังไม่ตรวจ/แก้
- **งานถัดไป:** S1 เริ่มในรายการด้านบน; กลับมาทำ A3 slice นี้หลังผ่าน S1

## 2026-09-25 02:57 — A2.3: Auto-Stop ตาม deadline และ startup แบบไม่หน่วงเมื่อพร้อมเร็ว

- **สถานะ:** ผ่านสำหรับ A2.3 และ automated A2-R gate — targeted 44/44, full suite 3 รอบ 105/105 ต่อรอบ, unsigned Release build `BUILD SUCCEEDED`; ทุก artifact ใช้ source fingerprint เดียวกัน `d661bde929f6b7bab9f1922d939f3104f913ddead4dc4ae7274b7b16b65317d3`. ยังไม่ปิด A4/device gate
- **เป้าหมาย:** ห้าม background-task expiration จบทริปก่อน absolute deadline; reconcile เมื่อแอปกลับ active/restore; ทดสอบเวลาและการ cancel แบบ deterministic. ตั้งค่า production startup เป็น `fastIfPossible`: ถ้าเตรียมพร้อมเร็วให้เข้าหน้าหลักทันที ถ้าช้าจึงค่อยแสดง loading
- **Baseline:** A2.2 source/test fingerprint `b9b155de2bc3fca9a9addde564e642346a95ce6d070a804f3e5284f53d936551`; ตรวจ `/tmp/NapNav-A2-2-results/20260923-130010-full/source-files.sha256` กับ checkout ปัจจุบันแล้วทุกไฟล์ตรง. A2.2 targeted 48/48, full Simulator 103/103 หนึ่งรอบ และ unsigned Release build ผ่านตาม entry ด้านล่าง
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/TripStore.swift`, `StopAlarm/RootView.swift`, tests ใน `StopAlarmTests/TripStoreTests.swift` และ `StopAlarmTests/StartupRecoveryTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md` และรายงานนี้
- **ตรวจ environment ก่อนแก้:** `xcrun simctl list devices available` ใน restricted execution ล้มเหลวด้วย `CoreSimulatorService connection became invalid` / `Connection refused`; ยังไม่ใช่ผล test หรือ source failure. จะลอง Xcode/Simulator ใน execution context ที่เข้าถึง CoreSimulator ได้ก่อน full-suite gate
- **ไฟล์ที่เปลี่ยนแล้ว:** `StopAlarm/TripStore.swift`, `StopAlarm/RootView.swift`, `StopAlarmTests/TripStoreTests.swift`, `StopAlarmTests/StartupRecoveryTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md`, `docs/DEVELOPMENT_REPORT.md`
- **การเปลี่ยนแปลง:** เพิ่ม `TripClock` และ background-task seam; timer ตรวจ `clock.now` กับ absolute deadline, ยืนยัน trip ID/generation/schedule ID ก่อนจบ และเมื่อ expiration เกิดขึ้นจะคืน background grant อย่างเดียว. เพิ่ม foreground scene-phase reconciliation และใช้ deadline เดิมตอน restore. Production startup resolver เปลี่ยน fallback จาก `alwaysShow` เป็น `fastIfPossible`; test/developer override ยังใช้ `alwaysShow`/`simulateSlow` ได้. เพิ่ม tests สำหรับ timer จริงด้วย manual clock, 59 วินาที, deadline, expiration, restore, Stop และ timer ทริปเก่ากับทริปใหม่. หลัง targeted retry พบว่า timer task ทำงานแบบ async หลัง manual clock advance แต่ tests ตรวจ state ก่อน event จบ; เพิ่ม event waiters ให้ test รอ Live Activity end/persistence clear อย่างชัดเจนก่อน assertions
- **หลักฐานทดสอบ:** ก่อนแก้ source manifest A2.2 ทุกไฟล์ตรงกับ checkout. `xcrun simctl list devices available` ใน restricted execution จบด้วย CoreSimulatorService `Connection refused`. Targeted รอบแรก exit 65 ก่อนเริ่ม tests เพราะ `StartupRecoveryTests.swift:686` กำหนด `Confirmation` ตรงให้ `@MainActor @Sendable () -> Void`; log `/tmp/NapNav-A2-3-targeted-20260925.log`, result bundle `/tmp/NapNav-A2-3-targeted-20260925.xcresult`. Targeted retry compile ผ่านและ runner รายงาน 44 tests/2 suites, 8 issues ใน assertions ที่ตรวจ auto-stop หลัง deadline โดยไม่มี await สำหรับ completion; assertions ก่อน deadline, expiration ไม่จบก่อนกำหนด, และ Stop/new-trip guard ผ่าน. เพิ่ม event waiters ใน tests แล้ว. Rerun คำสั่ง `xcodebuild -quiet -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -derivedDataPath /tmp/NapNav-A2-3-DerivedData -resultBundlePath /tmp/NapNav-A2-3-targeted-synced-20260925.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/TripStoreTests -only-testing:StopAlarmTests/StartupRecoveryTests CODE_SIGNING_ALLOWED=NO test` ผ่าน exit 0; xcresult summary ยืนยัน 44 ผ่าน, 0 failed, 0 skipped. Log `/tmp/NapNav-A2-3-targeted-synced-20260925.log`, `.xcresult` `/tmp/NapNav-A2-3-targeted-synced-20260925.xcresult`. Full suiteทั้ง 3 รอบใช้ `NAPNAV_DESTINATION='platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' NAPNAV_DERIVED_DATA=/tmp/NapNav-A2-3-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A2-3-results Scripts/phase-a0.sh test-full`, แยก artifact directoriesและรันต่อกันโดยไม่มี code/source edit ระหว่างรอบ; ทุกครั้ง exit 0, 105 passed, 0 failed/skipped. Fingerprint ทั้งสามรอบตรงกัน `d661bde929f6b7bab9f1922d939f3104f913ddead4dc4ae7274b7b16b65317d3`. Artifacts รอบ 1 `/tmp/NapNav-A2-3-results/20260925-032228-full/`, รอบ 2 `/tmp/NapNav-A2-3-results/20260925-032326-full/`, รอบ 3 `/tmp/NapNav-A2-3-results/20260925-032422-full/`; แต่ละ directory มี `summary.json`, `tests.xcresult`, `xcodebuild.log`, `source-manifest.sha256`. Unsigned generic iOS Release build คำสั่ง `NAPNAV_DERIVED_DATA=/tmp/NapNav-A2-3-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A2-3-results Scripts/phase-a0.sh release-build` exit 0, log มี `BUILD SUCCEEDED`, artifact `/tmp/NapNav-A2-3-results/20260925-032517-release-build/`; manifest ตรงกับ full tests ที่ fingerprint เดียวกัน. ผล run ก่อนหน้าที่ไม่ finalize ยุติหลัง `simctl diagnose --timeout=600`; ไม่นับเป็นผลผ่าน
- **Source/static:** ตรวจ source ของ deadline persistence/recovery, active-scene reconciliation, timer cancellation, background-grant expiration, trip ID/generation/schedule guards และ fast startup visibility; ไม่พบ issue เพิ่มใน scope นี้. ไม่ได้รัน static analyzer แยก
- **Build:** unsigned generic iOS Release, `BUILD SUCCEEDED`, exit 0; `/tmp/NapNav-A2-3-results/20260925-032517-release-build/` (`xcodebuild.log`, `build.xcresult`, manifest)
- **Simulator/GPX:** targeted 44/44; full suite รวม GPX routes 105/105 ในแต่ละ 3 รอบต่อเนื่อง บน iPhone 18 Pro / iOS 27.0 Simulator. Test/build manifests ตรงกันที่ fingerprint `d661bde929f6b7bab9f1922d939f3104f913ddead4dc4ae7274b7b16b65317d3`
- **iPhone จริง:** ยังไม่ได้ยืนยันเสียง, AlarmKit, Silent/Focus, locked screen หรือ Auto-Stop ขณะ process ถูกพัก/ยุติ; เป็น A4/device gate
- **หลักฐาน baseline:** artifacts เดิม `/tmp/NapNav-A2-2-results/20260923-130010-full/` และ `/tmp/NapNav-A2-2-results/20260923-130234-release-build/`
- **ความเสี่ยง/สิ่งค้าง:** process ที่ iOS พักหรือยุติอาจทำงานต่อหลัง deadline; รับประกันได้ว่าไม่จบก่อนกำหนดและ reconcile เมื่อกลับมาทำงานได้ แต่ยังห้ามสัญญาว่าจะจบตรงเวลาโดยไม่มีผลบนเครื่องจริง. การยืนยัน AlarmKit/เสียง/locked screen ยังเป็น physical-device gate
- **งานถัดไป:** A2-R automated gate ปิดแล้ว; ขั้นถัดไปตามแผนคือ Security gate S1 (URL stop confirmation), จากนั้น A3 และ A4. การทดสอบ AlarmKit/เสียง/locked screen บน iPhone จริงยังเป็นข้อกำหนดก่อน release

## 2026-09-23 12:28 — A2.2: ทำผลยกเลิก alert ให้ตรวจสอบและกู้คืนได้

- **สถานะ:** ผ่านสำหรับ A2.2 automated gate ณ 2026-09-23 13:07 +07:00; ในเวลานั้น A2-R ยังรอ A2.3/three-run gate. Automated A2-R ปิดภายหลัง 25 ก.ย. 2026; device gate สำหรับ AlarmKit ยังเปิด
- **เป้าหมาย:** คืนผล cancellation ที่แยก notification cleanup กับ AlarmKit success/failure; เก็บ AlarmKit ID ที่ยกเลิกไม่สำเร็จไว้ลองใหม่เมื่อเปิดแอป และให้ Stop/Complete/Notification action/AlarmKit intent/discard ใช้สัญญา cleanup เดียวกัน
- **Baseline:** A2.1 ผ่าน automated gate บน fingerprint `6232d8f96775bbf82bf71a531a5a59aeb8cf5dc23280091b3a59ceda34b38a83` (StartupRecovery 21/21, TripStore 13/13, full Simulator 95/95 และ unsigned generic iOS Release build ผ่าน; ดูรายการ A2.1 ด้านล่าง). ตรวจ fingerprint ปัจจุบันตามวิธี `Scripts/phase-a0.sh` ได้ตรงกับ `6232d8f96775bbf82bf71a531a5a59aeb8cf5dc23280091b3a59ceda34b38a83`; Xcode 27.0 (27A266a). Git ยังแสดงไฟล์ repo เป็น untracked
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/SystemClients.swift`, `StopAlarm/TripStore.swift`, `StopAlarm/DomainModels.swift`, `StopAlarm/RootView.swift`, `StopAlarm/th.lproj/Localizable.strings`, `StopAlarm/en.lproj/Localizable.strings`, tests/mocks ใน `StopAlarmTests/TripStoreTests.swift`, `StartupRecoveryTests.swift`, `AlertSettingsTests.swift`, `LiveActivityTests.swift`, `LocalizationTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md` และรายงานนี้
- **Baseline defect ที่ยืนยันจาก source:** `AlarmDelivering.cancelTripAlerts` คืน `Void` และมี default no-op; `LocalAlarmDelivery` กลืน error จาก `AlarmManager.cancel(id:)` แล้วล้าง `prominentAlarmID`; `cancelAllTripAlerts` ก็กลืนความล้มเหลวและล้าง ID; cleanup ถูกเรียกจากหลาย lifecycle path โดย caller ตรวจผลไม่ได้
- **ไฟล์ที่เปลี่ยนแล้ว:** `StopAlarm/DomainModels.swift`, `StopAlarm/SystemClients.swift`, `StopAlarm/TripStore.swift`, `StopAlarm/RootView.swift`, `StopAlarm/th.lproj/Localizable.strings`, `StopAlarm/en.lproj/Localizable.strings`, `StopAlarmTests/TripStoreTests.swift`, `StopAlarmTests/StartupRecoveryTests.swift`, `StopAlarmTests/AlertSettingsTests.swift`, `StopAlarmTests/LiveActivityTests.swift`, `StopAlarmTests/LocalizationTests.swift`
- **การเปลี่ยนแปลง:** เพิ่ม `AlertCancellationResult` แยก notification cleanup, AlarmKit cancellation outcome และ enumeration failure; ปรับ `AlarmDelivering` ให้ cancellation/reconciliation คืนผลโดยไม่มี default no-op; เพิ่ม pending-ID queue ที่ persist ใน `LocalAlarmDelivery` และ full-reconciliation marker สำหรับกรณี enumerate AlarmKit ไม่สำเร็จ. TripStore บันทึก cleanup failure ลง health/คำเตือนที่แสดงใน UI, reconcile ระหว่างเปิดแอป, และใช้ผลลัพธ์เดียวกันใน Stop/Complete/Notification action/AlarmKit intent/Live Activity URL/discard. จำกัด fallback จาก trip ID ตาม AlarmKit support เพื่อไม่สร้าง false pending ID บน iOS 18–25; ID ที่ระบุชัดแต่ยัง unsupported จะคงอยู่ให้กู้คืนได้. Source review ยืนยันเส้นทางเหล่านี้ผ่าน typed cancellation contract เดียวกัน และไม่มี `try?` กลืน AlarmKit cancellation. เพิ่ม tests สำหรับ fail→health warning→retry, สร้าง client ใหม่, launch/discard retry, successful mock cleanup, localization และ full-enumeration retry
- **หลักฐานทดสอบ:** รอบ targeted แรกใช้ `xcodebuild -quiet -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -derivedDataPath /tmp/NapNav-A2-2-DerivedData -resultBundlePath /tmp/NapNav-A2-2-red-tripstore.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/TripStoreTests CODE_SIGNING_ALLOWED=NO test`; exit 0. `xcresulttool get test-results summary` ยืนยัน Passed 15/15, failed 0, skipped 0 บน iPhone 18 Pro / iOS 27.0 Simulator. `.xcresult`: `/tmp/NapNav-A2-2-red-tripstore.xcresult`. Fingerprint source/test snapshot รอบนั้น `0fc34abd6efb1fa08d143c154f693f6124506da4cb50d04a3cd42b37c6dc6a58`; stdout ไม่ได้เก็บเป็นไฟล์แยก
- **หลักฐานทดสอบ targeted ล่าสุด:** `xcodebuild -quiet -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -derivedDataPath /tmp/NapNav-A2-2-DerivedData -resultBundlePath /tmp/NapNav-A2-2-targeted-20260923.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/TripStoreTests -only-testing:StopAlarmTests/StartupRecoveryTests -only-testing:StopAlarmTests/LocalizationTests -only-testing:StopAlarmTests/LiveActivityTests CODE_SIGNING_ALLOWED=NO test` exit 0; `xcresulttool get test-results summary` ยืนยัน Passed 46/46, failed 0, skipped 0 บน iPhone 18 Pro / iOS 27.0 Simulator. `.xcresult`: `/tmp/NapNav-A2-2-targeted-20260923.xcresult`. Source/test fingerprint ขณะรอบนี้ `e6ee8f71c6b51d2bc8e460f4b414e28aa5eb9f0cdd6ef2a4fe279daada53b0f9`; stdout ไม่ได้เก็บเป็นไฟล์แยก
- **หลักฐาน targeted บน snapshot ล่าสุด:** `xcodebuild -quiet -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -derivedDataPath /tmp/NapNav-A2-2-DerivedData -resultBundlePath /tmp/NapNav-A2-2-results/final-targeted.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/TripStoreTests -only-testing:StopAlarmTests/StartupRecoveryTests -only-testing:StopAlarmTests/LocalizationTests -only-testing:StopAlarmTests/LiveActivityTests CODE_SIGNING_ALLOWED=NO test` exit 0; summary Passed 48/48, 0 failed/0 skipped on iPhone 18 Pro / iOS 27.0 Simulator. `.xcresult`: `/tmp/NapNav-A2-2-results/final-targeted.xcresult`; log `/tmp/NapNav-A2-2-results/final-targeted.log`; fingerprint `b9b155de2bc3fca9a9addde564e642346a95ce6d070a804f3e5284f53d936551`
- **หลักฐาน full Simulator:** `NAPNAV_DESTINATION='platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' NAPNAV_DERIVED_DATA=/tmp/NapNav-A2-2-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A2-2-results Scripts/phase-a0.sh test-full` exit 0; `summary.json` Passed 103/103, failed 0, skipped 0, 11 suites on iPhone 18 Pro / iOS 27.0. `.xcresult`: `/tmp/NapNav-A2-2-results/20260923-130010-full/tests.xcresult`; log/metadata/source manifest: `/tmp/NapNav-A2-2-results/20260923-130010-full/`. Manifest digest `b9b155de2bc3fca9a9addde564e642346a95ce6d070a804f3e5284f53d936551`, ตรงกับ fingerprint จาก targeted ล่าสุด
- **หลักฐาน Release build:** `NAPNAV_DERIVED_DATA=/tmp/NapNav-A2-2-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A2-2-results Scripts/phase-a0.sh release-build` exit 0, `BUILD SUCCEEDED`, unsigned generic iOS Release. Artifact/log/source manifest: `/tmp/NapNav-A2-2-results/20260923-130234-release-build/`. `cmp` ระหว่าง `source-files.sha256` ของ full tests และ build exit 0; manifest digest ทั้งคู่ `b9b155de2bc3fca9a9addde564e642346a95ce6d070a804f3e5284f53d936551`; recompute หลัง build ยังได้ค่าเดิม
- **ผลตามชั้นการยืนยัน:** source/static — cancellation result, pending-ID persistence/reconcile และ app/notification/AlarmKit intent/Live Activity/discard lifecycle paths ตรวจแล้ว; trailing-whitespace check สะอาด; build — unsigned generic iOS Release `BUILD SUCCEEDED`; Simulator/GPX — targeted 48/48 และ full 103/103 ผ่านบน fingerprint `b9b155de2bc3fca9a9addde564e642346a95ce6d070a804f3e5284f53d936551`; source manifest ของ full test กับ build ตรงกัน; iPhone จริง — ยังไม่ทดสอบ และยังเป็น A4 device gate สำหรับ native AlarmKit
- **ความเสี่ยง/สิ่งค้าง:** หาก AlarmKit cancellation ล้มเหลว alarm เดิมอาจยังดัง; ตอนนี้ ID ถูกเก็บไว้ retry และมีคำเตือน แต่ Simulator/mocks ไม่พิสูจน์พฤติกรรม AlarmKit จริง. Full suite บน snapshot นี้ผ่านหนึ่งรอบ ยังไม่ใช่ three-run gate สำหรับจบ A2-R. ยังไม่แก้ product decision, signing, push หรือ TestFlight
- **งานถัดไป:** ทำ A2.3 — absolute Auto-Stop deadline และ deterministic clock/scheduler tests; เมื่อ A2-R code ครบให้รัน full suite 3 รอบต่อเนื่องบน snapshot เดียวกัน จากนั้นคง iPhone จริงเป็น device gate ตาม A4

## 2026-09-23 11:35 — A2.1: ป้องกันผล async ของทริปเก่ากลับมาเขียน state

- **สถานะ:** ผ่านสำหรับ A2.1 automated gate ณ 2026-09-23 12:19 +07:00; A2-R ยังเปิดรอ A2.2/A2.3 และ three-run gate ท้าย phase
- **เป้าหมาย:** ป้องกันผลจาก send/authorization/snooze/recovery ที่กลับมาหลัง Stop, Complete, Discard หรือเริ่มทริปใหม่ ไม่ให้แก้ state ของทริปปัจจุบันหรือฟื้น snapshot ของทริปเก่า; รักษา backward decoding ของ snapshots
- **Baseline:** source fingerprint สุดท้ายที่ยืนยันจาก A1 คือ `629d9d13d84cb76385f2073f939a6f50ba6ade073f0b45463e697c0fb1f2e4f6`; targeted A1 39/39, full suite 88/88 สามรอบ และ unsigned Release build ผ่านตาม entry A1-D/A1.2 ด้านล่าง. ตรวจ source manifest A1 ก่อนแก้แล้วทุกไฟล์ `OK`
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/TripStore.swift`, `StopAlarm/SystemClients.swift`, `StopAlarm/StopAlarmApp.swift` เพื่อส่ง trip identity ของ Notification action; `StopAlarmTests/StartupRecoveryTests.swift`, `StopAlarmTests/TripStoreTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md` และรายงานนี้. `ActiveTripSnapshot` มี `id` อยู่แล้ว จึงไม่ต้องแก้ `DomainModels.swift`/`TripPersistence.swift`
- **การเปลี่ยนแปลง:** เพิ่ม regression tests ควบคุม async continuation ก่อน production edit: late arrival, late snooze, authorization/recovery await และ terminal snapshot; จากนั้นเพิ่ม lifecycle generation/active trip ID guard, per-trip alert in-flight state, scoped Notification/AlarmKit identifiers and cleanup, stale notification-action rejection, persistence guard และ terminal snapshot rejection
- **หลักฐานทดสอบ:** baseline A1 source manifest `/tmp/NapNav-A1-2-results/20260923-112214-full/source-files.sha256` ตรวจด้วย `shasum -a 256 -c` ได้ทุกไฟล์ `OK` ก่อนเพิ่ม tests. รอบแรก `/tmp/NapNav-A2-1-results/red-startup-20260923-1154.xcresult` หยุดก่อนเริ่ม tests เพราะ compile error ใน mock `StartupRecoveryTests.swift:840` (`call can throw but is not marked with 'try'`); แก้เป็น `try await`. รอบสอง `xcodebuild -quiet ... -only-testing:StopAlarmTests/StartupRecoveryTests ... test` ทำ test execution เสร็จ: test-runner log `/tmp/NapNav-A2-1-results/red-startup-20260923-1158.xcresult/Staging/1_Test/Diagnostics/StopAlarmTests-DF3D6071-3135-40E0-9BA4-7022344E31BE-Configuration-Test Scheme Action-Iteration-1/StopAlarmTests-03E3F37A-0398-43FF-924D-877A7474637F/StandardOutputAndStandardError.txt` ยืนยัน 21 tests / 20 issues. Tests จับ regression ทั้ง late alert (ผล success/failure เปลี่ยน store/snapshot ของทริปใหม่), start authorization หลัง Stop, snooze เก่าบันทึกลงทริปใหม่, resume เริ่ม location หลัง Stop และ cancelled/completed snapshot ถูกเสนอ recovery. Xcode ยังติด `simctl diagnose --timeout=600` หลัง worker จบ จึง `.xcresult` ยังไม่มี `Info.plist` และไม่มี summary ใช้อ้างผล; ใช้เฉพาะ test-runner log เป็นหลักฐาน red
- **หลักฐานทดสอบหลังแก้รอบแรก:** rerun `xcodebuild -quiet -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' -derivedDataPath /tmp/NapNav-A2-1-DerivedData -resultBundlePath /tmp/NapNav-A2-1-green-startup-20260923-1207.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/StartupRecoveryTests CODE_SIGNING_ALLOWED=NO test` exit 0; `xcresulttool get test-results summary` exit 0: Passed 21/21, 0 failed/0 skipped, iPhone 18 Pro / iOS 27.0 Simulator. Log `/tmp/NapNav-A2-1-results/green-startup-20260923-1207.log`; bundle `/tmp/NapNav-A2-1-green-startup-20260923-1207.xcresult`
- **หลักฐานทดสอบ targeted เพิ่มเติม:** `xcodebuild -quiet ... -only-testing:StopAlarmTests/TripStoreTests ... test` exit 0; xcresult `/tmp/NapNav-A2-1-green-tripstore-20260923-1213.xcresult` summary Passed 13/13, 0 failed/0 skipped, iPhone 18 Pro / iOS 27.0 Simulator; log `/tmp/NapNav-A2-1-results/green-tripstore-20260923-1213.log`
- **หลักฐาน full Simulator:** `NAPNAV_DESTINATION='platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' NAPNAV_DERIVED_DATA=/tmp/NapNav-A2-1-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A2-1-results Scripts/phase-a0.sh test-full` exit 0; `/tmp/NapNav-A2-1-results/20260923-121606-full/summary.json` Passed 95/95, 0 failed/0 skipped, 11 suites; `.xcresult` `/tmp/NapNav-A2-1-results/20260923-121606-full/tests.xcresult`; log/metadata/source manifest อยู่ directory เดียวกัน. Unsigned generic iOS Release build exit 0 (`BUILD SUCCEEDED`), artifacts `/tmp/NapNav-A2-1-results/20260923-121756-release-build/`. Full test และ build ใช้ source files manifest เดียวกัน digest `6232d8f96775bbf82bf71a531a5a59aeb8cf5dc23280091b3a59ceda34b38a83` (`cmp` exit 0); ตรวจ `shasum -a 256 -c` หลัง build ได้ `OK` ทุกไฟล์
- **ไฟล์ที่เปลี่ยน:** `StopAlarm/TripStore.swift`, `StopAlarm/SystemClients.swift`, `StopAlarm/StopAlarmApp.swift`, `StopAlarmTests/StartupRecoveryTests.swift`, `StopAlarmTests/TripStoreTests.swift` และเอกสารแผน/ticket/report นี้
- **ผลตามชั้นการยืนยัน:** source/static — lifecycle และ persistence invariants เพิ่มพร้อม regression coverage; build — unsigned generic iOS Release `BUILD SUCCEEDED`; Simulator/GPX — full suite 95/95, 11 suites (รวม GPX route tests); iPhone จริง — ยังไม่ได้ทดสอบ จึงไม่มีข้อสรุปเรื่อง AlarmKit, เสียง, Silent/Focus, locked screen หรือ background
- **ความเสี่ยง/สิ่งค้าง:** A2.1 automated gate ผ่านบน fingerprint เดียวกัน: focused StartupRecovery 21/21, TripStore 13/13, full Simulator 95/95, unsigned Release build. Red `.xcresult` finalize ไม่ได้หลัง failing tests แต่ test-runner log เก็บหลักฐาน regression; รอบเขียว finalize ปกติ. ยังไม่มี physical iPhone proof; A2.2 cancellation failure reconciliation, A2.3 Auto-Stop deadline และ three consecutive full-suite gate ท้าย A2-R ยังไม่ทำ
- **งานถัดไป:** เริ่ม A2.2 — ทำ cancellation result ให้ observable และคง AlarmKit ID ไว้เมื่อ cancel ล้มเหลว; คง device/release gates ตามแผน

## 2026-09-23 08:06 — A1-D/A1.2: บล็อกการเริ่มทริปเมื่อไม่มี alert path และปิด delivery matrix

- **สถานะ:** ผ่านสำหรับ A1-D/A1.2 และ A1-R automated gate (ปิดงานเอกสาร 23 ก.ย. 2026 11:30 +07:00); physical-device gate ยังเปิด
- **เป้าหมาย:** ใช้การตัดสินใจของผู้ใช้ข้อ 1: ถ้า `AlertDeliveryPolicy` ไม่มี path ที่พร้อม ห้ามเริ่ม Trip Alarm และเปิดหน้า Alert Settings พร้อมเหตุผล/ทางไป iPhone Settings; ตรวจ matrix กับสัญญาเดิม และคงการ retry เมื่อ path หายหลังเริ่มทริปที่ถูกต้อง
- **Baseline:** ก่อนแก้ test source manifest `7100471a0a287846e94482c9798108f4065597734eaa84b3bbf794a676972fbd` ตรงกับ manifest A1.1 ทุกไฟล์; หลังเพิ่ม/ปรับ tests แล้ว source manifest ปัจจุบันเป็น `91ce9361253ee400809efc8a7113d75d56e5d4cbc204d2fe92652585675c3357`. Git ยังไม่มี commit แรกและไฟล์โปรเจกต์เป็น untracked. A1.1 evidence บน fingerprint ก่อนแก้ test: `AlertSettingsTests` 23/23, full Simulator 85/85 และ unsigned generic iOS Release build ผ่าน (รายละเอียด/artifact อยู่ใน entry A1.1 ด้านล่าง)
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/TripStore.swift`, `StopAlarm/DomainModels.swift` (เฉพาะถ้าการตรวจพบช่องว่างด้าน copy ยืนยัน), `StopAlarmTests/AlertSettingsTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md`, `archive/docs/NAPNAV_ALERT_BEHAVIOR_TABLE.md`, handoff และรายงานนี้; `StopAlarm/SystemClients.swift` ตรวจเทียบกับ contract ก่อน แต่จะไม่แก้หากไม่มี defect ที่พิสูจน์ได้
- **ไฟล์ที่เปลี่ยนแล้ว:** `StopAlarm/TripStore.swift`, `StopAlarm/DomainModels.swift`, `StopAlarmTests/AlertSettingsTests.swift`, `StopAlarmTests/TripStoreTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md`, `archive/docs/NAPNAV_ALERT_BEHAVIOR_TABLE.md`, `docs/A1_D_A1_2_HANDOFF.md` และรายงานนี้
- **การเปลี่ยนแปลง:** เพิ่ม test matrix เมื่อไม่มี path ครบ 4 delivery modes × 2 sound modes; เพิ่ม test ว่า muted Notification fallback ต้องบอกสถานะเสียงถูกปิด; `startTrip()` ตรวจ `alertDeliveryPlan.isAvailable` ก่อน location permission หรือการเปลี่ยน state, เปิด Alert Settings และ return เมื่อไม่มี path, และ clear health/settings state เมื่อเริ่มได้; เพิ่ม coverage ว่า start ที่ถูกบล็อกเริ่มได้อีกครั้งหลัง readiness คืนมา และ AlarmKit path เดี่ยวเริ่มได้แม้ Notification ปิด; ปรับ readiness-recovery test ให้จำลอง path หายหลังเริ่มทริป valid แล้วกลับมาก่อน retry; `AlertDeliveryResult.summary` ต่อ copy muted-system เมื่อ fallback target เป็น Notification ที่เสียงถูกปิด
- **หลักฐานทดสอบ:** ก่อน production edits sandbox run บน `91ce936...` จบ exit 70 เพราะ CoreSimulatorService ใช้ไม่ได้; compile run นอก sandboxบน fingerprint เดียวกันจบ exit 65 ด้วย `Missing return ... AsyncStream<LocationEvent>` ใน test mock และ summary `result: unknown`, `totalTestCount: 0`. แก้ explicit return แล้ว rerun บน fingerprint `f2c92ae...`: xcodebuild พิมพ์ `Testing started` แต่หลัง ~6 นาทีค้างระหว่าง test-session diagnostics; child `simctl diagnose ... --timeout=600` ไม่จบ, SIGINT ติด cleanup จึงส่ง SIGTERM ให้เฉพาะ xcodebuild รอบนี้ (exit 143). `.xcresult` `/tmp/NapNav-A1-2-red-20260923-1050.xcresult` ไม่มี `Info.plist`; `xcresulttool` ยืนยันว่า bundle ไม่สมบูรณ์และไม่มี test summary. หลัง implementation/cleanup fingerprint `629d9d13d84cb76385f2073f939a6f50ba6ade073f0b45463e697c0fb1f2e4f6`; targeted `AlertSettingsTests` ใช้ `xcodebuild -quiet -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' -derivedDataPath /tmp/NapNav-A1-2-DerivedData -resultBundlePath /tmp/NapNav-A1-2-targeted-20260923-1110.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/AlertSettingsTests CODE_SIGNING_ALLOWED=NO test` exit 0; xcresult Passed 26/26, failed 0, skipped 0. `TripStoreTests` ด้วย command เดียวกัน เปลี่ยน `-resultBundlePath` เป็น `/tmp/NapNav-A1-2-TripStore-20260923-1112.xcresult` และ test selector เป็น `-only-testing:StopAlarmTests/TripStoreTests` exit 0; xcresult Passed 13/13, failed 0, skipped 0. ทั้งสองรอบเป็น iPhone 18 Pro/iOS 27.0 Simulator; recomputed source manifest หลัง run ยังตรง `629d9d...`. หลังแก้ production code targeted รวม 39/39 ผ่าน จากนั้น `Scripts/phase-a0.sh test-full` บน destination `platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF` ผ่าน 88/88, 0 failed/0 skipped, exit 0; summary `/tmp/NapNav-A1-2-results/20260923-110438-full/summary.json`, `.xcresult` `/tmp/NapNav-A1-2-results/20260923-110438-full/tests.xcresult`, log และ source manifest อยู่ directory เดียวกัน. `Scripts/phase-a0.sh release-build` สร้าง generic iOS Release แบบ `CODE_SIGNING_ALLOWED=NO`, `BUILD SUCCEEDED`, exit 0; artifacts `/tmp/NapNav-A1-2-results/20260923-110630-release-build/`. ทั้ง full test และ Release build manifest ตรงกันที่ `629d9d...`. Full Simulator suite รอบต่อเนื่องที่ 2 ด้วยคำสั่ง `NAPNAV_DESTINATION='platform=iOS Simulator,id=E6266663-CEBB-4C45-B683-F71030D037FF' NAPNAV_DERIVED_DATA=/tmp/NapNav-A1-2-DerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A1-2-results Scripts/phase-a0.sh test-full` ผ่าน 88/88, 0 failed/0 skipped, exit 0; summary `/tmp/NapNav-A1-2-results/20260923-112008-full/summary.json`, `.xcresult` `/tmp/NapNav-A1-2-results/20260923-112008-full/tests.xcresult`, source manifest ตรง `629d9d...`
- **หลักฐานรอบสุดท้าย:** Full Simulator suite รอบต่อเนื่องที่ 3 ใช้คำสั่งเดียวกับรอบที่ 2; summary `/tmp/NapNav-A1-2-results/20260923-112214-full/summary.json` รายงาน Passed 88/88, 0 failed/0 skipped, exit 0, `.xcresult` `/tmp/NapNav-A1-2-results/20260923-112214-full/tests.xcresult`, source manifest ตรง `629d9d...`; GPX release routes ผ่านในแต่ละ full run. ดังนั้นสาม full runs ต่อเนื่อง, targeted 39/39 และ unsigned Release build ผ่านบน source fingerprint เดียวกัน. หลังแก้เอกสารอย่างเดียว รัน `shasum -a 256 -c /tmp/NapNav-A1-2-results/20260923-112214-full/source-files.sha256` ได้ exit 0; source files ทุกไฟล์ใน manifest ยังตรง fingerprint `629d9d...`
- **ความเสี่ยง/สิ่งค้าง:** ไม่มี automated blocker สำหรับ A1-R: A1.1/A1-D/A1.2, full suite 3 รอบ, GPX routes และ unsigned Release build ผ่านบน `629d9d...`. ไม่มี behavioral red ที่สรุปได้ เพราะ runner ก่อน implementation ไม่มี test summary; compile error ก่อนหน้านั้นอยู่ใน test mock และแก้แล้ว ไม่ใช่ production compile result. ยังไม่มี physical-iPhone proof สำหรับเสียง, Silent/Focus, locked screen หรือ background; คงเป็น A4 device gate
- **งานถัดไป:** เริ่ม A2.1 ตาม dependency ใน `docs/NAPNAV_REMEDIATION_PLAN.md`; ห้ามตีความ automated A1 pass ว่าเป็นหลักฐานเสียง/notification จริงบน iPhone

## 2026-09-23 07:04 — A1.1: retry หลังส่ง alert ไม่สำเร็จ

- **สถานะ:** ผ่านสำหรับ automated ticket A1.1; phase A1-R ยังเปิดอยู่
- **เป้าหมาย:** ให้การยืนยันว่าเข้าเขตรัศมียังคงอยู่ แต่แยกจากการส่ง alert; ลองใหม่ได้เมื่อส่งไม่สำเร็จหรือ readiness กลับมา โดยไม่ยิงถี่และไม่ซ้ำหลังสำเร็จ
- **Baseline:** A0-R fingerprint `29a83887e581606fea1d0430615211f440b352687fa0cdbc4e248b971b1a51cf`; full suite เดิม 78/78, core 75/75, GPX 3/3 และ Release build ผ่าน
- **ไฟล์ที่เปลี่ยน:** `StopAlarm/TripStore.swift`, `StopAlarmTests/AlertSettingsTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md`, `docs/DEVELOPMENT_REPORT.md`
- **การเปลี่ยนแปลง:** เพิ่ม regression tests 7 กรณีใน `AlertSettingsTests.swift` ครอบ schedule failure→retry/backoff, readiness กลับมา, in-flight dedup, rejected samples, no-duplicate หลังส่งสำเร็จ, no-duplicate หลังออก/กลับเข้าเขต และไม่เริ่ม retry หลัง Stop; mock รองรับ result queue/readiness/continuation และ sample timestamp ที่กำหนดได้ เพิ่ม optional `at:` ให้ `processLocationEvent` และส่งเวลาเดียวกันเข้า trigger/arrival policies โดยไม่แก้กติกา two-good-samples/20 m; เพิ่ม state machine ใน `TripStore` ที่กัน in-flight ซ้ำ refresh readiness ณ trigger/เวลา retry ตั้ง backoff 10→20→40 วินาที สูงสุด 60 วินาที แล้วยังคง retry ที่เพดานจนสำเร็จหรือจบทริป บันทึก `deliveryUnavailable` เมื่อ path ไม่พร้อม ล้าง state เมื่อส่งสำเร็จ/ทริป reset/restore/จบทริป และไม่เริ่ม retry หากไม่มี active trip ID; อัปเดต remediation plan กับ ticket handoff ให้ตรงความคืบหน้าที่ตรวจแล้ว โดยไม่ปิด A1-R
- **หลักฐานทดสอบ:** test-first ก่อนแก้แสดง regression จริง: runner รายงาน 19/21 ผ่านและ 2 tests ล้ม (6 assertions) เพราะ delivery failure และ unavailable readiness ไม่ retry (`/tmp/NapNav-A1-1-red.yqHrDd/xcodebuild.log`; `.xcresult` รอบนี้ไม่สมบูรณ์เพราะ xcodebuild ไม่ finalize แล้วถูก interrupt exit 130). Fingerprint สุดท้าย `7100471a0a287846e94482c9798108f4065597734eaa84b3bbf794a676972fbd`: targeted `xcodebuild -quiet -project StopAlarm.xcodeproj -scheme StopAlarm -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -derivedDataPath /tmp/NapNav-A1-1-FullDerivedData -resultBundlePath /tmp/NapNav-A1-1-final-targeted.POI5R4/AlertSettings.xcresult -parallel-testing-enabled NO -only-testing:StopAlarmTests/AlertSettingsTests CODE_SIGNING_ALLOWED=NO test` ผ่าน 23/23, 0 failed/0 skipped, exit 0. Full suite `NAPNAV_DERIVED_DATA=/tmp/NapNav-A1-1-FullDerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A1-1-results Scripts/phase-a0.sh test-full` ผ่าน 85/85, 0 failed/0 skipped, exit 0; summary `/tmp/NapNav-A1-1-results/20260923-073532-full/summary.json`, `.xcresult` และ log ใน directory เดียวกัน. Unsigned Release `NAPNAV_DERIVED_DATA=/tmp/NapNav-A1-1-FullDerivedData NAPNAV_A0_RESULTS_DIR=/tmp/NapNav-A1-1-results Scripts/phase-a0.sh release-build` ได้ `BUILD SUCCEEDED`, exit 0; artifacts `/tmp/NapNav-A1-1-results/20260923-073609-release-build/`. Full suite และ build มี `source-manifest.sha256` ตรงกันที่ fingerprint สุดท้าย
- **ขอบเขตหลักฐาน:** source/static review พบ trigger/arrival policy เดิมไม่เปลี่ยน; build เป็น generic iOS Release แบบไม่ sign; tests ผ่านบน iPhone 18 Pro iOS 27.0 Simulator. ไม่ได้ทดสอบเสียง, Silent/Focus, locked screen, background หรือ notification จริงบน iPhone
- **ความเสี่ยง/สิ่งค้าง:** A2.1 ยังต้องเพิ่ม lifecycle/generation guard หลัง send await เพื่อกัน late result จากทริปเก่า; A1-D เรื่อง startTrip เมื่อไม่มี alert path ยังรอผู้ใช้ตัดสินและไม่ได้เปลี่ยน; A1.2 delivery-policy matrix ยังไม่ได้ตรวจ ดังนั้น A1-R ยังไม่ปิด
- **งานถัดไป:** ขอผู้ใช้ตัดสิน A1-D แล้วทำ A1.2 ตาม dependency; หลังปิด A1-R จึงเริ่ม A2.1

## 2026-09-23 06:54 — D1: เตรียม handoff ให้ Luna

- **สถานะ:** ผ่านสำหรับงานเอกสาร/skill; ยังไม่เริ่มแก้ A1-R
- **เป้าหมาย:** หาและติดตั้ง skill ที่ช่วยลด context ที่ไม่จำเป็น แล้วขยายแผนแก้โค้ดเป็นงานย่อยที่ Luna รับช่วงได้
- **Baseline:** A0-R ผ่าน automated gate ตามรายการด้านล่าง; A1-R ยังติด product decision เรื่องไม่มี alert path
- **ไฟล์ที่เปลี่ยน:** `AGENTS.md`, `docs/NAPNAV_REMEDIATION_PLAN.md`,
  `docs/LUNA_CODE_FIX_TICKETS.md`, `docs/DEVELOPMENT_REPORT.md`;
  skill ติดตั้งนอก repo ที่ `/Users/te/.codex/skills/lean-agent-handoff/SKILL.md`
- **การเปลี่ยนแปลง:** สำรวจ curated skills แล้วไม่มี skill ลด token ที่ตรงโจทย์;
  experimental listing ไม่พบ path ใน upstream จึงสร้างและติดตั้ง
  `lean-agent-handoff` แบบสั้นแทน ขยายแผนเป็น ticket A1.1, A1-D, A1.2,
  A2.1–A2.3, Security, A3 และ A4/device gate พร้อมขอบเขต, tests,
  dependency และจุดที่รอผู้ใช้ตัดสิน ระบุให้ Luna เรียก skill นี้เมื่อพร้อมใช้
  ใน Codex turn ถัดไป ยังไม่แก้ source แอป
- **หลักฐานทดสอบ:** frontmatter ของ skill ผ่าน Ruby YAML validation และ
  SHA-256 ของไฟล์ต้นฉบับกับไฟล์ติดตั้งตรงกันที่
  `132a051af821311964fd9ac7ba5ead5db7bd2505c37fb0e3d270cba4b6e5b9dc`;
  `quick_validate.py` ของ skill-creator รันไม่สำเร็จเพราะ Python นี้ไม่มี `yaml`
  ตรวจชื่อ ticket, path และลิงก์จากแผน/`AGENTS.md` แล้ว;
  source fingerprint ตามวิธีของ A0-R ยังเป็น
  `29a83887e581606fea1d0430615211f440b352687fa0cdbc4e248b971b1a51cf`;
  ยังไม่รัน build/tests เพราะงานรอบนี้เป็นเอกสาร/skill
- **ความเสี่ยง/สิ่งค้าง:** skill ไม่สามารถบังคับภาษาของ reasoning ภายในหรือรับประกันจำนวน token ที่ประหยัดได้
- **งานถัดไป:** Luna เริ่ม A1.1 ได้โดยไม่ต้องรอ A1-D; ก่อนเปลี่ยนพฤติกรรม
  `startTrip()` ต้องได้คำตอบจากผู้ใช้ว่าจะบล็อก Trip Alarm เมื่อไม่มี alert path
  หรือแยกโหมด tracking-only

## 2026-09-23 06:39 — A0-R: ตรวจ baseline ปัจจุบัน

- **สถานะ:** ผ่าน automated A0-R gate; ยังไม่ผ่าน device/release gate
- **เป้าหมาย:** ระบุ source/toolchain ที่ตรวจซ้ำได้ แล้วรัน Release build กับ tests
- **Baseline:** `git log -1` แจ้งว่า branch `master` ยังไม่มี commit;
  `git status --short` แสดงไฟล์โปรเจกต์ทั้งหมดเป็น untracked
- **การเปลี่ยนแปลง:** เพิ่มแผน, ข้อปฏิบัติ agent และรายงานนี้;
  `Scripts/phase-a0.sh` บันทึก SHA-256 ของ source files, fingerprint รวม,
  Git state และ exit code ต่อรอบ ยังไม่แก้ business logic
- **หลักฐานทดสอบ:** `xcodebuild -version` ได้ Xcode 27.0 (27A266a);
  `xcrun simctl list devices available` ใน sandbox ล้มเหลวเพราะ
  CoreSimulatorService connection invalid / connection refused
- **Build ใน sandbox:** `.a0-results/20260923-064047-release-build/` และ
  `.a0-results/20260923-064115-release-build/` จบด้วย exit 133;
  `swift-plugin-server` ส่ง malformed response ให้ SwiftUI/Observation macros
  แม้รอบหลังใช้ DerivedData ใหม่
- **Build นอก sandbox:** `.a0-results/20260923-064149-release-build/`
  ใช้ DerivedData ใหม่ `/tmp/NapNav-A0R-20260923-UnrestrictedDerivedData`,
  exit 0 และ `BUILD SUCCEEDED`
- **Simulator/full test นอก sandbox:** `simctl` พบ iPhone 18 Pro iOS 27.0;
  `.a0-results/20260923-064222-full/summary.json` รายงาน `Passed`,
  78 ผ่าน, 0 ล้ม, 0 ข้าม source fingerprint ของ build และ test ตรงกันที่
  `29a83887e581606fea1d0430615211f440b352687fa0cdbc4e248b971b1a51cf`
- **Full suite 3 รอบต่อเนื่อง:**
  `.a0-results/20260923-064353-full-1/summary.json`,
  `.a0-results/20260923-064453-full-2/summary.json` และ
  `.a0-results/20260923-064548-full-3/summary.json` แต่ละรอบ `Passed`,
  78 ผ่าน, 0 ล้ม, 0 ข้าม, exit 0
- **Targeted tests:** `.a0-results/20260923-064649-core/summary.json`
  `Passed` 75/75; `.a0-results/20260923-064752-gpx/summary.json`
  `Passed` 3/3 ทั้งคู่ exit 0
- **Source snapshot:** Release build, full ทั้ง 4 รอบ, core และ GPX มี
  `source-manifest.sha256` ตรงกันทั้งหมดที่
  `29a83887e581606fea1d0430615211f440b352687fa0cdbc4e248b971b1a51cf`
  manifest ครอบคลุมแอป, widget, tests, routes, runner และ `project.pbxproj`
- **ความเสี่ยง/สิ่งค้าง:** ผล 69/69 และ Release build วันที่ 21 ก.ย. ใน
  `archive/docs/NAPNAV_RELEASE_QA_CHECKLIST.md` เป็นหลักฐานเก่า ยังไม่ใช่ผลของ
  source snapshot วันนี้; ได้แทนที่ด้วยผล 78/78 รอบปัจจุบันแล้ว โปรเจกต์ยังไม่มี
  Git commit แรกและต้องรัน Xcode/Simulator นอก sandbox ในเครื่องนี้
- **ขอบเขตหลักฐาน:** build และ automated Simulator tests ผ่าน ไม่ยืนยัน
  Silent/Focus, locked screen, background, เสียงจริง หรือการยกเลิก AlarmKit
- **งานถัดไป:** เริ่ม A1-R โดยตกลงนโยบายเมื่อไม่มี alert path แล้วเขียน
  failing tests ของ unavailable → available และ delivery failure ก่อนแก้ logic
## 2026-09-26 21:07 — UX: จัดหน้าเปิดแอปให้โลโก้อยู่เหนือข้อความ

- **สถานะ:** สำเร็จระดับ source/static, build และ visual Simulator; ยังไม่ได้ตรวจบน iPhone จริง
- **เป้าหมาย:** ปรับ StartupView ให้ใช้โลโก้ NapNav ที่ติดตั้งอยู่เป็นองค์ประกอบหลักด้านบน และมีข้อความสถานะสั้น ๆ ด้านล่าง โดยรักษา seamless native launch และ flow กู้ทริป/ข้อผิดพลาดเดิม
- **baseline:** Native Launch Screen ใช้ `LaunchLogo`; `StartupView` ยังวาดชื่อ `NapNav`/`Trip Alarm` เป็นข้อความและใช้ route animation แยก ทำให้ภาพแบรนด์ระหว่างหน้าเปิดไม่ต่อเนื่องกัน. งาน App Icon และ Launch asset ล่าสุด build ผ่านตามรายการ 20:25 และ 20:33 แต่ยังไม่ใช่หลักฐานของ source หลังงานนี้
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/StartupView.swift` และ `docs/DEVELOPMENT_REPORT.md`
- **การเปลี่ยนแปลง:** `StartupView` ใช้ `LaunchLogo` เป็นภาพหลักด้านบนแทนการวาดชื่อ `NapNav`/`Trip Alarm` ซ้ำ ตัด route animation ที่แยกจากแบรนด์ออก และวาง `ProgressView` กับข้อความสถานะสั้นแบบจัดกึ่งกลางไว้ด้านล่าง; flow ของ recovery/error และ startup timing ไม่เปลี่ยน
- **หลักฐานทดสอบ:** source/static: `XcodeRefreshCodeIssuesInFile` รายงาน 0 diagnostics ใน `StartupView.swift`; `git diff --check -- StopAlarm/StartupView.swift docs/DEVELOPMENT_REPORT.md` exit 0. Build: `BuildProject` สำเร็จใน 3.333 วินาที, 0 errors; log `/var/folders/bc/0t78kzzn5rnc3wbxrp3b8l5c0000gn/T/ActionArtifacts/B910C0A4-BE7C-4DAB-A9D6-55DC565A76EA/BuildProject/BuildProject-Log-20260926-210802.txt`. Simulator: เปิดด้วย developer override `simulateSlow` บน iPhone 17e iOS 27 (390×844); ภาพและ hierarchy ยืนยันว่า logo/wordmark อยู่เหนือข้อความและจัดกึ่งกลาง ไม่มี crop, overlap หรือหลุดขอบ ข้อความไทยอ่านชัด; image frame `{{85.3,194.7},{219.3,390.0}}`, status centered ที่ x=195. Screenshot `/var/folders/bc/0t78kzzn5rnc3wbxrp3b8l5c0000gn/T/ActionArtifacts/B910C0A4-BE7C-4DAB-A9D6-55DC565A76EA/DeviceInteractionSynthesize/Verify Startup Logo Layout-21_11_07_235-screenshot.png`; hierarchy/log อยู่ directory เดียวกัน. GPX: ไม่เกี่ยวและไม่ได้รัน. iPhone จริง: ไม่ได้ทดสอบ
- **ความเสี่ยง/สิ่งค้าง:** ข้อความสโลแกนอยู่ใน raster `LaunchLogo` จึงยังเป็นภาษาไทยแม้เลือกภาษาอังกฤษ; ไม่ได้ตรวจบน iPhone จริง. งานนี้ไม่เปลี่ยน product flow หรือ startup timing
- **งานถัดไป:** หากต้องการ localize สโลแกนใน native Launch Screen ต้องทำ asset แยกตามภาษาในรอบถัดไป; สำหรับ scope นี้จบแล้ว
## 2026-09-26 21:14 — UX: ใช้ iOS Native Launch Screen เพียงหน้าเดียว

- **สถานะ:** สำเร็จระดับ source/static, targeted tests, build และ Simulator post-launch; ยังไม่ได้ตรวจบน iPhone จริง
- **เป้าหมาย:** ให้ cold launch แสดงโลโก้/ข้อความผ่าน `UILaunchScreen` ของ iOS เพียงครั้งเดียว แล้วเข้าหน้าหลักทันที; ไม่ให้ developer override หรือ persisted setting เปิด SwiftUI loading screen ซ้ำ ส่วน recovery/error ที่ต้องตอบสนองยังคงอยู่
- **baseline:** `Info.plist` ตั้ง `UILaunchScreen` ใช้ `LaunchLogo` และ `LaunchBackground` ถูกต้องแล้ว แต่ `DevStartupBehavior.alwaysShow/simulateSlow` ยังทำให้ `TripStore` เปิด `StartupView` ซ้ำ และ Developer Tools ยังมีตัวเลือก/preview ของ loading screen; cold launch ปกติแบบ `fastIfPossible` ไม่แสดงซ้ำ
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/TripStore.swift`, `StopAlarm/DomainModels.swift`, `StopAlarm/AlertSettingsView.swift`, `StopAlarm/en.lproj/Localizable.strings`, `StopAlarm/th.lproj/Localizable.strings`, `StopAlarmTests/StartupRecoveryTests.swift`, `docs/NAPNAV_REMEDIATION_PLAN.md`, `docs/LUNA_CODE_FIX_TICKETS.md` และรายงานนี้
- **การเปลี่ยนแปลง:** ลบ `DevStartupBehavior` และ UserDefaults key `napnav.dev.startup-behavior.v1`; รวม `prepareForLaunch()` เป็นเส้นทางเดียวที่ไม่แสดง StartupView ระหว่าง launch; `relaunchApp()` ไม่เปิด loading overlay; ลบ picker และ Startup loading preview จาก Developer Tools พร้อมลบ test/copy ที่หมดการใช้งาน. คง `StartupView` สำหรับ awaiting recovery, recovery action และ failure เท่านั้น. อัปเดต remediation plan/ticket ให้ยืนยัน native-only decision
- **หลักฐานทดสอบ:** source/static: Xcode live diagnostics 0 issues ใน `TripStore.swift`, `DomainModels.swift`, `AlertSettingsView.swift` และ `StartupRecoveryTests.swift`; `plutil -lint` ผ่านทั้ง en/th strings; `rg` ไม่พบ enum/property/UserDefaults key/ข้อความเครื่องมือ loading เดิม; `git diff --check` exit 0. Targeted StartupRecovery ผ่าน 24/24, 0 failed/skipped; `.xcresult` `/var/folders/bc/0t78kzzn5rnc3wbxrp3b8l5c0000gn/T/ActionArtifacts/B910C0A4-BE7C-4DAB-A9D6-55DC565A76EA/RunSomeTests/Test-StopAlarm-2026.09.26_21-16-13-+0700.xcresult`. Build: `BuildProject` ผ่านใน 2.651 วินาที, 0 errors; log `/var/folders/bc/0t78kzzn5rnc3wbxrp3b8l5c0000gn/T/ActionArtifacts/B910C0A4-BE7C-4DAB-A9D6-55DC565A76EA/BuildProject/BuildProject-Log-20260926-211655.txt`. Simulator: เปิดบน iPhone Simulator พร้อม legacy launch argument `-napnav.dev.startup-behavior.v1 simulateSlow`; capture แรกและหลัง 0.5 วินาทีอยู่หน้าหลัก ไม่มี StartupView/spinner/status loading ใน hierarchy. หลักฐาน `/var/folders/bc/0t78kzzn5rnc3wbxrp3b8l5c0000gn/T/ActionArtifacts/B910C0A4-BE7C-4DAB-A9D6-55DC565A76EA/DeviceInteractionSynthesize/Verify Single Native Launch-21_17_30_761-screenshot.png` และไฟล์ hierarchy/log ชื่อเดียวกันใน directory นั้น. GPX: ไม่เกี่ยวและไม่ได้รัน. iPhone จริง: ไม่ได้ทดสอบ
- **ความเสี่ยง/สิ่งค้าง:** Native launch มีเวลาควบคุมโดย iOS และ capture tool ช้ากว่าช่วง launch จึงไม่เก็บเฟรม `LaunchLogo` แรกได้โดยตรง; `Info.plist`/asset compile ยืนยัน configuration และ post-launch ยืนยันว่าไม่มีหน้าที่สอง. แอปจะไม่หน่วงหน้าหลักเพื่อโชว์โลโก้. Recovery/error overlay ไม่ถือเป็น launch loading และต้องคงไว้เพื่อความปลอดภัยของข้อมูลทริป
- **งานถัดไป:** scope นี้จบแล้ว; หากต้องการหลักฐาน native launch frame ให้ตรวจด้วย screen recording บน iPhone จริงใน A4 device gate
## 2026-09-26 21:20 — A4 UX: แก้ Native Launch Logo ถูกขยายจนล้นจอ

- **สถานะ:** กำลังทำ — asset metadata และ build ผ่าน; รอ visual cold-launch check
- **เป้าหมาย:** แก้ `LaunchLogo` ใน iOS Native Launch Screen ให้แสดงเต็มโลโก้/ข้อความภายในหน้าจอ ไม่ครอปขยายตามภาพจริง `IMG_4119.PNG`
- **baseline:** `UILaunchScreen` อ้าง `LaunchLogo` ถูกต้อง แต่ `LaunchLogo.imageset/Contents.json` ไม่มี scale; PNG ขนาด 941×1672 px จึงถูก asset catalog ตีความเป็น 941×1672 points ที่ 1x และ iOS จัดกึ่งกลางพร้อมครอปออกนอกหน้าจอ. ภาพ iPhone ของผู้ใช้ยืนยันว่าเห็นเพียงส่วนขยายของตัว N/หมุด
- **ไฟล์ที่คาดว่าจะเปลี่ยน:** `StopAlarm/Assets.xcassets/LaunchLogo.imageset/Contents.json` และ `docs/DEVELOPMENT_REPORT.md`
- **การเปลี่ยนแปลง:** เพิ่ม `scale: 3x` ให้ PNG ใน `LaunchLogo.imageset` ทำให้ intrinsic size จาก 941×1672 points เหลือประมาณ 314×557 points และลบ `preserves-vector-representation` ที่ไม่เหมาะกับ raster PNG; ไม่แก้ตัวภาพหรือ startup flow
- **หลักฐานทดสอบ:** source/static: Ruby JSON parse ผ่าน, `git diff --check` exit 0. Build: `BuildProject` สำเร็จใน 3.555 วินาที, 0 errors; log `/var/folders/bc/0t78kzzn5rnc3wbxrp3b8l5c0000gn/T/ActionArtifacts/B910C0A4-BE7C-4DAB-A9D6-55DC565A76EA/BuildProject/BuildProject-Log-20260926-212140.txt`. Simulator: รอ cold-launch check. GPX/iPhone จริง: ไม่ได้ทดสอบ build ใหม่นี้
- **ความเสี่ยง/สิ่งค้าง:** iOS cache หน้า Launch Screen ได้ ต้องติดตั้ง build ใหม่/ลบแอปเดิมเพื่อยืนยัน asset ล่าสุด; ไม่เปลี่ยน startup flow
- **งานถัดไป:** กำหนด asset scale ให้ intrinsic point size พอดีจอ แล้วตรวจ cold launch
