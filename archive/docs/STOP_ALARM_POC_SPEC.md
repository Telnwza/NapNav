# NapNav — Trip Alarm: Technical POC Specification

อัปเดตล่าสุด: 20 กันยายน 2026  
สถานะ: Phase 0 vertical slice พร้อมทดสอบบนอุปกรณ์จริง

## Implementation checkpoint — 20 กันยายน 2026

ทำแล้ว:

- สร้าง `StopAlarm.xcodeproj` โดยกำหนด deployment target เป็น iOS 18+
- เปลี่ยนชื่อแอปและ build product เป็น **NapNav — Trip Alarm** โดยคงชื่อ target/module เดิมไว้
- เพิ่ม MapKit autocomplete และการแตะแผนที่เพื่อเลือกจุดหมายจริง
- สร้าง flow SwiftUI: เลือกอโศก → ตั้งระยะ → เริ่มเดินทาง → รับตำแหน่งจริง → หยุดการเตือน
- ใช้ `MapCircle(center:radius:)` แสดงวงแจ้งเตือนตามระยะ 100 เมตร–5 กิโลเมตร
- แยก `TriggerPolicy` เป็น pure domain logic
- ต่อ `CLLocationUpdate.liveUpdates(.otherNavigation)` พร้อม permission และ diagnostics
- ถือ `CLServiceSession` และ `CLBackgroundActivitySession` ตลอดทริป แล้วหยุดเมื่อจบทริป
- ต่อ local notification จริง พร้อม banner/sound ขณะแอปอยู่ foreground
- เพิ่มปุ่มทดสอบ notification แยกจากเงื่อนไขระยะทาง
- เพิ่ม Swift Testing จำนวน 9 tests และรันผ่านทั้งหมดบน iPhone 17 Simulator (iOS 27.0)
- เพิ่ม GPX fixtures สามแบบ: เข้าเขต, ผ่านนอกเขต และตำแหน่งกระโดด
- app target และ test target คอมไพล์ผ่านด้วย Swift 6 และ iPhoneOS/iPhoneSimulator 27 SDK

ยังไม่ถือว่าพิสูจน์:

- ยังไม่ได้ยืนยัน GPX ทั้งสามแบบด้วยการกด flow ใน UI
- ยังไม่ได้ทดสอบ background/ล็อกหน้าจอและ GPS จริงบน iPhone
- ยังไม่ได้วัดความแม่นยำและแบตเตอรี่ระหว่างการเดินทางจริง

## 1. Objective

พิสูจน์ว่า iPhone สามารถติดตามตำแหน่งของทริปที่ผู้ใช้เริ่มเอง และส่ง local notification เมื่อเข้าเขตเตือน โดยยังทำงานได้เมื่อแอปอยู่ background หรือหน้าจอล็อก

POC นี้ไม่ได้พิสูจน์ความแม่นยำในรถไฟใต้ดินและไม่ได้รับประกันเสียงเมื่ออุปกรณ์อยู่ใน Silent/Focus

## 2. Proposed platform

- SwiftUI
- Swift 6
- MapKit และ Core Location
- UserNotifications
- เสนอ deployment target: iOS 18+
- Toolchain ที่ตรวจพบบนเครื่อง: Xcode 27.0 (build 27A266a)
- ต้องทดสอบบน iPhone จริงอย่างน้อยหนึ่งเครื่อง

เหตุผลที่เสนอ iOS 18+: ใช้ `CLLocationUpdate`, `CLServiceSession` และ location diagnostics สมัยใหม่ได้โดยไม่ต้องรักษา implementation สองชุดในช่วงพิสูจน์แนวคิด ส่วน `CLMonitor` จะเพิ่มเมื่อเริ่ม outer/inner geofence ใน GPS MVP

## 3. Vertical slice

POC ต้องทำ flow นี้ได้ครบ:

```text
เปิดแอป
-> เห็นปลายทางทดสอบบนแผนที่
-> เลือกรัศมี 500 เมตร / 1 กิโลเมตร / 2 กิโลเมตร
-> กด Start
-> ตรวจและขอ permission ตามจังหวะ
-> แสดงระยะและคุณภาพ location ล่าสุด
-> ล็อกหน้าจอหรือออกจากแอป
-> เข้าเขตเตือนด้วย GPX หรือเดินทางจริง
-> ได้รับ local notification
-> กลับเข้าแอปและจบทริป
-> location/background work หยุดทั้งหมด
```

## 4. POC scope

### Included

