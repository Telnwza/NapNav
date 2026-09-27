# NapNav — Trip Alarm: Development Plan and POC Notes

อัปเดตล่าสุด: 19 กันยายน 2026  
สถานะ: เตรียมเริ่ม Proof of Concept (POC) บน iOS

เอกสารที่เกี่ยวข้อง:

- [Product and Experience Design](STOP_ALARM_PRODUCT_DESIGN.md)
- [Technical POC Specification](STOP_ALARM_POC_SPEC.md)

## 1. Product vision

NapNav คือผู้ช่วยเฝ้าจุดหมายระหว่างพักหรือนอนบนรถสาธารณะ แอปจะแจ้งเตือนเมื่อใกล้ถึงจุดหมาย โดยเริ่มจากตำแหน่ง GPS และค่อยเพิ่มความเข้าใจเรื่องสายรถ สถานี และลำดับป้ายในรุ่นถัดไป

หลักการสำคัญ:

- แกนหลักคือ “ปลุกเมื่อใกล้ถึงจุดหมาย” ไม่ใช่แอปดูตำแหน่งรถ
- รุ่นแรกต้องใช้งานได้โดยไม่ต้องมีบัญชีหรือ backend
- ตำแหน่งควรถูกประมวลผลบนอุปกรณ์เป็นค่าเริ่มต้น
- ต้องแยกคำว่า “ประมาณการ” ออกจาก “ยืนยันแล้ว” ให้ผู้ใช้เข้าใจ
- ความน่าเชื่อถือขณะล็อกจอสำคัญกว่าจำนวนฟีเจอร์

## 2. MVP — GPS distance alarm

### User flow

1. ผู้ใช้ค้นหาสถานที่หรือปักหมุดบนแผนที่
2. เลือกระยะเตือน เช่น 500 เมตร, 1 กิโลเมตร หรือ 2 กิโลเมตร
3. เลือกเสียงและการสั่น
4. กดเริ่มการเดินทาง
5. ล็อกหน้าจอหรือออกจากแอปได้
6. แอปแจ้งเตือนเมื่อเข้าเงื่อนไข
7. ผู้ใช้หยุดการเดินทางหรือเลื่อนการเตือน

### Trip state

```text
Idle
  -> Armed
  -> Tracking
  -> Approaching
  -> Alarm
  -> Completed
```

ต้องรองรับเส้นทางผิดปกติด้วย:

```text
Tracking -> LocationUnavailable
Tracking -> WrongDirection
Tracking -> Cancelled
Alarm    -> Snoozed -> Tracking
```

### Location strategy

ใช้การตรวจสอบสองชั้นเพื่อลดการใช้แบตเตอรี่:

```text
Geofence รอบนอกประมาณ 3–5 กม.
        -> เข้าเขตรอบนอก
เพิ่มความถี่และความแม่นยำของตำแหน่ง
        -> เข้าเขตปลุกประมาณ 500–1,000 ม.
ตรวจความใหม่ ความแม่นยำ ทิศทาง และความเร็ว
        -> แจ้งเตือน
```

ข้อมูลตำแหน่งที่จะนำไปตัดสินใจต้องผ่านอย่างน้อย:

- `horizontalAccuracy` เป็นค่าที่ใช้ได้และไม่กว้างเกินเกณฑ์
- timestamp ไม่เก่า
- การเคลื่อนที่สมเหตุผล
- ไม่ปลุกจากพิกัดกระโดดเพียง sample เดียว
- ใช้หลาย sample ยืนยันเมื่อตำแหน่งมีความไม่แน่นอนสูง

### MVP screens

1. Destination Search / Map
2. Alarm Configuration
3. Active Trip
4. Alarm / Arrival
5. Permission and Recovery UI

### MVP acceptance criteria

