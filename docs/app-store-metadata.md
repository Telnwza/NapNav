# NapNav - App Store Metadata & Launch Preparation

ร่างข้อมูลภาษาไทย/อังกฤษสำหรับตรวจทานก่อนกรอก **App Store Connect**; ยังไม่ใช่หลักฐานว่า metadata ที่เผยแพร่จริงตรงกับเอกสารนี้

---

## 1. App Store Information (ข้อมูลทั่วไปของแอป)

| หัวข้อ | ภาษาไทย | English | กฎของ Apple |
| :--- | :--- | :--- | :--- |
| **App Name** | `NapNav - หลับไม่เลยป้าย` | `NapNav - Wake at Your Stop` | ไม่เกิน 30 ตัวอักษร |
| **Subtitle** | `พักระหว่างทางได้อุ่นใจ` | `Rest on the way, stay aware` | ไม่เกิน 30 ตัวอักษร |
| **Primary Category** | Navigation (การนำทาง) | Navigation | หมวดหมู่หลัก |
| **Secondary Category** | Travel (การเดินทางและท่องเที่ยว) | Travel | หมวดหมู่รอง |
| **Content Rights** | ต้องตรวจใน App Store Connect: แอปแสดงข้อมูลแผนที่/สถานที่จาก Apple Maps | | ตรวจสิทธิ์และเงื่อนไข MapKit ก่อนยืนยัน |
| **Age Rating** | 4+ (ไม่มีเนื้อหารุนแรง/ผู้ใหญ่) | 4+ | |

---

### Promotional Text (ข้อความโปรโมต)

Apple limits Promotional Text to 170 characters per localization. ([App Store Connect Help](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information))

#### ภาษาไทย (107 ตัวอักษร)
```text
งีบระหว่างทางได้สบายใจขึ้น เลือกจุดหมายแล้วให้ NapNav เตือนเมื่อเข้าใกล้ พร้อมดูระยะทางที่เหลือบนหน้าจอล็อก
```

#### English (137 characters)
```text
Rest easier on the way. Choose a destination and let NapNav alert you when you're nearby. See the remaining distance on your Lock Screen.
```

---

## 2. Keywords (คำค้นหา - ไม่เกิน 100 ตัวอักษร)

> **ข้อแนะนำจาก Apple:** คั่นด้วยจุลภาค `,` ห้ามเว้นวรรคหลังจุลภาค ห้ามใส่ชื่อซ้ำกับชื่อแอป

### ภาษาไทย (94 Unicode code points; ต่ำกว่า 100):
```text
ปลุก,เตือนพิกัด,บีทีเอส,mrt,bts,รถเมล์,รถไฟฟ้า,ตื่น,จุดหมาย,เลยป้าย,นาฬิกาปลุก,งีบ,ปลุกตามระยะ
```

### English (97 characters; under 100):
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

NapNav (แน็พนาฟ) คือแอปปลุกเตือนตามตำแหน่งสำหรับคนเดินทาง ช่วยให้คุณพักสายตาระหว่างทางและรับการเตือนเมื่อเข้าใกล้จุดหมายที่เลือก เวลาเตือนขึ้นกับตำแหน่งที่ได้รับ สิทธิ์ และการตั้งค่า iOS

ฟีเจอร์เด่นของ NapNav:
• กำหนดระยะเตือนตามตำแหน่ง: เลือกรัศมีแจ้งเตือนล่วงหน้าได้ตามต้องการ (500 ม., 1 กม., 2 กม. ฯลฯ) ความแม่นยำและเวลาที่เตือนขึ้นกับสัญญาณ ตำแหน่ง และการตั้งค่า
• โหมดเตือน "Use Both": ใช้ AlarmKit เป็นเสียงหลักบน iOS/อุปกรณ์ที่รองรับ พร้อม Notification แบบไม่มีเสียงเมื่ออนุญาตและพร้อมใช้งาน หาก AlarmKit ใช้ไม่ได้จะใช้ Notification เมื่อระบบอนุญาต ผลการเตือนขึ้นกับสิทธิ์และการตั้งค่าอุปกรณ์
• ดูสถานะทริประหว่างทาง: เมื่อ Live Activity แสดงบนหน้าจอล็อกหรือ Dynamic Island คุณดูสถานะและระยะทางที่ระบบได้รับโดยไม่ต้องเปิดแอป
• ค้นหาง่าย ปักหมุดสะดวก: ค้นหาสถานที่ หรือแตะลากหมุดบนแผนที่ได้อย่างอิสระ
• บันทึกสถานที่โปรด: บันทึกสถานีประจำ บ้าน หรือที่ทำงาน เพื่อเริ่มทริปได้ในแตะเดียว
• ติดตามตำแหน่งระหว่างทริปที่เริ่ม: ใช้ตำแหน่งเพื่อคำนวณระยะทาง การใช้แบตเตอรี่และความแม่นยำขึ้นกับอุปกรณ์ สัญญาณ และการตั้งค่า
• ความเป็นส่วนตัว: ไม่มีบัญชีหรือ SDK โฆษณา/วิเคราะห์ข้อมูลจากผู้พัฒนา; สถานที่โปรดและล่าสุดจัดเก็บบนอุปกรณ์ การค้นหาสถานที่ใช้ Apple Maps/MapKit ซึ่งอาจส่งคำค้นหรือพิกัดที่จำเป็นให้ Apple

