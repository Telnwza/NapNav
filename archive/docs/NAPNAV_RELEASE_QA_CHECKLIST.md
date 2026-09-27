# NapNav — Integration QA และ Release Gate

อัปเดตล่าสุด: 21 กันยายน 2026

เอกสารนี้แยกหลักฐาน automated QA ออกจากการทดสอบบน iPhone จริง เพื่อไม่ให้ผลจาก Simulator ถูกตีความว่าเป็นหลักฐานเรื่องเสียง, Silent/Focus หรือ background/locked screen

## Automated gate

หลักฐานล่าสุดหลังแก้ Phase A0 เมื่อ 21 กันยายน 2026: core 44/44, GPX 3/3, full suite 47/47 ผ่าน 3 รอบต่อเนื่อง และ generic iOS Release build แบบไม่เซ็นผ่าน บน Xcode 27.0, SDK 27.0 และ iPhone 18 Pro Simulator (iOS 27.0) ผล test ยืนยันจาก `summary.json` ที่อ่านออกจาก `.xcresult` ไม่ได้อาศัยข้อความท้าย console อย่างเดียว

Phase A1 เพิ่ม automated coverage สำหรับ Delivery Mode × Sound Mode, iOS/AlarmKit capability, permission fallback, silent delivery, Both แบบไม่เกิดเสียงซ้อน และ fallback failure รวมเป็น core 54 tests / full 57 tests รายละเอียดสัญญาอยู่ใน `NAPNAV_ALERT_BEHAVIOR_TABLE.md`

Phase A2 เพิ่ม snapshot lifecycle ที่ backward-compatible, AlarmKit identifier reconciliation, AlarmKit stop-intent bridge, unified cleanup, snooze state, Auto-Stop restore/expiry, cleanup failure และ corrupt-snapshot cleanup coverage รวมเป็น core 66 tests / full 69 tests โดย full suite ผ่าน 3 รอบต่อเนื่อง

### คำสั่งมาตรฐาน Phase A0

รันจากโฟลเดอร์รากของโปรเจกต์ ผลแต่ละรอบจะอยู่ใน `.a0-results/` พร้อม `environment.txt`, `xcodebuild.log`, `.xcresult` และ `summary.json`

```bash
./Scripts/phase-a0.sh release-build
./Scripts/phase-a0.sh test-core
./Scripts/phase-a0.sh test-gpx
./Scripts/phase-a0.sh test-full
./Scripts/phase-a0.sh test-full-3
```

ค่าเริ่มต้นของ Simulator คือ `iPhone 18 Pro` บน iOS 27.0 หากเครื่องอื่นใช้ชื่อหรือ OS ต่างกัน ให้กำหนด `NAPNAV_DESTINATION` โดยยังต้องบันทึกค่าเดียวกันตลอดชุด 3 รอบ

```bash
NAPNAV_DESTINATION='platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' \
  ./Scripts/phase-a0.sh test-full-3
```

ถ้า Xcode ค้างที่ `Finalize test log` ให้เปิด Terminal อีกหน้าต่างและอ่านผลจาก bundle ที่ runner สร้างไว้ แทนการตีความว่าเป็น test failure ทันที:

```bash
./Scripts/phase-a0.sh summary .a0-results/<run>/tests.xcresult
```

ให้ถือว่ารอบนั้นผ่านได้ต่อเมื่อ `summary.json` หรือคำสั่งด้านบนรายงาน `result: Passed`, `failedTests: 0` และ `totalTestCount` ตรงกับชุดที่สั่งรัน ถ้ายังไม่มี summary ที่อ่านได้ ให้เก็บ `xcodebuild.log` และนับเป็น runner/infrastructure issue ไม่ใช่ผลผ่าน

runner ใช้ `/tmp/NapNav-A0-DerivedData` เป็นค่าเริ่มต้น เพราะการวาง build database ไว้ใต้โฟลเดอร์ Documents เคยทำให้ Xcode รายงาน `build.db: disk I/O error` ก่อนเริ่ม tests ขณะที่เก็บ log, metadata และ `.xcresult` ไว้ใน `.a0-results/` ตามเดิม เปลี่ยนตำแหน่งได้ด้วย `NAPNAV_DERIVED_DATA` หากจำเป็น