- เริ่มและหยุดทริปได้โดยไม่มี state ค้าง
- แจ้งเตือนเมื่อหน้าจอล็อกได้บนอุปกรณ์จริง
- ไม่ปลุกจาก GPS sample ที่เก่าหรือ invalid
- แสดงสถานะเมื่อไม่ได้รับสิทธิ์ Location หรือ Notification
- ยกเลิก background tracking หลังจบทริป
- จำลองเส้นทางด้วย GPX และผ่าน unit tests ของ trigger policy
- มีบันทึกผลการทดสอบจริงอย่างน้อยหลายเส้นทางและหลายสภาพสัญญาณ

## 3. Architecture proposal

เริ่มด้วย SwiftUI แบบ MV และแยก service/domain boundary เท่าที่จำเป็น ยังไม่ใช้สถาปัตยกรรมขนาดใหญ่จนกว่าจะพบความซับซ้อนจริง

```text
TripStore
  - owns trip state and coordinates effects

LocationProvider
  - Core Location implementation
  - mock implementation for tests

DestinationProvider
  - map coordinate destination
  - future transit-stop destination

TriggerPolicy
  - DistanceTrigger
  - future StopsRemainingTrigger
  - future ETATrigger
  - future HybridTrigger

AlarmService
  - local notification
  - sound
  - haptic where available

TransitCatalog
  - future GTFS agencies, routes, stops, trips and stop sequences
```

หลักการออกแบบคือ UI ไม่ตัดสินใจเองว่าเมื่อไรควรปลุก และ Core Location ไม่ควรรู้รายละเอียดหน้าจอ

## 4. Planned roadmap

### Phase 0 — Technical POC

- สร้าง Xcode project ขั้นต่ำ
- ขอ Location และ Notification permission อย่างถูกจังหวะ
- ปักหมุดปลายทาง
- รับ location updates และแสดงระยะทาง
- ทำ distance trigger แบบง่าย
- ส่ง local notification ตอนเข้าเงื่อนไข
- ทดสอบ foreground, background และ locked screen
- สร้าง GPX route fixtures

### Phase 1 — Usable GPS MVP

- outer/inner geofence strategy
- filtering ตำแหน่งที่ stale หรือ inaccurate
- persistent active-trip state
- alarm sound และ notification actions
- Settings recovery เมื่อ permission ถูกปฏิเสธ
- destination history และ favorite destinations
- battery and reliability testing บนอุปกรณ์จริง

### Phase 1.1 — Smart alarm

- ปรับระยะเตือนจากความเร็วและเวลาเตรียมตัว
- แจ้งเตือนหลายระดับ เช่น 10 นาทีและ 3 นาที
- wrong-direction detection
- confidence indicator
- fallback alarm จากเวลาประมาณการเมื่อ location หาย
- feedback หลังทริป: เร็วไป / พอดี / ช้าไป

### Phase 2 — Rail and station mode

- เลือกระบบ สาย สถานีขึ้น และสถานีลง
- ปลุกก่อนถึง 1–3 สถานี
- แสดงจำนวนสถานีที่เหลือ
- รองรับ interchange station
- cache ข้อมูลสถานีสำหรับใช้ออฟไลน์
- ใช้ GPS + route geometry + stop sequence ร่วมกัน

### Phase 3 — Bus route mode

- เลือกสายรถ ขาไป/ขากลับ และป้ายลง
- map matching กับแนวเส้นทาง
- นับป้ายที่ผ่านแล้ว
- ตรวจจับขึ้นผิดฝั่งหรือเคลื่อนผิดทิศทาง
- ปลุกก่อนถึงตามจำนวนป้ายหรือ ETA

### Phase 4 — Realtime and ecosystem

- เชื่อม official realtime API เมื่อยืนยันสิทธิ์ใช้งานได้
- Apple Watch haptic alert
- Live Activity บน Lock Screen
- Siri / App Intent เช่น “ปลุกฉันก่อนถึงอโศก”
- multi-leg journey เช่น รถเมล์ -> BTS -> เดิน
- transfer alarm

## 5. Transit data strategy

