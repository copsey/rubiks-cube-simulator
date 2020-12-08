//
//  Vector3.swift
//  Decipher
//
//  Created by Jack Copsey on 18/11/2020.
//

import Foundation

struct Vector3<Scalar: AdditiveArithmetic> {
    /// The three coordinates of the vector in the order `(self.x, self.y, self.z)`.
    var data: (Scalar, Scalar, Scalar)
    
    @inlinable
    var x: Scalar {
        get { data.0 }
        set { data.0 = newValue }
    }
    
    @inlinable
    var y: Scalar {
        get { data.1 }
        set { data.1 = newValue }
    }
    
    @inlinable
    var z: Scalar {
        get { data.2 }
        set { data.2 = newValue }
    }
    
    init() {
        data.0 = .zero
        data.1 = .zero
        data.2 = .zero
    }
    
    init(_ x: Scalar, _ y: Scalar, _ z: Scalar) {
        data.0 = x
        data.1 = y
        data.2 = z
    }
    
    init(_ data: (Scalar, Scalar, Scalar)) {
        self.data = data
    }
    
    subscript(_ index: Int) -> Scalar {
        get {
            switch index {
            case 0:     return data.0
            case 1:     return data.1
            case 2:     return data.2
            default:    Vector3._indexPreconditionFailure()
            }
        }
        
        set {
            switch index {
            case 0:     data.0 = newValue
            case 1:     data.1 = newValue
            case 2:     data.2 = newValue
            default:    Vector3._indexPreconditionFailure()
            }
        }
    }
}

extension Vector3 {
    private static func _indexPreconditionFailure() -> Never {
        preconditionFailure("Index must be 0, 1 or 2")
    }
}

extension Vector3: Equatable {
    static func == (lhs: Vector3, rhs: Vector3) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

extension Vector3: Hashable where Scalar: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
    }
}

extension Vector3 where Scalar: ExpressibleByIntegerLiteral {
    /// The basis vector along the x axis: `(1, 0, 0)`
    static var i: Vector3 {
        Vector3(1, 0, 0)
    }
    
    /// The basis vector along the y axis: `(0, 1, 0)`
    static var j: Vector3 {
        Vector3(0, 1, 0)
    }
    
    /// The basis vector along the z axis: `(0, 0, 1)`
    static var k: Vector3 {
        Vector3(0, 0, 1)
    }
}

extension Vector3: CustomStringConvertible {
    var description: String {
        "(\(x), \(y), \(z))"
    }
}

extension Vector3: AdditiveArithmetic {
    static var zero: Vector3 {
        Vector3(.zero, .zero, .zero)
    }
    
    static prefix func + (vector: Vector3) -> Vector3 {
        vector
    }
    
    static func + (lhs: Vector3, rhs: Vector3) -> Vector3 {
        let x = lhs.x + rhs.x
        let y = lhs.y + rhs.y
        let z = lhs.z + rhs.z
        return Vector3(x, y, z)
    }
    
    static func - (lhs: Vector3, rhs: Vector3) -> Vector3 {
        let x = lhs.x - rhs.x
        let y = lhs.y - rhs.y
        let z = lhs.z - rhs.z
        return Vector3(x, y, z)
    }
}

extension Vector3 where Scalar: Numeric {
    static func * (vector: Vector3, scalar: Scalar) -> Vector3 {
        let x = vector.x * scalar
        let y = vector.y * scalar
        let z = vector.z * scalar
        return Vector3(x, y, z)
    }
    
    static func * (scalar: Scalar, vector: Self) -> Self {
        let x = scalar * vector.x
        let y = scalar * vector.y
        let z = scalar * vector.z
        return Vector3(x, y, z)
    }
    
    static func *= (vector: inout Vector3, scalar: Scalar) {
        vector.x *= scalar
        vector.y *= scalar
        vector.z *= scalar
    }
    
    /// The squared length of the vector.
    var magnitudeSquared: Scalar {
        self.dot(self)
    }
    
    /// Calculate the squared distance between `self` and the given vector.
    func distanceSquared(from other: Vector3) -> Scalar {
        (self - other).magnitudeSquared
    }
    
    /// Calculate the scalar product of `self` and the given vector.
    func dot(_ other: Vector3) -> Scalar {
        let rx = self.x * other.x
        let ry = self.y * other.y
        let rz = self.z * other.z
        return rx + ry + rz
    }
    
    /// Calculate the vector product of `self` and the given vector.
    func cross(_ other: Vector3) -> Vector3 {
        let x = self.y * other.z - self.z * other.y
        let y = self.z * other.x - self.x * other.z
        let z = self.x * other.y - self.y * other.x
        return Vector3(x, y, z)
    }
}

extension Vector3 where Scalar: SignedNumeric {
    mutating func negate() {
        x.negate()
        y.negate()
        z.negate()
    }
    
    static prefix func - (vector: Vector3) -> Vector3 {
        Vector3(-vector.x, -vector.y, -vector.z)
    }
}

extension Vector3 where Scalar: FloatingPoint {
    static func / (vector: Vector3, scalar: Scalar) -> Vector3 {
        var result = vector
        result /= scalar
        return result
    }
    
    static func /= (vector: inout Vector3, scalar: Scalar) {
        vector.x /= scalar
        vector.y /= scalar
        vector.z /= scalar
    }
    
    /// The length of the vector.
    var magnitude: Scalar {
        sqrt(magnitudeSquared)
    }
    
    /// The unit vector in the same direction as `self`.
    ///
    /// ## Special cases
    /// - If `self.magnitude` is zero, then `self.direction` will be `(nan, nan, nan)`.
    /// - If `self.magnitude` is infinite, then the coordinates of `self.direction` will be 0, +1 or -1.
    /// - If any coordinates of `self` are `nan`, then `self.direction` will be `(nan, nan, nan)`.
    var direction: Vector3 {
        let magnitude = self.magnitude
        
        if magnitude.isZero {
            return Vector3(.nan, .nan, .nan)
        } else if magnitude.isFinite {
            return self / magnitude
        } else if magnitude.isInfinite {
            let x: Scalar = (self.x == .infinity) ? +1 : (self.x == -.infinity) ? -1 : 0
            let y: Scalar = (self.y == .infinity) ? +1 : (self.y == -.infinity) ? -1 : 0
            let z: Scalar = (self.z == .infinity) ? +1 : (self.z == -.infinity) ? -1 : 0
            return Vector3(x, y, z).direction
        } else { // magnitude.isNaN
            return Vector3(.nan, .nan, .nan)
        }
    }
    
    /// Calculate the distance between `self` and the given vector.
    func distance(from other: Vector3) -> Scalar {
        sqrt(self.distanceSquared(from: other))
    }
    
    /// Indicates if all of the vector's coordinates are finite.
    var isFinite: Bool {
        x.isFinite && y.isFinite && z.isFinite
    }
}
