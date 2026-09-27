import Foundation
import Testing
@testable import StopAlarm

@Suite("Trigger policy")
struct TriggerPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let destination = Destination(
        id: "test",
        name: "จุดหมายทดสอบ",
        detail: "",
        coordinate: LocationCoordinate(latitude: 0, longitude: 0)
    )

    @Test("ตำแหน่งนอกเขตไม่แจ้งเตือน")
    func outsideRadiusDoesNotTrigger() {
        var policy = TriggerPolicy()
        let decision = policy.evaluate(
            sample(latitude: 0.02),
            destination: destination,
            radiusMeters: 1_000,
            now: now
        )

        guard case .outside(let distance) = decision else {
            Issue.record("ควรได้ผลเป็น outside แต่ได้ \(decision)")
            return
        }
        #expect(distance > 2_000)
    }

    @Test("ปฏิเสธ accuracy ที่เป็นค่าติดลบ")
    func invalidAccuracyIsRejected() {
        var policy = TriggerPolicy()
        let decision = policy.evaluate(
            sample(latitude: 0.005, accuracy: -1),
            destination: destination,
            radiusMeters: 1_000,
            now: now
        )

        #expect(decision == .rejected(.invalidAccuracy))
    }

    @Test("ปฏิเสธ sample ที่เก่าเกิน 15 วินาที")
    func staleSampleIsRejected() {
        var policy = TriggerPolicy()
        let decision = policy.evaluate(
            sample(latitude: 0.005, timestamp: now.addingTimeInterval(-16)),
            destination: destination,
            radiusMeters: 1_000,
            now: now
        )

        #expect(decision == .rejected(.stale))
    }

    @Test("sample แรกในเขตยังไม่แจ้งเตือน")
    func oneInsideSampleOnlyApproaches() {
        var policy = TriggerPolicy()
        let decision = policy.evaluate(
            sample(latitude: 0.005),
            destination: destination,
            radiusMeters: 1_000,
            now: now
        )

        guard case .approaching = decision else {
            Issue.record("sample แรกควรเป็น approaching")
            return
        }
    }

    @Test("sample คุณภาพดีสองครั้งต่อเนื่องแจ้งเตือนหนึ่งครั้ง")
    func twoInsideSamplesTriggerOnlyOnce() {
        var policy = TriggerPolicy()
        let first = policy.evaluate(
            sample(latitude: 0.005),
            destination: destination,
            radiusMeters: 1_000,
            now: now
        )
        let second = policy.evaluate(
            sample(latitude: 0.004),
            destination: destination,
            radiusMeters: 1_000,
            now: now
        )
        let third = policy.evaluate(
            sample(latitude: 0.003),
            destination: destination,
            radiusMeters: 1_000,
            now: now
        )

        guard case .approaching = first else {
            Issue.record("sample แรกควรเป็น approaching")
            return
        }
        guard case .trigger = second else {
            Issue.record("sample ที่สองควร trigger")
            return
        }
        guard case .approaching = third else {
            Issue.record("หลัง trigger แล้วต้องไม่ trigger ซ้ำ")
            return
        }
    }

    @Test("accuracy กว้างกว่ารัศมีให้ผลไม่แน่นอน")
    func accuracyWiderThanRadiusIsUncertain() {
        var policy = TriggerPolicy()
        let decision = policy.evaluate(
            sample(latitude: 0.0002, accuracy: 80),
            destination: destination,
            radiusMeters: 50,
            now: now
        )

        guard case .uncertain = decision else {
            Issue.record("ควรได้ผลเป็น uncertain")
            return
        }
    }

    @Test("Haversine distance ป้องกัน NaN เมื่อคำนวณพิกัดซ้ำหรือตรงข้ามกัน")
    func distanceCalculationDoesNotProduceNaN() {
        let sameCoord = LocationCoordinate(latitude: 13.7367, longitude: 100.5604)
        let distSame = TriggerPolicy.distance(from: sameCoord, to: sameCoord)
        #expect(distSame.isNaN == false)
        #expect(distSame >= 0.0)

        let antipodeCoord = LocationCoordinate(latitude: -13.7367, longitude: -79.4396)
        let distAntipode = TriggerPolicy.distance(from: sameCoord, to: antipodeCoord)
        #expect(distAntipode.isNaN == false)
        #expect(distAntipode > 10_000_000)
    }

    private func sample(
        latitude: Double,
        accuracy: Double = 10,
        timestamp: Date? = nil
    ) -> LocationSample {
        LocationSample(
            coordinate: LocationCoordinate(latitude: latitude, longitude: 0),
            horizontalAccuracy: accuracy,
            timestamp: timestamp ?? now,
            speed: nil,
            course: nil
        )
    }
}