แหล่งข้อมูลที่น่าสนใจคือ Namtang Open Data ของสำนักงานนโยบายและแผนการขนส่งและจราจร ซึ่งเผยแพร่ข้อมูลจุดจอด สถานี และข้อมูลการเดินรถภายใต้ CC-BY

- Open Data: https://namtang-api.otp.go.th/opendata
- GTFS feed: https://namtang-api.otp.go.th/download/namtang-gtfs.zip
- System coverage: https://namtang-api.otp.go.th/about

แนวทางใช้งาน:

1. ไม่ใส่ GTFS ทั้งประเทศลงแอปโดยตรง
2. preprocess ข้อมูลตอน build หรือผ่าน backend ขนาดเล็ก
3. เลือกเฉพาะพื้นที่และระบบที่รองรับ
4. สร้าง compact SQLite หรือ JSON พร้อม version/date
5. validate feed ก่อนเผยแพร่ทุกครั้ง
6. แสดง attribution ตามเงื่อนไข CC-BY

ห้ามพึ่ง undocumented/private API หรือ scrape แอปของผู้ให้บริการเป็นแกนหลัก เพราะ API อาจเปลี่ยน ถูกปิด หรือมีปัญหาด้านสิทธิ์ใช้งาน

## 6. MRT underground station detection

### คำถามทดลอง

เมื่อ GPS ใช้ไม่ได้ในอุโมงค์ สามารถใช้ accelerometer ตรวจจับการเร่ง เบรก และหยุดเพื่อประมาณว่านับผ่านกี่สถานีได้หรือไม่

### ข้อสรุปปัจจุบัน

ทำเป็นตัวประมาณได้ แต่ accelerometer อย่างเดียวไม่ควรเป็นแหล่งตัดสินหลัก เพราะ:

- โทรศัพท์อาจอยู่ในมือ กระเป๋า หรือวางคนละทิศ
- ผู้ใช้หยิบหรือขยับโทรศัพท์ระหว่างทาง
- ขบวนรถอาจชะลอหรือหยุดกลางอุโมงค์
- เวลาจอดและเวลาระหว่างสถานีเปลี่ยนแปลงได้
- การอินทิเกรตค่าความเร่งเพื่อหาระยะทางสะสม error อย่างรวดเร็ว
- iOS อาจ suspend แอป และ live motion updates ไม่ได้รับประกันว่าจะมาถึงขณะ suspend
- recorded sensor data ใช้วิเคราะห์ย้อนหลังได้ แต่ไม่เหมาะกับ alarm แบบทันที

### Proposed hybrid estimator

```text
สถานีต้นทาง + ทิศทาง + ลำดับสถานี
                  +
ตารางเวลาแต่ละช่วง
                  +
Accelerometer/Gyroscope motion pattern
                  +
ตำแหน่งที่ได้รับเป็นครั้งคราว
                  ->
Estimated current station + confidence
```

ตัวจำแนกเบื้องต้น:

```text
StoppedAtStation
  -> Accelerating
  -> Cruising
  -> Braking
  -> PossibleStop
  -> EstimatedNextStation
```

เงื่อนไขการนับสถานีควรรวม:

- มีการเคลื่อนต่อเนื่องนานพอ
- พบ pattern เร่ง -> วิ่ง -> เบรก
- หยุดนิ่งภายในช่วงเวลาที่สมเหตุผล
- เวลาจากสถานีก่อนหน้าใกล้กับ expected segment time
- นับได้เฉพาะสถานีลำดับถัดไป
- ถ้าเงื่อนไขไม่ครบ ให้ลด confidence แทนการนับทันที

UX ต้องใช้คำว่า “คาดว่า” เช่น:

```text
คาดว่าอยู่ระหว่าง สุขุมวิท -> เพชรบุรี
สถานีถัดไป: เพชรบุรี
ความมั่นใจ: 72%
```

ควรแจ้งเตือนล่วงหน้าประมาณสองสถานีเพื่อมี safety margin

### Alternative techniques

