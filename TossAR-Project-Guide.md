# TossAR — Horseshoe & Cornhole AR Game for iOS

## Project Overview

**App Name (working title):** TossAR
**Platform:** iOS 17+
**Language:** Swift
**Architecture:** MVVM + Coordinator
**Developer:** Jonathan Calpin / LNH Enterprises LLC
**GitHub:** jonathancalpin
**Dev Tools:** Cursor, Claude Code (Claude Max)

TossAR is an iOS game that uses the device's gyroscope and accelerometer to capture a real throwing motion, then projects a horseshoe or cornhole bag along a physics-simulated arc into an AR scene. Players physically swing their phone to throw, with an AR-placed target (horseshoe pit or cornhole board) rendered on a real-world surface detected by the camera.

---

## Core Concept

1. **Player holds phone, swings arm** in an underhand tossing motion (like a real horseshoe/cornhole throw).
2. **CoreMotion captures** acceleration, rotation, and attitude throughout the swing.
3. **Release is triggered** by either: lifting a thumb from a screen-held zone, tapping a button at peak, or automatic detection of deceleration at the top of the arc.
4. **A 3D projectile** (horseshoe or cornhole bag) launches in the AR scene following a parabolic trajectory derived from the captured motion data.
5. **The target** (pit with stake, or angled cornhole board) is placed via ARKit plane detection on a real-world horizontal surface.
6. **Scoring** follows official rules for each game mode.

---

## Technical Architecture

### Frameworks & Dependencies

| Framework | Purpose |
|-----------|---------|
| **ARKit** | World tracking, horizontal plane detection, hit testing, distance estimation |
| **RealityKit** | 3D scene rendering, physics simulation, collision detection, entity management |
| **CoreMotion** | Gyroscope + accelerometer fusion via `CMDeviceMotion` |
| **CoreHaptics** | Tactile feedback on release, landing, scoring |
| **AVFoundation** | Sound effects (metal clang, bag thud, crowd cheers) |
| **GameKit** | Game Center leaderboards, achievements, multiplayer (Phase 2) |
| **SwiftUI** | UI layer for menus, HUD, scoring overlay |
| **Combine** | Reactive data flow between motion manager and game state |

### Project Structure