- ค้นหาจุดหมายจริงด้วย MapKit autocomplete
- แตะแผนที่เพื่อปักหมุดและ reverse geocode ชื่อสถานที่
- แผนที่พร้อม marker และ `MapCircle` แสดงรัศมี
- Start/Stop trip
- Location และ Notification permission flow
- foreground location updates
- background activity session ระหว่างทริป
- local notification เมื่อ trigger
- การกรอง invalid, stale และ inaccurate samples
- mock location provider สำหรับ tests
- GPX fixture อย่างน้อยหนึ่งเส้นทางเข้าเขตและหนึ่งเส้นทางผ่านนอกเขต
- diagnostic log ที่อ่านได้ใน Debug build

### Excluded

- directions/route polyline
- user account/backend
- history/favorites
- GTFS และ station mode
- wrong-direction product behavior นอกเหนือจาก diagnostic
- battery optimization แบบ outer/inner geofence เต็มรูปแบบ
- custom/critical alarm sound

## 5. Architecture

ใช้ SwiftUI MV และ dependency injection แบบเล็กที่สุด:

```text
StopAlarmApp
  |
  +-- TripStore (@MainActor, @Observable)
        |
        +-- LocationProviding
        +-- NotificationProviding
        +-- TripPersisting
        +-- TriggerPolicy (pure domain logic)
```

### `TripStore`

รับผิดชอบ:

- เริ่มและหยุดทริป
- เป็นเจ้าของ `TripPhase` และ `TripHealth`
- เริ่ม/ยกเลิก location stream
- ส่ง sample ที่ผ่านการกรองให้ `TriggerPolicy`
- สั่ง notification เมื่อ policy trigger ครั้งแรก
- คืน resource ทั้งหมดเมื่อ completed/cancelled

ไม่รับผิดชอบ:

- วาดแผนที่
- คำนวณ layout
- เรียก permission dialog จาก view โดยไม่มี user action
- ตัดสิน trigger ภายใน view

### Dependency protocols

```swift
protocol LocationProviding: Sendable {
    func updates() -> AsyncStream<LocationSample>
    func startTrip() async throws
    func stopTrip() async
}

protocol NotificationProviding: Sendable {
    func authorizationStatus() async -> NotificationStatus
    func requestAuthorization() async throws -> Bool
    func sendArrivalAlert(for destination: Destination) async throws
}

protocol TripPersisting: Sendable {
    func save(_ trip: ActiveTrip) async throws
    func loadActiveTrip() async throws -> ActiveTrip?
    func clearActiveTrip() async throws
}
```

ชนิดข้อมูลที่ข้าม concurrency boundary ต้องเป็น `Sendable`

## 6. Domain model

```text
TripPhase:
idle, preparing, tracking, approaching, alarm, completed, cancelled

TripHealth:
ready, locationUnavailable, staleLocation,
reducedAccuracy, notificationUnavailable

Destination:
id, name, latitude, longitude

ActiveTrip:
destination, alarmRadiusMeters, startedAt, phase

LocationSample:
coordinate, horizontalAccuracy, timestamp, speed, course
```

## 7. Trigger policy v0

ค่าทั้งหมดเป็นค่าเริ่มทดลองและต้องปรับจากข้อมูลจริง:

1. ปฏิเสธ sample ที่ `horizontalAccuracy < 0`
2. ปฏิเสธ sample ที่เก่ากว่า 15 วินาที
3. ปฏิเสธ sample ที่ accuracy กว้างเกิน 100 เมตร
4. คำนวณ straight-line distance ถึง destination
5. หากอยู่นอกรัศมี ให้กลับ `outside`
6. หากเข้าในรัศมีด้วย sample คุณภาพสูง ให้ต้องยืนยันสอง sample ต่อเนื่อง
7. หาก accuracy ใกล้เคียงหรือกว้างกว่ารัศมี ให้กลับ `uncertain` และยังไม่ปลุก
8. trigger ได้เพียงครั้งเดียวต่อ trip

API ที่เสนอ:

```swift
enum TriggerDecision: Equatable, Sendable {
    case rejected(LocationRejectionReason)
    case outside(distanceMeters: Double)
    case uncertain(distanceMeters: Double)
    case approaching(distanceMeters: Double)
    case trigger(distanceMeters: Double)
}
```

`TriggerPolicy` ต้องเป็น pure logic เพื่อทดสอบได้โดยไม่ใช้ Core Location จริง

## 8. Permission strategy