@Suite("Arrival policy")
struct ArrivalPolicyTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let destination = Destination(
        id: "arrival-test",
        name: "จุดหมายทดสอบ",
        detail: "",
        coordinate: LocationCoordinate(latitude: 0, longitude: 0)
    )

    @Test("ต้องอยู่ในระยะ 20 เมตรสอง sample ต่อเนื่องจึงถือว่าถึง")
    func twoGoodSamplesConfirmArrival() {
        var policy = ArrivalPolicy()

        let first = policy.evaluate(
            sample(latitude: 0.00015),
            destination: destination,
            now: now
        )
        let second = policy.evaluate(
            sample(latitude: 0.00014),
            destination: destination,
            now: now
        )

        guard case .confirming = first else {
            Issue.record("sample แรกควรอยู่ระหว่างยืนยัน")
            return
        }
        guard case .arrived = second else {
            Issue.record("sample ที่สองควรยืนยันว่าถึงแล้ว")
            return
        }
    }

    @Test("ตำแหน่งกระโดดออกนอก 20 เมตรตัดการยืนยันต่อเนื่อง")
    func bounceOutsideResetsConfirmation() {
        var policy = ArrivalPolicy()

        _ = policy.evaluate(
            sample(latitude: 0.00015),
            destination: destination,
            now: now
        )
        let outside = policy.evaluate(
            sample(latitude: 0.00030),
            destination: destination,
            now: now
        )
        let nextInside = policy.evaluate(
            sample(latitude: 0.00014),
            destination: destination,
            now: now
        )

        guard case .outside = outside else {
            Issue.record("sample ที่เด้งออกควรอยู่นอก arrival threshold")
            return
        }
        guard case .confirming = nextInside else {
            Issue.record("sample หลังเด้งกลับต้องเริ่มยืนยันใหม่")
            return
        }
    }

    @Test("อยู่ใกล้แต่ accuracy กว้างไม่ auto-complete")
    func inaccurateNearbySampleDoesNotArrive() {
        var policy = ArrivalPolicy()

        let uncertain = policy.evaluate(
            sample(latitude: 0.00010, accuracy: 35),
            destination: destination,
            now: now
        )
        let firstGood = policy.evaluate(
            sample(latitude: 0.00010),
            destination: destination,
            now: now
        )

        guard case .nearbyUncertain = uncertain else {
            Issue.record("พิกัดใกล้ที่ accuracy กว้างควรแสดงว่าอยู่ใกล้แต่ยังไม่ยืนยัน")
            return
        }
        guard case .confirming = firstGood else {
            Issue.record("sample คุณภาพดีหลัง accuracy แย่ต้องเริ่มนับใหม่")
            return
        }
    }

    @Test("sample เก่าไม่ยืนยัน arrival")
    func staleSampleDoesNotArrive() {
        var policy = ArrivalPolicy()
        let decision = policy.evaluate(
            sample(latitude: 0.00010, timestamp: now.addingTimeInterval(-16)),
            destination: destination,
            now: now
        )

        #expect(decision == .rejected(.stale))
    }

    @Test("เมื่อยืนยันว่าถึงแล้ว GPS bounce ไม่ย้อนสถานะ")
    func arrivalDoesNotReverseAfterConfirmation() {
        var policy = ArrivalPolicy()
        _ = policy.evaluate(
            sample(latitude: 0.00015),
            destination: destination,
            now: now
        )
        _ = policy.evaluate(
            sample(latitude: 0.00014),
            destination: destination,
            now: now
        )

        let bounced = policy.evaluate(
            sample(latitude: 0.00050),
            destination: destination,
            now: now
        )

        guard case .arrived = bounced else {
            Issue.record("สถานะ arrived ต้องไม่ย้อนกลับหลัง GPS เด้ง")
            return
        }
    }

    private func sample(
        latitude: Double,
        accuracy: Double = 10,
        timestamp: Date? = nil
    ) -> LocationSample {
        LocationSample(
            coordinate: LocationCoordinate(latitude: latitude, longitude: 0),
            horizontalAccuracy: accuracy,
            timestamp: timestamp ?? now,
            speed: nil,
            course: nil
        )
    }
}

