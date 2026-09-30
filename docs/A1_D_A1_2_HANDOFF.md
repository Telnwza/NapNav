# NapNav — A1-D / A1.2 handoff

อัปเดต: 23 กันยายน 2026  
สถานะ: เสร็จสำหรับ automated gate; A1-R ปิดในขอบเขต automated verification แล้ว

> **เอกสาร handoff ตามเวลา (superseded):** ส่วน “งานถัดไป” เดิมชี้ไป A2.1 ซึ่งทำเสร็จแล้วพร้อม A2.2/A2.3. สถานะงานปัจจุบันและ device/release gates ให้อ่าน `docs/NAPNAV_REMEDIATION_PLAN.md` กับรายการล่าสุดใน `docs/DEVELOPMENT_REPORT.md`; การทดสอบบน iPhone สำหรับ A1 ยังไม่ยืนยัน

## การตัดสินใจและ contract

ผู้ใช้เลือกข้อ 1: ถ้าไม่มี delivery path ที่พร้อม ห้ามเริ่ม **Trip Alarm** และ
เปิด Alert Settings พร้อมเหตุผลและปุ่มไป iPhone Settings; ไม่เริ่ม tracking-only
แบบเงียบ

`TripStore.startTrip()` ขอ Notification authorization เป็น baseline และขอ
AlarmKit authorization เฉพาะเมื่อ preference ที่เลือกต้องใช้ จากนั้น refresh
readiness ก่อนตรวจ `alertDeliveryPlan.isAvailable` ถ้าไม่มี path จะคงหน้า setup,
ตั้ง unavailable health, เปิด Alert Settings และ return ก่อนขอ location permission
หรือเปลี่ยน trip state/สร้าง snapshot/เริ่ม Live Activity/GPS ถ้ามี path อย่างน้อย
หนึ่งทาง (เช่น AlarmKit พร้อมแม้ Notification ไม่พร้อม) เริ่มทริปได้ตาม matrix
เดิม หาก path หายหลัง valid start ทริปเดินต่อและ A1.1 retry/backoff ทำงานเมื่อ
readiness กลับมา

## การเปลี่ยนแปลงที่ทำแล้ว

- `NapNav/TripStore.swift`: start gate ก่อน location permission และ trip-state
  mutation; unavailable แสดง Alert Settings และไม่เริ่ม resource ของทริป
- `NapNav/DomainModels.swift`: fallback ไป Notification ที่ระบบปิดเสียง
  รวม muted-system explanation ใน summary
- `NapNavTests/AlertSettingsTests.swift`: no-path matrix 4 delivery modes ×
  2 sound modes, blocked start/recovery, AlarmKit-only start, muted fallback
  copy และ readiness/path recovery
- `NapNavTests/TripStoreTests.swift`: regression coverage ว่า AlarmKit-only
  ที่ Notification denied ยังเริ่มทริปและขอ location ตามปกติ
- `archive/docs/NAPNAV_ALERT_BEHAVIOR_TABLE.md`, `docs/NAPNAV_REMEDIATION_PLAN.md`,
  `docs/LUNA_CODE_FIX_TICKETS.md`, `docs/DEVELOPMENT_REPORT.md`: contract,
  decision, status และหลักฐานล่าสุด

ไม่มีการแก้ `SystemClients.swift` หรือ UI implementation; reused Alert Settings
sheet และ iPhone Settings link ที่มีอยู่แล้ว.

## Automated evidence

Source fingerprint ของโค้ดที่ทดสอบ:  
`629d9d13d84cb76385f2073f939a6f50ba6ade073f0b45463e697c0fb1f2e4f6`

- `AlertSettingsTests`: 26/26 ผ่าน; `.xcresult`
  `/tmp/NapNav-A1-2-targeted-20260923-1110.xcresult`
- `TripStoreTests`: 13/13 ผ่าน; `.xcresult`
  `/tmp/NapNav-A1-2-TripStore-20260923-1112.xcresult`
- Full Simulator suite 3 รอบต่อเนื่อง: แต่ละรอบ 88/88, 0 failed/0 skipped;
  summaries ที่ `/tmp/NapNav-A1-2-results/20260923-110438-full/summary.json`,
  `/tmp/NapNav-A1-2-results/20260923-112008-full/summary.json` และ
  `/tmp/NapNav-A1-2-results/20260923-112214-full/summary.json`; manifest ของ
  ทั้งสามรอบตรงกับ fingerprint ด้านบน
- Unsigned generic iOS Release build: `BUILD SUCCEEDED`, exit 0; artifacts
  `/tmp/NapNav-A1-2-results/20260923-110630-release-build/`; manifest ตรงกัน

คำสั่ง, tool output, และประวัติ runner/compile failure ก่อนหน้านี้บันทึกใน
`docs/DEVELOPMENT_REPORT.md`. Full suite รวม GPX release routes.

## ขอบเขตที่ยังไม่ยืนยัน

Automated tests และ generic Release build ไม่ยืนยันเสียงจริง, Silent/Focus,
การสั่น, locked screen, background หรือการได้รับ alert บน iPhone จริง สิ่งเหล่านี้
ยังเป็น A4 physical-device gate; ห้ามใช้ผล Simulator แทนหลักฐานดังกล่าว

## งานถัดไป (ข้อความเดิมถูก supersede)

A2.1–A2.3 ผ่าน automated gates ภายหลังเอกสาร handoff นี้. อย่าใช้หัวข้อนี้
กำหนดงานถัดไป; ดู remediation plan และ development report ปัจจุบันก่อนเริ่มช่วงงานใหม่.
