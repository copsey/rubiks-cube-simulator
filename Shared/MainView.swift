//
//  MainView.swift
//  Decipher
//
//  Created by Jack Copsey on 25/11/2020.
//

import Cocoa
import OpenGL.GL

class MainView: NSOpenGLView {
    var rubiksCube: RubiksCube {
        get { self.rubiksCubeRenderer.rubiksCube }
        set { self.rubiksCubeRenderer.rubiksCube = newValue }
    }
    var rubiksCubeRenderer: RubiksCubeRenderer
    
    var backgroundColor = defaultBackgroundColor
    static let defaultBackgroundColor = Color(red: 0.545098, green: 0.792157, blue: 0.968627)
    
    var cubeDistance = defaultCubeDistance
    static let defaultCubeDistance = 0.275 // measured in m
    static let minCubeDistance = 0.18      // ... , can result in clipping for large cubes
    static let maxCubeDistance = 0.43      // ...
    
    var cubeOrientation = defaultCubeOrientation
    static let defaultCubeOrientation = Quaternion<Double>(0.326247, -0.200024, -0.482900, -0.787630)
    
    var cubeRotator: (Quaternion<Double>, Quaternion<Double>, Vector3<Double>, LinearAccelerator, Date)? = nil
    var layerRotator: (RubiksCube.Layer, LinearAccelerator, Date)? = nil
    
    required init?(coder: NSCoder) {
        // Display a solved 3x3 cube by default.
        let rubiksCube = makeSolvedRubiksCube(length: 3)
        self.rubiksCubeRenderer = RubiksCubeRenderer(rubiksCube: rubiksCube)
        
        super.init(coder: coder)
        
        // Set up a timer for animating the scene.
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { timer in
            self.animateScene(usingTimer: timer)
        }
    }
    
    override func prepareOpenGL() {
        glEnable(GLenum(GL_DEPTH_TEST))
//        glEnable(GLenum(GL_MULTISAMPLE))
//        glEnable(GLenum(GL_LIGHTING))
//        glEnable(GLenum(GL_LIGHT0))
//        glPolygonMode(GLenum(GL_FRONT_AND_BACK), GLenum(GL_LINE))
    }
    
    func updateViewport() {
        // Get the view's width and height in pixels.
        let frame = self.convertToBacking(self.frame)
        let viewWidth = GLsizei(frame.width)
        let viewHeight = GLsizei(frame.height)
        
        // Set the viewport.
        GL.setViewport(x: 0, y: 0, width: viewWidth, height: viewHeight)
    }
    
    func updatePerspective() {
        // Get the view's width and height in pixels.
        let viewFrame = self.convertToBacking(self.frame)
        let viewWidth = GLdouble(viewFrame.width)
        let viewHeight = GLdouble(viewFrame.height)
        
        // Find the largest square that will fit in the view, and choose the
        // frustum dimensions so that this square is preserved in the viewport.
        let viewBase = min(viewWidth, viewHeight)
        let frustumBase = 0.06 // measured in m
        let frustumWidth  = viewWidth * frustumBase/viewBase
        let frustumHeight = viewHeight * frustumBase/viewBase
        
        // Centre the square in the viewport.
        let left  = -frustumWidth/2
        let right =  frustumWidth/2
        let bottom = -frustumHeight/2
        let top    =  frustumHeight/2
        let near = 0.13 // measured in m, can result in clipping for large cubes
        let far  = 10.0 // any large number will do
        
        // Apply the frustum.
        GL.setFrustum(left: left, right: right, bottom: bottom, top: top, near: near, far: far)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Set the scene's viewport and perspective.
        self.updateViewport()
        self.updatePerspective()
        
        // Clear the buffers.
        GL.clearColor = self.backgroundColor
        GL.clear()
        
        // Bring the viewpoint to its correct position in the scene.
        GL.resetModelviewMatrix()
        let rotation = AxisAngle<GLdouble>(fromUnitQuaternion: self.cubeOrientation)
        
        GL.translate(x: 0, y: 0, z: -self.cubeDistance)
        GL.rotate(by: rotation)
        
        // Draw the cube.
        self.rubiksCubeRenderer.render()
        
        // Finish rendering the scene.
        GL.flush()
//        print("Scene rendered")
    }
    
    func setUpCubeRotation(toOrientation newOrientation: Quaternion<Double>) {
        // Complete any animation in progress.
        if let cubeRotator = self.cubeRotator {
            let endOrientation = cubeRotator.1
            
            self.cubeOrientation = endOrientation
            self.cubeRotator = nil
        }
        
        // Find the rotation needed to reach the new orientation, represented as a quaternion.
        let startOrientation = self.cubeOrientation
        let endOrientation = newOrientation.direction
        var rotationAsQuaternion = endOrientation * startOrientation.conjugate
        
        // Reverse the direction of rotation if this would reduce the total distance.
        if rotationAsQuaternion.real < 0 {
            rotationAsQuaternion.negate()
        }
        
        // Convert the rotation from quaternion form to axis-angle form.
        let rotationAsAxisAndAngle = AxisAngle(fromUnitQuaternion: rotationAsQuaternion)
        let axis = rotationAsAxisAndAngle.axis
        let angle = rotationAsAxisAndAngle.angle
        
        // Create an animation handler for the rotation.
        let maxSpeed = Double.pi
        let acceleration = Double.pi * 0.8
        let animator = LinearAccelerator(startPoint: 0, endPoint: angle, initialTime: 0,
                                         maxSpeed: maxSpeed, acceleration: acceleration)
        let timeNow = Date()
        
        self.cubeRotator = (startOrientation, endOrientation, axis, animator, timeNow)
    }
    
