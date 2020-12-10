//
//  RubiksCubeRenderer.swift
//
//  Created by Jack Copsey on 16/11/2020.
//

import Cocoa
import OpenGL.GL

class RubiksCubeRenderer {
    typealias Scalar = GLdouble
    typealias Vertex = Vector3<Scalar>
    
    var rubiksCube: RubiksCube
    
    let cubeletLength: Scalar = 0.0187 // based on real Rubik's Cube, measured in m
    let cornerRadius:  Scalar = 0.0011 // ...
    let stickerLength: Scalar = 0.0158 // ...
    let stickerDepth:  Scalar = 0.0002 // ...
    var cubeLength: Scalar { cubeletLength * Scalar(rubiksCube.size) }
    var cubeRadius: Scalar { cubeLength * sqrt(0.75) }
    
    /// Graphical fidelity when rendering the cubelets. Must be at least zero.
    var cubeletLevelOfDetail = 4 {
        willSet {
            precondition(newValue >= 0, "Cannot set level of detail to value less than zero")
        }
        didSet {
            if cubeletLevelOfDetail != oldValue {
                computeCubeletVertices()
            }
        }
    }
    
    /// Graphical fidelity when rendering the stickers. Must be at least zero.
    var stickerLevelOfDetail = 4 {
        willSet {
            precondition(newValue >= 0, "Cannot set level of detail to value less than zero")
        }
        didSet {
            if stickerLevelOfDetail != oldValue {
                computeStickerVertices()
            }
        }
    }
    
    private var cubeletFaceVertexData: [Vertex] = []
    private var cubeletEdgeVertexData: [Vertex] = []
    private var cubeletCornerVertexData: [Vertex] = []
    private var stickerVertexData: [Vertex] = []
    private var stickerVertexDrawingOrder: [(Int, Int, Int)] = []
    
    /// Layer of the cube being rotated, if any, along with the angle measured in radians.
    var rotatedLayerAndAngle: (layer: RubiksCube.Layer, angle: Scalar)? = nil
    
    /// Color used to render the cube.
    var cubeColor = defaultCubeColor
    
    /// Color set used to render the stickers.
    /// Make sure every value on the cube has an entry in this dictionary.
    var stickerColors = defaultStickerColors
    
    /// Default colors for rendering the scene.
    static let defaultCubeColor = Color(red: 0, green: 0, blue: 0)
    static let defaultStickerColors = [
        -1: Color(red: 0.321569, green: 0.321569, blue: 0.321569), // grey
         0: Color(red: 0.000000, green: 0.337255, blue: 0.752941), // blue
         1: Color(red: 0.843137, green: 0.000000, blue: 0.000000), // red
         2: Color(red: 1.000000, green: 0.956863, blue: 0.000000), // yellow
         3: Color(red: 0.000000, green: 0.568627, blue: 0.000000), // green
         4: Color(red: 1.000000, green: 0.447059, blue: 0.000000), // orange
         5: Color(red: 1.000000, green: 1.000000, blue: 1.000000)  // white
    ]
    
    init(rubiksCube: RubiksCube) {
        self.rubiksCube = rubiksCube
        
        computeCubeletVertices()
        computeStickerVertices()
    }
    
    func computeCubeletVertices() {
        let length = cubeletLength
        let radius = cornerRadius
        
        // Case #1: Use rounded corners.
        if cubeletLevelOfDetail > 0 {
            // Compute the face vertices.
            
            cubeletFaceVertexData = [
                length * Vertex(0, 0, 0) + radius * Vertex( 1,  1, 0),
                length * Vertex(1, 0, 0) + radius * Vertex(-1,  1, 0),
                length * Vertex(1, 1, 0) + radius * Vertex(-1, -1, 0),
                length * Vertex(0, 1, 0) + radius * Vertex( 1, -1, 0)
            ]

            // Compute the edge vertices.
            
            cubeletEdgeVertexData.removeAll()
            cubeletEdgeVertexData.reserveCapacity(2 * (cubeletLevelOfDetail + 1))
            
            for row in 0...cubeletLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(row) / Scalar(cubeletLevelOfDetail)
                let sn = sin(theta)
                let cs = cos(theta)

                cubeletEdgeVertexData.append(length * Vertex(0, 0, 0) + radius * Vertex( 1, 1-sn, 1-cs))
                cubeletEdgeVertexData.append(length * Vertex(1, 0, 0) + radius * Vertex(-1, 1-sn, 1-cs))
            }

            // Compute the corner vertices.
            
            cubeletCornerVertexData.removeAll()
            cubeletCornerVertexData.reserveCapacity((cubeletLevelOfDetail + 1) * (cubeletLevelOfDetail + 2) / 2)
            
            for row in 0...cubeletLevelOfDetail {
                for col in 0...row {
                    let theta = 0.5 * .pi * Scalar(row) / Scalar(cubeletLevelOfDetail)
                    let phi = (row == 0) ? 0 : (0.5 * .pi * Scalar(col) / Scalar(row))

                    cubeletCornerVertexData.append(cornerRadius * Vector3(1 - sin(theta) * sin(phi), 1 - cos(theta), 1 - sin(theta) * cos(phi)))
                }
            }
        }