ให้ทุกการเดินทางกลับบ้านหรือไปทำงานของคุณผ่อนคลายยิ่งขึ้น โหลด NapNav แล้วพักผ่อนสายตาได้เต็มที่เลยวันนี้! โปรดสังเกตป้ายและประกาศระหว่างเดินทาง เพราะตำแหน่งและการส่งการเตือนอาจล่าช้าหรือไม่พร้อมใช้งาน
```

### ภาษาอังกฤษ (English Description):
```text
Tired after a long day? Want to take a quick nap on the train, subway, or bus without worrying about missing your stop?

NapNav is a location-based transit alarm designed for commuters. It helps you rest along the way and receive an alert as you approach your selected stop. Alert timing depends on location, permissions, and iOS settings.

Key Features:
• Adjustable Location Alert Radius: Choose a radius for NapNav to attempt an alert (500m, 1km, 2km, and more). Accuracy and timing vary with signal, location, and device settings.
• "Use Both" Alert Mode: Uses AlarmKit as its primary sound on supported iOS devices when authorized, with a silent notification companion when available. If AlarmKit is unavailable, NapNav uses the notification path when allowed. Delivery depends on permissions and device settings.
• Live Activities & Dynamic Island: When an activity is available, view trip status and the remaining distance reported by the device on your Lock Screen or Dynamic Island.
• Intuitive Map Pinning: Search destinations effortlessly or drag-and-drop pins anywhere on the map.
• Favorite Places: Save your frequent transit stations, home, or office for instant one-tap trip starts.
• Location During Active Trips: NapNav uses location updates while a trip is active; battery use and accuracy vary by device, signal, and settings.
• Privacy: No NapNav account, developer-operated location server, or third-party advertising/analytics SDK. Favorites and recent destinations are stored on device. Place search uses Apple Maps/MapKit, which may send the query or coordinates needed to Apple.

Make your daily commute restful and worry-free. Download NapNav today and nap with confidence! Location accuracy and alert delivery can be affected by signal, permissions, and device settings; continue to monitor transit signs and announcements.
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
   - *ข้อความพาดหัว:* "Use Both: AlarmKit พร้อมการแจ้งเตือนบนอุปกรณ์ที่รองรับ"
   - *หน้าจอ:* หน้ารายการเลือกวิธีเตือนที่มี "เตือนทั้งสองแบบ (Use Both)" อยู่บนสุด
3. **รูปที่ 3 - หน้าจอล็อกและ Dynamic Island (Live Activities)**
   - *ข้อความพาดหัว:* "ดูสถานะทริปบน Lock Screen"
   - *หน้าจอ:* หน้าจอล็อกที่แสดง Live Activity พร้อมสถานะและระยะทางที่อุปกรณ์รายงาน
4. **รูปที่ 4 - หน้าจัดการสถานที่โปรดและประวัติ (Favorites & History)**
   - *ข้อความพาดหัว:* "บันทึกสถานที่โปรด เริ่มเดินทางได้ในสัมผัสเดียว"
   - *หน้าจอ:* รายการสถานีโปรด เช่น "บ้าน", "ที่ทำงาน", "BTS อโศก"

---

## 7. App Review Information (ข้อมูลสำหรับเจ้าหน้าที่ Apple Reviewer)

> **นำข้อความด้านล่างนี้ไปวางในช่อง "Notes" ใต้หัวข้อ "App Review Information" ใน App Store Connect**

