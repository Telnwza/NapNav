# NapNav — แผนทำแอปให้สมบูรณ์ก่อนเข้าสู่ TestFlight

อัปเดตล่าสุด: 21 กันยายน 2026  
สถานะปัจจุบัน: **Feature-complete beta candidate — ยังไม่ผ่าน App Complete Gate**

เอกสารนี้แทน roadmap ฉบับเดิมที่ระบุว่า Core Features สมบูรณ์ 100% ลำดับใหม่จะแยกงานออกเป็นสองช่วงชัดเจน:

1. ทำตัวแอปให้สมบูรณ์ เสถียร และตรงกับสิ่งที่บอกผู้ใช้
2. เมื่อผ่านเกณฑ์ภายในแล้ว จึงค่อยนำขึ้น TestFlight และทดสอบภาคสนาม

แนวคิดหลักคือ **ยังไม่ถือว่าแอปพร้อมเพียงเพราะหน้าจอและฟีเจอร์ทำงานบน Simulator** ฟังก์ชันหลักของ NapNav คือการเตือนเมื่อใกล้ถึงจุดหมาย เรื่อง background, locked screen, Silent, Focus และ AlarmKit จึงต้องมีหลักฐานจาก iPhone จริงก่อนปล่อยให้ผู้ใช้ภายนอกทดสอบ

---

## 1. ขอบเขต v1.0

### ต้องมีใน v1.0

- ค้นหา เลือก และลากปรับจุดหมายบนแผนที่
- เลือกระยะเตือนล่วงหน้า
- ติดตามตำแหน่งระหว่างทริปและทำงานต่อเมื่อหน้าจอล็อก
- แจ้งเตือนหนึ่งครั้งเมื่อเข้าเขตที่เลือก
- แยกระยะเตือนออกจากเกณฑ์ถึงจุดหมาย 20 เมตร
- เลือก Notification, AlarmKit หรือโหมดอัตโนมัติตามความสามารถของเครื่อง
- แสดงสถานะการเตือนอย่างตรงไปตรงมา ไม่รับประกันสิ่งที่ระบบปฏิบัติการอาจปิดกั้น
- Live Activity และ Dynamic Island ระหว่างทริป
- หยุดทริป, เลื่อนเตือน และ Auto-Stop โดยไม่ทิ้ง GPS, notification หรือ alarm ค้าง
- กู้คืนทริปหลังแอปถูกปิดหรือระบบยุติ process
- หน้า Settings, onboarding แบบสั้น และข้อความแก้ปัญหา permission
- รองรับ Dynamic Type, VoiceOver, Reduce Motion, Light/Dark Mode

### ยังไม่อยู่ใน v1.0

- Favorite และ Recent Destinations
- ป้ายรถเมล์หรือเส้นทาง transit จากฐานข้อมูลภายนอก
- การคาดเดาสถานีใต้ดินด้วย motion sensor
- Dynamic radius ที่ปรับตามความเร็วโดยอัตโนมัติ
- Critical Alerts entitlement
- ระบบบัญชี, cloud sync หรือ analytics จากเซิร์ฟเวอร์

ใน v1.0 คำว่า “ระยะเตือน” หมายถึงระยะคงที่ที่ผู้ใช้เลือก ไม่ใช้คำว่า Dynamic Radius จนกว่าจะมี logic ปรับระยะจริง

---

## 2. หลักฐานปัจจุบัน

### ผ่านแล้ว

- Release build สำหรับ generic iOS device ผ่านเมื่อปิด code signing
- Full suite 69/69 ผ่าน 3 รอบต่อเนื่องบน Xcode 27.0 และ iPhone 18 Pro Simulator (iOS 27.0)
- Core suite 66/66 และ GPX targeted suite 3/3 ผ่านหลัง Phase A2
- มี runner มาตรฐานที่เก็บ `.xcresult`, log และข้อมูล Xcode/SDK/Simulator ต่อรอบ
- Trigger policy, arrival threshold, GPX routes, persistence, Settings และ Live Activity มี automated tests
- ชุด TripStore ที่แยกรันผ่าน 11/11 tests
- UI flow หลักผ่านการตรวจรอบล่าสุดของผู้พัฒนา

### ยังไม่ผ่าน

- ยังไม่มี signed Archive ที่ตรวจ distribution configuration แล้ว
- Physical-device gate สำหรับ background, locked screen, Silent, Focus และ AlarmKit ยังไม่ครบ
- AlarmKit, background, locked screen, Silent และ Focus ยังต้องพิสูจน์บน iPhone จริง
- ยังไม่มี App Icon, Bundle ID สำหรับ production และ Privacy Manifest