```
TossAR/
├── TossAR.xcodeproj
├── TossAR/
│   ├── App/
│   │   ├── TossARApp.swift                 # App entry point
│   │   └── AppCoordinator.swift            # Navigation coordinator
│   │
│   ├── Models/
│   │   ├── GameMode.swift                  # .horseshoe, .cornhole enum
│   │   ├── GameState.swift                 # Scores, turn tracking, round state
│   │   ├── ThrowData.swift                 # Captured motion data for a single throw
│   │   ├── ThrowResult.swift               # Computed trajectory + landing result
│   │   └── ScoringRules.swift              # Official scoring logic per game mode
│   │
│   ├── Services/
│   │   ├── MotionCaptureService.swift      # CoreMotion wrapper, data collection
│   │   ├── ThrowAnalyzer.swift             # Processes raw motion → release vector
│   │   ├── TrajectoryCalculator.swift      # Converts release vector → parabolic arc
│   │   ├── HapticsService.swift            # CoreHaptics patterns
│   │   └── AudioService.swift              # Sound effect management
│   │
│   ├── AR/
│   │   ├── ARGameView.swift                # ARView wrapped for SwiftUI
│   │   ├── ARSessionManager.swift          # ARSession configuration + delegate
│   │   ├── TargetPlacementManager.swift    # Plane detection → target placement
│   │   ├── ProjectileEntity.swift          # 3D horseshoe or bag model + physics
│   │   ├── HorseshoePitEntity.swift        # 3D pit with stake, scoring zones
│   │   ├── CornholeBoardEntity.swift       # 3D board with hole, scoring zones
│   │   └── CollisionHandler.swift          # Detect landing zone, compute score
│   │
│   ├── ViewModels/
│   │   ├── GameViewModel.swift             # Main game logic coordinator
│   │   ├── MotionViewModel.swift           # Bridges motion service to UI
│   │   └── ScoreViewModel.swift            # Score display state
│   │
│   ├── Views/
│   │   ├── MainMenuView.swift              # Game mode selection
│   │   ├── GameHUDView.swift               # Score overlay, throw indicator, power meter
│   │   ├── CalibrationView.swift           # Pre-game sensor calibration
│   │   ├── TargetPlacementView.swift       # AR target setup screen
│   │   ├── ResultsView.swift               # Post-game summary
│   │   └── SettingsView.swift              # Sensitivity, difficulty, safety warnings
│   │
│   ├── Utilities/
│   │   ├── PhysicsConstants.swift          # Gravity, drag coefficients, scale factors
│   │   ├── Vector3Extensions.swift         # SIMD3 helper methods
│   │   └── MotionDataBuffer.swift          # Ring buffer for motion samples
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── Models/                          # USDZ 3D models
│       │   ├── horseshoe.usdz
│       │   ├── cornhole_bag.usdz
│       │   ├── horseshoe_pit.usdz
│       │   └── cornhole_board.usdz
│       ├── Sounds/
│       │   ├── metal_clang.wav
│       │   ├── bag_thud.wav
│       │   ├── ringer.wav
│       │   └── crowd_cheer.wav
│       └── HapticPatterns/
│           ├── throw_release.ahap
│           ├── landing_hit.ahap
│           └── ringer_celebration.ahap
│
├── TossARTests/
│   ├── ThrowAnalyzerTests.swift
│   ├── TrajectoryCalculatorTests.swift
│   └── ScoringRulesTests.swift
│
└── TossARUITests/
```

---

## Phase 1: Sensor Playground (Prototype Sprint 1)

**Goal:** Capture and visualize motion data from phone-swinging gestures. Identify what a "good throw" looks like in raw sensor data.

### MotionCaptureService.swift

```swift
import CoreMotion
import Combine

class MotionCaptureService: ObservableObject {
    private let motionManager = CMMotionManager()
    private var motionDataBuffer: [CMDeviceMotion] = []

    @Published var isCapturing = false
    @Published var currentAcceleration: SIMD3<Double> = .zero
    @Published var currentRotationRate: SIMD3<Double> = .zero
    @Published var currentAttitude: (roll: Double, pitch: Double, yaw: Double) = (0, 0, 0)

    let updateInterval: TimeInterval = 1.0 / 100.0  // 100 Hz

    func startCapture() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }

        motionDataBuffer.removeAll()
        motionManager.deviceMotionUpdateInterval = updateInterval

        // Use .xArbitraryZVertical for consistent gravity reference
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            self.motionDataBuffer.append(motion)

            // userAcceleration excludes gravity — this is what we want
            self.currentAcceleration = SIMD3<Double>(
                motion.userAcceleration.x,
                motion.userAcceleration.y,
                motion.userAcceleration.z
            )

            self.currentRotationRate = SIMD3<Double>(
                motion.rotationRate.x,
                motion.rotationRate.y,
                motion.rotationRate.z
            )

            self.currentAttitude = (
                roll: motion.attitude.roll,
                pitch: motion.attitude.pitch,
                yaw: motion.attitude.yaw
            )
        }

        isCapturing = true
    }

    func stopCapture() -> [CMDeviceMotion] {
        motionManager.stopDeviceMotionUpdates()
        isCapturing = false
        return motionDataBuffer
    }

    /// Acceleration magnitude — useful for detecting peak of throw
    var accelerationMagnitude: Double {
        length(currentAcceleration)
    }
}
```

### Key Observations to Make in Phase 1

When swinging the phone in an underhand throw motion, you should observe:

