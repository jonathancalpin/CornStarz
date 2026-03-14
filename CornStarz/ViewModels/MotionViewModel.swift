import SwiftUI
import Combine
import simd

class MotionViewModel: ObservableObject {
    @Published var accelerationX: Double = 0
    @Published var accelerationY: Double = 0
    @Published var accelerationZ: Double = 0
    @Published var magnitude: Double = 0
    @Published var rotationX: Double = 0
    @Published var rotationY: Double = 0
    @Published var rotationZ: Double = 0

    private let motionService: MotionCaptureService
    private var cancellables = Set<AnyCancellable>()

    init(motionService: MotionCaptureService) {
        self.motionService = motionService

        motionService.$currentAcceleration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accel in
                self?.accelerationX = accel.x
                self?.accelerationY = accel.y
                self?.accelerationZ = accel.z
                self?.magnitude = simd_length(accel)
            }
            .store(in: &cancellables)

        motionService.$currentRotationRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rot in
                self?.rotationX = rot.x
                self?.rotationY = rot.y
                self?.rotationZ = rot.z
            }
            .store(in: &cancellables)
    }
}