ผลเก่าในเอกสาร QA ใช้เป็นข้อมูลอ้างอิงได้ แต่จะไม่นับแทนผลทดสอบหลังแก้รอบใหม่

---

# ช่วง A — ทำตัวแอปให้สมบูรณ์

## Phase A0 — ทำ baseline ให้ตรวจซ้ำได้

สถานะ: **ผ่านแล้วเมื่อ 21 กันยายน 2026** — core 44/44, GPX 3/3, full suite 47/47 จำนวน 3 รอบต่อเนื่อง และ Release build แบบไม่เซ็นผ่าน หลักฐานและคำสั่งมาตรฐานอยู่ใน `NAPNAV_RELEASE_QA_CHECKLIST.md`

เป้าหมาย: ให้ทุกคนเริ่มจาก build และ test ชุดเดียวกัน ก่อนแตะ behavior เพิ่ม

งาน:

- แก้ async tests ที่ใช้ `Task.yield()` เป็นตัวรอผล ให้รอ event หรือ state transition แบบ deterministic
- แยกปัญหา test runner ค้างที่ `Finalize test log` ออกจาก test failure
- ทำคำสั่งมาตรฐานสำหรับ:
  - Release build แบบไม่เซ็น
  - Core unit tests
  - GPX route tests
  - Full test suite
- อัปเดต `NAPNAV_RELEASE_QA_CHECKLIST.md` ให้ตรงกับจำนวน tests ปัจจุบัน
- บันทึกผลแต่ละรอบพร้อมวันที่, Xcode, SDK และ Simulator ที่ใช้

Acceptance criteria:

- Full suite ผ่านอย่างน้อย 3 รอบต่อเนื่องโดยไม่แยก suite
- ไม่มี test ที่อาศัยจำนวน `Task.yield()` เพื่อหวังว่า async task จะทำงานทัน
- Release build ผ่านโดยไม่มี compiler error
- ถ้า test runner ค้าง ต้องมีผล test ที่อ่านได้และวิธีเก็บ log ที่ทำซ้ำได้

---

## Phase A1 — ปิดสัญญาการเตือนให้ชัด

สถานะ: **ผ่าน automated gate เมื่อ 21 กันยายน 2026** — behavior contract อยู่ใน `NAPNAV_ALERT_BEHAVIOR_TABLE.md`; core suite 54/54 และ full suite 57/57 ผ่าน พร้อม Release build แบบไม่เซ็น ทั้งนี้เสียงจริง, การสั่น, Silent/Focus, background และ locked screen ยังอยู่ใน physical-device gate

เป้าหมาย: สิ่งที่ผู้ใช้เลือกใน Settings ต้องตรงกับสิ่งที่ระบบทำจริง

งาน:

- กำหนด behavior table สำหรับทุกคู่ของ Delivery Mode และ Sound Mode
- ปรับโหมดตาม OS:
  - iOS 18–25 ใช้ Notification เป็น baseline
  - iOS 26+ ใช้ AlarmKit ได้เมื่อได้รับอนุญาต
  - ตัวเลือกที่เครื่องทำไม่ได้ต้องถูกซ่อน ปิดใช้งาน หรืออธิบาย fallback ก่อนเลือก
- ปรับคำว่า “สั่นอย่างเดียว” ให้เป็นความสามารถที่พิสูจน์ได้
  - Notification ที่ไม่มีเสียงไม่ควรถูกอธิบายว่าจะสั่นแน่นอน
  - AlarmKit ต้องไม่เมินค่าที่ผู้ใช้เลือกโดยไม่มีคำอธิบาย
- ออกแบบโหมด Both ไม่ให้เกิดเสียงซ้อนโดยไม่ตั้งใจ
- แยกผลลัพธ์การส่งเป็น `alarm scheduled`, `notification delivered path`, `fallback used` และ `delivery unavailable`
- ทำ error UI เมื่อเส้นทางที่เลือกใช้ไม่ได้ พร้อมปุ่มเปิด Settings
- เพิ่ม tests สำหรับทุก delivery mode, fallback และ permission state

Acceptance criteria:

- ผู้ใช้รู้ก่อนเริ่มทริปว่าจะเตือนด้วยวิธีใด
- เลือกโหมดที่ไม่รองรับแล้วไม่เกิด silent failure
- Both ไม่มีเสียงซ้อนแบบควบคุมไม่ได้
- fallback failure ไม่ถูกแสดงว่า “พร้อมเตือน”
- automated tests ครบทุก combination ที่โค้ดรองรับ

---

## Phase A2 — ทำ AlarmKit และ trip lifecycle ให้จบจริง

สถานะ: **ผ่าน automated gate เมื่อ 21 กันยายน 2026** — บันทึก AlarmKit ID และ lifecycle state ลง snapshot, reconcile alarm เดิมก่อน restore, รวม stop/complete เข้าสู่ cleanup เดียว, เพิ่ม AlarmKit `stopIntent`, กู้ Auto-Stop หลัง relaunch และเพิ่มทางล้าง snapshot ที่เสียหาย; core 66/66 และ full 69/69 ผ่าน 3 รอบ พร้อม Release build แบบไม่เซ็น ทั้งนี้พฤติกรรม AlarmKit/Live Activity/location ขณะ process ถูกระบบยุติยังต้องยืนยันใน physical-device gate

เป้าหมาย: ไม่ว่าแอปจะอยู่ foreground, background, ถูกปิด หรือเปิดใหม่ ทริปและ alarm ต้องอยู่ในสถานะที่อธิบายได้

งาน:

- บันทึก AlarmKit identifier และสถานะที่จำเป็นลง persistence
- ตอน restore ทริป ให้ตรวจ alarm เดิมก่อนสร้างใหม่
- ป้องกัน alarm ซ้ำหลัง app relaunch
- กดหยุดจาก Notification, AlarmKit, Live Activity หรือในแอปแล้วต้องวิ่งเข้าจุด cleanup เดียวกัน
- cleanup ต้องยกเลิก:
  - location stream และ background activity session
  - pending/delivered notification ที่เกี่ยวข้อง
  - AlarmKit alarm ของทริป
  - Live Activity
  - active trip snapshot
- ทำ snooze contract ให้ชัดว่าเตือนซ้ำอย่างไร และเมื่อใดที่ proximity trigger จะไม่ยิงซ้ำ
- กู้คืน Auto-Stop countdown ให้ถูกต้องหลัง relaunch หรือจบทริปทันทีเมื่อเวลาผ่านไปแล้ว
- เพิ่ม state-transition tests สำหรับ restore, stop, snooze, arrived และ cleanup failure
- แยก lifecycle/alert orchestration ออกจาก `TripStore` หาก logic โตจนทดสอบยาก โดยยังคง SwiftUI MV และ dependency injection เดิม

Acceptance criteria:

- เปิดแอปใหม่ระหว่างทริปแล้วไม่สร้าง alarm หรือ Live Activity ซ้ำ
- หยุดจากทุก entry point แล้วไม่มี GPS, notification, AlarmKit หรือ Live Activity ค้าง
- Auto-Stop ทำงานถูกต้องแม้มี app relaunch
- persistence เสียหรืออ่านไม่ได้แล้วแอปยังมีทางออกที่ปลอดภัย
- state-transition tests ผ่านซ้ำได้

---

## Phase A3 — ทำ UX หลักให้ครบและพร้อมใช้งานจริง

เป้าหมาย: ผู้ใช้ครั้งแรกเริ่มทริปได้ เข้าใจ permission และแก้ปัญหาเองได้

แบ่งทำทีละช่วงสั้น ๆ ตามลำดับนี้:

### Phase A3.0 — วางระบบภาษาไทยและอังกฤษ

- เพิ่ม localization resources สำหรับ `th` และ `en`
- ย้ายข้อความที่ผู้ใช้มองเห็นออกจาก Swift code
- ใช้ภาษาของระบบอัตโนมัติ โดยยังไม่เพิ่มตัวเลือกภาษาใน Settings
- ตรวจข้อความหลักทั้งสองภาษาว่าไม่ล้นในหน้าจอเดิม

จบช่วงเมื่อ: เปลี่ยนภาษาเครื่องแล้ว flow หลักแสดงภาษาไทยหรืออังกฤษได้ครบ และ build/tests เดิมผ่าน

### Phase A3.1 — Onboarding แบบสั้น

- เพิ่ม onboarding ครั้งแรก 3 ขั้น: เลือกจุดหมาย, เลือกระยะเตือน และอธิบายสิทธิ์ที่จำเป็น
- แสดงเหตุผลของ Location, Notification และ AlarmKit ก่อน system prompt
- เพิ่มทางข้ามและทางกลับมาเปิดดูใหม่ โดยไม่รบกวนผู้ใช้เดิม

