# NapNav

<div align="center">
  <img src="NapNav/Assets.xcassets/AppIcon.appiconset/NapNav-iOS-Default-1024@1x.png" width="128" height="128" alt="NapNav Icon" style="border-radius: 28px;" />

  <h3>แอปแจ้งเตือนพิกัดจุดหมาย สำหรับคนเดินทาง — หลับได้สบายใจ ไม่ต้องกลัวเลยป้าย</h3>

  <p><a href="https://apps.apple.com/us/app/napnav-%E0%B8%AB%E0%B8%A5-%E0%B8%9A%E0%B9%84%E0%B8%A1-%E0%B9%80%E0%B8%A5%E0%B8%A2%E0%B8%9B-%E0%B8%B2%E0%B8%A2/id6816610764">ดาวน์โหลด NapNav บน App Store</a></p>

  <p>
    <a href="https://telnwza.github.io/NapNav/"><img src="https://img.shields.io/badge/Website-Live-2e7d32?logo=safari" alt="Website"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL_v3-blue.svg" alt="License: GPL v3"></a>
    <img src="https://img.shields.io/badge/iOS-18.0%2B-black?logo=apple" alt="iOS 18.0+">
    <img src="https://img.shields.io/badge/Swift-6.0-orange?logo=swift" alt="Swift 6.0">
    <img src="https://img.shields.io/badge/Xcode-16.0%2B-blue?logo=xcode" alt="Xcode 16.0+">
    <a href="https://buymeacoffee.com/techin"><img src="https://img.shields.io/badge/Buy%20Me%20A%20Coffee-Donate-yellow.svg?logo=buy-me-a-coffee" alt="Buy Me A Coffee"></a>
  </p>
</div>

---

## เกี่ยวกับ NapNav (About NapNav)

**NapNav** เป็นแอปพลิเคชันบน iOS พัฒนาด้วย **SwiftUI** และ **ActivityKit** ออกแบบมาเพื่อแก้ปัญหาของคนเดินทางด้วยระบบขนส่งสาธารณะ (รถไฟฟ้า BTS/MRT, รถไฟชานเมือง, รถเมล์ หรือรถตู้) ที่เหนื่อยล้าจากการทำงานหรือเรียน แล้วต้องการงีบหลับพักสายตาระหว่างทาง โดยไม่ต้องกังวลว่าจะนอนเพลินจนเลยป้ายหรือสถานีปลายทาง

เมื่อเริ่มทริป NapNav จะติดตามตำแหน่งเพื่อคำนวณระยะทางที่เหลือ และส่งสัญญาณเตือนเมื่อเข้าใกล้รัศมีที่กำหนดไว้ พร้อมแสดงผลผ่าน **Live Activity** บน **Lock Screen** และ **Dynamic Island** ช่วยให้เหลือบดูสถานะการเดินทางได้ตลอดเวลาโดยไม่ต้องปลดล็อกเครื่อง

---

## คุณสมบัติหลัก (Key Features)

- **ระบบเตือนตามพิกัดจริง (Proximity & Location-based Alert)**
  - เลือกระยะเตือนล่วงหน้าได้ตามต้องการ (500 ม., 1 กม., 2 กม. หรือกำหนดเองตั้งแต่ 100 ม. ถึง 5 กม.)
  - วงรัศมีบนแผนที่ปรับขนาดตามระยะที่เลือกแบบเรียลไทม์
  - ระบบตรวจสอบความพร้อมของสัญญาณและส่งการเตือนเมื่อเข้าสู่รัศมีที่เลือก
- **Live Activities & Dynamic Island**
  - แสดงสถานะทริป ระยะทางคงเหลือ และชื่อจุดหมายบน Lock Screen และ Dynamic Island ตลอดการเดินทาง
  - แตะเพื่อเปิดแอป หรือกดหยุดทริปพร้อมหน้าต่างยืนยันความปลอดภัยเพื่อป้องกันการกดพลาด