        // Case #2: Use sharp corners.
        else {
            cubeletFaceVertexData = [
                length * Vertex(0, 0, 0),
                length * Vertex(1, 0, 0),
                length * Vertex(1, 1, 0),
                length * Vertex(0, 1, 0)
            ]

            cubeletEdgeVertexData = [
                length * Vertex(0, 0, 0),
                length * Vertex(1, 0, 0)
            ]

            cubeletCornerVertexData = [
                length * Vertex(0, 0, 0)
            ]
        }
    }

    func computeStickerVertices() {
        let length = stickerLength
        let radius = cornerRadius
        let depth = stickerDepth
        let inset = (cubeletLength - stickerLength) / 2
        
        let base = Vertex(inset, inset, depth)

        // Case #1: Use rounded corners.
        if stickerLevelOfDetail > 0 {
            stickerVertexData.removeAll()
            stickerVertexData.reserveCapacity(4 * (stickerLevelOfDetail + 1) + 1)
            
            // Centre
            stickerVertexData.append(base + length * Vertex(0.5, 0.5, 0))
            
            // Bottom-left corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertexData.append(base + length * Vertex(0, 0, 0) + radius * Vertex(1-cs, 1-sn, 0))
            }
            
            // Bottom-right corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertexData.append(base + length * Vertex(1, 0, 0) + radius * Vertex(sn-1, 1-cs, 0))
            }
            
            // Top-right corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertexData.append(base + length * Vertex(1, 1, 0) + radius * Vertex(cs-1, sn-1, 0))
            }
            
            // Top-left corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertexData.append(base + length * Vertex(0, 1, 0) + radius * Vertex(1-sn, cs-1, 0))
            }
            
            stickerVertexDrawingOrder.removeAll()
            stickerVertexDrawingOrder.reserveCapacity(4 * (stickerLevelOfDetail + 1))
            
            for i in 0 ... 4 * (stickerLevelOfDetail + 1) {
                let bufferIndex1 = 0
                let bufferIndex2 = 1 +       i % (4 * (stickerLevelOfDetail + 1))
                let bufferIndex3 = 1 + (i + 1) % (4 * (stickerLevelOfDetail + 1))
                
                stickerVertexDrawingOrder.append((bufferIndex1, bufferIndex2, bufferIndex3))
            }
        }

        // Case #2: Use sharp corners.
        else {
            self.stickerVertexData = [
                base + length * Vertex(0, 0, 0),
                base + length * Vertex(1, 0, 0),
                base + length * Vertex(1, 1, 0),
                base + length * Vertex(0, 1, 0)
            ]
            
            self.stickerVertexDrawingOrder = [
                (0, 1, 2),
                (0, 2, 3)
            ]
        }
    }

    func render() {
        GL.pushMatrix()
        
        // Bring the origin to the corner of the first face.
        GL.translate(by: 0.5 * cubeLength * Vector3(-1, -1, 1))

        // Use a general drawing routine if one of the layers has been rotated.
        // Otherwise, use an optimised method.
        if rotatedLayerAndAngle != nil {
            renderCubeWithRotatedLayer()
        } else {
            renderCubeWithoutRotatedLayer()
        }

        GL.popMatrix()
    }
    
    private func renderCubeWithRotatedLayer() {
        let n = rubiksCube.size
        
        let rotatedLayer = rotatedLayerAndAngle!.layer
        let rotatedFace = rotatedLayer.face
        let oppositeFace = rotatedLayer.oppositeFace
        let angle = rotatedLayerAndAngle!.angle

        // Bring the origin to the face of rotation.
        for _ in 0 ..< rotatedFace.rawValue {
            bringOriginToNextFace()
        }

        // Render the cubelets.
        do {
            GL.pushMatrix()
            
            GL.translate(by: -cubeLength * .k)
            
            for z in 0..<n {
                for y in 0..<n {
                    for x in 0..<n {
                        GL.pushMatrix()
                        
                        // Apply an extra rotation for the rotated layer.
                        let depth = n - 1 - z
                        if depth == rotatedLayer.depth {
                            rotateOriginAroundCentralAxis(byAngle: angle)
                        }
                        
                        GL.translate(by: cubeletLength * Vector3(Double(x), Double(y), Double(z)))
                        renderCubelet()
                        
                        GL.popMatrix()
                    }
                }
            }

            GL.popMatrix()
        }
        
        // Render the top face's stickers.
        do {
            GL.pushMatrix()
            
            if rotatedLayer.depth == 0 {
                rotateOriginAroundCentralAxis(byAngle: angle)
            }
            
            renderStickers(onFace: rotatedFace)
            
            GL.popMatrix()
        }
        
        // Render the bottom face's stickers.
        do {
            GL.pushMatrix()
            
            if rotatedLayer.depth == n - 1 {
                rotateOriginAroundCentralAxis(byAngle: angle)
            }
            
            bringOriginToOppositeFace()
            renderStickers(onFace: oppositeFace)
            
            GL.popMatrix()
        }
        
        // Render the remaining stickers.
        do {
            GL.pushMatrix()
            
            GL.translate(by: -cubeLength * .k)
            
            for z in 0..<n {
                for x in 0..<n {
                    let face = rotatedFace + 5
                    let xRelativeToFace = z
                    let yRelativeToFace = x
                    let position = RubiksCube.Position(face: face, x: xRelativeToFace, y: yRelativeToFace)
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    renderSticker(at: position)
                    
                    GL.popMatrix()
                }
            }
            
            self.bringOriginToNextSide()

            for z in 0..<n {
                for x in 0..<n {
                    let face = rotatedFace + 1
                    let xRelativeToFace = x
                    let yRelativeToFace = n - 1 - z
                    let position = RubiksCube.Position(face: face, x: xRelativeToFace, y: yRelativeToFace)
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    renderSticker(at: position)
                    
                    GL.popMatrix()
                }
            }
            
            self.bringOriginToNextSide()
            
            for z in 0..<n {
                for x in 0..<n {
                    let face = rotatedFace + 2
                    let xRelativeToFace = n - 1 - z
                    let yRelativeToFace = x
                    let position = RubiksCube.Position(face: face, x: xRelativeToFace, y: yRelativeToFace)
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    renderSticker(at: position)
                    
                    GL.popMatrix()
                }
            }
            
            self.bringOriginToNextSide()
            
            for z in 0..<n {
                for x in 0..<n {
                    let face = rotatedFace + 4
                    let xRelativeToFace = x
                    let yRelativeToFace = z
                    let position = RubiksCube.Position(face: face, x: xRelativeToFace, y: yRelativeToFace)
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    renderSticker(at: position)
                    
                    GL.popMatrix()
                }
            }
            
            GL.popMatrix()
        }
    }
    
    private func renderCubeWithoutRotatedLayer() {
        let n = rubiksCube.size
        
        // Render the stickers.
        do {
            GL.pushMatrix()
            
            for face in RubiksCube.Face.allCases {
                renderStickers(onFace: face)
                bringOriginToNextFace()
            }
            
            GL.popMatrix()
        }

        // Render the cubelets.
        do {
            GL.pushMatrix()
            
            GL.translate(by: -cubeLength * .k)
            
            for z in 0..<n {
                for y in 0..<n {
                    for x in 0..<n {
                        GL.pushMatrix()
                        
                        GL.translate(by: cubeletLength * Vector3(Double(x), Double(y), Double(z)))
                        renderCubelet()
                        
                        GL.popMatrix()
                    }
                }
            }
            
            GL.popMatrix()
        }
    }
    
    private func renderCubelet() {
        GL.pushMatrix()

        // bottom face, edges and corners
        renderCubeletFace()
        for _ in 0..<4 {
            renderCubeletEdge()
            renderCubeletCorner()
            
            GL.translate(x: cubeletLength, y: 0, z: 0)
            GL.rotate(angle: .pi/2, axis: .k)
        }
        
        GL.rotate(angle: -.pi/2, axis: .j)
        GL.rotate(angle: -.pi/2, axis: .i)

        // middle faces and edges
        for _ in 0..<4 {
            renderCubeletFace()
            renderCubeletEdge()
            
            GL.translate(x: 0, y: cubeletLength, z: 0)
            GL.rotate(angle: .pi/2, axis: .i)
        }
        
        GL.translate(x: cubeletLength, y: 0, z: 0)
        GL.rotate(angle: -.pi/2, axis: .j)

        // top face, edges and corners
        renderCubeletFace()
        for _ in 0..<4 {
            renderCubeletEdge()
            renderCubeletCorner()
            
            GL.translate(x: cubeletLength, y: 0, z: 0)
            GL.rotate(angle: .pi/2, axis: .k)
        }

        GL.popMatrix()
    }

    private func renderCubeletFace() {
        GL.renderColor = cubeColor

        GL.beginQuads()
        
        for vertex in cubeletFaceVertexData {
            GL.addVertex(vertex)
        }

        GL.endShape()
    }

    private func renderCubeletEdge() {
        GL.renderColor = cubeColor

        GL.beginQuadStrip()
        
        for vertex in cubeletEdgeVertexData {
            GL.addVertex(vertex)
        }

        GL.endShape()
    }

    private func renderCubeletCorner() {
        GL.renderColor = cubeColor

        for row in 0..<cubeletLevelOfDetail {
            GL.beginTriangleStrip()

            for col in 0...row {
                GL.addVertex(cubeletCornerVertexData[(row + 1) * (row + 2) / 2 + col])
                GL.addVertex(cubeletCornerVertexData[row * (row + 1) / 2 + col])
            }
            
            GL.addVertex(cubeletCornerVertexData[(row + 1) * (row + 4) / 2])

            GL.endShape()
        }
    }

    private func renderSticker(color: Color) {
        GL.renderColor = color

        GL.beginTriangles()

        for (bufferIndex1, bufferIndex2, bufferIndex3) in stickerVertexDrawingOrder {
            GL.addVertex(stickerVertexData[bufferIndex1])
            GL.addVertex(stickerVertexData[bufferIndex2])
            GL.addVertex(stickerVertexData[bufferIndex3])
        }

        GL.endShape()
    }
    
    private func renderSticker(at position: RubiksCube.Position) {
        let value = rubiksCube[position]
        let color = stickerColors[value]!
        
        renderSticker(color: color)
    }

    private func renderStickers(onFace face: RubiksCube.Face) {
        let n = rubiksCube.size

        for x in 0..<n {
            for y in 0..<n {
                let position = RubiksCube.Position(face: face, x: x, y: y)
                let value = rubiksCube[position]
                let color = stickerColors[value]!
                
                GL.pushMatrix()

                GL.translate(by: cubeletLength * Vector3(Double(x), Double(y), 0))
                renderSticker(color: color)
                
                GL.popMatrix()
            }
        }
    }

    private func bringOriginToNextFace() {
        // Apply a translation `A` along the x axis, followed by a
        // rotation `B` by 1/4 turn anticlockwise around the y axis, and
        // finally a reflection `C` in the plane x=y.
        //
        // Note that due to how OpenGL's matrix operations work, the
        // transformation matrices are multiplied in _reverse_ order,
        // i.e. `A * B * C` instead of `C * B * A`.
        
        let transform = Matrix4x4(
            0,  0, 1, cubeLength,
            1,  0, 0,          0,
            0, -1, 0,          0,
            0,  0, 0,          1
        )
        
        GL.multiplyMatrix(by: transform)
    }

    private func bringOriginToOppositeFace() {
        // Apply a translation to the opposite corner of the cube,
        // followed by a reflection in each of the x, y and z directions.
        
        let transform = Matrix4x4(
            -1,  0,  0,  cubeLength,
             0, -1,  0,  cubeLength,
             0,  0, -1, -cubeLength,
             0,  0,  0,           1
        )
        
        GL.multiplyMatrix(by: transform)
    }
    
    private func bringOriginToNextSide() {
        // Apply a translation by the cube's length in the x direction,
        // then a rotation by 1/4 turn anticlockwise around the z axis.
        
        let transform = Matrix4x4(
            0, -1, 0, cubeLength,
            1,  0, 0,          0,
            0,  0, 1,          0,
            0,  0, 0,          1
        )
        
        GL.multiplyMatrix(by: transform)
    }
    
    private func rotateOriginAroundCentralAxis(byAngle angle: Double) {
        let halfLength = cubeLength / 2
        
        // Apply a translation `A` towards the cube's centre, followed by
        // a rotation `B` around the cube's central axis anticlockwise by the
        // specified angle, and finally a translation `C` away from the cube's
        // centre.
        //
        // Note that due to how OpenGL's matrix operations work, the
        // transformation matrices are multiplied in _reverse_ order,
        // i.e. `A * B * C` instead of `C * B * A`.
        
        let sn = sin(angle)
        let cs = cos(angle)
        
        let transform = Matrix4x4(
            cs, -sn, 0, halfLength * (1 + sn - cs),
            sn,  cs, 0, halfLength * (1 - sn - cs),
             0,   0, 1,                          0,
             0,   0, 0,                          1
        )
        
        GL.multiplyMatrix(by: transform)
    }
}

extension RubiksCube.Face {
    /// Find the unit vector perpendicular to the plane that the specified face lies within,
    /// with its sign adjusted to point from the cube's centre towards the face.
    var direction: Vector3<RubiksCubeRenderer.Scalar> {
        switch self {
            case .first:     return  .k
            case .second:    return  .i
            case .third:     return  .j
            case .fourth:    return -.k
            case .fifth:     return -.i
            case .sixth:     return -.j
        }
    }
}