    func setUpCubeRotation(toFrontFace frontFace: RubiksCube.Face, topFace: RubiksCube.Face) {
        // It's an error if the faces are either the same or on opposite sides of the cube
        precondition(frontFace != topFace, "Front and top faces cannot be the same")
        precondition((frontFace + 3) % 6 != topFace, "Front and top faces cannot be opposite")
        
//        print("front face is \(frontFace), top face is \(topFace)")
        
        // Find the vectors pointing in the directions of what will become the front and top faces.
        // Note: the two vectors will be perpendicular.
        let frontFacingDirection = direction(forFace: frontFace)
        let topFacingDirection = direction(forFace: topFace)
        
        // Set the y direction to the top face, and the z direction to the front face.
        // Then rotate by 1/12 turn anticlockwise around the x axis, so that part of the
        // top face is visible.
        let sn: Double = sin(.pi/6)
        let cs: Double = cos(.pi/6)
        // TODO: Check that the transformation is correct. (There might be a bug in another
        // part of the code that means the signs in front of `sn` are the wrong way round.)
        let yDirection = cs * topFacingDirection - sn * frontFacingDirection
        let zDirection = sn * topFacingDirection + cs * frontFacingDirection
        
        // Set the x direction to the cross product of the two vectors.
        // This keeps the same orientation as the original (i,j,k) axes.
        let xDirection = yDirection.cross(zDirection)
        
//        print("i -> \(xDirection)")
//        print("j -> \(yDirection)")
//        print("k -> \(zDirection)")
        
        // Calculate the quaternion that represents this new orientation.
        let newOrientation = Quaternion(fromOrientation: (xDirection, yDirection, zDirection))
        
        // TODO: Investigate why conjugation is needed here.
        self.setUpCubeRotation(toOrientation: newOrientation.conjugate)
    }
    
    func finishCubeRotation() {
        if let cubeRotator = self.cubeRotator {
            let (_, endOrientation, _, _, _) = cubeRotator
            
            self.cubeOrientation = endOrientation
            self.cubeRotator = nil
        }
    }
    
    func setUpLayerRotation(layer: RubiksCube.Layer, turns: Int) {
        // Immediately apply the turns to the underlying Rubik's Cube.
        self.rubiksCube.turn(layer: layer, count: turns)
        
        // Graphically rotate the layer in the _opposite_ direction. This makes
        // it appear as though the Rubik's Cube has not been turned yet.
        let angle = Double(-turns) * .pi/2
        
        // The layer will now be animated to rotate back to its neutral position.
        // Create an animation handler for this.
        let maxSpeed = Double.pi * 0.9
        let acceleration = Double.pi * 3.1
        let animator = LinearAccelerator(startPoint: angle, endPoint: 0, initialTime: 0,
                                         maxSpeed: maxSpeed, acceleration: acceleration)
        let timeNow = Date()
        
        self.layerRotator = (layer, animator, timeNow)
    }
    
    func finishLayerRotation() {
        self.rubiksCubeRenderer.rotatedLayerAndAngle = nil
        self.layerRotator = nil
    }
    
    func animateScene(usingTimer timer: Timer) {
        if let cubeRotator = self.cubeRotator {
            self.needsDisplay = true
            
            let (startOrientation, _, axis, animator, startDate) = cubeRotator
            
            // Calculate what the cube's orientation will be when the scene is rendered.
            let time = timer.fireDate.timeIntervalSince(startDate)
            let angle = animator.position(atTime: time)
            
            // Check if the animation has completed
            let animationHasFinished = (angle == animator.endPoint)
            if animationHasFinished {
                self.finishCubeRotation()
            } else {
                let axisAndAngle = AxisAngle<Double>(axis: axis, angle: angle)
                let rotation = Quaternion<Double>(fromRotation: axisAndAngle)
                let currentOrientation = rotation * startOrientation
                self.cubeOrientation = currentOrientation
            }
        }
        
        if let layerRotator = self.layerRotator {
            self.needsDisplay = true
            
            let (layer, animator, startDate) = layerRotator
            
            // Calculate what angle the layer will be at when the scene is rendered.
            let time = timer.fireDate.timeIntervalSince(startDate)
            let angle = animator.position(atTime: time)
            
//            print("Angle is \(angle)")
            
            // Update the cube renderer, completing the animation if applicable.
            let animationHasFinished = (angle == animator.endPoint)
            if animationHasFinished {
                self.finishLayerRotation()
            } else {
                self.rubiksCubeRenderer.rotatedLayerAndAngle = (layer, angle)
            }
        }
    }
}