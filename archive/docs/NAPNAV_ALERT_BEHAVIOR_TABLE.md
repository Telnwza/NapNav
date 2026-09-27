# NapNav — Alert Delivery Contract (Phase A1)

อัปเดตล่าสุด: 23 กันยายน 2026

เอกสารนี้เป็นสัญญาระหว่างตัวเลือกใน Settings กับพฤติกรรมจริงของแอป คำว่า “Notification แบบไม่มีเสียง” ไม่ได้หมายความว่า iOS จะสั่นเสมอ เพราะการสั่นยังขึ้นกับการตั้งค่าระบบ, Focus และอุปกรณ์

## Behavior table

| Delivery Mode | Sound Mode | iOS 18–25 | iOS 26+ เมื่อ AlarmKit อนุญาต | เมื่อเส้นทางหลักไม่พร้อม |
|---|---|---|---|---|
| Automatic | มีเสียง | Notification พร้อมเสียง | AlarmKit | ถ้า AlarmKit ไม่พร้อม ใช้ Notification; ถ้าไม่มีทั้งคู่รายงาน unavailable |
| Automatic | ไม่มีเสียง | Notification ไม่มีเสียง | Notification ไม่มีเสียง ไม่เรียก AlarmKit | ถ้า Notification ไม่พร้อมรายงาน unavailable |
| Notification | มีเสียง | Notification พร้อมเสียง | Notification พร้อมเสียง | ถ้าปิดเสียงใน Settings จะแสดง Notification แต่รายงานว่าเสียงถูกปิด; ถ้าปิด alerts รายงาน unavailable |
| Notification | ไม่มีเสียง | Notification ไม่มีเสียง | Notification ไม่มีเสียง | ถ้า Notification ไม่พร้อมรายงาน unavailable และไม่รับประกันการสั่น |
| AlarmKit | มีเสียง | ซ่อนตัวเลือก; ค่าที่เคยบันทึกไว้ fallback เป็น Notification | AlarmKit | ถ้าไม่รองรับหรือไม่ได้อนุญาต fallback เป็น Notification; ถ้า fallback ไม่ได้รายงาน unavailable |
| AlarmKit | ไม่มีเสียง | ซ่อนตัวเลือก; fallback เป็น Notification ไม่มีเสียง | ไม่เรียก AlarmKit และ fallback เป็น Notification ไม่มีเสียง | ถ้า Notification ไม่พร้อมรายงาน unavailable |
| Both | มีเสียง | ซ่อนตัวเลือก; ค่าที่เคยบันทึกไว้ fallback เป็น Notification | AlarmKit เป็นเสียงหลัก + Notification แบบไม่มีเสียง | ถ้า AlarmKit ไม่พร้อม ใช้ Notification; ถ้า Notification ไม่พร้อมแต่ AlarmKit พร้อม ใช้ AlarmKit ช่องทางเดียว |
| Both | ไม่มีเสียง | ซ่อนตัวเลือก; fallback เป็น Notification ไม่มีเสียง | ไม่เรียก AlarmKit และใช้ Notification ไม่มีเสียง | ถ้า Notification ไม่พร้อมรายงาน unavailable |

## ผลลัพธ์ที่โค้ดต้องรายงาน

- `alarmScheduled`: ตั้ง AlarmKit สำเร็จ พร้อมระบุว่า companion Notification ตั้งได้หรือไม่
- `notificationScheduled`: เลือกเส้นทาง Notification สำเร็จ พร้อมระบุ audible, silent by choice หรือ muted by system
- `fallbackUsed`: เส้นทางที่เลือกใช้ไม่ได้ แต่มีเส้นทางสำรองที่ตั้งสำเร็จ
- `deliveryUnavailable`: ไม่มีเส้นทางที่พร้อม หรือการตั้งทั้งเส้นทางหลักและ fallback ล้มเหลว

`deliveryUnavailable` ต้องไม่ตั้ง `alertSent = true` และ UI ต้องแสดงสาเหตุพร้อมทางลัดไป Settings

## Permission policy

- NapNav ขอ Notification permission เป็น baseline เมื่อเริ่มทริป
- NapNav ขอ AlarmKit permission เฉพาะเมื่อผู้ใช้เลือก AlarmKit หรือ Both พร้อมโหมดมีเสียง
- Automatic ใช้ AlarmKit เมื่อเคยได้รับอนุญาตแล้ว แต่ไม่แสดง prompt AlarmKit เพิ่มโดยไม่เกิดจากตัวเลือกที่ชัดเจนของผู้ใช้
- บนระบบที่ไม่รองรับ AlarmKit หน้า Settings แสดงเฉพาะ Automatic และ Notification

## Start gate และ path ที่หายระหว่างทริป

- ก่อนเริ่ม **Trip Alarm** แอปขอเฉพาะ authorization ที่เกี่ยวกับ delivery mode
  ที่เลือกและ refresh readiness ล่าสุดก่อนตัดสินใจ
- ถ้า `alertDeliveryPlan.isAvailable == false` ให้คงอยู่หน้า setup, แจ้งว่า
  delivery unavailable และเปิด Alert Settings พร้อมทางไป iPhone Settings; ห้าม
  ขอ location permission, สร้าง/บันทึก trip, เริ่ม GPS หรือ Live Activity
- ไม่เริ่ม tracking-only แบบเงียบ ๆ เพราะคำสั่งเริ่มใน v1.0 หมายถึง Trip Alarm
- ถ้าเริ่มทริปได้แล้วและ delivery path หายภายหลัง อย่าย้อนหรือหยุดทริปโดย
  อัตโนมัติ; แสดง unavailable และ retry ตาม backoff ของ A1.1 เมื่อ readiness กลับมา
- มี path อย่างน้อยหนึ่งทางก็เริ่มได้ เช่น AlarmKit พร้อม แม้ Notification
  permission/alerts ไม่พร้อม; ให้ delivery policy เลือก fallback/path ที่ระบุไว้
  ในตารางด้านบน

## ขอบเขตหลักฐาน

Automated tests ตรวจ decision table, fallback, permission state และการไม่รายงานความสำเร็จเมื่อ delivery ล้มเหลว ส่วนเสียงจริง, Silent, Focus, การสั่น, locked screen และ background ยังต้องผ่าน physical-device gate แยกต่างหาก