ผลรอบที่ใช้ปิด gate:

- Core: `.a0-results/20260921-150450-core/summary.json` — 44 ผ่าน, 0 ล้ม
- GPX: `.a0-results/20260921-150518-gpx/summary.json` — 3 ผ่าน, 0 ล้ม
- Full 1: `.a0-results/20260921-150558-full-1/summary.json` — 47 ผ่าน, 0 ล้ม
- Full 2: `.a0-results/20260921-150604-full-2/summary.json` — 47 ผ่าน, 0 ล้ม
- Full 3: `.a0-results/20260921-150608-full-3/summary.json` — 47 ผ่าน, 0 ล้ม
- Release: `.a0-results/20260921-150624-release-build/xcodebuild.log` — `BUILD SUCCEEDED`
- A1 Core: `.a0-results/20260921-152336-core/summary.json` — 54 ผ่าน, 0 ล้ม
- A1 Full: `.a0-results/20260921-152434-full/summary.json` — 57 ผ่าน, 0 ล้ม
- A1 Release: `.a0-results/20260921-152527-release-build/xcodebuild.log` — `BUILD SUCCEEDED`
- A2 Core: `.a0-results/20260921-203959-core/summary.json` — 66 ผ่าน, 0 ล้ม
- A2 Full 1: `.a0-results/20260921-203919-full-1/summary.json` — 69 ผ่าน, 0 ล้ม
- A2 Full 2: `.a0-results/20260921-203937-full-2/summary.json` — 69 ผ่าน, 0 ล้ม
- A2 Full 3: `.a0-results/20260921-203941-full-3/summary.json` — 69 ผ่าน, 0 ล้ม
- A2 Release: `.a0-results/20260921-204011-release-build/xcodebuild.log` — `BUILD SUCCEEDED`

### Phase A0 gate

- [x] มี baseline ก่อนแก้: full suite 47/47 ผ่าน 1 รอบ
- [x] ไม่มี test ที่ใช้ `Task.yield()` หรือ `Task.sleep()` รอ async state
- [x] มีคำสั่งมาตรฐานสำหรับ Release build, core, GPX และ full suite
- [x] มี `.xcresult`, log และ metadata ของ Xcode/SDK/Simulator ต่อรอบ
- [x] Core suite หลังแก้ผ่าน 44/44
- [x] GPX targeted suite หลังแก้ผ่าน 3/3
- [x] Full suite หลังแก้ผ่าน 47/47 จำนวน 3 รอบต่อเนื่อง
- [x] Release build แบบไม่เซ็นผ่านหลังแก้

- [x] Trigger นอกเขตไม่ยิงเตือน
- [x] Trigger ต้องได้ sample ในเขตต่อเนื่อง 2 ครั้ง
- [x] Alert radius ยิงเพียงครั้งเดียว
- [x] Arrival threshold 20 เมตรแยกจาก alert radius
- [x] Arrival ต้องได้ sample คุณภาพดีต่อเนื่อง 2 ครั้ง
- [x] stale, inaccurate และ GPS bounce ไม่ทำให้ arrived ผิดพลาด
- [x] arrived แล้วสถานะไม่ย้อนกลับ
- [x] หยุดทริปแล้วหยุด location stream และยกเลิก alert ของทริป
- [x] กู้คืน active trip จาก persistence ได้
- [x] persistence failure มี recovery UI
- [x] notification ปิดแต่ AlarmKit พร้อมยังถือว่ามี alert path
- [x] GPX เข้าเขตยิงเตือนหนึ่งครั้งและจบด้วย arrival
- [x] GPX ผ่านนอกเขตไม่ยิงเตือน
- [x] GPX กระโดดเข้าเขตครั้งเดียวไม่ยิงเตือน

### Phase A1 gate

