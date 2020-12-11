//
//  MainView.swift
//
//  Created by Jack Copsey on 25/11/2020.
//

import Cocoa
import OpenGL.GL

class MainView: NSOpenGLView {
    var rubiksCube: RubiksCube { rubiksCubeRenderer.rubiksCube }
    var rubiksCubeRenderer: RubiksCubeRenderer
    
    var polygonMode = GL.PolygonMode.fill {
        didSet {
            self.needsDisplay = true
        }
    }
    
    var backgroundColor = defaultBackgroundColor {
        didSet {
            self.needsDisplay = true
        }
    }
    static let defaultBackgroundColor = Color(red: 0.545098, green: 0.792157, blue: 0.968627)
    
    var cubeDistance = defaultCubeDistance {
        didSet {
            self.needsDisplay = true
        }
    }
    static let defaultCubeDistance = 0.275 // measured in m
    static let minCubeDistance = 0.18      // ... , can result in clipping for large cubes
    static let maxCubeDistance = 0.43      // ...
    
    var cubeOrientation = defaultCubeOrientation {
        didSet {
            self.needsDisplay = true
        }
    }
    static let defaultCubeOrientation = Quaternion<Double>(0.326247, -0.200024, -0.482900, -0.787630)
    
    var cubeRotator: (startOrientation: Quaternion<Double>, endOrientation: Quaternion<Double>, axis: Vector3<Double>,
                      animator: LinearAccelerator, startDate: Date)? = nil
    var layerRotator: (layer: RubiksCube.Layer, animator: LinearAccelerator, startDate: Date)? = nil
    
    required init?(coder: NSCoder) {
        // Display a solved 3x3 cube by default.
        rubiksCubeRenderer = RubiksCubeRenderer(rubiksCube: .solvedRubiksCube(size: 3))
        
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
    }
    
    func replaceRubiksCube(with newRubiksCube: RubiksCube) {
        finishLayerRotation()
        rubiksCubeRenderer.rubiksCube = newRubiksCube
        self.needsDisplay = true
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
        
        // Set the polygon mode.
        GL.setPolygonMode(polygonMode)
        
        // Set the scene's viewport and perspective.
        updateViewport()
        updatePerspective()
        
        // Clear the buffers.
        GL.clearColor = backgroundColor
        GL.clear()
        
        // Bring the viewpoint to its correct position in the scene.
        let rotation = AxisAngle<GLdouble>(fromUnitQuaternion: cubeOrientation)
        GL.resetMatrix()
        GL.translate(x: 0, y: 0, z: -cubeDistance)
        GL.rotate(by: rotation)
        
        // Draw the cube.
        rubiksCubeRenderer.render()
        
        // Finish rendering the scene.
        GL.flush()
//        print("Scene rendered")
    }
    
    func setUpCubeRotation(toOrientation newOrientation: Quaternion<Double>) {
        // Complete any animation in progress.
        finishCubeRotation()
        
        // Find the rotation needed to reach the new orientation, represented by a quaternion.
        let startOrientation = cubeOrientation
        let endOrientation = newOrientation.direction
        var rotationAsQuaternion = endOrientation * startOrientation.conjugated
        
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
        
        cubeRotator = (startOrientation, endOrientation, axis, animator, timeNow)
    }
    
    func setUpCubeRotation(toFrontFace frontFace: RubiksCube.Face, topFace: RubiksCube.Face) {
        // It's an error if the faces are either the same or on opposite sides of the cube
        precondition(frontFace != topFace, "Front and top faces cannot be the same")
        precondition(!frontFace.isOpposite(to: topFace), "Front and top faces cannot be opposite")
        
//        print("front face is \(frontFace), top face is \(topFace)")
        
        // Set the y direction to point at the top face, and the z direction to point at the front face.
        // Then rotate by 1/12 turn anticlockwise around the x axis, so that part of the top face is visible.
        let sn: Double = sin(.pi/6)
        let cs: Double = cos(.pi/6)
        // TODO: Check that the transformation is correct. (There might be a bug in another
        // part of the code that means the signs in front of `sn` are the wrong way round.)
        let yDirection = cs * topFace.direction - sn * frontFace.direction
        let zDirection = sn * topFace.direction + cs * frontFace.direction
        
        // Set the x direction to the cross product of the two vectors.
        // This keeps the same orientation as the original (i,j,k) axes.
        let xDirection = yDirection.cross(zDirection)
        
//        print("i -> \(xDirection)")
//        print("j -> \(yDirection)")
//        print("k -> \(zDirection)")
        
        // Calculate the quaternion that represents this new orientation.
        let newOrientation = Quaternion(fromOrientation: (xDirection, yDirection, zDirection))
        
        // TODO: Investigate why conjugation is needed here.
        setUpCubeRotation(toOrientation: newOrientation.conjugated)
    }
    
    func finishCubeRotation() {
        if let cubeRotator = self.cubeRotator {
            cubeOrientation = cubeRotator.endOrientation
            self.cubeRotator = nil
        }
    }
    
    func setUpLayerRotation(layer: RubiksCube.Layer, turns: Int) {
        // Immediately apply the turns to the underlying Rubik's Cube.
        rubiksCube.turn(layer: layer, count: turns)
        
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
        
        layerRotator = (layer, animator, timeNow)
    }
    
    func finishLayerRotation() {
        layerRotator = nil
        rubiksCubeRenderer.rotatedLayerAndAngle = nil
        self.needsDisplay = true
    }
    
    func animateScene(usingTimer timer: Timer) {
        if let cubeRotator = self.cubeRotator {
            let time = timer.fireDate.timeIntervalSince(cubeRotator.startDate)
            
            if cubeRotator.animator.hasFinished(at: time) {
                finishCubeRotation()
            } else {
                let angle = cubeRotator.animator.position(at: time)
                let axisAndAngle = AxisAngle<Double>(axis: cubeRotator.axis, angle: angle)
                let rotation = Quaternion<Double>(fromRotation: axisAndAngle)
                cubeOrientation = rotation * cubeRotator.startOrientation
            }
        }
        
        if let layerRotator = self.layerRotator {
            let time = timer.fireDate.timeIntervalSince(layerRotator.startDate)
            
            if layerRotator.animator.hasFinished(at: time) {
                finishLayerRotation()
            } else {
                let angle = layerRotator.animator.position(at: time)
//                print("Layer angle is \(angle)")
                rubiksCubeRenderer.rotatedLayerAndAngle = (layerRotator.layer, angle)
                self.needsDisplay = true
            }
        }
    }
}
