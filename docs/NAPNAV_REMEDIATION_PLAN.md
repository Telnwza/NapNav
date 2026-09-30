# NapNav — แผนแก้โค้ดหลัง audit

อัปเดต: 30 กันยายน 2026
สถานะ: A0-R/A1-R/A2-R ผ่าน automated gates. S1 เปลี่ยน `stop-trip` เป็น confirmation แล้ว แต่ยังค้าง manual iPhone check และทบทวน `stop-alarm` ที่ยังสั่งหยุดตรง. A3 slices 1–3 ผ่าน automated work บน snapshots ก่อนหน้า; slice 4 และ visual/accessibility audition ยังเปิด. A4/device/release gates ยังเปิด; copy ล่าสุดใน `db7937f` ยังไม่ได้รัน tests/build ซ้ำ

## เป้าหมายและขอบเขต

สัญญาหลักของ v1.0 คือเลือกจุดหมาย เริ่มทริป ล็อกจอ แล้วได้รับการเตือนเมื่อเข้าเขต
ที่เลือก แผนนี้ปิดช่องว่างด้านความน่าเชื่อถือก่อนเพิ่มงาน UX และเตรียม TestFlight
รักษา SwiftUI MV, dependency injection, map-first flow และหมุดคงที่กลางจอ
ไม่เพิ่ม Favorite, transit data, dynamic radius, backend หรือ Critical Alerts ในรอบนี้

เอกสารนี้ต่อจาก `archive/docs/NAPNAV_STORE_RELEASE_ROADMAP.md` โดยเปิด A1/A2
กลับมาตรวจใหม่ A0/A1/A2 ที่เอกสารเดิมทำเครื่องหมายผ่าน หมายถึงเคยผ่าน automated
gate ของ snapshot ก่อนหน้า ไม่ใช่ผลยืนยันของ source ปัจจุบัน

งานแก้โค้ดที่ส่งต่อให้ Luna แตกเป็น ticket พร้อมไฟล์ที่ต้องอ่าน, test ที่ต้องเพิ่ม,
dependency และเกณฑ์หยุดใน `docs/LUNA_CODE_FIX_TICKETS.md` ให้เลือกทำครั้งละหนึ่ง
ticket ไม่ข้ามจุดที่รอการตัดสินใจของผู้ใช้ และบันทึกผลใน
`docs/DEVELOPMENT_REPORT.md` ระหว่างทำงาน

## ทำไมต้องเปลี่ยนลำดับเดิม

| แผนเดิม | ผล audit และการปรับแผน |
| --- | --- |
| A0 ผ่านแล้ว | **baseline ณ audit แรก:** Git ยังไม่มี commit และไฟล์โปรเจกต์เป็น untracked; จึงสร้าง baseline ที่ระบุ source/toolchain/log ก่อน. Repository ปัจจุบันมี history แล้ว |
| A1 ผ่านแล้ว | `TripStore` ตั้ง `alertTriggered` ก่อนรู้ผลส่ง; ถ้าส่งไม่สำเร็จ trigger policy ไม่ลองใหม่ จึงเปิด A1-R |
| A2 ผ่านแล้ว | async result อาจบันทึกทริปที่หยุดไปแล้ว; AlarmKit cancellation กลืน error; Auto-Stop อาจจบก่อน deadline จึงเปิด A2-R |
| เริ่ม A3 ต่อทันที | ปิด A1-R/A2-R และ device smoke test ของเส้นทางเตือนก่อน แล้วค่อยเดิน A3 |
| B1 หลัง TestFlight | ทดสอบ foreground/background/locked บน development-signed iPhone ตั้งแต่หลังแก้ core; full matrix ยังอยู่ก่อน external beta |

## ลำดับงานและเกณฑ์จบ

### A0-R — baseline ที่ตรวจซ้ำได้ (ผ่าน automated gate)

