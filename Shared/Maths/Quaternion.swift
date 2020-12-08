//
//  Quaternion.swift
//  Decipher
//
//  Created by Jack Copsey on 18/11/2020.
//

import Foundation

/// A quaternion w + x i + y j + z k.
struct Quaternion<Scalar: SignedNumeric> {
    var w: Scalar
    var x: Scalar
    var y: Scalar
    var z: Scalar
    
    /// The real part.
    @inlinable
    var real: Scalar {
        get { w }
        set { w = newValue }
    }
    
    /// The imaginary parts as a triple.
    @inlinable
    var imag: (Scalar, Scalar, Scalar) {
        get { (x, y, z) }
        set { x = newValue.0; y = newValue.1; z = newValue.2 }
    }
    
    /// Construct the zero quaternion.
    init() {
        w = 0
        x = 0
        y = 0
        z = 0
    }
    
    init(_ w: Scalar, _ x: Scalar, _ y: Scalar, _ z: Scalar) {
        self.w = w
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Construct a real quaternion from the given value.
    init(_ real: Scalar) {
        w = real
        x = 0
        y = 0
        z = 0
    }
    
    /// Construct a pure quaternion from the given triple.
    init(imag: (Scalar, Scalar, Scalar)) {
        w = 0
        x = imag.0
        y = imag.1
        z = imag.2
    }
    
    /// Construct a quaternion from the given real and imaginary values.
    init(real: Scalar, imag: (Scalar, Scalar, Scalar)) {
        w = real
        x = imag.0
        y = imag.1
        z = imag.2
    }
    
    @inlinable
    static var i: Quaternion { .init(0, 1, 0, 0) }
    
    @inlinable
    static var j: Quaternion { .init(0, 0, 1, 0) }
    
    @inlinable
    static var k: Quaternion { .init(0, 0, 0, 1) }
}

extension Quaternion: Equatable {
    @inlinable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.w == rhs.w && lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
}

extension Quaternion: Hashable where Scalar: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(w)
        hasher.combine(x)
        hasher.combine(y)
        hasher.combine(z)
    }
}

extension Quaternion: ExpressibleByIntegerLiteral {
    init(integerLiteral w: Scalar.IntegerLiteralType) {
        self.w = Scalar(integerLiteral: w)
        x = 0
        y = 0
        z = 0
    }
}

extension Quaternion: ExpressibleByFloatLiteral where Scalar: ExpressibleByFloatLiteral {
    init(floatLiteral w: Scalar.FloatLiteralType) {
        self.w = Scalar(floatLiteral: w)
        x = 0
        y = 0
        z = 0
    }
}

extension Quaternion: CustomStringConvertible {
    @inlinable
    var description: String {
        "\(w) + \(x) i + \(y) j + \(z) k"
    }
}

extension Quaternion: AdditiveArithmetic {
    @inlinable
    static var zero: Quaternion { 0 }
    
    @inlinable
    static prefix func + (operand: Quaternion) -> Quaternion {
        operand
    }
    
    static func + (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        let w = lhs.w + rhs.w
        let x = lhs.x + rhs.x
        let y = lhs.y + rhs.y
        let z = lhs.z + rhs.z
        return Quaternion(w, x, y, z)
    }
    
    static func - (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        let w = lhs.w - rhs.w
        let x = lhs.x - rhs.x
        let y = lhs.y - rhs.y
        let z = lhs.z - rhs.z
        return Quaternion(w, x, y, z)
    }
}

extension Quaternion {
    mutating func negate() {
        w.negate()
        x.negate()
        y.negate()
        z.negate()
    }
    
    @inlinable
    static prefix func - (q: Quaternion) -> Quaternion {
        Quaternion(-q.w, -q.x, -q.y, -q.z)
    }
    
    @inlinable
    var conjugate: Quaternion {
        Quaternion(w, -x, -y, -z)
    }
}

extension Quaternion {
    @inlinable
    static var one: Quaternion { 1 }
    
