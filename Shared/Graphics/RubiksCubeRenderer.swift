//
//  RubiksCubeRenderer.swift
//  Decipher
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
    var cubeLength: Scalar { self.cubeletLength * Scalar(self.rubiksCube.valuesPerSide) }
    var cubeRadius: Scalar { self.cubeLength * sqrt(0.75) }
    
    /// Graphical fidelity when rendering the cubelets. Must be at least zero.
    var cubeletLevelOfDetail = 4 {
        willSet {
            precondition(newValue >= 0, "Cannot set level of detail to value less than zero")
        }
        didSet {
            if self.cubeletLevelOfDetail != oldValue {
                self.computeCubeletVertices()
            }
        }
    }
    
    /// Graphical fidelity when rendering the stickers. Must be at least zero.
    var stickerLevelOfDetail = 4 {
        willSet {
            precondition(newValue >= 0, "Cannot set level of detail to value less than zero")
        }
        didSet {
            if self.stickerLevelOfDetail != oldValue {
                self.computeStickerVertices()
            }
        }
    }
    
    private var cubeletFaceVertices: Array<Vertex> = []
    private var cubeletEdgeVertices: Array<Vertex> = []
    private var cubeletCornerVertices: Array<Vertex> = []
    private var stickerVertices: Array<Vertex> = []
    
    /// Layer of the cube being rotated, if any, along with the angle measured in radians.
    var rotatedLayerAndAngle: (RubiksCube.Layer, Scalar)? = nil
    
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
        
        self.computeCubeletVertices()
        self.computeStickerVertices()
    }
    
    func computeCubeletVertices() {
        let length = self.cubeletLength
        let radius = self.cornerRadius
        
        // Case #1: Use rounded corners.
        if cubeletLevelOfDetail > 0 {
            // Compute the face vertices.
            
            cubeletFaceVertices = [
                length * Vertex(0, 0, 0) + radius * Vertex( 1,  1, 0),
                length * Vertex(1, 0, 0) + radius * Vertex(-1,  1, 0),
                length * Vertex(1, 1, 0) + radius * Vertex(-1, -1, 0),
                length * Vertex(0, 1, 0) + radius * Vertex( 1, -1, 0)
            ]

            // Compute the edge vertices.
            
            cubeletEdgeVertices.removeAll()
            cubeletEdgeVertices.reserveCapacity(2 * (cubeletLevelOfDetail + 1))
            
            for row in 0...cubeletLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(row) / Scalar(cubeletLevelOfDetail)
                let sn = sin(theta)
                let cs = cos(theta)

                cubeletEdgeVertices.append(length * Vertex(0, 0, 0) + radius * Vertex( 1, 1-sn, 1-cs))
                cubeletEdgeVertices.append(length * Vertex(1, 0, 0) + radius * Vertex(-1, 1-sn, 1-cs))
            }

            // Compute the corner vertices.
            
            cubeletCornerVertices.removeAll()
            cubeletCornerVertices.reserveCapacity((cubeletLevelOfDetail + 1) * (cubeletLevelOfDetail + 2) / 2)
            
            for row in 0...cubeletLevelOfDetail {
                for col in 0...row {
                    let theta = 0.5 * .pi * Scalar(row) / Scalar(cubeletLevelOfDetail)
                    let phi = (row == 0) ? 0 : (0.5 * .pi * Scalar(col) / Scalar(row))

                    cubeletCornerVertices.append(cornerRadius * Vector3(1 - sin(theta) * sin(phi), 1 - cos(theta), 1 - sin(theta) * cos(phi)))
                }
            }
        }

        // Case #2: Use sharp corners.
        else {
            cubeletFaceVertices = [
                length * Vertex(0, 0, 0),
                length * Vertex(1, 0, 0),
                length * Vertex(1, 1, 0),
                length * Vertex(0, 1, 0)
            ]

            cubeletEdgeVertices = [
                length * Vertex(0, 0, 0),
                length * Vertex(1, 0, 0)
            ]

            cubeletCornerVertices = [
                length * Vertex(0, 0, 0)
            ]
        }
    }

    func computeStickerVertices() {
        let length = self.stickerLength
        let radius = self.cornerRadius
        let depth = self.stickerDepth
        let inset = (self.cubeletLength - self.stickerLength) / 2
        
        let base = Vertex(inset, inset, depth)

        // Case #1: Use rounded corners.
        if stickerLevelOfDetail > 0 {
            stickerVertices.removeAll()
            stickerVertices.reserveCapacity(4 * (stickerLevelOfDetail + 1))
            
            // Bottom-left corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertices.append(base + length * Vertex(0, 0, 0) + radius * Vertex(1-cs, 1-sn, 0))
            }
            
            // Bottom-right corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertices.append(base + length * Vertex(1, 0, 0) + radius * Vertex(sn-1, 1-cs, 0))
            }
            
            // Top-right corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertices.append(base + length * Vertex(1, 1, 0) + radius * Vertex(cs-1, sn-1, 0))
            }
            
            // Top-left corner
            for i in 0...stickerLevelOfDetail {
                let theta = 0.5 * .pi * Scalar(i) / Scalar(stickerLevelOfDetail)
                let cs = cos(theta)
                let sn = sin(theta)

                stickerVertices.append(base + length * Vertex(0, 1, 0) + radius * Vertex(1-sn, cs-1, 0))
            }
        }

        // Case #2: Use sharp corners.
        else {
            stickerVertices = [
                base + length * Vertex(0, 0, 0),
                base + length * Vertex(1, 0, 0),
                base + length * Vertex(1, 1, 0),
                base + length * Vertex(0, 1, 0)
            ]
        }
    }

    func render() {
        GL.pushMatrix()

        /* TODO: Draw the core of the cube */
        /* (i.e. draw enough central cubelets to fill in the whole of the middle.) */

        //   NSColor * cubeColor = self.cubeColor;
        //   glColor3f(cubeColor.redComponent, cubeColor.greenComponent, cubeColor.blueComponent);
        //
        //   glBegin(GL_QUAD_STRIP);
        //
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[0]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[1]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[2]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[3]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[4]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[5]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[6]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[7]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[0]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[1]);
        //
        //   glEnd();
        //
        //   glBegin(GL_QUADS);
        //
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[0]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[2]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[4]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[6]);
        //
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[1]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[3]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[5]);
        //   glVertex3dv(rubiksCubeCentralCubeletVertices[7]);
        //
        //   glEnd();
        
        // Bring the origin to the corner of the first face.
        GL.translate(by: 0.5 * self.cubeLength * Vector3(-1, -1, 1))

        // Use a general drawing routine if one of the layers has been rotated.
        // Otherwise, use an optimised method.
        if rotatedLayerAndAngle != nil {
            self.renderCubeWithRotatedLayer()
        } else {
            self.renderCubeWithoutRotatedLayer()
        }

        GL.popMatrix()
    }
    
    private func renderCubeWithRotatedLayer() {
        let n = self.rubiksCube.valuesPerSide
        
        let rotatedLayer = self.rotatedLayerAndAngle!.0
        let rotatedFace = rotatedLayer.face
        let oppositeFace = (rotatedFace + 3) % 6
        let angle = self.rotatedLayerAndAngle!.1
        
        let cubeLength = self.cubeLength
        let cubeletLength = self.cubeletLength

        // Bring the origin to the face of rotation.
        for _ in 0 ..< rotatedFace {
            self.bringOriginToNextFace()
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
                            self.rotateOriginAroundCentralAxis(byAngle: angle)
                        }
                        
                        GL.translate(by: cubeletLength * Vector3(Double(x), Double(y), Double(z)))
                        self.renderCubelet()
                        
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
                self.rotateOriginAroundCentralAxis(byAngle: angle)
            }
            
            self.renderStickers(onFace: rotatedFace)
            
            GL.popMatrix()
        }
        
        // Render the bottom face's stickers.
        do {
            GL.pushMatrix()
            
            if rotatedLayer.depth == n - 1 {
                self.rotateOriginAroundCentralAxis(byAngle: angle)
            }
            
            self.bringOriginToOppositeFace()
            self.renderStickers(onFace: oppositeFace)
            
            GL.popMatrix()
        }
        
        // Render the remaining stickers.
        do {
            GL.pushMatrix()
            
            GL.translate(by: -cubeLength * .k)
            
            for z in 0..<n {
                for x in 0..<n {
                    let face = (rotatedLayer.face + 5) % 6
                    let xRelativeToFace = z
                    let yRelativeToFace = x
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        self.rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    self.renderSticker(at: .init(face: face, x: xRelativeToFace, y: yRelativeToFace))
                    
                    GL.popMatrix()
                }
            }
            
            self.bringOriginToNextSide()

            for z in 0..<n {
                for x in 0..<n {
                    let face = (rotatedLayer.face + 1) % 6
                    let xRelativeToFace = x
                    let yRelativeToFace = n - 1 - z
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        self.rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    self.renderSticker(at: .init(face: face, x: xRelativeToFace, y: yRelativeToFace))
                    
                    GL.popMatrix()
                }
            }
            
            self.bringOriginToNextSide()
            
            for z in 0..<n {
                for x in 0..<n {
                    let face = (rotatedLayer.face + 2) % 6
                    let xRelativeToFace = n - 1 - z
                    let yRelativeToFace = x
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        self.rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    self.renderSticker(at: .init(face: face, x: xRelativeToFace, y: yRelativeToFace))
                    
                    GL.popMatrix()
                }
            }
            
            self.bringOriginToNextSide()
            
            for z in 0..<n {
                for x in 0..<n {
                    let face = (rotatedFace + 4) % 6
                    let xRelativeToFace = x
                    let yRelativeToFace = z
                    
                    GL.pushMatrix()
                    
                    // Apply an extra rotation for the rotated layer.
                    let depth = n - 1 - z
                    if depth == rotatedLayer.depth {
                        self.rotateOriginAroundCentralAxis(byAngle: angle)
                    }
                    
                    GL.translate(by: cubeletLength * Vector3(Double(x), 0, Double(z)))
                    GL.rotate(angle: .pi/2, axis: .i)
                    
                    self.renderSticker(at: .init(face: face, x: xRelativeToFace, y: yRelativeToFace))
                    
                    GL.popMatrix()
                }
            }
            
            GL.popMatrix()
        }
    }
    
    private func renderCubeWithoutRotatedLayer() {
        let n = self.rubiksCube.valuesPerSide
        
        // Render the stickers.
        do {
            GL.pushMatrix()
            
            for face in 0..<6 {
                self.renderStickers(onFace: face)
                self.bringOriginToNextFace()
            }
            
            GL.popMatrix()
        }

        // Render the cubelets.
        do {
            GL.pushMatrix()
            
            GL.translate(by: -self.cubeLength * .k)
            
            for z in 0..<n {
                for y in 0..<n {
                    for x in 0..<n {
                        GL.pushMatrix()
                        
                        GL.translate(by: self.cubeletLength * Vector3(Double(x), Double(y), Double(z)))
                        self.renderCubelet()
                        
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
        self.renderCubeletFace()
        for _ in 0..<4 {
            self.renderCubeletEdge()
            self.renderCubeletCorner()
            
            GL.translate(x: cubeletLength, y: 0, z: 0)
            GL.rotate(angle: .pi/2, axis: .k)
        }
        
        GL.rotate(angle: -.pi/2, axis: .j)
        GL.rotate(angle: -.pi/2, axis: .i)

        // middle faces and edges
        for _ in 0..<4 {
            self.renderCubeletFace()
            self.renderCubeletEdge()
            
            GL.translate(x: 0, y: cubeletLength, z: 0)
            GL.rotate(angle: .pi/2, axis: .i)
        }
        
        GL.translate(x: cubeletLength, y: 0, z: 0)
        GL.rotate(angle: -.pi/2, axis: .j)

        // top face, edges and corners
        self.renderCubeletFace()
        for _ in 0..<4 {
            self.renderCubeletEdge()
            self.renderCubeletCorner()
            
            GL.translate(x: cubeletLength, y: 0, z: 0)
            GL.rotate(angle: .pi/2, axis: .k)
        }

        GL.popMatrix()
    }

    private func renderCubeletFace() {
        GL.renderColor = cubeColor

        GL.beginQuads()
        
        for vertex in cubeletFaceVertices {
            GL.addVertex(vertex)
        }

        GL.endShape()
    }

    private func renderCubeletEdge() {
        GL.renderColor = cubeColor

        GL.beginQuadStrip()
        
        for vertex in cubeletEdgeVertices {
            GL.addVertex(vertex)
        }

        GL.endShape()
    }

    private func renderCubeletCorner() {
        GL.renderColor = cubeColor

        for row in 0..<cubeletLevelOfDetail {
            GL.beginTriangleStrip()

            for col in 0...row {
                GL.addVertex(cubeletCornerVertices[(row + 1) * (row + 2) / 2 + col])
                GL.addVertex(cubeletCornerVertices[row * (row + 1) / 2 + col])
            }
            
            GL.addVertex(cubeletCornerVertices[(row + 1) * (row + 4) / 2])

            GL.endShape()
        }
    }

    private func renderSticker(color: Color) {
        GL.renderColor = color

        GL.beginPolygon()

        for vertex in stickerVertices {
            GL.addVertex(vertex)
        }

        GL.endShape()
    }
    
    private func renderSticker(at p: RubiksCube.Position) {
        let value = self.rubiksCube[position: p]
        let color = self.stickerColors[value]!
        
        self.renderSticker(color: color)
    }

    private func renderStickers(onFace face: RubiksCube.Face) {
        let cubeletLength = self.cubeletLength
        let n = rubiksCube.valuesPerSide

        for x in 0..<n {
            for y in 0..<n {
                let p = RubiksCube.Position(face: face, x: x, y: y)
                let value = self.rubiksCube[position: p]
                let color = self.stickerColors[value]!
                
                GL.pushMatrix()

                GL.translate(by: cubeletLength * Vector3(Double(x), Double(y), 0))
                self.renderSticker(color: color)
                
                GL.popMatrix()
            }
        }
    }

    private func bringOriginToNextFace() {
        let length = self.cubeLength

        // Apply a translation `A` along the x axis, followed by a
        // rotation `B` by 1/4 turn anticlockwise around the y axis, and
        // finally a reflection `C` in the plane x=y.
        //
        // Note that due to how OpenGL's matrix operations work, the
        // transformation matrices are multiplied in _reverse_ order,
        // i.e. `A * B * C` instead of `C * B * A`.
        
        let transform = Matrix4x4(
            0,  0, 1, length,
            1,  0, 0,      0,
            0, -1, 0,      0,
            0,  0, 0,      1
        )
        
        GL.multiplyMatrix(by: transform)
    }

    private func bringOriginToOppositeFace() {
        let length = self.cubeLength

        // Apply a translation to the opposite corner of the cube,
        // followed by a reflection in each of the x, y and z directions.
        
        let transform = Matrix4x4(
            -1,  0,  0,  length,
             0, -1,  0,  length,
             0,  0, -1, -length,
             0,  0,  0,       1
        )
        
        GL.multiplyMatrix(by: transform)
    }
    
    private func bringOriginToNextSide() {
        let length = self.cubeLength
        
        // Apply a translation by the cube's length in the x direction,
        // then a rotation by 1/4 turn anticlockwise around the z axis.
        
        let transform = Matrix4x4(
            0, -1, 0, length,
            1,  0, 0,      0,
            0,  0, 1,      0,
            0,  0, 0,      1
        )
        
        GL.multiplyMatrix(by: transform)
    }
    
    private func rotateOriginAroundCentralAxis(byAngle angle: Double) {
        let halfLength = self.cubeLength / 2
        
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

/// Find the unit vector perpendicular to the plane that the given Rubik's Cube face lies within,
/// with its sign adjusted to point from the cube's centre towards the face.
func direction(forFace face: RubiksCube.Face) -> Vector3<Double> {
    switch face {
        case 0:     return  .k
        case 1:     return  .i
        case 2:     return  .j
        case 3:     return -.k
        case 4:     return -.i
        case 5:     return -.j
        default:    fatalError("Unexpected face of Rubik's Cube")
    }
}