- ตรวจ source tree, Git state, Xcode/SDK/Simulator และสคริปต์ `Scripts/phase-a0.sh`
- เก็บ source fingerprint หรือ commit ที่ระบุ snapshot ได้ โดยไม่ commit/push แทนผู้ใช้
- รัน generic iOS Release build, core/GPX/full tests และอ่านผลจาก `.xcresult`
- แยก failure ของ Xcode macro plugin/CoreSimulator ออกจาก compiler/test failure
- บันทึกคำสั่ง, exit code, environment และตำแหน่ง artifacts ในรายงาน

จบเมื่อ: build ผ่าน, full suite ผ่าน 3 รอบพร้อม summary ที่อ่านได้ และ source
snapshot ตรงกันทุกผล ถ้าเครื่องมือยังเสีย ให้คงสถานะติดขัดพร้อมหลักฐาน ห้ามเริ่ม
อ้างว่า A0-R ผ่าน

ผลรอบนี้: Release build ผ่าน, full 78/78 สามรอบ, core 75/75 และ GPX 3/3
บน source fingerprint เดียวกัน รายละเอียดและ artifacts อยู่ใน
`docs/DEVELOPMENT_REPORT.md` ผลนี้ยังไม่พิสูจน์ behavior บน iPhone จริง

### A1-R — ส่งเตือนให้สำเร็จหรือบอกตรง ๆ ว่าทำไม่ได้ (ผ่าน automated gate; device gate ยังเปิด)

- ใน `TripStore.swift` และ `TriggerPolicy.swift` แยก proximity detected,
  delivery in-flight, delivered และ unavailable ออกจากกัน
- เมื่อ scheduling ล้มเหลวหรือ permission กลับมาพร้อมขณะยังอยู่ในเขต ให้มีทาง
  retry ที่จำกัดและไม่ยิงซ้ำหลังสำเร็จ
- A1-D ตัดสินแล้ว 23 ก.ย. 2026: ไม่เริ่ม “Trip Alarm” ถ้าไม่มี alert path;
  เปิด Alert Settings พร้อมเหตุผล/ทางไป iPhone Settings และไม่เริ่ม tracking-only
- เพิ่ม Swift Testing สำหรับ unavailable → available, schedule failure,
  fallback, repeated samples และ no-duplicate หลังส่งสำเร็จ

ความคืบหน้า 23 ก.ย. 2026: ticket A1.1 ผ่าน automated checks บน fingerprint
`7100471a0a287846e94482c9798108f4065597734eaa84b3bbf794a676972fbd`
(AlertSettings 23/23, full Simulator suite 85/85, unsigned Release build ผ่าน);
retry ใช้ backoff 10/20/40 วินาทีและจำกัดสูงสุด 60 วินาที พร้อม retry ต่อระหว่าง
ทริปที่ยัง active. ต่อมา A1-D ถูกตัดสินและนำไปใช้: start gate บล็อกก่อนขอ
location permission/เปลี่ยน trip state เมื่อไม่มี delivery path; ถ้า path หาย
หลัง valid start ทริปเดินต่อและใช้ retry ของ A1.1. A1.2 ตรวจ delivery matrix
และเพิ่ม no-path/fallback-copy/start-gate tests. A1-D, A1.2 และ A1-R ผ่าน
automated gate 23 ก.ย. 2026 บน fingerprint `629d9d13d84cb76385f2073f939a6f50ba6ade073f0b45463e697c0fb1f2e4f6`:
targeted 39/39, full Simulator 88/88 สามรอบต่อเนื่อง (รวม GPX routes) และ
unsigned generic iOS Release build ผ่าน; artifacts อยู่ใน
`docs/DEVELOPMENT_REPORT.md`. ยังไม่มีการยืนยัน alert บน iPhone จริง; เสียง,
Silent/Focus, locked screen และ background คงเป็น device gate ใน A4.