1. **Wind-up phase:** Increasing negative Y acceleration (arm going back)
2. **Forward swing:** Large positive Y acceleration spike (arm coming forward)
3. **Peak / release point:** Rapid deceleration — acceleration drops toward zero at the top of the arc
4. **Rotation rate:** Pitch rate (rotation around X axis) should peak during the swing and drop at release

The throw profile in data should look roughly like:
```
Time →
Accel Y:   ~~~\___/‾‾‾‾‾\___~~~   (dip back, spike forward, decelerate)
Rot X:     ~~~___/‾‾‾‾‾\___~~~    (rotation peaks during forward swing)
```

### Phase 1 Deliverable

A SwiftUI debug view showing:
- Real-time line graphs of acceleration (X, Y, Z) and rotation rate (X, Y, Z)
- Acceleration magnitude meter
- A "Record Throw" button that captures 2 seconds of motion data
- Playback/export of recorded throw data as JSON for analysis
- Console output of detected peak acceleration magnitude and estimated release angle

---

## Phase 2: 2D Physics Prototype (Prototype Sprint 2)

**Goal:** Map captured motion data to a 2D side-view projectile simulation using SpriteKit.

### ThrowAnalyzer.swift

```swift
import CoreMotion
import simd

struct ReleaseVector {
    let speed: Double        // m/s (scaled from sensor data)
    let angle: Double        // radians from horizontal
    let spin: Double         // rad/s — affects flight behavior
    let lateralOffset: Double // left/right deviation from center

    var velocity: SIMD2<Double> {
        SIMD2<Double>(
            speed * cos(angle),
            speed * sin(angle)
        )
    }
}

class ThrowAnalyzer {

    /// Tuning constants — these will need extensive calibration
    struct Config {
        var speedScaleFactor: Double = 2.5       // maps sensor accel to game speed
        var angleOffsetDegrees: Double = 0.0     // bias correction for holding angle
        var minThrowAcceleration: Double = 1.5   // minimum g-force to register as throw
        var releaseDetectionThreshold: Double = 0.3 // decel rate to trigger release
        var spinScaleFactor: Double = 1.0
    }

    var config = Config()

    /// Analyze a buffer of motion samples and extract the release vector
    func analyze(motionData: [CMDeviceMotion]) -> ReleaseVector? {
        guard motionData.count > 10 else { return nil }

        // Step 1: Find the peak forward acceleration
        let accelerations = motionData.map { m in
            sqrt(
                m.userAcceleration.x * m.userAcceleration.x +
                m.userAcceleration.y * m.userAcceleration.y +
                m.userAcceleration.z * m.userAcceleration.z
            )
        }

        guard let peakIndex = accelerations.indices.max(by: { accelerations[$0] < accelerations[$1] }) else {
            return nil
        }

        let peakAcceleration = accelerations[peakIndex]

        // Reject if not enough force for a throw
        guard peakAcceleration > config.minThrowAcceleration else { return nil }

        // Step 2: Find release point — first significant deceleration after peak
        var releaseIndex = peakIndex
        for i in peakIndex..<motionData.count - 1 {
            let decelRate = accelerations[i] - accelerations[i + 1]
            if decelRate > config.releaseDetectionThreshold {
                releaseIndex = i
                break
            }
        }

        let releaseMotion = motionData[releaseIndex]

        // Step 3: Compute release speed (scaled from peak acceleration)
        let speed = peakAcceleration * config.speedScaleFactor

        // Step 4: Compute release angle from device attitude at release
        // Pitch gives us the vertical angle of the throw
        let angle = releaseMotion.attitude.pitch + (config.angleOffsetDegrees * .pi / 180.0)

        // Step 5: Compute spin from rotation rate at release
        let spin = releaseMotion.rotationRate.x * config.spinScaleFactor

        // Step 6: Lateral offset from yaw rate at release
        let lateralOffset = releaseMotion.rotationRate.y * 0.1

        return ReleaseVector(
            speed: speed,
            angle: angle,
            spin: spin,
            lateralOffset: lateralOffset
        )
    }
}
```

