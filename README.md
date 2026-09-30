# NapNav 🧭💤

<div align="center">
  <img src="NapNav/Assets.xcassets/AppIcon.appiconset/NapNav-iOS-Default-1024@1x.png" width="128" height="128" alt="NapNav Icon" style="border-radius: 28px;" />

  <h3>แอปแจ้งเตือนพิกัดจุดหมาย สำหรับคนเดินทาง — หลับได้สบายใจ ไม่ต้องกลัวเลยป้าย</h3>

  <p>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL_v3-blue.svg" alt="License: GPL v3"></a>
    <img src="https://img.shields.io/badge/iOS-18.0%2B-black?logo=apple" alt="iOS 18.0+">
    <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift 6.0">
    <img src="https://img.shields.io/badge/Xcode-16.0%2B-blue?logo=xcode" alt="Xcode 16.0+">
    <a href="https://buymeacoffee.com/techin"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow.svg?logo=buy-me-a-coffee" alt="Buy Me A Coffee"></a>
  </p>
</div>

---

## 📖 เกี่ยวกับ NapNav (About NapNav)

**NapNav** เป็นแอปพลิเคชันบน iOS พัฒนาด้วย **SwiftUI** และ **ActivityKit** ออกแบบมาเพื่อแก้ปัญหาคลาสสิกของคนเดินทางด้วยระบบขนส่งสาธารณะ (รถไฟฟ้า BTS/MRT, รถไฟชานเมือง, รถเมล์ หรือรถตู้) ที่เหนื่อยล้าจากการทำงานหรือเรียน แล้วอยากงีบหลับพักสายตาระหว่างทาง แต่กังวลว่าจะนอนเพลินจนเลยป้ายหรือสถานีปลายทาง

เมื่อเริ่มทริป NapNav ใช้ตำแหน่งเพื่อคำนวณระยะและพยายามแจ้งเตือนเมื่อเข้าใกล้รัศมีที่เลือก เวลาและการส่งเตือนขึ้นกับตำแหน่งที่ระบบได้รับ สิทธิ์ และการตั้งค่า iOS. เมื่อระบบรองรับและแสดง **Live Activity** คุณดูสถานะกับระยะทางบน **Lock Screen** หรือ **Dynamic Island** ได้โดยไม่ต้องเปิดแอป

---

## ✨ คุณสมบัติเด่น (Key Features)

- 📍 **ระบบเตือนตามพิกัดจริง (Proximity & Location-based Alert)**
  - เลือกระยะเตือน เช่น 500 ม., 1 กม., 2 กม. หรือกำหนดเอง
  - Trigger policy ใช้ตำแหน่งที่ได้รับเพื่อยืนยันการเข้าเขต; สัญญาณหรือการอัปเดตตำแหน่งอาจทำให้การเตือนล่าช้าหรือไม่พร้อมใช้งาน
- 🏝️ **Live Activities & Dynamic Island**
  - ดูสถานะทริปและระยะทางบน Lock Screen หรือ Dynamic Island เมื่อ Live Activity พร้อมใช้งาน
  - ปุ่มหยุด/จบทริปเปิดหน้าต่างยืนยันก่อนเปลี่ยนสถานะทริป
- 🔔 **ตั้งค่าการแจ้งเตือนได้ยืดหยุ่น (Customizable Alerts)**
  - ใช้ AlarmKit และ/หรือ Notification ตามโหมดที่เลือก การอนุญาต และความพร้อมของอุปกรณ์
  - ปุ่มหยุดเสียงของระบบ AlarmKit ปิดเสียง alarm นั้น; ทริปที่ยัง active จะติดตามต่อจนถึงจุดหมายหรือผู้ใช้สั่งหยุดทริปแยกต่างหาก
