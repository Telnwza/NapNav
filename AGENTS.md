# NapNav agent working agreement

เริ่มงานทุกครั้งด้วยการอ่าน `docs/NAPNAV_REMEDIATION_PLAN.md` และ
`docs/DEVELOPMENT_REPORT.md` ก่อนแก้ไฟล์อื่น แผนใหม่ใช้กำหนดลำดับงาน ส่วน
`archive/docs/` เป็นประวัติและหลักฐานเดิม ไม่ใช่ข้อยืนยันว่ารหัสปัจจุบันผ่าน gate แล้ว
ถ้ารับงานแก้โค้ด ให้เปิดเฉพาะ ticket ที่กำลังทำใน
`docs/LUNA_CODE_FIX_TICKETS.md` พร้อม source/tests ที่ ticket ระบุ ไม่ต้องอ่าน
ทุก ticket เพื่อเริ่มงานหนึ่งช่วง

## ระหว่างแก้งาน

1. เลือกงานในแผนเพียงหนึ่งช่วงที่มีขอบเขตชัดเจน ตรวจ source และ tests ที่เกี่ยวข้องก่อนแก้
2. เพิ่มรายการใน `docs/DEVELOPMENT_REPORT.md` ตั้งแต่เริ่มงาน ระบุวันเวลา เป้าหมาย
   baseline และไฟล์ที่คาดว่าจะเปลี่ยน ถ้างานค้าง ให้ทิ้งสถานะ `กำลังทำ` หรือ `ติดขัด`
3. หลังแก้หรือทดสอบแต่ละรอบ อัปเดตรายการเดิมทันที: ไฟล์ที่เปลี่ยน เหตุผล คำสั่ง
   ผลลัพธ์ และ path ของ log/`.xcresult` ห้ามเขียนว่า “ผ่าน” จากข้อความคาดเดาหรือ
   ผลทดสอบคนละ source snapshot
4. แยกผลเป็น source/static, build, Simulator/GPX, และ iPhone จริง เสมอ
   Build หรือ Simulator ไม่พิสูจน์เสียง, Silent/Focus, locked screen หรือ background
5. หากยังรันทดสอบไม่ได้ ให้บันทึก error จริง สิ่งที่ลอง และสิ่งที่ยังไม่ยืนยัน
   ห้ามเปลี่ยน checkbox ในแผนเป็นเสร็จเพราะมี implementation อย่างเดียว
6. รักษา scope ของ v1.0 และอย่าแก้ product decision ที่แผนทำเครื่องหมายว่ารอผู้ใช้ตัดสิน
   ห้าม push, publish, สร้าง TestFlight หรือแก้ signing โดยอนุมานสิทธิ์จากแผนนี้

## รูปแบบรายงานหนึ่งรายการ

ใช้หัวข้อ `YYYY-MM-DD HH:MM — <phase>: <งาน>` แล้วบันทึก `สถานะ`, `เป้าหมาย`,
`baseline`, `การเปลี่ยนแปลง`, `หลักฐานทดสอบ`, `ความเสี่ยง/สิ่งค้าง`, และ `งานถัดไป`
ใน `docs/DEVELOPMENT_REPORT.md` ไม่ต้องลบรายการเก่า เมื่อกลับมาทำต่อให้อัปเดต
รายการเดิมหรือเพิ่มรายการใหม่พร้อมลิงก์กลับไปยังงานที่ค้าง

## Report and handoff language

Write reports and handoffs in English by default. Keep Thai wording when the exact
Thai copy, label, evidence, or other Thai-language context is important to the
work; do not translate or paraphrase away meaning that depends on that context.
