import simd

enum PhysicsConstants {
    static let gravity: Double = 9.81
    static let horseshoeMass: Float = 1.13       // kg (~2.5 lbs)
    static let cornholeBagMass: Float = 0.45      // kg (~1 lb)
    static let horseshoeDistance: Double = 12.2   // meters (~40 ft)
    static let cornholeDistance: Double = 8.2     // meters (~27 ft)
    static let releaseHeight: Double = 1.5        // meters (~chest height)
    static let defaultDragCoefficient: Double = 0.05
    static let defaultSpeedScale: Double = 2.5
}