- **ตั้งค่ารูปแบบการแจ้งเตือน (Customizable Alerts)**
  - รองรับทั้ง AlarmKit (เสียงเตือนแบบนาฬิกาปลุก) และ UserNotifications ตามการอนุญาตสิทธิ์และความพร้อมของเครื่อง
  - ปรับแต่งระดับเสียงและเปิด/ปิดระบบสั่นได้จากหน้าตั้งค่าการเตือน
- **ค้นหาสถานที่และรายการโปรด (Search & Favorites)**
  - ค้นหาสถานีและสถานที่ปลายทางได้อย่างรวดเร็วผ่าน Apple Maps (MapKit)
  - บันทึกสถานที่ที่ใช้บ่อย (Favorites) เช่น "บ้าน", "ที่ทำงาน" พร้อมเลือก Custom Emoji ประจำจุดหมาย แตะครั้งเดียวเริ่มเดินทางได้ทันที
  - บันทึกประวัติจุดหมายล่าสุด (Recent Destinations) เพื่อความสะดวกรวดเร็ว
- **การติดตามตำแหน่งและข้อจำกัดของสัญญาณ (Location & Transit Limitations)**
  - ติดตามตำแหน่งเฉพาะขณะทริปกำลังทำงาน (Active Trip) เพื่อช่วยประหยัดแบตเตอรี่
  - มีคำแนะนำและข้อจำกัดเรื่องสัญญาณ GPS ในกรณีที่เดินทางในอุโมงค์รถไฟฟ้าใต้ดิน (MRT)
- **รองรับ 2 ภาษาเต็มรูปแบบ (Bilingual Support)**
  - รองรับทั้งภาษาไทย (Thai) และภาษาอังกฤษ (English) ปรับเปลี่ยนตามภาษาของระบบหรือเลือกเองในแอป
- **การช่วยการเข้าถึง (Accessibility)**
  - รองรับ Dynamic Type สำหรับขยายขนาดตัวอักษร, Reduce Motion สำหรับลดการเคลื่อนไหวของแอนิเมชัน และระบุ Accessibility Labels/Values สำหรับ VoiceOver

---

## เว็บไซต์และเอกสาร (Website & Links)