### TrajectoryCalculator.swift

```swift
import simd

struct TrajectoryPoint {
    let position: SIMD2<Double>  // (x: distance, y: height) in meters
    let time: Double
    let velocity: SIMD2<Double>
}

class TrajectoryCalculator {

    struct Config {
        var gravity: Double = 9.81
        var dragCoefficient: Double = 0.05   // air resistance
        var timeStep: Double = 0.016         // ~60fps
        var maxFlightTime: Double = 3.0      // safety cutoff
    }

    var config = Config()

    /// Calculate the full trajectory arc from a release vector
    func calculateTrajectory(
        release: ReleaseVector,
        releaseHeight: Double = 1.5,  // ~chest height in meters
        targetDistance: Double = 12.0  // standard horseshoe distance ~40ft ≈ 12m
    ) -> [TrajectoryPoint] {

        var points: [TrajectoryPoint] = []
        var position = SIMD2<Double>(0, releaseHeight)
        var velocity = release.velocity
        var time: Double = 0

        while time < config.maxFlightTime {
            points.append(TrajectoryPoint(
                position: position,
                time: time,
                velocity: velocity
            ))

            // Simple Euler integration with drag
            let speed = length(velocity)
            let dragForce = config.dragCoefficient * speed * speed
            let dragDirection = normalize(velocity)

            let acceleration = SIMD2<Double>(
                -dragForce * dragDirection.x,
                -config.gravity - dragForce * dragDirection.y
            )

            velocity += acceleration * config.timeStep
            position += velocity * config.timeStep
            time += config.timeStep

            // Stop if projectile hits the ground
            if position.y <= 0 {
                points.append(TrajectoryPoint(
                    position: SIMD2<Double>(position.x, 0),
                    time: time,
                    velocity: velocity
                ))
                break
            }
        }

        return points
    }

    /// Where the projectile lands (X distance from release point)
    func landingDistance(from trajectory: [TrajectoryPoint]) -> Double {
        return trajectory.last?.position.x ?? 0
    }
}
```

### Phase 2 Deliverable

A SpriteKit side-view scene showing:
- A ground plane with a target marker at the configured distance
- Swing phone → projectile launches following calculated trajectory
- Visual trail showing the arc
- Landing position indicator with distance-from-target readout
- On-screen sliders to tune: speedScaleFactor, angleOffset, dragCoefficient
- Multiple throw attempts visible simultaneously for comparison

---

## Phase 3: AR Scene (Prototype Sprint 3)

**Goal:** Replace 2D scene with full AR experience using RealityKit + ARKit.

### ARSessionManager.swift

