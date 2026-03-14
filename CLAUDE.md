# CornStarz — AR Toss Game for iOS

## Build & Run
- Project uses `xcodegen` — run `xcodegen generate` after adding/removing Swift files
- Build: `xcodebuild -project CornStarz.xcodeproj -scheme CornStarz -destination 'generic/platform=iOS' build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO`
- Must test on physical device — AR and motion sensors don't work in simulator
- Always verify the build compiles after making changes

## Project Structure
- **Architecture:** MVVM + Coordinator
- **Target:** iOS 18+, Swift, SwiftUI lifecycle
- **Bundle ID:** com.lnhenterprises.CornStarz
- **Key Frameworks:** ARKit, RealityKit, CoreMotion, CoreHaptics, AVFoundation, Swift Charts

## Code Style & Conventions

### Swift
- Use `let` over `var` unless mutation is required
- Prefer value types (`struct`, `enum`) over `class` unless reference semantics or inheritance are needed
- Use `guard` for early returns, not nested `if` blocks
- Mark classes `final` unless designed for inheritance
- Use access control — default to `private` for properties/methods, expose only what's needed
- Prefer `[weak self]` in closures that capture `self` to prevent retain cycles
- No force-unwrapping (`!`) except for `IBOutlet`s — use `guard let` or `if let`
- No force-try (`try!`) — handle errors properly or use `try?` with logging

### SwiftUI
- Use `@StateObject` for owned objects, `@ObservedObject` for passed-in objects
- Extract reusable views into separate structs when used more than once
- Keep view `body` lean — break complex views into computed properties or subviews
- Use `.task {}` for async work on view appear, not `onAppear` with Task blocks
- Prefer `Label` over `HStack { Image; Text }` for icon+text pairs

### Combine & Data Flow
- Use Combine publishers for reactive data flow (not async/await polling)
- Throttle high-frequency publishers (e.g., motion data) before binding to UI
- Always store subscriptions in `cancellables` and cancel on deinit
- ViewModels own services; Views observe ViewModels via `@Published`

### Project Organization
- Keep physics tuning constants in `Utilities/PhysicsConstants.swift`
- 3D entity classes go in `AR/` and conform to RealityKit `Has*` protocols
- Views use SwiftUI, no UIKit unless wrapping AR/SpriteKit views
- Debug/dev tools should be wrapped in `#if DEBUG`
- One type per file — file name matches the primary type name
- Group related files by feature layer (Models, Views, ViewModels, Services, AR, Utilities)

## Git & Version Control
- Write short commit messages focused on "why" not "what"
- Commit logical units of work — don't mix unrelated changes
- Never commit secrets, API keys, or credentials
- Keep `.gitignore` up to date — no derived data, build artifacts, or `.DS_Store`
- Use feature branches for non-trivial changes

## Testing
- Write unit tests for all business logic (scoring, physics, throw analysis)
- Test files go in `CornStarzTests/` and mirror the source file name with `Tests` suffix
- Tests should be independent — no shared mutable state between tests
- Name tests descriptively: `test<What>_<Condition>_<Expected>` (e.g., `testAnalyzer_belowThreshold_returnsNil`)

## Performance
- Profile with Instruments before optimizing — don't guess at bottlenecks
- Downsample sensor data for display (20Hz) while keeping full rate (100Hz) for capture
- Avoid allocations in tight loops (motion callbacks, render loops)
- Use `@MainActor` sparingly — only for UI updates, not computation
- Watch for thermal throttling on device — AR + physics + CoreMotion is intensive

## Safety & Security
- Never store user data without explicit consent
- Validate all external input at system boundaries
- Use `NSCameraUsageDescription` and `NSMotionUsageDescription` — already configured in Info.plist
- Always show wrist strap / safety warnings for motion-based gameplay

## Development Phases
See `TossAR-Project-Guide.md` for the full roadmap. Currently on Sprint 1 (Sensor Playground).