@Suite("GPX release routes")
struct GPXReleaseRouteTests {
    private let destination = Destination.asok

    @Test("เส้นทางเข้าเขตเตือนครั้งเดียวและยืนยัน arrival ตอนท้าย")
    func approachRouteTriggersOnceAndArrives() throws {
        let coordinates = try loadRoute(named: "approach-destination")
        var triggerPolicy = TriggerPolicy()
        var arrivalPolicy = ArrivalPolicy()
        var alertCount = 0
        var didArrive = false

        for (index, coordinate) in coordinates.enumerated() {
            let timestamp = Date(timeIntervalSince1970: 1_800_000_000 + Double(index))
            let sample = routeSample(coordinate: coordinate, timestamp: timestamp)

            if case .trigger = triggerPolicy.evaluate(
                sample,
                destination: destination,
                radiusMeters: 500,
                now: timestamp
            ) {
                alertCount += 1
            }
            if case .arrived = arrivalPolicy.evaluate(
                sample,
                destination: destination,
                now: timestamp
            ) {
                didArrive = true
            }
        }

        #expect(alertCount == 1)
        #expect(didArrive)
    }

    @Test("เส้นทางที่ผ่านนอกเขตไม่แจ้งเตือน")
    func outsideRouteDoesNotTrigger() throws {
        let coordinates = try loadRoute(named: "pass-outside")
        #expect(triggerCount(for: coordinates, radiusMeters: 500) == 0)
    }

    @Test("GPS กระโดดเข้าเขตเพียงครั้งเดียวไม่แจ้งเตือน")
    func jumpRouteDoesNotTrigger() throws {
        let coordinates = try loadRoute(named: "gps-jump")
        #expect(triggerCount(for: coordinates, radiusMeters: 500) == 0)
    }

    private func triggerCount(
        for coordinates: [LocationCoordinate],
        radiusMeters: Double
    ) -> Int {
        var policy = TriggerPolicy()
        var count = 0

        for (index, coordinate) in coordinates.enumerated() {
            let timestamp = Date(timeIntervalSince1970: 1_800_000_000 + Double(index))
            if case .trigger = policy.evaluate(
                routeSample(coordinate: coordinate, timestamp: timestamp),
                destination: destination,
                radiusMeters: radiusMeters,
                now: timestamp
            ) {
                count += 1
            }
        }
        return count
    }

    private func routeSample(
        coordinate: LocationCoordinate,
        timestamp: Date
    ) -> LocationSample {
        LocationSample(
            coordinate: coordinate,
            horizontalAccuracy: 8,
            timestamp: timestamp,
            speed: 10,
            course: nil
        )
    }

    private func loadRoute(named name: String) throws -> [LocationCoordinate] {
        let projectDirectory = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = projectDirectory
            .appendingPathComponent("TestRoutes")
            .appendingPathComponent("\(name).gpx")
        let xml = try String(contentsOf: url, encoding: .utf8)
        let expression = try NSRegularExpression(
            pattern: #"<wpt\s+lat="([^"]+)"\s+lon="([^"]+)""#
        )
        let range = NSRange(xml.startIndex..., in: xml)

        return expression.matches(in: xml, range: range).compactMap { match in
            guard let latitudeRange = Range(match.range(at: 1), in: xml),
                  let longitudeRange = Range(match.range(at: 2), in: xml),
                  let latitude = Double(xml[latitudeRange]),
                  let longitude = Double(xml[longitudeRange]) else { return nil }
            return LocationCoordinate(latitude: latitude, longitude: longitude)
        }
    }
}