```swift
import ARKit
import RealityKit
import Combine

class ARSessionManager: NSObject, ObservableObject {
    let arView = ARView(frame: .zero)

    @Published var planesDetected: Int = 0
    @Published var isTargetPlaced = false
    @Published var targetDistance: Float = 0  // meters from camera to target

    private var planeAnchors: [ARPlaneAnchor] = []
    private var cancellables = Set<AnyCancellable>()

    func configure() {
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        // Enable LiDAR scene reconstruction if available
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        arView.session.run(config)
        arView.session.delegate = self

        // Enable coaching overlay to guide user
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)
    }

    func placeTarget(at worldPosition: SIMD3<Float>, gameMode: GameMode) {
        let anchor = AnchorEntity(world: worldPosition)

        switch gameMode {
        case .horseshoe:
            let pit = HorseshoePitEntity()
            anchor.addChild(pit)
        case .cornhole:
            let board = CornholeBoardEntity()
            anchor.addChild(board)
        }

        arView.scene.addAnchor(anchor)

        // Calculate distance from camera
        if let cameraTransform = arView.session.currentFrame?.camera.transform {
            let cameraPos = SIMD3<Float>(
                cameraTransform.columns.3.x,
                cameraTransform.columns.3.y,
                cameraTransform.columns.3.z
            )
            targetDistance = distance(cameraPos, worldPosition)
        }

        isTargetPlaced = true
    }

    /// Launch a projectile into the AR scene
    func launchProjectile(
        release: ReleaseVector,
        gameMode: GameMode
    ) {
        guard let frame = arView.session.currentFrame else { return }

        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        // Forward direction from camera
        let forward = SIMD3<Float>(
            -cameraTransform.columns.2.x,
            -cameraTransform.columns.2.y,
            -cameraTransform.columns.2.z
        )

        let projectile = ProjectileEntity(gameMode: gameMode)
        let anchor = AnchorEntity(world: cameraPosition)
        anchor.addChild(projectile)
        arView.scene.addAnchor(anchor)

        // Convert release vector to 3D impulse
        let speed = Float(release.speed)
        let angle = Float(release.angle)
        let lateral = Float(release.lateralOffset)

        // Up direction
        let up = SIMD3<Float>(0, 1, 0)
        // Right direction
        let right = normalize(cross(forward, up))

        let impulseDirection = normalize(
            forward * cos(angle) +
            up * sin(angle) +
            right * lateral
        )

        let impulse = impulseDirection * speed

        // Apply physics impulse
        projectile.physicsBody?.mode = .dynamic
        projectile.addForce(impulse, relativeTo: nil)

        // Add spin
        let spinTorque = SIMD3<Float>(Float(release.spin), 0, 0)
        projectile.addTorque(spinTorque, relativeTo: nil)
    }
}

extension ARSessionManager: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        let newPlanes = anchors.compactMap { $0 as? ARPlaneAnchor }
        planeAnchors.append(contentsOf: newPlanes)
        planesDetected = planeAnchors.count
    }
}
```

### ProjectileEntity.swift

```swift
import RealityKit

class ProjectileEntity: Entity, HasModel, HasPhysicsBody, HasCollision {

    required init() {
        super.init()
    }

    convenience init(gameMode: GameMode) {
        self.init()

        switch gameMode {
        case .horseshoe:
            // Load USDZ model or create programmatic mesh
            let mesh = MeshResource.generateBox(size: [0.15, 0.02, 0.18]) // placeholder
            let material = SimpleMaterial(color: .gray, isMetallic: true)
            self.model = ModelComponent(mesh: mesh, materials: [material])

            // Horseshoe physics
            let shape = ShapeResource.generateBox(size: [0.15, 0.02, 0.18])
            self.physicsBody = PhysicsBodyComponent(
                shapes: [shape],
                mass: 1.13,  // regulation horseshoe ~2.5 lbs
                material: .generate(
                    staticFriction: 0.6,
                    dynamicFriction: 0.4,
                    restitution: 0.3  // some bounce on metal
                ),
                mode: .dynamic
            )
            self.collision = CollisionComponent(shapes: [shape])

        case .cornhole:
            let mesh = MeshResource.generateBox(size: [0.15, 0.05, 0.15]) // placeholder
            let material = SimpleMaterial(color: .blue, isMetallic: false)
            self.model = ModelComponent(mesh: mesh, materials: [material])

            let shape = ShapeResource.generateBox(size: [0.15, 0.05, 0.15])
            self.physicsBody = PhysicsBodyComponent(
                shapes: [shape],
                mass: 0.45,  // regulation bag ~1 lb
                material: .generate(
                    staticFriction: 0.8,
                    dynamicFriction: 0.6,
                    restitution: 0.05  // bags barely bounce
                ),
                mode: .dynamic
            )
            self.collision = CollisionComponent(shapes: [shape])
        }
    }
}
```

### Phase 3 Deliverable

Full AR experience:
- Camera feed with plane detection visualization
- Tap-to-place target at desired distance
- Distance readout from player to target
- Swing phone → 3D projectile launches in AR
- Physics-based landing with proper material behavior (horseshoe clangs and bounces, bag thuds and stays)
- Basic collision detection with scoring zones

