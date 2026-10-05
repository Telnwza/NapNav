# NapNav — Git File Management Guide & Policy
**คู่มือและนโยบายการจัดเก็บไฟล์บน Git vs ไฟล์ที่ควรเก็บไว้เฉพาะในเครื่อง**

เอกสารนี้รวบรวมเกณฑ์และรายการไฟล์ทั้งหมดในโปรเจกต์ **NapNav** เพื่อเป็นมาตรฐานในการพัฒนา ว่าไฟล์ประเภทใดควรถูกนำขึ้น Git (Tracked) และไฟล์ประเภทใดควรเก็บไว้เฉพาะในเครื่องคอมพิวเตอร์ส่วนบุคคล (Untracked / Ignored) เพื่อรักษาขนาด repository ให้เบา ปลอดภัย และไม่สูญหาย

---

## 1. เกณฑ์การแบ่งประเภทไฟล์ (Core Principles)

| หมวดหมู่ | เกณฑ์การพิจารณา | ตัวอย่าง |
| :--- | :--- | :--- |
| **1. Must Commit (ต้องอยู่บน Git)** | ไฟล์ที่จำเป็นต่อการ Compile, Build, Test, และ Deploy ตัวแอป รวมทั้งการตั้งค่าโปรเจกต์ที่เป็นมาตรฐานส่วนกลาง | Swift source code, Assets.xcassets, Info.plist, Unit tests, GPX routes, Shared schemes |
| **2. Public Web & Legal (ต้องอยู่บน Git)** | ไฟล์ที่โฮสต์สาธารณะตามข้อกำหนดของ Apple App Store (Support & Privacy URLs) | `docs/index.html`, `docs/privacy.html`, `docs/support.html`, `docs/app-icon.png` |
| **3. Project Docs (เก็บประวัติบน Git)** | เอกสารวางแผน สัญญาการทำงานของทีม/Agent และข้อมูลเตรียมกรอก App Store | `README.md`, `AGENTS.md`, `docs/app-store-metadata.md`, Remediation plan |
| **4. Local Only / Untracked (เก็บไว้ในเครื่อง)** | ไฟล์ร่าง, Mockup ชั่วคราว, ไอเดียต้นฉบับ, ไฟล์ที่โหลดจาก AI หรือ Prototype เก่าที่ไม่ได้เชื่อมกับแอปจริง | `docs/artwork/`, `ui-prototype/`, `archive/*.png`, HTML proposals |
| **5. Strict Local / Never Commit (ห้ามขึ้น Git เด็ดขาด)** | Build cache, ผลเทสต์ขนาดใหญ่, IDE session ส่วนบุคคล, และกุญแจความปลอดภัย/ใบรับรอง | `.a0-results/`, `.build/`, `xcuserdata/`, `.DS_Store`, Certificates (`.p12`), Private keys |

---

## 2. รายการจำแนกไฟล์ในโปรเจกต์ NapNav

### กลุ่มที่ 1: ไฟล์ที่ต้องอยู่บน Git (Tracked in Git)

* **Source Code (`NapNav/`)**:
  * โค้ดภาษา Swift ทั้งหมด (`*.swift`): `NapNavApp.swift`, `TripStore.swift`, `DestinationSelection.swift`, `TriggerPolicy.swift`, `SystemClients.swift`, `DomainModels.swift`, etc.
  * ไฟล์สิทธิ์และความเป็นส่วนตัว: `Info.plist`, `PrivacyInfo.xcprivacy`, `NapNav.entitlements`
  * ไฟล์ภาษาและการแปล: `en.lproj/Localizable.strings`, `th.lproj/Localizable.strings`, `*.strings`
  * แอสเซททางการที่ใช้ในแอป: `NapNav/Assets.xcassets/` (AppIcon, LaunchLogo, สี)
  * ไอคอนเวกเตอร์ทางการ: `NapNav/NapNav.icon/`