เกณฑ์ automated จบเมื่อ: behavior ตรง
`archive/docs/NAPNAV_ALERT_BEHAVIOR_TABLE.md`, tests ผ่าน และ GPX route ที่
เกี่ยวข้องไม่ถอยหลัง — ผ่าน 23 ก.ย. 2026 บน fingerprint
`629d9d13d84cb76385f2073f939a6f50ba6ade073f0b45463e697c0fb1f2e4f6` ด้วย
targeted 39/39, full Simulator 88/88 สามรอบต่อเนื่อง และ unsigned Release build.
หลักฐานอยู่ใน `docs/DEVELOPMENT_REPORT.md`. เสียง/notification จริง, Silent/Focus,
locked screen และ background ยังไม่ผ่านการยืนยันบน iPhone; เป็น A4 device gate.
`A2.1` ผ่าน automated gate วันที่ 23 ก.ย. 2026 บน source fingerprint
`6232d8f96775bbf82bf71a531a5a59aeb8cf5dc23280091b3a59ceda34b38a83`:
focused StartupRecovery 21/21, TripStore 13/13, full Simulator 95/95 และ
unsigned generic iOS Release build ผ่าน. ต่อมา `A2.2` ผ่าน automated gate บน
fingerprint `b9b155de2bc3fca9a9addde564e642346a95ce6d070a804f3e5284f53d936551`:
targeted 48/48, full iOS 27.0 Simulator 103/103 และ unsigned generic iOS
Release build ผ่าน; test/build source manifests ตรงกัน. Cancellation failure
เก็บ ID ไว้ retry และมี health/UI warning; ผล mocks/Simulator ยังไม่ใช่หลักฐาน
AlarmKit จริงบน iPhone. A2.3 เสร็จ 25 ก.ย. 2026 และปิด automated A2-R gate บน
fingerprint `d661bde929f6b7bab9f1922d939f3104f913ddead4dc4ae7274b7b16b65317d3`:
targeted 44/44, full iOS 27.0 Simulator 105/105 สามรอบต่อเนื่อง และ unsigned
generic iOS Release build ผ่าน; test/build manifests ตรงกัน. หลักฐาน native
alert และเวลา Auto-Stop ขณะ iOS พักยังเป็น A4/device gate. คำสั่งและ artifacts
อยู่ใน `docs/DEVELOPMENT_REPORT.md`.

### A2-R — lifecycle, cleanup และ Auto-Stop

- ใช้ trip ID/generation guard หลังทุก `await` ที่อาจกลับมาหลัง Stop/new trip
  ห้าม `persistActiveTrip()` สร้าง ID ให้ทริปที่จบแล้ว
- ทำ cancellation result ของ Notification/AlarmKit ให้ตรวจได้ เก็บ ID ที่ยกเลิก
  ไม่สำเร็จไว้ reconcile ตอนเปิดแอปใหม่
- คุม Auto-Stop ด้วย absolute deadline; background-task expiration ห้ามปิดทริป
  ก่อนเวลา กู้ deadline ตอน relaunch และระบุข้อจำกัดเมื่อ process ถูกพัก/ยุติ
- เพิ่ม tests ที่พัก async mock แล้ว Stop/restart, throw ตอน cancel, timer ก่อน/
  ตรง/หลัง deadline และ relaunch ระหว่าง countdown

**สถานะ:** automated A2-R gate ผ่านแล้ว (A2.1–A2.3, cancellation recovery,
timer/recovery regression tests, full suite 3 รอบ และ unsigned Release build).
ผล Simulator ยังไม่ยืนยันเสียง/AlarmKit/locked screen/background timing บน iPhone;
เก็บสิ่งเหล่านี้ไว้ใน A4/device gate.

จบ automated gate เมื่อไม่มี snapshot ฟื้นคืนหลัง Stop, cleanup failure กู้คืนได้,
ไม่ Auto-Stop ก่อน absolute deadline และ timer tests ยืนยัน state จริงโดยไม่ใช้
การจบทริปด้วยมือแทนการทดสอบ timer — ผ่านบน fingerprint ข้างต้น.

