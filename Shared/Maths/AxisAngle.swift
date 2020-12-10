//
//  AxisAngle.swif
//
//  Created by Jack Copsey on 19/11/2020.
//

import Foundation

/// A type representing an anticlockwise rotation in 3D space around an axis,
/// by an angle measured in radians.
struct AxisAngle<Scalar: FloatingPoint> {
    typealias Vector = Vector3<Scalar>
    
    var axis: Vector
    var angle: Scalar
    
    /// Choose the axis and angle to represent a rotation by zero radians.
    init() {
        self.axis = .i
        self.angle = 0
    }
    
    /// Construct the rotation from the given axis and angle.
    /// It's expected that the axis has a magnitude of one.
    init(axis: Vector, angle: Scalar) {
        self.axis = axis
        self.angle = angle
    }
}

extension AxisAngle where Scalar == Double {
    /// Construct the rotation from a unit quaternion.
    /// It's an error if the quaternion does not have a magnitude of one.
    init(fromUnitQuaternion q: Quaternion<Scalar>) {
        let theta = acos(q.w)
        let cosec = 1 / sin(theta)
        
        if cosec.isFinite {
            self.init(axis: cosec * Vector3(q.imag), angle: 2 * theta)
        } else {
            self.init(axis: .i, angle: 0)
        }
    }
}

extension Quaternion where Scalar == Double {
    init(fromRotation axisAndAngle: AxisAngle<Scalar>) {
        let axis = axisAndAngle.axis
        let angle = axisAndAngle.angle
        
        let theta = angle / 2
        let w = cos(theta)
        let xyz = axis * sin(theta)
        self.init(real: w, imag: xyz.data)
    }
    
    init(fromOrientation newBasis: (Vector3<Scalar>, Vector3<Scalar>, Vector3<Scalar>)) {
        // The orientation can be represented as a 3x3 special orthogonal matrix,
        // mapping the original basis (i,j,k) to the new basis (e,f,g).
        let (e, f, g) = newBasis
        let (m11, m12, m13) = (e.x, e.y, e.z)
        let (m21, m22, m23) = (f.x, f.y, f.z)
        let (m31, m32, m33) = (g.x, g.y, g.z)
        
        // Calculate the quaternion that represents the new orientation.
        // (adapted from http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/ )
        
        let w, x, y, z: Scalar
        let trace = m11 + m22 + m33

        if trace > 0 {
            let S = sqrt(1 + trace) * 2
            w = 0.25 * S
            x = (m32 - m23) / S
            y = (m13 - m31) / S
            z = (m21 - m12) / S
        } else if m11 > m22 && m11 > m33 {
            let S = sqrt(1 + m11 - m22 - m33) * 2
            w = (m32 - m23) / S
            x = 0.25 * S
            y = (m12 + m21) / S
            z = (m13 + m31) / S
        } else if m11 > m22 {
            let S = sqrt(1 - m11 + m22 - m33) * 2
            w = (m13 - m31) / S
            x = (m12 + m21) / S
            y = 0.25 * S
            z = (m23 + m32) / S
        } else {
            let S = sqrt(1 - m11 - m22 + m33) * 2
            w = (m21 - m12) / S
            x = (m13 + m31) / S
            y = (m23 + m32) / S
            z = 0.25 * S
        }
        
        // NOTE: The quaternion must be conjugated
        self.init(w, -x, -y, -z)
    }
}
