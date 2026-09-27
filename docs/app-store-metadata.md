# NapNav - App Store Metadata & Launch Preparation

เอกสารรวบรวมข้อมูลสำหรับกรอกในระบบ **App Store Connect** ครบทุกช่องตามข้อกำหนดของ Apple พร้อมภาษาไทยและภาษาอังกฤษ

---

## 1. App Store Information (ข้อมูลทั่วไปของแอป)

| หัวข้อ | ภาษาไทย | English | กฎของ Apple |
| :--- | :--- | :--- | :--- |
| **App Name** | `NapNav - ปลุกเตือนตามพิกัด` | `NapNav - GPS Transit Alarm` | ไม่เกิน 30 ตัวอักษร |
| **Subtitle** | `งีบหลับสบาย ไม่ต้องกลัวเลยป้าย` | `Wake up before your stop` | ไม่เกิน 30 ตัวอักษร |
| **Primary Category** | Navigation (การนำทาง) | Navigation | หมวดหมู่หลัก |
| **Secondary Category** | Travel (การเดินทางและท่องเที่ยว) | Travel | หมวดหมู่รอง |
| **Content Rights** | Does not contain third-party content | | |
| **Age Rating** | 4+ (ไม่มีเนื้อหารุนแรง/ผู้ใหญ่) | 4+ | |

---

## 2. Keywords (คำค้นหา - ไม่เกิน 100 ตัวอักษร)

> **ข้อแนะนำจาก Apple:** คั่นด้วยจุลภาค `,` ห้ามเว้นวรรคหลังจุลภาค ห้ามใส่ชื่อซ้ำกับชื่อแอป

### ภาษาไทย (87 ตัวอักษร):
```text
ปลุก,เตือนพิกัด,บีทีเอส,mrt,bts,รถเมล์,รถไฟฟ้า,ตื่น,จุดหมาย,เลยป้าย,นาฬิกาปลุก,งีบ,ปลุกตามระยะ
```

### English (98 characters):
```text
transit,alarm,stop,wake,subway,train,bus,commute,sleep,nap,geofence,location,station,alert,arrive
```

---

## 3. URLs (ลิงก์ที่ Apple บังคับ)

* **Privacy Policy URL:** `https://telnwza.github.io/NapNav/privacy.html`
* **Support URL:** `https://telnwza.github.io/NapNav/support.html` (หรือ `https://github.com/Telnwza/NapNav/issues`)
* **Marketing URL (ทางเลือก):** `https://github.com/Telnwza/NapNav`

---

## 4. Description (คำอธิบายแอป)

### ภาษาไทย (Thai Description):
```text
เคยมั้ย? ขึ้นรถไฟฟ้า รถเมล์ หรือรถไฟหลังเลิกงานเหนื่อยๆ แล้วอยากงีบหลับ แต่ก็กังวลว่าจะนอนเพลินจนเลยป้าย...

NapNav (แน็พนาฟ) คือแอปปลุกเตือนตามพิกัด GPS อัจฉริยะ ที่ออกแบบมาเพื่อคนเดินทางโดยเฉพาะ ช่วยให้คุณงีบหลับพักผ่อนได้อย่างสบายใจ โดยระบบจะส่งเสียงปลุกและสั่นเตือนอย่างแม่นยำก่อนถึงจุดหมายปลายทาง

ฟีเจอร์เด่นของ NapNav:
• ปลุกตรงจุดด้วย GPS อัจฉริยะ: เลือกระยะรัศมีแจ้งเตือนล่วงหน้าได้ตามต้องการ (500ม., 1 กม., 2 กม. ฯลฯ)
• โหมดเตือนขั้นสุด "Use Both": ผสานพลังเสียงปลุกระดับ AlarmKit ร่วมกับการแจ้งเตือนแบบแบนเนอร์ ปลุกตื่นแน่นอนแม้เปิดโหมดเงียบ (บนอุปกรณ์ที่รองรับ)
• แสดงสถานะแบบ Real-time บนหน้าจอล็อก: รองรับ Live Activities และ Dynamic Island ติดตามระยะทางที่เหลือได้ทันทีโดยไม่ต้องปลดล็อกเครื่อง
• ค้นหาง่าย ปักหมุดสะดวก: ค้นหาสถานที่ หรือแตะลากหมุดบนแผนที่ได้อย่างอิสระ
• บันทึกสถานที่โปรด: บันทึกสถานีประจำ บ้าน หรือที่ทำงาน เพื่อเริ่มทริปได้ในแตะเดียว
• ประหยัดแบตเตอรี่: อัลกอริทึมคำนวณตำแหน่งแบบประหยัดพลังงาน ตรวจสอบแม่นยำสูงเฉพาะเมื่อเข้าใกล้พื้นที่
• ปลอดภัย ไร้กังวล (100% Privacy): ไม่มีการเก็บข้อมูลส่วนบุคคล ไม่มีการติดตามพฤติกรรม ข้อมูลพิกัดประมวลผลบนเครื่องของคุณเท่านั้น

ให้ทุกการเดินทางกลับบ้านหรือไปทำงานของคุณผ่อนคลายยิ่งขึ้น โหลด NapNav แล้วพักผ่อนสายตาได้เต็มที่เลยวันนี้!
```