### Security gate — คำสั่งหยุดทริปจากภายนอก

- **ทำแล้วบน automated snapshot 25 ก.ย.:** `napnav://stop-trip` เปิด confirmation ที่ผูกกับ trip UUID; Live Activity Stop/Finish ใช้ confirmation เดียวกัน. Targeted/full Simulator และ unsigned Release build ผ่านตาม `docs/DEVELOPMENT_REPORT.md` รายการ S1
- **ยังเปิด:** `napnav://stop-alarm` ซึ่งใช้โดย Siri shortcut ยังเรียก `handleStopAlarm()` โดยตรง; ตัดสินใจ/ตรวจ guard สำหรับ public custom URL โดยไม่ทำให้ Siri action ที่ผู้ใช้สั่งเองเสียไป
- **ยังเปิด:** manual check บน iPhone สำหรับ Live Activity, cold launch/recovery และการเรียก URL จากแอปอื่น

จบเมื่อ: public URL ไม่หยุดทริปโดยไร้การยืนยัน, Siri/Live Activity ยังทำงานตามข้อตกลง, และ iPhone checks ผ่าน

### A3 — UX, ภาษา และ accessibility

- ตรวจ permission/recovery, search/geocode error, ภาษาไทย/อังกฤษ และ onboarding
- ตรวจ Dynamic Type, VoiceOver, Reduce Motion, Light/Dark และทุก map style
- ย้าย animation decision ที่ยังบังคับ `reduceMotion: false` ออกจาก `TripStore`
- QA งานที่มีแล้ว เช่น safe area, เข็มทิศ, search distance, center pin และ
  Liquid Glass; ไม่เขียน flow ใหม่ถ้าไม่มี regression

ความคืบหน้า ณ 30 ก.ย. 2026: A3 slice 1 (permission/recovery, localization และ
search empty/error states) ผ่าน source/static checks, focused tests 41/41,
full Simulator suite 116/116 และ unsigned generic iOS Release build บน source
fingerprint `78873af69af8de03878c7b4cbc8c2463d51ede7de256b4496965c9cfb5ca709e`.
Slices 2–3 (Dynamic Type/VoiceOver labels และ Reduce Motion) มี implementation
และ automated test 127/127 ใน Simulator บน snapshot 26 ก.ย. ตามรายงานด้านล่าง.
หลังจากนั้นมีการแก้ localization/metadata copy; commit ปัจจุบัน `db7937f` ยังไม่มี
ผล test/build ใหม่หลังการคืนคำโปรยล่าสุด. Slice 4 (Light/Dark และ map styles),
visual/VoiceOver audition และ iPhone จริงยังเปิด; A3 phase ยังไม่ปิด.
ภาพ iPhone ของผู้ใช้แสดง English title บน AlarmKit alert ถูกย่อและตัดท้าย;
รอบ 21:25 ย่อข้อความเป็น `Almost there` แต่ยังต้องตรวจหน้าจอจริงหลังติดตั้ง build ใหม่.
รอบเดียวกันแก้ปุ่ม X ของ AlarmKit ที่เคยเรียก `stopTrip()` ผ่าน `stopIntent`:
ปล่อยให้ระบบหยุดเฉพาะ alarm และแก้ recovery ไม่ลบ snapshot เมื่อ alarm
ที่ถูกปิดหายจากระบบ เพื่อให้การติดตามทริปดำเนินต่อถึง arrival แม้เปิดแอปใหม่.
Recovery targeted 26/26, full Simulator suite 116/116 และ unsigned Release
build ผ่านบน fingerprint สุดท้าย
`cb18b5637686d72e152045a4f536facb0fe71ff281f1b93418bfe08d9717a2c1`;
ยังต้องยืนยันเสียง, X, GPS และ Live Activity บน iPhone จริง.
รายละเอียดและ artifact path อยู่ใน `docs/DEVELOPMENT_REPORT.md` รายการ
`2026-09-25 21:25 — A3: ปิดเสียง AlarmKit แล้วทริปต้องเดินต่อ`.

