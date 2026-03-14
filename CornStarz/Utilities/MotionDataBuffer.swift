import CoreMotion

/// Fixed-size ring buffer for motion data samples
struct MotionDataBuffer {
    private var buffer: [CMDeviceMotion?]
    private var writeIndex: Int = 0
    private(set) var count: Int = 0

    let capacity: Int

    init(capacity: Int = 200) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }

    mutating func append(_ sample: CMDeviceMotion) {
        buffer[writeIndex] = sample
        writeIndex = (writeIndex + 1) % capacity
        count = min(count + 1, capacity)
    }

    mutating func clear() {
        buffer = Array(repeating: nil, count: capacity)
        writeIndex = 0
        count = 0
    }

    /// Returns samples in chronological order
    func allSamples() -> [CMDeviceMotion] {
        if count < capacity {
            return buffer[0..<count].compactMap { $0 }
        }
        let tail = buffer[writeIndex..<capacity].compactMap { $0 }
        let head = buffer[0..<writeIndex].compactMap { $0 }
        return tail + head
    }
}
