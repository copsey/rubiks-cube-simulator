//
//  Matrix4x4.swift
//
//  Created by Jack Copsey on 02/12/2020.
//

import Foundation

struct Matrix4x4<Scalar: AdditiveArithmetic> {
    /// The elements of the matrix in row-major order.
    var data: (Scalar, Scalar, Scalar, Scalar,
               Scalar, Scalar, Scalar, Scalar,
               Scalar, Scalar, Scalar, Scalar,
               Scalar, Scalar, Scalar, Scalar)
    
    /// Construct the matrix whose elements are all zero.
    init() {
        self.data = (.zero, .zero, .zero, .zero,
                     .zero, .zero, .zero, .zero,
                     .zero, .zero, .zero, .zero,
                     .zero, .zero, .zero, .zero)
    }
    
    /// Construct the matrix with the given elements in row-major order.
    init(_ m00: Scalar, _ m01: Scalar, _ m02: Scalar, _ m03: Scalar,
         _ m10: Scalar, _ m11: Scalar, _ m12: Scalar, _ m13: Scalar,
         _ m20: Scalar, _ m21: Scalar, _ m22: Scalar, _ m23: Scalar,
         _ m30: Scalar, _ m31: Scalar, _ m32: Scalar, _ m33: Scalar)
    {
        self.data = (m00, m01, m02, m03,
                     m10, m11, m12, m13,
                     m20, m21, m22, m23,
                     m30, m31, m32, m33)
    }
}

extension Matrix4x4: Equatable {
    static func == (lhs: Matrix4x4, rhs: Matrix4x4) -> Bool {
        lhs.data.00 == rhs.data.00
            && lhs.data.01 == rhs.data.01
            && lhs.data.02 == rhs.data.02
            && lhs.data.03 == rhs.data.03
            && lhs.data.04 == rhs.data.04
            && lhs.data.05 == rhs.data.05
            && lhs.data.06 == rhs.data.06
            && lhs.data.07 == rhs.data.07
            && lhs.data.08 == rhs.data.08
            && lhs.data.09 == rhs.data.09
            && lhs.data.10 == rhs.data.10
            && lhs.data.11 == rhs.data.11
            && lhs.data.12 == rhs.data.12
            && lhs.data.13 == rhs.data.13
            && lhs.data.14 == rhs.data.14
            && lhs.data.15 == rhs.data.15
    }
}

extension Matrix4x4: AdditiveArithmetic {
    static var zero: Matrix4x4 {
        Matrix4x4(.zero, .zero, .zero, .zero,
                  .zero, .zero, .zero, .zero,
                  .zero, .zero, .zero, .zero,
                  .zero, .zero, .zero, .zero)
    }
    
    static prefix func + (matrix: Matrix4x4) -> Matrix4x4 {
        matrix
    }
    
    static func + (lhs: Matrix4x4, rhs: Matrix4x4) -> Matrix4x4 {
        let m00 = lhs.data.00 + rhs.data.00
        let m01 = lhs.data.01 + rhs.data.01
        let m02 = lhs.data.02 + rhs.data.02
        let m03 = lhs.data.03 + rhs.data.03
        let m10 = lhs.data.04 + rhs.data.04
        let m11 = lhs.data.05 + rhs.data.05
        let m12 = lhs.data.06 + rhs.data.06
        let m13 = lhs.data.07 + rhs.data.07
        let m20 = lhs.data.08 + rhs.data.08
        let m21 = lhs.data.09 + rhs.data.09
        let m22 = lhs.data.10 + rhs.data.10
        let m23 = lhs.data.11 + rhs.data.11
        let m30 = lhs.data.12 + rhs.data.12
        let m31 = lhs.data.13 + rhs.data.13
        let m32 = lhs.data.14 + rhs.data.14
        let m33 = lhs.data.15 + rhs.data.15
        
        return Matrix4x4(m00, m01, m02, m03,
                         m10, m11, m12, m13,
                         m20, m21, m22, m23,
                         m30, m31, m32, m33)
    }
    
    static func - (lhs: Matrix4x4, rhs: Matrix4x4) -> Matrix4x4 {
        let m00 = lhs.data.00 - rhs.data.00
        let m01 = lhs.data.01 - rhs.data.01
        let m02 = lhs.data.02 - rhs.data.02
        let m03 = lhs.data.03 - rhs.data.03
        let m10 = lhs.data.04 - rhs.data.04
        let m11 = lhs.data.05 - rhs.data.05
        let m12 = lhs.data.06 - rhs.data.06
        let m13 = lhs.data.07 - rhs.data.07
        let m20 = lhs.data.08 - rhs.data.08
        let m21 = lhs.data.09 - rhs.data.09
        let m22 = lhs.data.10 - rhs.data.10
        let m23 = lhs.data.11 - rhs.data.11
        let m30 = lhs.data.12 - rhs.data.12
        let m31 = lhs.data.13 - rhs.data.13
        let m32 = lhs.data.14 - rhs.data.14
        let m33 = lhs.data.15 - rhs.data.15
        
        return Matrix4x4(m00, m01, m02, m03,
                         m10, m11, m12, m13,
                         m20, m21, m22, m23,
                         m30, m31, m32, m33)
    }
}

extension Matrix4x4 where Scalar: Numeric {
    static var one: Matrix4x4 {
        Matrix4x4(1, 0, 0, 0,
                  0, 1, 0, 0,
                  0, 0, 1, 0,
                  0, 0, 0, 1)
    }
}