จบช่วงเมื่อ: ผู้ใช้ใหม่ผ่าน onboarding แล้วเข้าสู่หน้าหลักได้ ส่วนผู้ใช้เดิมไม่ถูกบังคับให้ดูซ้ำ

### Phase A3.2 — Permission และการแก้ปัญหา

- ปรับข้อความสรุปสถานะให้ตรงกับ permission และ OS จริง โดยไม่ใช้คำว่า “พร้อม” เป็น badge ทั่วไป
- แยกสถานะที่ใช้งานได้, ถูกปฏิเสธ, จำกัด และต้องไปแก้ใน Settings
- เพิ่มปุ่มเปิด Settings เฉพาะกรณีที่ผู้ใช้แก้จากในแอปไม่ได้

จบช่วงเมื่อ: ทุก permission state มีคำอธิบายและทางไปต่อที่ชัดเจนทั้งสองภาษา

### Phase A3.3 — Empty และ error states

- เพิ่มสถานะสำหรับ search ไม่พบ, geocoder ล้มเหลว, location unavailable และ network unavailable
- ให้ retry เฉพาะกรณีที่ลองใหม่แล้วมีประโยชน์
- ใช้ coordinate fallback เมื่อยังเลือกจุดหมายต่อได้

จบช่วงเมื่อ: ทุก failure หลักมีข้อความและ action ที่ไม่ทำให้ flow ตัน

### Phase A3.4 — Layout และหน้าจอหลายขนาด

- ตรวจ keyboard, ชื่อสถานที่ยาว และ bottom sheet ทุก detent
- ตรวจหน้าจอเล็กสุดที่รองรับและรุ่นที่มี Dynamic Island
- แก้ safe area, การตัดข้อความ และปุ่มที่ถูกบัง โดยไม่เปลี่ยน business logic

จบช่วงเมื่อ: flow หลักใช้งานได้ครบในหน้าจอเล็กและไม่มี control สำคัญถูกบัง

### Phase A3.5 — Accessibility และ motion

- ตรวจ Dynamic Type ขนาด accessibility
- เพิ่ม VoiceOver label, value และ action ให้ map controls, radius, Settings และ active trip
- ตรวจ Reduce Motion กับ startup, pin และ sheet transitions

จบช่วงเมื่อ: VoiceOver ทำ flow ตั้งแต่เลือกจุดหมายจนหยุดทริปได้ และ Reduce Motion ไม่ซ่อนข้อมูลสำคัญ

### Phase A3.6 — Visual QA และ release-facing UI

- ตรวจ Light/Dark Mode กับ Explore, Driving, Transit และ Satellite
- ปรับ contrast และชั้น material/glass ให้ข้อความอ่านได้ทุก map style
- ซ่อน developer tools จาก flow ปกติ และกำหนดวิธีเปิดสำหรับ App Review

จบช่วงเมื่อ: UI หลักอ่านได้ครบทุก theme/map style และไม่มีเครื่องมือทดสอบโผล่ใน flow ปกติ

Acceptance criteria:

- ผู้ใช้ใหม่เริ่มทริปได้โดยไม่ต้องเดาความหมายของ permission
- ไม่มีข้อความหรือปุ่มถูกตัดที่ Dynamic Type ขนาดใหญ่
- VoiceOver ทำ flow สำคัญได้ตั้งแต่เลือกจุดหมายจนหยุดทริป
- Reduce Motion ไม่เหลือ animation ที่จำเป็นต้องดูเพื่อเข้าใจสถานะ
- UI หลักอ่านได้ทุก map style และทั้ง Light/Dark Mode

---

## Phase A4 — เตรียม project สำหรับ production

เป้าหมาย: ตัว binary และข้อมูลประกอบภายในโปรเจกต์พร้อมสร้าง signed Archive

งาน:

- กำหนด Bundle Identifier จริงของแอป, Widget และ test target
- ตรวจ Apple Developer Team, certificates, provisioning profiles และ capabilities
- คง `MARKETING_VERSION` เป็น `0.x` ระหว่าง beta และเปลี่ยนเป็น `1.0` เมื่อผ่าน release gate พร้อมกำหนดแนวทางเพิ่ม build number
- เปลี่ยน `CFBundleURLName` จากค่า placeholder
- สร้าง App Icon 1024×1024 และ AppIcon asset ที่ครบ
- ปรับ `NSAlarmKitUsageDescription` ไม่ให้มีคำว่าทดสอบ
- ตรวจ Location usage description ให้ตรงกับ background behavior จริง
- เพิ่ม `PrivacyInfo.xcprivacy`
  - ประกาศ Required Reason API สำหรับ UserDefaults ด้วยเหตุผลที่ตรงกับการใช้งาน
  - ตรวจ privacy report จาก Archive
- แก้คำอธิบาย privacy จาก “ประมวลผลบนเครื่อง 100%” เป็นข้อความที่ตรงกว่า:
  - NapNav ไม่มีเซิร์ฟเวอร์ของตัวเอง
  - พิกัดทริปไม่ถูกส่งให้ผู้พัฒนา
  - การค้นหาสถานที่และแผนที่ใช้บริการระบบของ Apple
- ตรวจว่า Release build ไม่มี developer-only copy หรือปุ่มทดลองโผล่ใน flow ปกติ
- สร้าง signed Archive และตรวจ embedded Widget, Info.plist, entitlements และ privacy manifest

Acceptance criteria:

- ไม่มี `com.example.*` ใน production targets
- Archive ใช้ version/build number ที่ถูกต้อง
- App Icon แสดงครบใน Home Screen, Settings, Notification และ Spotlight
- permission copy ทุกข้อความเป็น production copy
- Archive privacy report ไม่มี Required Reason API ที่ไม่ได้ประกาศ
- signed Archive ผ่าน validation ขั้นต้นของ Xcode Organizer

---

## App Complete Gate

จะเริ่ม TestFlight ได้เมื่อทุกข้อด้านล่างผ่าน:

- [x] Full automated suite ผ่าน 3 รอบต่อเนื่อง
- [x] Alarm behavior table implement และทดสอบครบ
- [x] AlarmKit identifier และ Auto-Stop state กู้คืนหลัง relaunch ได้
- [x] Stop/cleanup ทุก entry point ผ่าน integration tests
- [ ] Onboarding และ permission recovery flow เสร็จ
- [ ] Dynamic Type, VoiceOver, Reduce Motion และ Light/Dark Mode ผ่าน
- [ ] App Icon, Bundle IDs, version, permission copy และ Privacy Manifest ครบ
- [ ] Signed Archive ผ่าน Xcode validation
- [ ] ไม่มี known issue ระดับ blocker หรือ critical

เมื่อ gate นี้ผ่าน ให้ติด tag ภายในว่า `v1.0-testflight-candidate` แล้วหยุดเพิ่มฟีเจอร์ใหม่ชั่วคราว

---

# ช่วง B — TestFlight และการพิสูจน์บนเครื่องจริง

## Phase B0 — Internal TestFlight

เป้าหมาย: ตรวจ installation, signing, extension และ upgrade path ก่อนเชิญผู้ใช้ภายนอก

งาน:

- สร้าง App Store Connect record
- อัปโหลด build จาก Archive ที่ผ่าน App Complete Gate
- ติดตั้งผ่าน TestFlight บน iPhone อย่างน้อย 2 รุ่น
- ตรวจ clean install และ update ทับ build ก่อนหน้า
- ตรวจ App Icon, permission prompts, Live Activity, Dynamic Island และ deep links
- เขียน App Review/Test Notes พร้อมวิธีเปิด developer diagnostics หากจำเป็น

Acceptance criteria:

- Build ผ่าน processing โดยไม่มี entitlement หรือ privacy warning
- ติดตั้ง เปิด และเริ่มทริปได้จาก TestFlight build
- Widget/Live Activity ถูกฝังและทำงานใน distribution build
- ไม่มี behavior ที่ทำงานเฉพาะตอนเปิดจาก Xcode

---

## Phase B1 — Physical-device reliability matrix

เป้าหมาย: พิสูจน์ product promise บนเครื่องจริงก่อนเปิด external beta

ทดสอบอย่างน้อย:

- foreground, background และ locked screen
- Notification บน iOS 18–25
- AlarmKit บน iOS 26+
- Silent mode และ Focus/Do Not Disturb
- ปิด sound, ปิด lock-screen notification และปฏิเสธ AlarmKit
- AirPods, Bluetooth audio และไม่มีอุปกรณ์เสียง
- ปิดแอปแล้วเปิดใหม่ระหว่างทริป
- หยุดจากในแอป, Notification และ Live Activity
- GPS หลุดและกลับมาใหม่
- MRT ใต้ดิน, BTS, รถเมล์ และรถยนต์อย่างน้อยอย่างละหนึ่งสถานการณ์ที่เกี่ยวข้อง
- เดินทาง 45–60 นาทีเพื่อวัดแบตเตอรี่และอุณหภูมิ

เก็บข้อมูลโดยไม่บันทึกตำแหน่งละเอียดเกินจำเป็น:

- เวลา trigger
- เวลา alert ปรากฏ
- วิธีเตือนที่ใช้และ fallback
- accuracy ตอน trigger
- app state และ permission state
- battery ก่อนและหลัง

Acceptance criteria:

- ไม่มี missed alert ในกรณีที่ permission และระบบพร้อม
- ไม่มี false arrival จาก GPS sample เดียวหรือ sample ที่ accuracy แย่
- stop trip แล้วไม่มี tracking หรือ alert ค้าง
- ระยะเวลาจาก trigger ถึง alert อยู่ในกรอบที่ยอมรับได้และบันทึกไว้
- battery drain อยู่ในระดับที่รับได้สำหรับแอปติดตามการเดินทาง

---

## Phase B2 — External beta

เป้าหมาย: ตรวจ usability และความน่าเชื่อถือกับผู้ใช้จริง 5–10 คน

งาน:

- เชิญผู้ที่ใช้ BTS, MRT หรือรถเมล์เป็นประจำ
- แจก test script สั้น ๆ และช่องรายงานปัญหา
- เก็บ feedback แยกเป็น:
  - missed/late/false alert
  - permission confusion
  - search/map usability
  - battery
  - Live Activity/Dynamic Island
- แก้เฉพาะ blocker, reliability และ usability ที่กระทบ flow หลัก
- ทุก build ใหม่ต้องย้อนผ่าน App Complete Gate ส่วนที่ได้รับผลกระทบ

Exit criteria:

- ไม่มี blocker หรือ critical issue เปิดอยู่
- ไม่มี missed alert ที่อธิบายไม่ได้ใน environment ที่รองรับ
- ผู้ทดสอบส่วนใหญ่เริ่มทริปและเข้าใจรูปแบบการเตือนได้เอง
- release candidate ผ่าน regression suite และ physical-device smoke test

---

## Phase B3 — เตรียมส่ง App Store

งาน:

- ทำ Privacy Policy และ Support URL
- กรอก App Privacy ให้ตรงกับพฤติกรรมจริงของแอป
- เตรียมชื่อ, subtitle, description, keywords, categories และ age rating
- ถ่าย screenshots จาก release candidate จริง:
  1. เลือกจุดหมาย
  2. เลือกระยะเตือน
  3. Active Trip
  4. Live Activity/Dynamic Island
  5. Settings และรูปแบบการเตือน
- เขียน Review Notes พร้อมขั้นตอนทดสอบ location-triggered behavior
- ตรวจ export compliance, content rights และข้อมูลติดต่อ
- สร้าง final Archive จาก source revision เดียวกับที่ผ่าน QA

Release criteria:

- Metadata และ screenshots ตรงกับ release candidate
- Privacy Policy, App Privacy และ privacy manifest ให้ข้อมูลสอดคล้องกัน
- Reviewer สามารถทดสอบฟังก์ชันหลักได้โดยไม่ต้องเดาขั้นตอน
- final build ผ่าน regression และ physical-device smoke test

---

## 3. ลำดับทำงานจริง

1. Phase A0 — ทำ tests ให้เขียวและตรวจซ้ำได้
2. Phase A1 — ปิด contract ของ Notification/AlarmKit/Sound/Vibrate/Both
3. Phase A2 — แก้ lifecycle, persistence และ cleanup
4. Phase A3 — ปิด UX, onboarding และ accessibility
5. Phase A4 — ปิด production config, privacy, icon และ signed Archive
6. ผ่าน App Complete Gate และ freeze ฟีเจอร์
7. Phase B0 — Internal TestFlight
8. Phase B1 — ทดสอบบนเครื่องจริงและเส้นทางจริง
9. Phase B2 — External beta
10. Phase B3 — เตรียมและส่ง App Store

งานพัฒนาถัดไปคือ **Phase A3**: onboarding, permission recovery และ accessibility/UI matrix ก่อนเข้าสู่ production configuration ใน Phase A4