- [x] มี behavior table ครบ 8 คู่ของ Delivery Mode × Sound Mode
- [x] iOS ที่ไม่รองรับซ่อน AlarmKit และ Both พร้อมรองรับค่าที่เคยบันทึกด้วย fallback
- [x] โหมดไม่มีเสียงไม่เรียก AlarmKit และไม่รับประกันการสั่น
- [x] Both ใช้ AlarmKit เป็นเสียงหลักและ Notification แบบไม่มีเสียง
- [x] แยกผล alarm scheduled, notification path, fallback used และ delivery unavailable
- [x] fallback failure ไม่ถูกนับว่า alert ส่งสำเร็จ
- [x] Settings แสดงเส้นทางจริงล่วงหน้าและมีปุ่มเปิด Settings เมื่อ fallback/unavailable
- [x] Core suite หลัง A1 ผ่าน 54/54
- [x] Full suite หลัง A1 ผ่าน 57/57
- [x] Release build แบบไม่เซ็นผ่านหลัง A1

### Phase A2 gate

- [x] Snapshot เก็บ trip ID, phase, alert flags, AlarmKit ID, snooze และ Auto-Stop deadline
- [x] Snapshot รุ่นเก่า decode ได้โดยมี safe defaults
- [x] Restore ตรวจ AlarmKit ID เดิมและไม่ schedule alarm ซ้ำ
- [x] AlarmKit ที่ถูกหยุดระหว่าง app ไม่ทำงานถูก reconcile และ cleanup ตอนเปิดใหม่
- [x] ปุ่มหยุดในแอป, Notification, Live Activity URL และ AlarmKit stop intent เข้าสู่ cleanup เดียว
- [x] Cleanup หยุด location/background session, notification, AlarmKit, Live Activity และ snapshot
- [x] Snooze ไม่เปิด proximity trigger ให้ยิงซ้ำ
- [x] Auto-Stop countdown กู้คืนได้ และทริปที่เลย deadline ถูกจบทันที
- [x] Persistence ที่เสียหายมีปุ่มล้างข้อมูลทริปเดิม
- [x] Core suite หลัง A2 ผ่าน 66/66
- [x] Full suite หลัง A2 ผ่าน 69/69 จำนวน 3 รอบต่อเนื่อง
- [x] Release build แบบไม่เซ็นผ่านหลัง A2

## UI checkpoint

- [x] ผู้ใช้ยืนยัน flow เลือกจุดหมาย, ค้นหา, ลากหมุด, เลือกระยะ และ active trip รอบล่าสุด
- [x] Map controls, เข็มทิศ, map style และ current-location control ผ่านการตรวจรอบล่าสุด
- [x] Dynamic Island/safe area, bottom sheet และ stop confirmation ผ่านการแก้ตาม feedback
- [ ] ตรวจ Dynamic Type ขนาด accessibility ให้ครบ
- [ ] ตรวจ Reduce Motion บนเครื่องจริง
- [ ] ตรวจ Light/Dark Mode กับ map style ทุกแบบ

## Physical-device gate

- [ ] Notification ปกติขณะ foreground
- [ ] Notification ปกติขณะ background
- [ ] Notification ปกติขณะล็อกหน้าจอ
- [ ] AlarmKit ขณะ foreground บน iOS 26+
- [ ] AlarmKit ขณะ background บน iOS 26+
- [ ] AlarmKit ขณะล็อกหน้าจอบน iOS 26+
- [ ] Silent mode
- [ ] Focus mode
- [ ] ปิดเสียง notification
- [ ] ปฏิเสธ AlarmKit แล้ว fallback เป็น notification
- [ ] หยุดทริปแล้วไม่มี notification หรือ AlarmKit ค้าง
- [ ] ปิดและเปิดแอปใหม่ระหว่างทริปแล้ว recovery ถูกต้อง
- [ ] ทดสอบเดินทางจริงอย่างน้อยหนึ่งเส้นทาง พร้อมบันทึกเวลาที่ trigger และเวลาที่ alert แสดง

## Release decision

ยังไม่ปิด release gate จนกว่า physical-device gate ที่เกี่ยวกับ background, locked screen, AlarmKit, Silent และ Focus จะมีผลจาก iPhone จริง