---

## Phase 4: Scoring System

### ScoringRules.swift

```swift
enum GameMode: String, CaseIterable, Codable {
    case horseshoe
    case cornhole
}

enum HorseshoeScore: Int {
    case ringer = 3       // around the stake
    case leaner = 2       // leaning against stake
    case closeShoe = 1    // within 6 inches of stake
    case miss = 0
}

enum CornholeScore: Int {
    case inTheHole = 3    // through the hole
    case onTheBoard = 1   // lands and stays on board
    case miss = 0
}

struct ScoringRules {

    /// Horseshoe: Cancellation scoring
    /// Only the player who scores more in a round gets points (difference)
    static func calculateHorseshoeRound(
        player1Throws: [HorseshoeScore],
        player2Throws: [HorseshoeScore]
    ) -> (player1Points: Int, player2Points: Int) {
        let p1Total = player1Throws.reduce(0) { $0 + $1.rawValue }
        let p2Total = player2Throws.reduce(0) { $0 + $1.rawValue }

        if p1Total > p2Total {
            return (p1Total - p2Total, 0)
        } else if p2Total > p1Total {
            return (0, p2Total - p1Total)
        }
        return (0, 0)
    }

    /// Cornhole: Cancellation scoring
    static func calculateCornholeRound(
        player1Throws: [CornholeScore],
        player2Throws: [CornholeScore]
    ) -> (player1Points: Int, player2Points: Int) {
        let p1Total = player1Throws.reduce(0) { $0 + $1.rawValue }
        let p2Total = player2Throws.reduce(0) { $0 + $1.rawValue }

        if p1Total > p2Total {
            return (p1Total - p2Total, 0)
        } else if p2Total > p1Total {
            return (0, p2Total - p1Total)
        }
        return (0, 0)
    }

    /// Horseshoe: First to 21, must win by 2 (or exact 21 in casual)
    static let horseshoeWinScore = 21

    /// Cornhole: First to 21, must win by 2 (or exact 21 in casual)
    static let cornholeWinScore = 21
}
```

### Collision-Based Score Detection

For horseshoes, use distance from the stake entity center:
- **Ringer:** Horseshoe entity encircles the stake (bounding box test or collision mesh overlap)
- **Leaner:** Horseshoe in contact with stake AND not flat on ground (check attitude)
- **Close shoe:** Distance from horseshoe center to stake < 0.15m (~6 inches)

For cornhole, use collision events with board zones:
- **In the hole:** Projectile passes through a trigger volume behind the hole
- **On the board:** Projectile resting on board collision surface after physics settles
- **Miss:** Projectile contacts ground plane, not board

---

## Phase 5: Polish & Game Feel

### Release Mechanism Options (implement all, let user choose)

```swift
enum ReleaseMode: String, CaseIterable {
    case thumbLift       // Hold thumb on screen during swing, lift to release
    case autoDetect      // Detect deceleration peak automatically
    case buttonTap       // Tap dedicated button at desired release point
}
```

**Recommended default:** `thumbLift` — most intuitive, gives player control without needing split-second button timing.

### Haptic Feedback Patterns

| Event | Pattern | Intensity |
|-------|---------|-----------|
| Throw release | Short sharp tap | 0.8 |
| Projectile landing (miss) | Dull thud | 0.4 |
| On the board / close shoe | Medium bump | 0.6 |
| Ringer / in-the-hole | Celebration burst sequence | 1.0 |
| Power meter peak | Subtle continuous | 0.3 |

### Audio Design

| Sound | Description |
|-------|-------------|
| `whoosh.wav` | Air sound during flight, pitch scales with speed |
| `metal_clang.wav` | Horseshoe hitting stake |
| `metal_ground.wav` | Horseshoe hitting ground/pit |
| `bag_thud.wav` | Cornhole bag landing on board |
| `bag_slide.wav` | Bag sliding on board surface |
| `hole_swoosh.wav` | Bag going through the hole |
| `crowd_cheer.wav` | Ringer or hole-in-one |