```text
Hello Apple App Review Team,

Thank you for reviewing NapNav!

NapNav is a location-based proximity alarm that helps transit commuters receive an alert near a destination they select.

Key Testing Notes:
1. No Login Required: The app functions immediately without any user authentication, sign-up, or third-party accounts.
2. Background Location Usage: NapNav requests 'When In Use' authorization and uses the location background mode only while a trip is active, so it can update distance while the screen is locked when iOS allows it. NapNav does not request 'Always' authorization. Location accuracy and alert timing can vary with signal, permissions, and system activity.
3. How to Review the Trip Alert:
   - On a supported iPhone, allow While In Use location and Notifications. On iOS 26 or later, allow AlarmKit if the system prompt is shown.
   - Choose a destination near the device's current location and a radius that includes the current location, then tap "Start Trip" and wait for a fresh location update.
   - Observe the trip status and alert. Alert delivery and sound depend on authorization and device settings; NapNav does not guarantee an exact trigger time.
   - Stop or finish the trip from inside NapNav after review. The system alarm's stop control silences that alarm; it does not end the active trip.
4. Siri App Shortcuts: "Go home with NapNav" starts a trip to the saved Home destination, or the first saved favorite if Home is not set. "Stop alert" stops the active trip when explicitly invoked. Siri shortcuts are optional; the trip can be reviewed using the in-app steps above.
5. Contact: If you need any clarification or assistance during review, please reach out via email: techin.cr@gmail.com.

Best regards,
Techin
```

---

## 8. App Privacy Questionnaire (แบบสอบถามความเป็นส่วนตัวใน App Store Connect)

จาก source snapshot ที่ตรวจ ไม่พบ NapNav account/server, analytics/ad SDK หรือการส่ง live GPS ไปยังระบบของผู้พัฒนา; ตำแหน่งที่ใช้เฉพาะบนอุปกรณ์ไม่ถือเป็น data collected ตามคำอธิบายของ Apple และข้อมูลที่ Apple เก็บผ่าน Apple frameworks/services ไม่ใช่ข้อมูลที่ผู้พัฒนาต้องประกาศแทน Apple

1. **Do you or your third-party partners collect data from this app?** — draft answer: **No**, หลังตรวจยืนยัน release binary และ third-party SDK/บริการที่ใช้จริงอีกครั้ง
2. **Data Types:** ไม่เลือกประเภทข้อมูล หากไม่มีการเก็บข้อมูลเพิ่มจาก source snapshot นี้
3. **Tracking:** **No**; source ที่ตรวจไม่พบ ATT/IDFA use หรือการเชื่อมข้อมูลข้ามแอป/เว็บไซต์
4. หากเพิ่ม analytics, advertising, crash reporting, account, backend, หรือ SDK ที่รับข้อมูล ต้องทบทวน App Privacy label และนโยบายนี้ใหม่ก่อนส่ง

หมายเหตุ: Apple Maps/MapKit อาจประมวลผลข้อความค้นหาและพิกัดที่จำเป็นต่อผลลัพธ์ตามนโยบายของ Apple; ดู [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/) และ [Apple Maps & Privacy](https://www.apple.com/legal/privacy/data/en/apple-maps/). ตรวจรายการ dependency และ processed archive ก่อนเลือกคำตอบใน App Store Connect ทุกครั้ง

---

## 9. Age Rating (การจัดเรตติ้งอายุ)

ตอบคำถามในแบบสอบถามเรตติ้งอายุของ Apple ทุกข้อเป็น **"None" / "No"**:
- ไม่มีเนื้อหารุนแรง, ไม่มีคำหยาบ, ไม่มีการพนัน, ไม่มีการจำหน่ายแอลกอฮอล์/บุหรี่, ไม่มีการเข้าถึงเว็บเบราว์เซอร์อิสระ
- **ผลลัพธ์เรตติ้งที่ได้:** **4+ (เหมาะสำหรับทุกวัย)**

---

## 10. General App Information (ข้อมูลทั่วไปของแอป)

* **Primary Category (หมวดหมู่หลัก):** Navigation (การนำทาง) — ให้ตรงกับตารางข้อ 1
* **Secondary Category (หมวดหมู่รอง):** Travel (การเดินทางและท่องเที่ยว) — ให้ตรงกับตารางข้อ 1
* **Price (ราคา):** Free (ฟรี)
* **Availability (พื้นที่จำหน่าย):** All Countries and Regions (ทั่วโลก) หรือเฉพาะ Thailand ตามต้องการ
* **Copyright:** `2026 Techin`
* **Trade Representative Contact:** กรอกชื่อ-นามสกุล ที่อยู่ และเบอร์โทรศัพท์ของตนเอง
* **Export Compliance (การปฏิบัติตามกฎหมายการส่งออก):**
  - `NapNav/Info.plist` ระบุ `ITSAppUsesNonExemptEncryption = NO`; ยืนยันคำตอบอีกครั้งกับสิ่งที่ release binary ใช้จริงใน App Store Connect