### ภาษาอังกฤษ (English Description):
```text
Tired after a long day? Want to take a quick nap on the train, subway, or bus without worrying about missing your stop?

NapNav is your smart location-based transit alarm that wakes you up right before you arrive. Designed specifically for commuters, NapNav lets you rest peacefully knowing you won’t miss your destination.

Key Features:
• Precise GPS Geofencing: Customize your alert radius (500m, 1km, 2km, etc.) to get notified right on time.
• "Use Both" Dual Alarm System: Combines prominent AlarmKit ringtones with notifications to ensure you wake up even in silent mode (on supported devices).
• Live Activities & Dynamic Island: Glance at remaining distance and real-time transit progress right from your Lock Screen without unlocking your iPhone.
• Intuitive Map Pinning: Search destinations effortlessly or drag-and-drop pins anywhere on the map.
• Favorite Places: Save your frequent transit stations, home, or office for instant one-tap trip starts.
• Battery Efficient: Smart tracking algorithm conserves battery while away and increases GPS precision only when nearing your stop.
• 100% Privacy by Design: Zero user tracking, no ads, and no external data logging. All location processing happens entirely on your device.

Make your daily commute restful and worry-free. Download NapNav today and nap with confidence!
```

---

## 5. What’s New in This Version (สำหรับเวอร์ชัน 1.0.0)

```text
ยินดีต้อนรับสู่ NapNav เวอร์ชันแรก!
• ปักหมุดเลือกจุดหมายปลายทางและกำหนดระยะเตือนได้อย่างอิสระ
• ระบบปลุกอัจฉริยะ "Use Both" ผสานเสียงเตือนและระบบปลุก
• ติดตามระยะทางผ่าน Live Activities และ Dynamic Island บนหน้าจอล็อก
• รองรับภาษาไทยและภาษาอังกฤษอย่างสมบูรณ์
```

---

## 6. แผนผังภาพหน้าจอ (Screenshots Storyboard 6.7" / 6.9")

ขนาดภาพที่ Apple กำหนด:
- **6.9" Display** (iPhone 16 Pro Max): `1320 x 2868` พิกเซล
- **6.7" Display** (iPhone 15 Pro Max): `1290 x 2796` พิกเซล

ลำดับภาพที่แนะนำ (4 รูปเล่าเรื่องครบ):

1. **รูปที่ 1 - หน้าค้นหา/เลือกจุดหมาย (Search & Pin Destination)**
   - *ข้อความพาดหัว:* "ปักหมุดจุดหมายง่ายๆ เลือกระยะเตือนได้ตามใจ"
   - *หน้าจอ:* แผนที่ปักหมุดที่สถานีปลายทาง พร้อมวงรัศมีวงกลมสีฟ้าสวยงาม
2. **รูปที่ 2 - หน้าระหว่างเดินทางและตั้งค่าเสียงเตือน (Alert Method: Use Both)**
   - *ข้อความพาดหัว:* "ระบบปลุกคู่ Use Both ปลุกตื่นชัวร์ แม้เปิดโหมดเงียบ"
   - *หน้าจอ:* หน้ารายการเลือกวิธีเตือนที่มี "เตือนทั้งสองแบบ (Use Both)" อยู่บนสุด
3. **รูปที่ 3 - หน้าจอล็อกและ Dynamic Island (Live Activities)**
   - *ข้อความพาดหัว:* "เช็กระยะทางแบบเรียลไทม์ บน Lock Screen"
   - *หน้าจอ:* หน้าจอล็อกที่กำลังแสดง Widget Live Activity บอกระยะทางถอยหลังสู่จุดหมาย
