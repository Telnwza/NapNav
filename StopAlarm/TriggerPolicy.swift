import Foundation

struct TriggerPolicy: Sendable {
    struct Configuration: Equatable, Sendable {
        var maximumSampleAge: TimeInterval = 15
        var maximumHorizontalAccuracy: Double = 100
        var requiredInsideSamples = 2
    }

    private let configuration: Configuration
    private var consecutiveInsideSamples = 0
    private var hasTriggered = false

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    mutating func evaluate(
        _ sample: LocationSample,
        destination: Destination,
        radiusMeters: Double,
        now: Date = Date()
    ) -> TriggerDecision {
        guard sample.horizontalAccuracy >= 0 else {
            consecutiveInsideSamples = 0
            return .rejected(.invalidAccuracy)
        }

        guard now.timeIntervalSince(sample.timestamp) <= configuration.maximumSampleAge else {
            consecutiveInsideSamples = 0
            return .rejected(.stale)
        }

        guard sample.horizontalAccuracy <= configuration.maximumHorizontalAccuracy else {
            consecutiveInsideSamples = 0
            return .rejected(.inaccurate)
        }

        let distance = Self.distance(
            from: sample.coordinate,
            to: destination.coordinate
        )

        guard distance <= radiusMeters else {
            consecutiveInsideSamples = 0
            return .outside(distanceMeters: distance)
        }

        guard sample.horizontalAccuracy < radiusMeters else {
            consecutiveInsideSamples = 0
            return .uncertain(distanceMeters: distance)
        }

        guard hasTriggered == false else {
            return .approaching(distanceMeters: distance)
        }

        consecutiveInsideSamples += 1
        guard consecutiveInsideSamples >= configuration.requiredInsideSamples else {
            return .approaching(distanceMeters: distance)
        }

        hasTriggered = true
        return .trigger(distanceMeters: distance)
    }

    mutating func reset() {
        consecutiveInsideSamples = 0
        hasTriggered = false
    }

    static func distance(
        from start: LocationCoordinate,
        to end: LocationCoordinate
    ) -> Double {
        let earthRadius = 6_371_000.0
        let latitudeDelta = radians(end.latitude - start.latitude)
        let longitudeDelta = radians(end.longitude - start.longitude)
        let startLatitude = radians(start.latitude)
        let endLatitude = radians(end.latitude)

        let a = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)
        let clampedA = min(max(a, 0.0), 1.0)
        let centralAngle = 2 * atan2(sqrt(clampedA), sqrt(1 - clampedA))
        return earthRadius * centralAngle
    }

    private static func radians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }
}

struct ArrivalPolicy: Sendable {
    struct Configuration: Equatable, Sendable {
        var thresholdMeters: Double = 20
        var maximumSampleAge: TimeInterval = 15
        var maximumHorizontalAccuracy: Double = 20
        var requiredInsideSamples = 2
    }

    private let configuration: Configuration
    private var consecutiveInsideSamples = 0
    private var hasArrived = false

    init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    mutating func evaluate(
        _ sample: LocationSample,
        destination: Destination,
        now: Date = Date()
    ) -> ArrivalDecision {
        guard sample.horizontalAccuracy >= 0 else {
            consecutiveInsideSamples = 0
            return .rejected(.invalidAccuracy)
        }

        guard now.timeIntervalSince(sample.timestamp) <= configuration.maximumSampleAge else {
            consecutiveInsideSamples = 0
            return .rejected(.stale)
        }

        let distance = TriggerPolicy.distance(
            from: sample.coordinate,
            to: destination.coordinate
        )

        guard hasArrived == false else {
            return .arrived(distanceMeters: distance)
        }

        guard distance <= configuration.thresholdMeters else {
            consecutiveInsideSamples = 0
            return .outside(distanceMeters: distance)
        }

        guard sample.horizontalAccuracy <= configuration.maximumHorizontalAccuracy else {
            consecutiveInsideSamples = 0
            return .nearbyUncertain(distanceMeters: distance)
        }

        consecutiveInsideSamples += 1
        guard consecutiveInsideSamples >= configuration.requiredInsideSamples else {
            return .confirming(distanceMeters: distance)
        }

        hasArrived = true
        return .arrived(distanceMeters: distance)
    }

    mutating func reset() {
        consecutiveInsideSamples = 0
        hasArrived = false
    }
}