- 🗺️ **ค้นหาสถานที่ & จุดหมายโปรด (Search & Favorites)**
  - ค้นหาสถานีหรือสถานที่ปลายทางได้อย่างรวดเร็วผ่าน Apple Maps (MapKit)
  - บันทึกสถานที่ที่ใช้บ่อยเป็นรายการโปรด (Favorites) เช่น "บ้าน", "ที่ทำงาน" แตะครั้งเดียวเริ่มเดินทางได้ทันที
  - ประวัติจุดหมายล่าสุด (Recent Destinations) เพื่อความสะดวกรวดเร็ว
- 🔋 **ติดตามตำแหน่งระหว่างทริป (Location During Active Trips)**
  - ใช้ location updates ขณะทริป active; การใช้แบตเตอรี่และความแม่นยำขึ้นกับอุปกรณ์ สัญญาณ และการตั้งค่า
- 🌐 **รองรับ 2 ภาษาเต็มรูปแบบ (Bilingual Support)**
  - ภาษาไทย (Thai) และ ภาษาอังกฤษ (English) ปรับเปลี่ยนตามระบบหรือเลือกในแอปได้
- ♿ **การช่วยการเข้าถึง (Accessibility)**
  - มี accessibility labels/values สำหรับตัวควบคุมหลัก และปรับ layout สำหรับ Dynamic Type กับ Reduce Motion
  - การตรวจด้วย VoiceOver และหน้าจอจริงยังเป็นงาน QA แยกต่างหาก; ดูสถานะล่าสุดใน `docs/DEVELOPMENT_REPORT.md`

---

## 🛠️ สถาปัตยกรรมและเทคโนโลยี (Architecture & Tech Stack)

NapNav พัฒนาขึ้นโดยยึดหลัก Clean Architecture และ Modern iOS Concurrency:

- **UI Framework:** SwiftUI (iOS 18+)
- **Concurrency:** Swift Concurrency (`async`/`await`, `Task`, `@MainActor`) บน Swift 6.0
- **Location Services:** CoreLocation, MapKit (`PlaceSearchService`)
- **Live Activities & Widgets:** ActivityKit, WidgetKit
- **Notifications:** UserNotifications
- **State Management:** Observable Pattern (`TripStore`) แยก Business Logic ออกจาก View ชัดเจน
- **Persistence:** Local Storage Protocol-oriented (`UserDefaultsTripPersistence`)
- **Automated Testing:** Swift Testing ครอบคลุม location policy, trip recovery, localization และ alert delivery; ผลล่าสุดพร้อม source fingerprint อยู่ใน `docs/DEVELOPMENT_REPORT.md` (ไม่มี static pass-count badge เพื่อไม่ให้ผลเก่าถูกเข้าใจว่าเป็น snapshot ปัจจุบัน)

```text
NapNav/
├── NapNav/                  # ซอร์สโค้ดหลักของแอป
│   ├── DomainModels.swift      # Model ข้อมูลหลัก (Trip, Destination, Location)
│   ├── TripStore.swift         # State Machine และ Logic การจัดการทริป
│   ├── TriggerPolicy.swift     # ตรรกะการคำนวณระยะและการสั่งปลุก
│   ├── RootView.swift          # UI หลักและการนำทาง
│   ├── LiveActivityManager.swift # จัดการวงจรชีวิตของ ActivityKit
│   └── SystemClients.swift     # ตัวประสานงาน CoreLocation, Audio, Notifications
├── NapNavWidget/               # Extension สำหรับ Dynamic Island & Live Activity
│   └── TripLiveActivityWidget.swift
├── NapNavTests/             # ชุด Unit Tests และ Mock Objects
└── TestRoutes/                 # ไฟล์ GPX จำลองพิกัดการเดินทางสำหรับทดสอบ
```

---

## 🚀 วิธีติดตั้งและรันโปรเจกต์ (Getting Started)

### ความต้องการของระบบ (Prerequisites)
- Mac ที่ใช้ macOS รุ่นซึ่งรองรับ Xcode 16 หรือใหม่กว่า
- **Xcode 16.0** หรือใหม่กว่า (project ใช้ Swift 6.0)
- อุปกรณ์ iOS 18.0+ หรือ iPhone/iPad Simulator ที่ Xcode รองรับ