* **Extensions & Tests (`NapNavWidget/`, `NapNavTests/`, `TestRoutes/`)**:
  * โค้ด Live Activity Widget: `NapNavWidgetBundle.swift`, `TripLiveActivityWidget.swift`, Widget `Info.plist`
  * ชุดการทดสอบ Swift Testing / XCTest: `NapNavTests/*.swift`
  * ไฟล์ GPX จำลองพิกัดเดินทาง: `TestRoutes/*.gpx` (จำเป็นสำหรับการรัน UI/Integration Test บน Simulator)
* **การตั้งค่า Xcode (`NapNav.xcodeproj/`)**:
  * `NapNav.xcodeproj/project.pbxproj` (โครงสร้างไฟล์และ targets ของ Xcode)
  * `NapNav.xcodeproj/xcshareddata/xcschemes/NapNav.xcscheme` (Shared Scheme เพื่อให้คนอื่นหรือ CI สามารถกด build/test ได้)
  * `NapNav.xcodeproj/xcshareddata/xcodecloud/manifest.json` (การเชื่อมต่อ Xcode Cloud)
  * `StopAlarm.xcodeproj` (Symlink เพื่อ backward compatibility กับคำสั่ง/script เดิม)
* **หน้าเว็บสาธารณะและเอกสารตามกฎหมาย (`docs/`)**:
  * `docs/index.html` (Landing page)
  * `docs/privacy.html` (Privacy Policy URL ส่งให้ Apple App Store)
  * `docs/support.html` (Support URL ส่งให้ Apple App Store)
  * `docs/.nojekyll` & `docs/app-icon.png` (ไอคอนสำหรับแสดงบนหน้าเว็บ)
* **เอกสารโปรเจกต์และสัญญาการทำงาน**:
  * `README.md`, `LICENSE`, `.github/FUNDING.yml`, `.gitignore`
  * `AGENTS.md` (Working agreement สำหรับ AI Pair Programming)
  * `docs/NAPNAV_REMEDIATION_PLAN.md` & `docs/LUNA_CODE_FIX_TICKETS.md`
  * `docs/app-store-metadata.md` (ร่างข้อความสำหรับส่ง App Store Connect)
  * `docs/DEVELOPMENT_REPORT.md` (บันทึกความคืบหน้าและการทดสอบ)
  * `archive/docs/*.md` (เอกสารประวัติการออกแบบเดิมที่อ้างอิงในแผน)
  * `Scripts/phase-a0.sh` (สคริปต์ automate ตรวจสอบ build และ test)

---

### กลุ่มที่ 2: ไฟล์ที่ควรเก็บไว้เฉพาะในเครื่อง (Kept Locally / Ignored in Git)

ไฟล์เหล่านี้มีประโยชน์สำหรับการอ้างอิงของนักพัฒนา **แต่ไม่จำเป็นต้องส่งขึ้น GitHub** เพื่อป้องกันไม่ให้ Git Repository บวมและไม่เป็นระเบียบ:

1. **`archive/*.png` (เช่น `archive/ChatGPT Image Sep 26, 2026, 09_01_22 PM.png`)**
   * *เหตุผล:* เป็นภาพ binary ขนาดใหญ่ (~504 KB) ที่เซฟมาจาก AI/ChatGPT ไม่ได้ถูกเรียกใช้ในโค้ดหรือหน้าเว็บ
   * *การจัดการ:* เก็บไฟล์ไว้ในเครื่อง ลบออกจาก Git index และเพิ่มลงใน `.gitignore`
2. **`docs/artwork/` (รวมถึง `concepts/*.svg` และ `napnav-fresh-board.png`)**
   * *เหตุผล:* เป็นแบบร่างไอคอนและโลโก้กว่า 40 แบบที่ใช้ระหว่างการระดมไอเดีย (Design scratchpad) เมื่อเลือกแบบแล้ว โลโก้จริงได้ถูกบันทึกไว้ใน `NapNav.icon` และ `Assets.xcassets` เรียบร้อยแล้ว
   * *การจัดการ:* เก็บไฟล์ต้นฉบับไว้ในเครื่องหรือใน Figma / Drive ส่วนตัว