### Power / Aim HUD

Display a transparent overlay during the throw:
- **Power meter:** Vertical bar on the side that fills based on real-time acceleration magnitude
- **Direction indicator:** Subtle arrow showing current yaw deviation from center
- **Arc preview (optional, easy mode):** Dotted line showing predicted trajectory based on current motion

---

## Safety Considerations

**This is critical — users are swinging their phones.**

1. **Wrist strap reminder** on every app launch (dismissable after first 5 sessions)
2. **Calibration mode** where users do gentle test swings before a real game
3. **Sensitivity settings** so smaller gestures can map to full throws (accessibility)
4. **Stationary mode fallback** — touch-and-drag aiming for users who don't want to swing
5. **Clear play area check** — show AR warning if detected objects/walls are too close
6. **Phone case recommendation** in onboarding

---

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────┐
│                     USER SWINGS PHONE                     │
└──────────────┬───────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────┐
│   MotionCaptureService   │  ← CoreMotion @ 100Hz
│   (gyro + accel + att)   │
└──────────┬───────────────┘
           │ [CMDeviceMotion]
           ▼
┌──────────────────────────┐
│     ThrowAnalyzer        │  ← Detects throw gesture
│  (peak detection,        │  ← Identifies release point
│   release extraction)    │  ← Computes release vector
└──────────┬───────────────┘
           │ ReleaseVector(speed, angle, spin, lateral)
           ▼
┌──────────────────────────┐     ┌─────────────────────┐
│  TrajectoryCalculator    │     │  ARSessionManager    │
│  (parabolic arc,         │────▶│  (3D projectile      │
│   drag, gravity)         │     │   launch + physics)  │
└──────────────────────────┘     └──────────┬──────────┘
                                            │
                                            ▼
                                 ┌─────────────────────┐
                                 │  CollisionHandler    │
                                 │  (scoring zone       │
                                 │   detection)         │
                                 └──────────┬──────────┘
                                            │
                                 ┌──────────▼──────────┐
                                 │   GameState          │
                                 │   + ScoreViewModel   │
                                 │   + HapticsService   │
                                 │   + AudioService     │
                                 └─────────────────────┘