    static func * (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        let w1 = lhs.w * rhs.w
        let w2 = lhs.x * rhs.x
        let w3 = lhs.y * rhs.y
        let w4 = lhs.z * rhs.z
        let w = w1 - w2 - w3 - w4
        
        let x1 = lhs.w * rhs.x
        let x2 = lhs.x * rhs.w
        let x3 = lhs.y * rhs.z
        let x4 = lhs.z * rhs.y
        let x = x1 + x2 + x3 - x4
        
        let y1 = lhs.w * rhs.y
        let y2 = lhs.x * rhs.z
        let y3 = lhs.y * rhs.w
        let y4 = lhs.z * rhs.x
        let y = y1 - y2 + y3 + y4
        
        let z1 = lhs.w * rhs.z
        let z2 = lhs.x * rhs.y
        let z3 = lhs.y * rhs.x
        let z4 = lhs.z * rhs.w
        let z = z1 + z2 - z3 + z4

        return Quaternion(w, x, y, z)
    }
}

extension Quaternion {
    /// The squared length of `self`.
    var magnitudeSquared: Scalar {
        let rw = w * w
        let rx = x * x
        let ry = y * y
        let rz = z * z
        return rw + rx + ry + rz
    }
}

extension Quaternion where Scalar: FloatingPoint {
    @inlinable
    var reciprocal: Quaternion {
        conjugate / magnitudeSquared
    }
    
    @inlinable
    static func / (lhs: Quaternion, rhs: Quaternion) -> Quaternion {
        lhs * rhs.reciprocal
    }
    
    /// The length of `self`.
    @inlinable
    var magnitude: Scalar {
        sqrt(magnitudeSquared)
    }
    
    /// The unit quaternion in the same direction as `self`.
    @inlinable
    var direction: Quaternion {
        self / magnitude
    }
}

// Syntactic sugar for treating scalars as quaternions

extension Quaternion {
    static func + (quaternion: Quaternion, real: Scalar) -> Quaternion {
        let w = quaternion.w + real
        let x = quaternion.x
        let y = quaternion.y
        let z = quaternion.z
        return Quaternion(w, x, y, z)
    }
    
    static func + (real: Scalar, quaternion: Self) -> Quaternion {
        let w = real + quaternion.w
        let x = quaternion.x
        let y = quaternion.y
        let z = quaternion.z
        return Quaternion(w, x, y, z)
    }
    
    static func += (quaternion: inout Quaternion, real: Scalar) {
        quaternion.w += real
    }
    
    static func - (quaternion: Quaternion, real: Scalar) -> Quaternion {
        let w = quaternion.w - real
        let x = quaternion.x
        let y = quaternion.y
        let z = quaternion.z
        return Quaternion(w, x, y, z)
    }
    
    static func - (real: Scalar, quaternion: Quaternion) -> Quaternion {
        let w = real - quaternion.w
        let x = -quaternion.x
        let y = -quaternion.y
        let z = -quaternion.z
        return Quaternion(w, x, y, z)
    }
    
    static func -= (quaternion: inout Quaternion, real: Scalar) {
        quaternion.w -= real
    }
    
    static func * (quaternion: Quaternion, real: Scalar) -> Quaternion {
        let w = quaternion.w * real
        let x = quaternion.x * real
        let y = quaternion.y * real
        let z = quaternion.z * real
        return Quaternion(w, x, y, z)
    }
    
    static func * (real: Scalar, quaternion: Quaternion) -> Quaternion {
        let w = real * quaternion.w
        let x = real * quaternion.x
        let y = real * quaternion.y
        let z = real * quaternion.z
        return Quaternion(w, x, y, z)
    }
    
    static func *= (quaternion: inout Quaternion, real: Scalar) {
        quaternion.w *= real
        quaternion.x *= real
        quaternion.y *= real
        quaternion.z *= real
    }
}

extension Quaternion where Scalar: FloatingPoint {
    static func / (quaternion: Quaternion, real: Scalar) -> Quaternion {
        let w = quaternion.w / real
        let x = quaternion.x / real
        let y = quaternion.y / real
        let z = quaternion.z / real
        return Quaternion(w, x, y, z)
    }
    
    @inlinable
    static func / (real: Scalar, quaternion: Quaternion) -> Quaternion {
        real * quaternion.reciprocal
    }
    
    static func /= (quaternion: inout Quaternion, real: Scalar) {
        quaternion.w /= real
        quaternion.x /= real
        quaternion.y /= real
        quaternion.z /= real
    }
}