4. **รูปที่ 4 - หน้าจัดการสถานที่โปรดและประวัติ (Favorites & History)**
   - *ข้อความพาดหัว:* "บันทึกสถานที่โปรด เริ่มเดินทางได้ในสัมผัสเดียว"
   - *หน้าจอ:* รายการสถานีโปรด เช่น "บ้าน", "ที่ทำงาน", "BTS อโศก"

---

## 7. App Review Information (ข้อมูลสำหรับเจ้าหน้าที่ Apple Reviewer)

> **นำข้อความด้านล่างนี้ไปวางในช่อง "Notes" ใต้หัวข้อ "App Review Information" ใน App Store Connect**

```text
Hello Apple App Review Team,

Thank you for reviewing NapNav!

NapNav is an on-device, location-based proximity alarm designed to help public transit commuters rest without missing their stop.

Key Testing Notes:
1. No Login Required: The app functions immediately without any user authentication, sign-up, or third-party accounts.
2. Background Location Usage: NapNav uses 'When In Use' location authorization coupled with the background location capability (UIBackgroundModes: location). This is required strictly to calculate the distance between the commuter and their destination while the screen is locked, firing the alarm when crossing the preset geofence perimeter. No background location is collected when a trip is not active.
3. How to Test Arrival Alarm:
   - Method A (Simulated GPX Route): In Xcode, simulate location using any of the GPX test files provided in the repository (e.g. TestRoutes/approach-destination.gpx).
   - Method B (Physical On-Device Test): 
     a. Grant Location and Notification permissions.
     b. Search or drop a pin at a landmark ~300-500 meters from your current location.
     c. Select alert radius (e.g. 500m).
     d. Tap "Start Trip".
     e. Because you are already within or approaching the perimeter, the alarm trigger will activate promptly, demonstrating the alarm sound, haptic feedback, and Live Activity / Dynamic Island presentation.
4. Contact: If you need any clarification or assistance during review, please reach out via email: techin.cr@gmail.com.

Best regards,
Techin
```

---

## 8. App Privacy Questionnaire (แบบสอบถามความเป็นส่วนตัวใน App Store Connect)

เมื่อ Apple ถามในแท็บ **App Privacy**:

1. **Do you or your third-party partners collect data from this app?**
   - ตอบ: **Yes** (เพราะมีการใช้พิกัดตำแหน่งในเครื่อง)
2. **Data Types ที่เลือก:**
   - ติ๊กเลือกเฉพาะ: **Location** -> **Precise Location** และ **Coarse Location**
3. **การใช้งานพิกัด (Usage Purpose):**
   - ติ๊กเลือก: **App Functionality** (การทำงานของแอป)
4. **Is this data linked to the user's identity?**
   - ตอบ: **No** (ไม่มีการผูกโยงกับตัวตนผู้ใช้)
5. **Do you use this data for tracking purposes?**
   - ตอบ: **No** (ไม่มีการสะกดรอยข้ามแอป/เว็บไซต์)

---

## 9. Age Rating (การจัดเรตติ้งอายุ)

ตอบคำถามในแบบสอบถามเรตติ้งอายุของ Apple ทุกข้อเป็น **"None" / "No"**:
- ไม่มีเนื้อหารุนแรง, ไม่มีคำหยาบ, ไม่มีการพนัน, ไม่มีการจำหน่ายแอลกอฮอล์/บุหรี่, ไม่มีการเข้าถึงเว็บเบราว์เซอร์อิสระ
- **ผลลัพธ์เรตติ้งที่ได้:** **4+ (เหมาะสำหรับทุกวัย)**

---

## 10. General App Information (ข้อมูลทั่วไปของแอป)

* **Primary Category (หมวดหมู่หลัก):** Navigation (การนำทาง) หรือ Travel (การเดินทาง)
* **Secondary Category (หมวดหมู่รอง):** Utilities (เครื่องมืออำนวยความสะดวก)
* **Price (ราคา):** Free (ฟรี)
* **Availability (พื้นที่จำหน่าย):** All Countries and Regions (ทั่วโลก) หรือเฉพาะ Thailand ตามต้องการ
* **Copyright:** `2026 Techin`
* **Trade Representative Contact:** กรอกชื่อ-นามสกุล ที่อยู่ และเบอร์โทรศัพท์ของตนเอง
* **Export Compliance (การปฏิบัติตามกฎหมายการส่งออก):**
  - ตัวแอปมีคีย์ `ITSAppUsesNonExemptEncryption = NO` ใน `Info.plist` แล้ว ระบบจะไม่ถามคำถามเรื่องการเข้ารหัสซ้ำซ้อน
