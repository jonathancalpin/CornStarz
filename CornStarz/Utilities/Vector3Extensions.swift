import simd

extension SIMD3 where Scalar == Float {
    var horizontalLength: Float {
        sqrt(x * x + z * z)
    }

    var description2D: String {
        String(format: "(%.2f, %.2f, %.2f)", x, y, z)
    }
}

extension SIMD3 where Scalar == Double {
    var horizontalLength: Double {
        sqrt(x * x + z * z)
    }
}