1. ไม่ขอสิทธิ์ทันทีที่เปิดแอป
2. อธิบายประโยชน์ก่อน system dialog
3. เริ่มจาก When In Use
4. เปิด background session เฉพาะตอนมี active trip
5. ขอ Always เฉพาะเมื่อผลทดสอบยืนยันว่าจำเป็นต่อ recovery/relaunch ที่ต้องการ
6. เมื่อ denied ให้แสดง Settings recovery path
7. เมื่อ Notification ไม่พร้อม ห้ามแสดงว่าทริป “พร้อมเตือน”

ข้อความ `Info.plist` ฉบับร่าง:

> NapNav ใช้ตำแหน่งระหว่างทริปที่คุณเริ่ม เพื่อแจ้งเตือนเมื่อเข้าใกล้จุดหมาย แม้หน้าจอจะล็อกอยู่

## 9. Persistence and recovery

เก็บเฉพาะ active trip ที่จำเป็น:

- destination
- alarm radius
- start time
- last phase
- whether alert has fired

เมื่อเปิดแอปใหม่:

1. โหลด active trip
2. ตรวจ authorization ใหม่ทุกครั้ง
3. สร้าง service/background session ใหม่ตาม lifecycle ที่ระบบอนุญาต
4. ห้าม trigger จาก cached location เก่า
5. หากกู้คืนไม่ได้ ให้แสดง recovery state พร้อม Stop Trip

POC ไม่เก็บ location history

## 10. Test plan

### Unit tests

- outside radius ไม่ trigger
- invalid accuracy ถูก reject
- stale sample ถูก reject
- sample กระโดดเข้าเขตครั้งเดียวไม่ trigger
- valid samples สองครั้งต่อเนื่อง trigger หนึ่งครั้ง
- uncertain accuracy ไม่ trigger
- completed/cancelled trip ไม่รับ sample เพิ่ม
- stopping a trip cancels work and clears persistence

### GPX tests

- `approach-destination.gpx`: เคลื่อนจากนอกเขตเข้าสู่เขต
- `pass-outside.gpx`: ผ่านใกล้แต่ไม่เข้าเขต
- `gps-jump.gpx`: sample หนึ่งจุดกระโดดเข้าเขตแล้วกลับออก

### Physical-device matrix

| Case | Foreground | Background | Locked screen |
|---|---:|---:|---:|
| Start/stop trip | Required | — | — |
| Receive location | Required | Required | Required |
| Trigger once | Required | Required | Required |
| Notification visible | Required | Required | Required |
| Cleanup after stop | Required | Required | Required |
| Permission denied recovery | Required | Required | — |

ทดสอบเพิ่มอย่างน้อย:

- Wi-Fi เปิด/ปิด
- Low Power Mode
- Reduced Accuracy
- Notification sound เปิด/ปิด
- เครื่องเคลื่อนที่เร็วและช้า

## 11. Acceptance criteria

POC ผ่านเมื่อ:

- vertical slice ทำงานครบโดยไม่มี state ค้าง
- trigger policy unit tests ผ่านทั้งหมด
- GPX ทั้งสามแบบให้ผลตามคาด
- local notification ปรากฏเมื่อหน้าจอล็อกบนอุปกรณ์จริง
- sample ที่ stale/invalid ไม่ทำให้แจ้งเตือน
- notification ถูกส่งไม่เกินหนึ่งครั้งต่อ trip
- Stop Trip ยกเลิก location task, background session และ pending trip state
- UI แสดง degraded state เมื่อ permission หรือ location ใช้ไม่ได้
- มี test log ระบุอุปกรณ์, OS, เส้นทาง, permission state และผลลัพธ์

สิ่งที่ยังไม่ถือว่าพิสูจน์แม้ POC ผ่าน:

- ความน่าเชื่อถือบนรถไฟใต้ดิน
- ความแม่นยำครอบคลุมทุกพื้นที่
- battery impact ระยะยาว
- เสียงดังผ่าน Silent/Focus
- ความพร้อมสำหรับ App Store

## 12. Implementation order

1. สร้าง Xcode project และ test target
2. สร้าง domain models กับ `TriggerPolicy` tests
3. สร้าง mock location stream และ TripStore tests
4. ทำ UI ด้วย mock data พร้อม previews
5. ต่อ live Core Location
6. ต่อ notification permission และ local notification
7. เพิ่ม background session และ persistence
8. เพิ่ม GPX fixtures
9. ทดสอบ Simulator
10. ทดสอบบน iPhone จริงและบันทึกผล