### ขั้นตอนการรัน
1. **Clone คลังโค้ดนี้:**
   ```bash
   git clone https://github.com/Telnwza/NapNav.git
   cd NapNav
   ```

2. **เปิดโปรเจกต์ใน Xcode:**
   ```bash
   open NapNav.xcodeproj
   ```

3. **ตั้งค่า Signing & Capabilities:**
   - เลือก Root Project `NapNav` ในแถบ Project Navigator
   - ไปที่แท็บ **Signing & Capabilities**
   - เปลี่ยน **Team** เป็น Apple Developer Account ของคุณ (หรือ Personal Team)
   - ปรับแก้ **Bundle Identifier** ทั้งใน Target `NapNav` และ `NapNavWidget` ให้ตรงกับ Team ของคุณ

4. **เลือก Device หรือ Simulator แล้วกด Run (`Cmd + R`)**

---

## 🧪 การทดสอบ (Testing)

โปรเจกต์มาพร้อมชุด Unit Tests ครอบคลุมฟังก์ชันสำคัญ:
- รันแบบทดสอบทั้งหมดได้ง่ายๆ ด้วยคีย์ลัด **`Cmd + U`** ใน Xcode

### การทดสอบจำลองการเดินทางด้วยไฟล์ GPX
ในโฟลเดอร์ `TestRoutes/` มีไฟล์เส้นทาง GPX เตรียมไว้สำหรับทดสอบบน Xcode Simulator:
1. สั่งรันแอปบน iPhone Simulator
2. ไปที่เมนูของ Simulator: **Features** > **Location** > **Custom Location...** หรือเลือกโหลด GPX จาก:
   - `approach-destination.gpx` (จำลองการเดินทางเข้าใกล้จุดหมายเพื่อทดสอบเสียงเตือน)
   - `pass-outside.gpx` (จำลองการเดินทางผ่านนอกเขต)
   - `gps-jump.gpx` (จำลองกรณีสัญญาณ GPS กระโดด)

---

## 🤝 การมีส่วนร่วม (Contributing)

ยินดีต้อนรับผู้พัฒนาทุกท่านที่มีความสนใจจะร่วมปรับปรุง NapNav!
1. Fork โปรเจกต์นี้
2. สร้าง Feature Branch ของคุณ (`git checkout -b feature/AmazingFeature`)
3. Commit การเปลี่ยนแปลง (`git commit -m 'Add some AmazingFeature'`)
4. Push ไปยัง Branch ของคุณ (`git push origin feature/AmazingFeature`)
5. เปิด **Pull Request** เข้ามาได้เลย

---

## ☕ สนับสนุนผู้พัฒนา (Support & Donate)

หาก **NapNav** ช่วยให้คุณเดินทางและงีบหลับได้อย่างสบายใจ ไม่ต้องพะวงเรื่องเลยป้าย และอยากร่วมเป็นส่วนหนึ่งในการสนับสนุนโปรเจกต์โอเพนซอร์สนี้ คุณสามารถร่วมสนับสนุนค่าน้ำชา/กาแฟให้กับผู้พัฒนาได้ที่:

<div align="center">
  <a href="https://buymeacoffee.com/techin" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="220" />
  </a>
</div>

---

## 📄 ใบอนุญาต (License)

โปรเจกต์นี้เผยแพร่ภายใต้ใบอนุญาต **GNU General Public License v3.0 (GPL-3.0)** ดูรายละเอียดเพิ่มเติมได้ที่ไฟล์ [LICENSE](LICENSE)

```text
NapNav
Copyright (C) 2026 Telnwza / NapNav Contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```

---

<div align="center">
  พัฒนาด้วยความใส่ใจ เพื่อให้ทุกการเดินทางพักผ่อนได้อย่างอุ่นใจ ❤️
</div>