จบเมื่อ: flow เลือกจุดหมายถึงหยุดทริปทำได้ด้วย VoiceOver และหน้าจอ/ข้อความ
อ่านได้ในขนาดตัวอักษรและธีมที่รองรับ โดยยืนยันด้วย visual/accessibility audition
บนอุปกรณ์ ไม่ใช่ automated test เพียงอย่างเดียว

### A4 → device gate → TestFlight

ความคืบหน้า 30 ก.ย. 2026: App Icon ถูกติดตั้งใน asset catalog แล้ว (รายการ
26 ก.ย. ใน `docs/DEVELOPMENT_REPORT.md`); unsigned Release build ตรวจ local Bundle
IDs, privacy manifest และ settings ได้ใน audit 30 ก.ย. แต่ยังไม่มี signed Archive,
processed upload, metadata/live URL confirmation หรือ physical-iPhone evidence.
สถานะ A4 จึงยังเปิดอยู่

- ยืนยัน Bundle IDs, App Icon, URL name, permission copy, privacy manifest,
  developer-tool policy และ signed Archive ตาม release roadmap
- ทดสอบ Notification บน iOS 18 path และ AlarmKit บน iOS 26+ path บน iPhone จริง
  ทั้ง foreground, background, locked, Silent, Focus, denied permission,
  stop/relaunch และเดินทางจริง พร้อมเวลา trigger/เวลา alert
- ผ่าน App Complete Gate ก่อน Internal TestFlight; ไม่ใช้ Simulator แทน device gate

## ประเด็นที่ตัดสินแล้วและขอบเขตหลักฐานที่ยังค้าง

1. A1-D — ตัดสินแล้ว 23 ก.ย. 2026: เมื่อไม่มี alert path ให้บล็อกการเริ่ม
   Trip Alarm และเปิด Alert Settings พร้อมเหตุผล/ทางไป iPhone Settings; ไม่เสนอ
   tracking-only แบบเงียบ
2. Startup — ตัดสินล่าสุด 26 ก.ย. 2026 ตามคำสั่งผู้ใช้: ใช้ iOS Native Launch
   Screen ที่มีโลโก้/ข้อความเพียงหน้าเดียว แล้วเข้าหน้าหลักทันที; ไม่มี SwiftUI
   loading screen หรือ developer override ซ้ำ. แสดง overlay เฉพาะ recovery/error
   ที่ต้องให้ผู้ใช้ตัดสินใจหรือแก้ปัญหาเท่านั้น.
3. Auto-Stop — สัญญา v1.0 คือไม่จบทริปก่อน absolute deadline; หาก iOS พักหรือยุติ
   process การจบอาจล่าช้าจนแอปกลับมาทำงาน. ยังไม่สัญญาว่าจะจบตรงเวลาจนกว่าจะมีผล
   วัดบน iPhone จริงใน A4/device gate.

หมุดป้ายรถเมล์รูปแบบใหม่ยังเป็นงานออกแบบต่างหาก ต้องเสนอทิศทางให้ผู้ใช้ดูก่อน
ลงโค้ด และ transit data ไม่อยู่ใน v1.0

## เอกสารและรายงาน

- แผนเดิม: `archive/docs/NAPNAV_STORE_RELEASE_ROADMAP.md`
- สัญญา alert: `archive/docs/NAPNAV_ALERT_BEHAVIOR_TABLE.md`
- QA เดิม: `archive/docs/NAPNAV_RELEASE_QA_CHECKLIST.md`
- รายงานงานปัจจุบันและงานถัดไป: `docs/DEVELOPMENT_REPORT.md`
- ข้อปฏิบัติของ agent: `AGENTS.md`
- งานย่อยสำหรับ Luna: `docs/LUNA_CODE_FIX_TICKETS.md`
