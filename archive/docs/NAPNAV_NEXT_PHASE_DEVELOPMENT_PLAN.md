# NapNav — แผนพัฒนารอบ Map UX, Arrival และ Alarm

อัปเดตล่าสุด: 21 กันยายน 2026  
สถานะ: **Phase 0–5 implement แล้ว — รอทดสอบ Alarm/Silent/Focus และ background/locked screen ให้ครบ**

เอกสารนี้สรุป feedback หลังทดสอบแอปรอบล่าสุด และใช้แทนแนวทางเลือกจุดหมายแบบแยกสองโหมดใน [NAPNAV_DESTINATION_AND_MOTION_DESIGN.md](NAPNAV_DESTINATION_AND_MOTION_DESIGN.md) เฉพาะส่วนที่ขัดกัน

## Implementation checkpoint

| Phase | สถานะ | หลักฐานปัจจุบัน |
|---|---|---|
| 0 — Alarm feasibility | ทดสอบปุ่มแจ้งเตือนผ่าน / device matrix ค้าง | ผู้ใช้ยืนยันว่า test action ส่งการแจ้งเตือนได้; Time Sensitive, readiness, Stop/Snooze actions และ AlarmKit spike มีในโค้ด แต่ Silent/Focus/background/locked screen ยังต้องทดสอบแยก |
| 1 — Map shell + bottom sheet | Implement แล้ว | search อยู่ใน sheet 3 ระดับ และค้นหาแล้วลากหมุดต่อได้ |
| 2 — Pin | Implement แล้ว | ใช้ pin shape ที่มีปลายชี้พิกัด ขอบขาว เงา และ target dot |
| 3 — Map styles + POI | Implement แล้ว | Explore, Driving + traffic, Transit POI และ Satellite hybrid |
| 4 — Setup + Active Trip | Implement แล้ว | ใช้ map-first flow, แสดงระยะด้านบน และ stop confirmation อยู่ bottom sheet |
| 5 — Alert radius + Arrival threshold | Implement แล้ว | ระยะปลุกกับเกณฑ์ถึงจุดหมาย 20 ม. แยกจากกัน, ยืนยัน arrival 2 samples, ป้องกัน stale/inaccurate/GPS bounce และสถานะไม่ย้อนกลับ |

Automated tests ล่าสุด: core suite 29/29 ผ่าน และ GPX release routes 3/3 ผ่านแบบ targeted run บน iOS 27.0 Simulator; generic iOS device build ผ่าน  
ข้อจำกัดการยืนยัน: Simulator ใช้ตรวจ layout/state ได้ แต่ไม่ใช่หลักฐานว่า AlarmKit, เสียง, การสั่น และ background locked-screen ทำงานจริง

## เป้าหมายของรอบนี้

ทำให้ NapNav รู้สึกเป็น flow เดียวแบบ Apple Maps ตั้งแต่ค้นหาจุดหมาย เลื่อนหมุด เลือกระยะ เริ่มทริป ไปจนถึงการเตือน โดยมีแผนที่เป็นพื้นหลักตลอดทั้ง flow

ผลลัพธ์ที่ต้องการ:

- ไม่มีหน้าเลือก Search mode / Map mode
- ค้นหาแล้วลากแผนที่ปรับหมุดต่อได้ทันที
- ช่องค้นหาและข้อมูลจุดหมายอยู่ใน bottom sheet ที่ย่อ–ขยายได้
- หน้าตั้งระยะและหน้าทริปยังเห็นแผนที่ขนาดใหญ่
- แยก “ระยะปลุก” ออกจาก “ถึงจุดหมายแล้ว” อย่างชัดเจน
- ปรับระบบแจ้งเตือนให้ดังและสังเกตง่ายที่สุดเท่าที่ iOS อนุญาต โดยไม่อ้างว่าฝ่า Silent/Focus ได้ถ้ายังพิสูจน์ไม่ได้

## ข้อสรุปเรื่อง Alarm, Silent mode และการสั่น

### สิ่งที่ทำได้แน่นอนใน baseline

- ใช้ local notification พร้อมเสียงมาตรฐานหรือเสียงที่มากับแอป
- ตั้ง notification เป็น `timeSensitive` เพื่อให้ส่งทันทีและผ่าน Notification Summary/Focus ได้ในกรณีที่ผู้ใช้อนุญาต
- ตรวจ `authorizationStatus`, `soundSetting`, `lockScreenSetting` และ `timeSensitiveSetting` ก่อนเริ่มทริป แล้วบอกผู้ใช้ตรง ๆ ว่าระบบพร้อมระดับไหน
- เมื่อแอปเปิดอยู่ ทำเสียงและ haptic ภายในแอปได้
- เพิ่ม action เช่น `หยุดเตือน` และ `เตือนอีกครั้ง` บน notification ได้