| เทคนิค | ความน่าเชื่อถือ | ข้อจำกัด |
|---|---:|---|
| Official train-position feed | สูงที่สุด | ต้องมี API หรือความร่วมมือ |
| iBeacon/BLE ที่สถานี | สูง | ต้องติดตั้งหรือเข้าถึง beacon identifiers |
| Schedule + motion sensor fusion | ปานกลาง | คลาดเมื่อรถล่าช้าหรือหยุดผิดปกติ |
| Magnetic fingerprint | ปานกลางในงานทดลอง | ต้องสร้างฐานข้อมูลทุกช่วงรางและหลายรุ่นอุปกรณ์ |
| เสียงประกาศสถานี | ต่ำ–ปานกลาง | เสียงรบกวน ความเป็นส่วนตัว และ background microphone |
| Accelerometer เท่านั้น | ต่ำ | false detection สูง |
| Timer เท่านั้น | ต่ำ | ไม่ปรับตามความล่าช้า |

ทางออกที่น่าเชื่อถือที่สุดในระยะยาวคือ official realtime feed หรือ beacon infrastructure จากผู้ให้บริการ

## 7. MRT sensor experiment

ก่อนพัฒนาเป็นฟีเจอร์จริง ให้สร้าง experiment แยกจาก production app

### Data collection

- บันทึก accelerometer, gyroscope, timestamp และ device orientation
- ให้ผู้ทดสอบแตะ ground-truth marker เมื่อประตูเปิด
- บันทึกสาย ทิศทาง สถานีต้นทางและปลายทาง
- ทดลองหลายตำแหน่ง: ถือในมือ กระเป๋ากางเกง กระเป๋าสะพาย
- ทดลองอย่างน้อย 20–30 เที่ยวและหลายรุ่น iPhone
- แยกผลตอนเปิดจอ ล็อกจอ และแอปอยู่เบื้องหลัง

### Metrics

- station-count accuracy
- false station rate
- missed station rate
- alert lead time
- battery usage
- background data continuity
- confidence calibration

### Suggested POC success gate

- ไม่ปลุกหลังสถานีเป้าหมายในการทดสอบปกติ
- แจ้งล่วงหน้าอย่างน้อยหนึ่งสถานีในอย่างน้อย 95% ของเที่ยวทดสอบ
- false count ไม่ทำให้ตำแหน่งคลาดเกินหนึ่งสถานี
- เมื่อ confidence ต่ำ แอปต้องเตือนผู้ใช้ว่าเป็นการประมาณและเลือก fallback ที่ปลอดภัยกว่า

## 8. Immediate next steps

1. ยืนยันข้อเสนอ deployment target ที่ iOS 18+
2. Xcode 27.0 ตรวจแล้ว; ระบุ iPhone ที่จะใช้ทดสอบจริง
3. สร้าง POC project ที่ยังไม่มี design ซับซ้อน
4. สร้าง `LocationProvider` และ mock provider
5. สร้าง `DistanceTrigger` พร้อม unit tests
6. สร้าง local notification smoke test
7. สร้าง GPX route fixture
8. ทดสอบ background/locked-screen บนอุปกรณ์จริง
9. เก็บผลก่อนตัดสินใจทำ UI เต็มรูปแบบ

## 9. Open decisions

- ยืนยันว่าจะใช้ iOS 18+ เป็นขั้นต่ำสำหรับ POC หรือไม่
- ใช้ `When In Use` + active background session หรือจำเป็นต้องขอ `Always`
- ระยะปลุกเริ่มต้นควรเป็นค่าคงที่หรือเวลาเตรียมตัว
- notification ปกติเพียงพอหรือควรมีขั้นตอนตรวจ Silent/Focus ก่อนเริ่มทริป
- เก็บข้อมูลทริปในเครื่องนานเท่าไร
- POC แรกจะทดสอบบนรถประเภทใดและเส้นทางใด
- จะรวม MRT sensor experiment ในแอปเดียวหรือทำเป็น diagnostic target แยก