- **ดาวน์โหลดแอป:** [NapNav บน App Store](https://apps.apple.com/us/app/napnav-%E0%B8%AB%E0%B8%A5-%E0%B8%9A%E0%B9%84%E0%B8%A1-%E0%B9%80%E0%B8%A5%E0%B8%A2%E0%B8%9B-%E0%B8%B2%E0%B8%A2/id6816610764)
- **หน้าเว็บไซต์หลัก:** [telnwza.github.io/NapNav](https://telnwza.github.io/NapNav/)
- **นโยบายความเป็นส่วนตัว (Privacy Policy):** [telnwza.github.io/NapNav/privacy.html](https://telnwza.github.io/NapNav/privacy.html)
- **ศูนย์ช่วยเหลือและคำถามที่พบบ่อย (Support & FAQ):** [telnwza.github.io/NapNav/support.html](https://telnwza.github.io/NapNav/support.html)

---

## สถาปัตยกรรมและเทคโนโลยี (Architecture & Tech Stack)

NapNav พัฒนาขึ้นโดยยึดหลัก Clean Architecture และ Modern iOS Concurrency:

- **UI Framework:** SwiftUI (iOS 18+)
- **Concurrency:** Swift Concurrency (`async`/`await`, `Task`, `@MainActor`) บน Swift 6.0
- **Location Services:** CoreLocation, MapKit (`PlaceSearchService`)
- **Live Activities & Widgets:** ActivityKit, WidgetKit
- **Alerts & Audio:** AlarmKit, UserNotifications, AVFoundation
- **State Management:** MV Pattern ร่วมกับ Observation (`TripStore`) แยก Business Logic ออกจาก View ชัดเจน
- **Persistence:** Local Storage Protocol-oriented (`UserDefaultsTripPersistence`)
- **Automated Testing:** ชุดการทดสอบ Swift Testing ครอบคลุม Proximity logic, Trip recovery, Alert delivery และ Localization

```text
NapNav/
├── NapNav/                     # ซอร์สโค้ดหลักของแอป
│   ├── DestinationSelection.swift # UI แผนที่หลัก, เลือกจุดหมาย, และแถบควบคุม
│   ├── AlertSettingsView.swift    # หน้าตั้งค่าเสียงและรูปแบบการปลุก
│   ├── OnboardingView.swift       # หน้าแนะนำการใช้งานและขอสิทธิ์
│   ├── DomainModels.swift         # Model ข้อมูลหลัก (Trip, Destination, Location)
│   ├── TripStore.swift            # State Machine จัดการสถานะและวงจรชีวิตของทริป
│   ├── TriggerPolicy.swift        # ตรรกะการคำนวณระยะทางและการตัดสินใจสั่งเตือน
│   ├── LiveActivityManager.swift  # ตัวจัดการ Dynamic Island & Live Activity
│   ├── SystemClients.swift        # ตัวประสานงาน CoreLocation, Audio, Notifications
│   └── RootView.swift             # หน้าจอ Root และการเปลี่ยนผ่านสถานะ
├── NapNavWidget/                  # Widget Extension สำหรับ Dynamic Island & Live Activity
│   └── TripLiveActivityWidget.swift
├── NapNavTests/                   # ชุดแบบทดสอบ Swift Testing และ Mock Objects
├── TestRoutes/                    # ไฟล์ GPX จำลองพิกัดการเดินทางสำหรับทดสอบ
└── docs/                          # หน้าเว็บ GitHub Pages (Landing, Privacy, Support)
```

---

## วิธีติดตั้งและรันโปรเจกต์ (Getting Started)

### ความต้องการของระบบ (Prerequisites)
- Mac ที่ใช้ macOS ซึ่งรองรับ Xcode 16 หรือใหม่กว่า
- **Xcode 16.0** หรือใหม่กว่า (โปรเจกต์ใช้ Swift 6.0)
- อุปกรณ์ iPhone ที่ใช้ iOS 18.0+ หรือ iPhone Simulator ใน Xcode

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

## การทดสอบ (Testing)

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

## การมีส่วนร่วม (Contributing)

ยินดีต้อนรับผู้พัฒนาทุกท่านที่มีความสนใจจะร่วมปรับปรุง NapNav:
1. Fork โปรเจกต์นี้
2. สร้าง Feature Branch ของคุณ (`git checkout -b feature/AmazingFeature`)
3. Commit การเปลี่ยนแปลง (`git commit -m 'Add some AmazingFeature'`)
4. Push ไปยัง Branch ของคุณ (`git push origin feature/AmazingFeature`)
5. เปิด **Pull Request** ได้เลย

---

## สนับสนุนผู้พัฒนา (Support & Donate)

หาก **NapNav** ช่วยให้คุณเดินทางและงีบหลับได้อย่างสบายใจ ไม่ต้องพะวงเรื่องเลยป้าย และอยากร่วมเป็นส่วนหนึ่งในการสนับสนุนโปรเจกต์โอเพนซอร์สนี้ คุณสามารถร่วมสนับสนุนค่าน้ำชา/กาแฟให้กับผู้พัฒนาได้ที่:

<div align="center">
  <a href="https://buymeacoffee.com/techin" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="220" />
  </a>
</div>

---

## ใบอนุญาต (License)

โปรเจกต์นี้เผยแพร่ภายใต้ใบอนุญาต **GNU General Public License v3.0 (GPL-3.0)** ดูรายละเอียดเพิ่มเติมได้ที่ไฟล์ [LICENSE](LICENSE)

```text
NapNav
Copyright (C) 2026 Telnwza / NapNav Contributors

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```