ข้อจำกัด: notification ปกติไม่สามารถบังคับให้มีเสียงหรือสั่นได้ทุกกรณี ผู้ใช้ยังควบคุม Silent mode, Focus, Sounds & Haptics และการตั้งค่ารายแอปอยู่ ถ้าเลือก “สั่นอย่างเดียว” เราทำได้เพียง best effort และต้องไม่เขียนว่า “รับประกันว่าจะสั่น” โดยเฉพาะตอนแอปอยู่เบื้องหลังหรือเครื่องล็อก

### AlarmKit — ใกล้เคียง Clock/Timer ที่สุด

Apple ระบุว่า AlarmKit บน iOS/iPadOS 26 สามารถสร้าง alarm/timer ที่แสดงบน Lock Screen, Dynamic Island และทะลุ Silent mode กับ Focus ได้ ผู้ใช้ต้องอนุญาต AlarmKit ให้แอปก่อน และแอปต้องมี `NSAlarmKitUsageDescription`

อย่างไรก็ตาม NapNav รู้เวลาปลุกเมื่อ GPS เข้าเขต ไม่ได้รู้เป็นเวลาคงที่ล่วงหน้า ขณะที่ Apple วาง AlarmKit ไว้สำหรับ alarm ตามกำหนดเวลาหรือ countdown และระบุว่าไม่ใช่ตัวแทนของ prominent notification แบบอื่น ดังนั้นยังไม่ควรรับปากว่าจะใช้ AlarmKit เป็นระบบหลักจนกว่าจะผ่าน technical spike บนเครื่องจริง

แนวทดลองคือ เมื่อ trigger จาก GPS เกิดขึ้น ให้ลองสร้าง alarm ระยะสั้นมากแล้วตรวจว่า:

- schedule ได้จริงขณะแอปอยู่ background
- แจ้งเตือนทันเวลา ไม่หน่วงจนเลยจุดหมาย
- พฤติกรรมผ่าน Silent/Focus เป็นไปตามเอกสาร
- lifecycle, stop action และ cleanup ไม่ทิ้ง alarm ค้าง
- รูปแบบการใช้งานเหมาะสมกับข้อกำหนดและการ review ของ Apple

เนื่องจากโปรเจกต์รองรับ iOS 18 อยู่แล้ว AlarmKit ต้องอยู่หลัง `if #available(iOS 26, *)` และมี UserNotifications เป็น fallback สำหรับ iOS 18–25

### Critical Alerts

Critical Alert สามารถเล่นเสียงได้แม้เครื่อง mute, ล็อกอยู่ หรือเปิด Do Not Disturb แต่ต้องขอ entitlement พิเศษจาก Apple จึงเก็บเป็นทางเลือกอนาคต ไม่ใช้เป็น dependency ของ MVP และไม่สมมติว่าแอปจะได้รับอนุมัติ

### แนวทางผลิตภัณฑ์ที่เสนอ

ให้มีระดับการเตือนภายในดังนี้:

| โหมด | พฤติกรรม | สถานะในแผน |
|---|---|---|
| มาตรฐาน | local notification + sound + `timeSensitive` | baseline สำหรับ iOS 18+ |
| สั่นเป็นหลัก | ไม่มีเสียงจากแอป และใช้ system/in-app haptic เท่าที่ระบบอนุญาต | best effort พร้อมข้อความข้อจำกัด |
| Alarm เด่นชัด | AlarmKit พร้อม system alarm UI | ทดลองสำหรับ iOS 26+ ก่อนตัดสินใจ |
| Critical | ฝ่า mute/Focus ด้วย entitlement | นอก MVP จนกว่า Apple อนุมัติ |

อ้างอิง Apple:

- [AlarmKit](https://developer.apple.com/documentation/alarmkit)
- [Scheduling an alarm with AlarmKit](https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit)
- [WWDC25: Wake up to the AlarmKit API](https://developer.apple.com/videos/play/wwdc2025/230/)
- [Time Sensitive notifications](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive)
- [Critical Alerts entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.critical-alerts)
- [Notification sound requirements](https://developer.apple.com/documentation/usernotifications/unnotificationsound)

## Target user flow

```text
Startup แบบสั้นและมี motion
  -> แผนที่ + bottom search sheet
       -> ค้นหาสถานที่ หรือเลื่อนแผนที่ใต้หมุดเดียวกัน
       -> ย่อ sheet เพื่อดูแผนที่ / ขยายเพื่อค้นหาและดูรายละเอียด
  -> เลือกระยะปลุกใน sheet เดิม
  -> ตรวจความพร้อมและเริ่มทริป
  -> แผนที่ + ระยะห่างด้านบน + controls ด้านล่าง
       -> เข้าเขตระยะปลุก: ส่ง alarm/notification หนึ่งครั้ง
       -> เหลือประมาณ 20 ม.: ถือว่าถึงจุดหมาย
  -> จบทริป
```

## แผนแบ่ง Phase

### Phase 0 — Alarm feasibility spike

เป้าหมาย: ตัดสินใจระบบเตือนจากหลักฐานบนเครื่องจริงก่อนออกแบบ UI การตั้งค่าเสียงถาวร

งาน:

- ทำ abstraction `AlarmDelivery` แยกจาก trigger policy โดยยังไม่เปลี่ยนพฤติกรรมผู้ใช้
- ทดสอบ local notification แบบ `timeSensitive`, custom sound และ notification actions
- ตรวจสถานะ notification รายด้านก่อนเริ่มทริป
- ทำ AlarmKit spike สำหรับ iOS 26+ ด้วย alarm ระยะสั้นหลัง GPS trigger
- ทดสอบ foreground, background, locked screen, Silent mode, Focus และ permission denied
- บันทึกเวลา GPS trigger เทียบกับเวลาที่ alert แสดงจริง
- ตัดสินใจหลัง spike ว่า AlarmKit เป็น production path หรือคงเป็น experimental/future path

Acceptance criteria:

- มีผลทดสอบจาก iPhone จริง ไม่ใช้ Simulator เป็นหลักฐานเรื่องเสียง/สั่น/ล็อกจอ
- ทราบชัดว่าแต่ละเส้นทางทำงานบน iOS 18–25 และ iOS 26+ อย่างไร
- ไม่มีคำว่า “ปลุกได้แน่นอน” ถ้าการตั้งค่าระบบยังปิดกั้นการเตือน
- เมื่อ permission ถูกปฏิเสธ ผู้ใช้เห็นวิธีแก้และเข้า Settings ได้

### Phase 1 — Map shell และ bottom sheet แบบเดียวตลอด flow

เป้าหมาย: ยกเลิกการแบ่ง Search/Map mode และทำหน้าเลือกจุดหมายให้เป็นงานเดียว

งาน:

- ใช้ live map เต็มพื้นจอ
- ย้าย search field ลง bottom sheet
- รองรับระดับ `collapsed`, `medium`, `large`
- `collapsed` แสดงชื่อสถานที่ 1–2 บรรทัดและปุ่มดึงขึ้น
- `medium` แสดงรายละเอียดจุดหมายกับปุ่มไปต่อ
- `large` แสดงช่องค้นหาและผลลัพธ์
- หลังเลือกผลค้นหา กล้องไปยังตำแหน่งนั้นและผู้ใช้ลากแผนที่ปรับต่อได้ทันที
- อัปเดต reverse geocode แบบ debounce และป้องกันผลเก่าย้อนมาทับจุดล่าสุด
- แผนที่ด้านหลังยัง pan/zoom ได้เมื่อ sheet อยู่ระดับที่เหมาะสม

Acceptance criteria:

- ไม่มี mode selector
- ค้นหา เลือกผล แล้วลากหมุดต่อได้โดยไม่เปลี่ยนหน้า
- ชื่อยาวไม่ดัน sheet บังแผนที่เกินจำเป็น
- keyboard, VoiceOver และ Dynamic Type ใช้งานได้

### Phase 2 — หมุดและความแม่นยำของจุดเลือก

เป้าหมาย: ผู้ใช้รู้แน่นอนว่าพิกัดอยู่ที่ปลายหมุดตรงไหน

งาน:

- เปลี่ยนหมุดวงกลมเป็น pin ทรงหยดน้ำที่มีปลายชี้ชัด
- ตัดกรอบวงกลมภายนอกออก
- ใช้ขอบสีอ่อน เงา และ clear space รอบหมุดเพื่อให้ contrast กับทุกชนิดแผนที่
- เพิ่มจุด target เล็ก ๆ บนพื้นตรงตำแหน่งจริง
- ตอนลากแผนที่ให้หมุดยกขึ้น และวางลงเมื่อกล้องหยุด
- พิกัดที่บันทึกต้องมาจากตำแหน่งปลายหมุด ไม่ใช่ visual center ของรูปทั้งก้อน

Acceptance criteria:

- ทดสอบกับพื้นถนน พื้นสีเขียว น้ำ และ satellite แล้วยังเห็นหมุดชัด
- พิกัดปลายหมุดตรงกับ center coordinate ที่บันทึก
- Reduce Motion ปิด lift/spring แต่ flow ยังเข้าใจได้

### Phase 3 — รูปแบบแผนที่และ POI

เป้าหมาย: ให้เลือกมุมมอง Explore, Driving, Transit และ Satellite ในภาษาภาพใกล้เคียง Apple Maps เท่าที่ public MapKit รองรับ

งาน:

- เพิ่ม map-style control แบบ compact บนแผนที่
- `Explore`: standard map พร้อม POI ทั่วไป
- `Driving`: standard map + traffic และเน้นข้อมูลที่เกี่ยวกับถนน
- `Transit`: standard map + POI หมวดขนส่ง
- `Satellite`: hybrid imagery เพื่อยังเห็นชื่อสถานที่
- เลิก filter แบบตัด POI ทั้งหมด และกำหนด filter ตาม style
- รักษา camera position และหมุดเดิมเมื่อสลับ style

ข้อจำกัด: public MapKit ไม่ได้เปิดให้คัดลอกทุก layer หรือทุก logic ของแอป Apple Maps แบบหนึ่งต่อหนึ่ง ชื่อสถานี/ป้ายรถที่เห็นขึ้นกับข้อมูล Apple, zoom level และพื้นที่ ถ้าจุดสำคัญยังไม่พอ ค่อยเพิ่ม annotation จากข้อมูลที่ตรวจสอบแหล่งแล้วใน phase อนาคต

Acceptance criteria:

- สลับทั้งสี่ style ได้โดยจุดหมายไม่หายและกล้องไม่กระโดด
- Transit แสดง transport POI ที่ MapKit มีให้ในพื้นที่ทดสอบ
- Satellite ยังอ่านชื่อสถานที่ได้

### Phase 4 — เลือกระยะและ Active Trip แบบ map-first

เป้าหมาย: ทำให้การเลือกจุดหมายต่อเนื่องไปถึงตั้งระยะและเริ่มทริป โดยแผนที่ไม่หาย

งาน:

- เมื่อยืนยันจุดหมาย เปลี่ยนเนื้อหาใน bottom sheet เป็นตัวเลือกระยะทันที
- ตัด tag หรือข้อความ “พร้อมเตือน”, “ตำแหน่ง”, “ขอสิทธิ์เมื่อเริ่ม” ที่รบกวนหน้าออก
- แสดงวงรัศมีบนแผนที่และอัปเดตตามค่าที่เลือก
- หลังเริ่มทริปคงแผนที่เต็มพื้นไว้
- วางระยะปัจจุบันและชื่อจุดหมายเป็น compact overlay ด้านบน
- วางสถานะสัญญาณและปุ่มหยุดไว้ใน bottom sheet ด้านล่าง
- เปลี่ยน confirmation หยุดทริปเป็น bottom confirmation sheet ที่ยึดกับปุ่ม ไม่ลอยผิดตำแหน่งด้านบน

Acceptance criteria:

- จากเลือกจุดหมายถึงเลือก radius ไม่มี full-screen transition ที่ทำให้รู้สึกเปลี่ยนบริบท
- Active Trip เห็นตำแหน่งผู้ใช้ จุดหมาย ระยะปัจจุบัน และวงรัศมีในแผนที่เดียวกัน
- confirmation หยุดทริปอยู่ด้านล่างและไม่ชน safe area

### Phase 5 — แยก Alert radius ออกจาก Arrival threshold

สถานะ: **Implement แล้ว — รอทดสอบกับตำแหน่งจริง/GPX ใน flow ของแอป**

เป้าหมาย: ปลุกล่วงหน้าตามระยะที่ผู้ใช้เลือก แต่ถือว่า “ถึงแล้ว” เมื่อเหลือประมาณ 20 เมตร

งาน:

- คง `selectedRadiusMeters` เป็นระยะปลุกล่วงหน้า เช่น 500 เมตรหรือ 1 กิโลเมตร
- เพิ่ม arrival threshold เริ่มต้นที่ 20 เมตร แยกจาก radius
- ส่ง alarm เพียงครั้งเดียวเมื่อผ่าน trigger policy ของระยะปลุก
- เปลี่ยนสถานะเป็น arrived เมื่อระยะไม่เกิน 20 เมตรต่อเนื่องอย่างน้อย 2 location samples
- ใช้ freshness และ horizontal accuracy guard; ถ้าความแม่นยำแย่ ให้แสดง “อยู่ใกล้มาก” แต่ยังไม่ auto-complete
- ป้องกัน GPS bounce ทำให้สถานะย้อนกลับหรือส่ง alarm ซ้ำ

Acceptance criteria:

- เข้าเขต 1 กม. ไม่ถูกนับว่า “ถึงแล้ว”
- ระยะ 15–20 เมตรที่มี sample คุณภาพดีเปลี่ยนเป็น arrived ได้
- sample เก่า ไม่แม่น หรือกระโดดเพียงครั้งเดียวไม่จบทริป
- notification/alarm ต่อหนึ่งทริปไม่ถูกยิงซ้ำ

### Phase 6 — Alarm delivery ที่เลือกจากผล Phase 0

สถานะ: **เริ่ม implement แล้ว — trigger จริงใช้ AlarmKit บน iOS 26+ เมื่อได้รับอนุญาต และ fallback เป็น time-sensitive notification; ยังรอ device validation และ lifecycle/stop-action gate**

เป้าหมาย: ทำ production implementation โดยเลือกเส้นทางที่พิสูจน์แล้ว

Baseline ทุกเวอร์ชัน:

- local notification แบบ time-sensitive
- เสียงสั้นที่ชัดเจนและผ่านข้อกำหนดของ `UNNotificationSound`
- stop/snooze action
- readiness summary ที่อ่านง่ายก่อนเริ่ม
- fallback copy เมื่อ sound หรือ lock-screen notification ถูกปิด

ถ้า AlarmKit spike ผ่าน:

- เพิ่ม AlarmKit path เฉพาะ iOS 26+
- มี system alarm UI, stop action และ lifecycle cleanup
- fallback อัตโนมัติเมื่อไม่ได้รับ AlarmKit authorization หรือ schedule ไม่สำเร็จ
- ไม่แสดงตัวเลือก AlarmKit บน OS ที่ไม่รองรับ

Acceptance criteria:

- ผู้ใช้รู้ก่อนเริ่มว่าการเตือนเป็น Standard, Vibrate best effort หรือ AlarmKit
- failure ของ enhanced path ไม่ทำให้ baseline notification หาย
- stop trip ยกเลิก pending notification/alarm ที่เกี่ยวข้องทั้งหมด

### Phase 7 — Startup motion

สถานะ: **Implement แล้ว — มี route/pin motion เฉพาะตอน startup/recovery ที่ใช้เวลาจริง และ Reduce Motion ใช้ fade โดยไม่เพิ่ม artificial delay**

เป้าหมาย: ให้หน้าเตรียมแอปดูมีชีวิต แต่ไม่ทำให้เปิดแอปช้าลง

งาน:

- ใช้ native Launch Screen แบบคงที่ตามข้อกำหนด iOS
- เพิ่ม animation ใน `StartupView` เช่น pin เคลื่อนตามเส้นทางสั้น ๆ หรือวงรัศมีหายใจหนึ่งรอบ
- animation ทำงานเฉพาะเมื่อมีงาน startup/recovery จริง
- ถ้าพร้อมภายในประมาณ 250–300 ms ให้เข้าหน้าหลักทันที
- รองรับ Reduce Motion ด้วย fade ธรรมดา

Acceptance criteria:

- ไม่มี artificial delay เพื่อโชว์ animation
- ไม่เกิด loading flash ตอนเปิดเร็ว
- recovery/error state ยังอ่านและกด retry ได้

### Phase 8 — Integration QA และ release gate

สถานะ: **Automated gate implement แล้ว — ดู checklist ที่ [NAPNAV_RELEASE_QA_CHECKLIST.md](NAPNAV_RELEASE_QA_CHECKLIST.md); physical-device gate ยังรอผลทดสอบจริง**

เป้าหมาย: ตรวจ flow ทั้งก้อนและยืนยันเรื่อง alarm บนอุปกรณ์จริง

Test matrix ขั้นต่ำ:

| กลุ่ม | กรณีทดสอบ |
|---|---|
| UI | sheet 3 ระดับ, ชื่อยาว, keyboard, Dynamic Type, Dark Mode, Reduce Motion |
| Map | 4 styles, POI, drag หลัง search, user location, destination/radius overlays |
| Trigger | นอกเขต, เข้าเขต 2 samples, accuracy แย่, stale sample, GPS bounce, 20 m arrival |
| Lifecycle | foreground, background, locked screen, app relaunch, stop trip, recovered trip |
| Alert | normal, Silent, Focus, sound disabled, notifications denied, AlarmKit denied |
| Device | iOS 18 fallback และ iOS 26+ enhanced path บน iPhone จริง |

Release gate:

- unit tests ของ trigger/state ผ่าน
- GPX route replay ผ่านทั้งเข้าใกล้และผ่านเลย
- ไม่มี notification/alarm ค้างหลังหยุดหรือจบทริป
- locked-screen test บนเครื่องจริงมีบันทึกผลและเวลาที่เตือน
- ข้อความในแอปตรงกับความสามารถจริงของแต่ละ OS และ permission state

## ลำดับแนะนำ

1. Phase 0 พิสูจน์ระบบ alarm ก่อน เพราะมีผลต่อ promise หลักของผลิตภัณฑ์
2. Phase 1–2 รวม flow และแก้หมุด
3. Phase 3 เพิ่ม map styles/POI
4. Phase 4 ปรับหน้าเลือก radius, Active Trip และ stop confirmation
5. Phase 5 แยก alert/arrival policy
6. Phase 6 ลง production alarm path จากผลทดลอง
7. Phase 7 เติม startup motion
8. Phase 8 ทดสอบรวมและตัดสิน release

## ไฟล์ที่คาดว่าจะเกี่ยวข้องเมื่อเริ่มพัฒนา

- `StopAlarm/DestinationSelection.swift`
- `StopAlarm/RootView.swift`
- `StopAlarm/TripStore.swift`
- `StopAlarm/TriggerPolicy.swift`
- `StopAlarm/SystemClients.swift`
- `StopAlarm/StartupView.swift`
- `StopAlarm/Motion.swift`
- `StopAlarm/DomainModels.swift`
- `StopAlarmTests/DestinationSelectionTests.swift`
- `StopAlarmTests/TriggerPolicyTests.swift`
- `StopAlarmTests/TripStoreTests.swift`
- `StopAlarmTests/StartupRecoveryTests.swift`
- target/configuration ใหม่สำหรับ Widget Extension เฉพาะกรณี AlarmKit countdown path จำเป็นต้องใช้

## สิ่งที่ยังไม่ทำหลัง Phase 0–5

- ยังไม่ยืนยัน AlarmKit, Silent mode, Focus, vibration และ locked-screen background บน iPhone จริง
- ยังไม่ตัดสินว่า AlarmKit ผ่าน production gate; spike 5 วินาทียังไม่ใช่ production path และปุ่มทดสอบถูกนำออกจาก UI ตั้งค่าทริปแล้ว
- ยังไม่เพิ่ม Widget Extension เพราะ spike ใช้ fixed alarm ไม่ใช่ countdown presentation
- AlarmKit production path แบบอัตโนมัติต่อแล้ว แต่ยังไม่มีหน้าให้ผู้ใช้เลือก Notification/AlarmKit/ทั้งคู่ และยังรอ device validation
- ยังไม่ขอ Critical Alerts entitlement
- ยังไม่ commit หรือ push

## Backlog รอบถัดไป — Alert Settings

เพิ่มหน้า Settings ให้ผู้ใช้กำหนดรูปแบบการเตือน โดยออกแบบให้ความสามารถที่เลือกได้ขึ้นกับ OS และ permission จริง:

- Delivery mode: `อัตโนมัติ`, `Notification`, `AlarmKit` และ `ทั้งสองแบบ`
- Sound mode: `มีเสียง` และ `สั่นเป็นหลัก` โดยต้องอธิบายว่าสั่นใน background/locked screen เป็น best effort ถ้าไม่ได้ใช้ system alarm
- แสดงสถานะสิทธิ์ Notification, Sound, Lock Screen, Time Sensitive และ AlarmKit ในหน้าเดียว
- ถ้าเลือก AlarmKit บน OS ที่ไม่รองรับหรือ permission ถูกปฏิเสธ ให้ fallback ตามค่าที่ผู้ใช้อนุญาตไว้
- โหมด `ทั้งสองแบบ` ต้องป้องกันเสียงซ้อนและมี cleanup ร่วมกันเมื่อกดหยุดทริป
- บันทึก preference ในเครื่องและใช้ค่าเดิมกับทริปถัดไป