3. **`ui-prototype/` (`index.html`, `README.md`)**
   * *เหตุผล:* เป็น HTML prototype หน้าจอแอปยุคแรกก่อนเริ่มเขียนโค้ด SwiftUI จริง ปัจจุบันตัวแอปจริงถูกสร้างบน SwiftUI หมดแล้ว
   * *การจัดการ:* เก็บไว้ในเครื่องเพื่อดูย้อนหลัง ไม่ต้อง sync ขึ้น Git
4. **`docs/UI5_SURFACE_PROPOSALS_*.html`**
   * *เหตุผล:* เป็น HTML mockups สำหรับดูข้อเสนอแนะ UI ชั่วคราว

---

### กลุ่มที่ 3: ไฟล์ที่ห้ามนำขึ้น Git เด็ดขาด (Strictly Ignored)

ไฟล์กลุ่มนี้ถูกระบุใน [.gitignore](file:///Users/te/Documents/ChatGPT/stop%20alarm/.gitignore) แล้ว เพื่อป้องกันความปลอดภัยและไม่ให้ขยะจากการ build ขึ้น Git:

1. **ไฟล์ Cache และ Artifacts ขนาดใหญ่จากการทดสอบ/Build**:
   * `.a0-results/` (ขนาด ~209 MB — ข้อมูล DerivedData, `.xcresult`, logs)
   * `.build/` & `.build-*/` (ขนาดรวม ~270 MB — SPM caches และ object files)
   * `build/`, `DerivedData/`, `*.xcarchive`, `*.ipa`, `*.dSYM*`
2. **Xcode User-Specific State**:
   * `*.xcuserdatad/` เช่น `NapNav.xcodeproj/xcuserdata/` และ `project.xcworkspace/xcuserdata/`
   * `*.xcuserstate` (จำตำแหน่งแท็บบน Xcode ของเครื่องผู้ใช้แต่ละคน)
3. **OS System Files**:
   * `.DS_Store`
4. **ข้อมูลความลับและความปลอดภัย (Security & Credentials)**:
   * Signing Certificates: `*.p12`, `*.cer`, `*.pem`
   * Provisioning Profiles: `*.mobileprovision`
   * App Store Connect API Keys: `AuthKey_*.p8`
   * Environment files: `.env`, `.env.*`

---

## 3. วิธีจัดการไฟล์เมื่อต้องการ Untrack โดยไม่ลบไฟล์ในเครื่อง

หากเผลอ commit ไฟล์ร่างหรือไฟล์ที่ไม่จำเป็นไปแล้ว และต้องการเอาออกจาก Git โดยยังเก็บไฟล์ไว้ในเครื่อง:

```bash
# 1. ปลดไฟล์หรือโฟลเดอร์ออกจากการติดตามของ Git (ไฟล์ในเครื่องจะไม่หาย)
git rm --cached -r <path-to-folder-or-file>

# ตัวอย่างที่ใช้ในโปรเจกต์นี้:
git rm --cached "archive/ChatGPT Image Sep 26, 2026, 09_01_22 PM.png"
git rm --cached -r docs/artwork/ ui-prototype/ docs/UI5_SURFACE_PROPOSALS_2026-10-05.html

# 2. เพิ่ม path ดังกล่าวลงใน .gitignore เพื่อไม่ให้ถูก track อีกในอนาคต

# 3. ตรวจสอบสถานะว่าไฟล์เหล่านั้นกลายเป็น Ignored (ไม่ขึ้น Untracked)
git status

# 4. บันทึก Commit การเปลี่ยนแปลง
git commit -m "chore: untrack non-essential drafts, prototypes, and local artwork"
```