```

---

## Development Roadmap

### Sprint 1 (Week 1-2): Sensor Playground
- [ ] Create Xcode project, iOS 17 target
- [ ] Implement `MotionCaptureService`
- [ ] Build debug SwiftUI view with real-time sensor graphs
- [ ] Record and export throw gesture data as JSON
- [ ] Document observed patterns for different throw intensities
- [ ] Test on-device (simulator has no motion sensors)

### Sprint 2 (Week 3-4): 2D Physics
- [ ] Implement `ThrowAnalyzer`
- [ ] Implement `TrajectoryCalculator`
- [ ] Build SpriteKit 2D side-view prototype
- [ ] Add tuning sliders for physics parameters
- [ ] Calibrate speed/angle mapping to feel natural
- [ ] Test with multiple people to validate feel

### Sprint 3 (Week 5-6): AR Scene
- [ ] Set up ARKit + RealityKit pipeline
- [ ] Implement horizontal plane detection + coaching overlay
- [ ] Build tap-to-place target functionality
- [ ] Create placeholder 3D models (boxes/cylinders)
- [ ] Implement 3D projectile launch with physics
- [ ] Basic collision detection

### Sprint 4 (Week 7-8): Scoring & Game Loop
- [ ] Implement scoring zone collision detection
- [ ] Build `ScoringRules` for both game modes
- [ ] Create `GameState` with turn management
- [ ] Build `GameHUDView` with score overlay
- [ ] Add haptic feedback for all events
- [ ] Add basic sound effects

### Sprint 5 (Week 9-10): Polish
- [ ] Replace placeholder models with proper USDZ assets
- [ ] Implement all three release modes
- [ ] Add power meter and direction HUD
- [ ] Implement settings/calibration screens
- [ ] Safety warnings and wrist strap reminders
- [ ] Performance optimization

### Phase 2 Features (Post-MVP)
- [ ] Game Center leaderboards and achievements
- [ ] Local multiplayer (pass and play)
- [ ] Online multiplayer via GameKit
- [ ] Custom throw styles/animations
- [ ] Tournament mode
- [ ] Unlockable cosmetics (horseshoe skins, bag designs)
- [ ] AR environmental effects (wind, rain)
- [ ] Replay system with slow-motion camera

---

## Technical Notes & Gotchas

### CoreMotion
- **Must test on real device** — simulator has no motion sensors
- Use `.xArbitraryZVertical` reference frame so Z always points up regardless of phone orientation
- `userAcceleration` excludes gravity (what you want for gesture detection)
- `gravity` property gives gravity vector in device frame (useful for orientation)
- 100Hz is the practical max; 60Hz is fine for most use cases
- Always call `stopDeviceMotionUpdates()` when not needed — battery drain

### ARKit + RealityKit
- **LiDAR** (iPhone Pro/iPad Pro) dramatically improves plane detection and distance estimation, but app must work without it
- Plane detection takes 1-3 seconds typically; use `ARCoachingOverlayView` to guide users
- RealityKit physics runs at 60fps; match your motion capture rate to this
- `CollisionComponent` is required for physics interactions — entities without it pass through each other
- Use `HasPhysicsBody` protocol for entities that need physics simulation
- Scene anchors persist across frames; don't re-add entities every frame

### Physics Tuning
- The mapping from sensor acceleration to game velocity is the **most critical tuning parameter**
- Start with `speedScaleFactor = 2.5` and adjust based on feel
- Real horseshoe distance is ~40 feet (12.2m); cornhole is ~27 feet (8.2m)
- Consider a "difficulty" setting that scales the required accuracy of throws
- Drag coefficient affects how "floaty" the projectile feels — too low = bullet, too high = balloon

### Performance
- AR + physics + CoreMotion is CPU/GPU intensive
- Profile with Instruments early; watch for thermal throttling
- Consider reducing physics simulation quality on older devices
- Use `ModelComponent` LOD if available, or swap to simpler meshes at distance

---

## Bundle ID & Signing

- **Bundle ID:** `com.lnhenterprises.tossar` (or `com.lnhenterprises.TossAR`)
- **Team:** LNH Enterprises LLC (once Apple Developer enrollment completes)
- **Capabilities needed:** Camera (ARKit), Motion (CoreMotion)
- **Privacy descriptions required in Info.plist:**
  - `NSCameraUsageDescription`: "TossAR uses your camera to place game targets in your real environment."
  - `NSMotionUsageDescription`: "TossAR uses motion sensors to detect your throwing gesture."

---

## Claude Code Prototyping Instructions

When working with Claude Code on this project:

1. **Start with Sprint 1** — get the sensor playground working first
2. **Create the Xcode project** via `xcodegen` or manually — target iOS 17, SwiftUI lifecycle
3. **Implement files in order:** `MotionCaptureService` → debug view → `ThrowAnalyzer` → `TrajectoryCalculator` → SpriteKit scene → AR scene
4. **Test on-device after every meaningful change** — motion and AR cannot be tested in simulator
5. **Keep physics constants in a centralized `PhysicsConstants.swift`** so tuning is easy
6. **Use Combine publishers** to pipe motion data reactively rather than polling
7. **Log everything** in early sprints — sensor data, detected throws, computed trajectories — this data is gold for tuning

The starter code in this document is production-direction but needs compilation testing and iterative refinement. Use it as the foundation, not as copy-paste-and-ship.
