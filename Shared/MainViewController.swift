//
//  MainViewController.swift
//  Decipher
//
//  Created by Jack Copsey on 25/11/2020.
//

import Cocoa

class MainViewController: NSViewController {
    @IBOutlet weak var controlPanelController: ControlPanelController!
    @IBOutlet weak var preferencesController: PreferencesController!
    
    override func awakeFromNib() {
        let view = self.view as! MainView
        
        // Update the main view.
        
        view.backgroundColor = preferencesController.backgroundColor
        view.rubiksCubeRenderer.cubeletLevelOfDetail = preferencesController.cubeletLevelOfDetail
        view.rubiksCubeRenderer.stickerLevelOfDetail = preferencesController.stickerLevelOfDetail
        
        // Bring the main window to the front.
        
        view.window!.makeKeyAndOrderFront(nil)
    }
    
    override func mouseDown(with event: NSEvent) {
        // Convert the mouse coordinates from points to pixels.
        
        let locationInPoints = event.locationInWindow
        let locationInPixels = self.view.convertToBacking(locationInPoints)
        
        // Then convert to coordinates within the scene.
        
        let view = self.view as! MainView
        view.openGLContext?.makeCurrentContext()
        
        let viewX = round(locationInPixels.x)
        let viewY = round(locationInPixels.y)
        let viewZ = GL.readDepthComponent(x: GLint(viewX), y: GLint(viewY))
        
        let viewLocation = Vector3(GLdouble(viewX), GLdouble(viewY), GLdouble(viewZ))
        let sceneLocation = GL.unproject(viewLocation)
        
//        print("", "Click detected!", "View location is \(viewLocation)", "Scene location is \(sceneLocation)",
//              separator: "\n",
//              terminator: "\n")
        
        // Clear the selected position if the mouse wasn't clicked on the cube.
        
        let boundary = view.rubiksCubeRenderer.cubeLength * 0.51
        if abs(sceneLocation.x) > boundary || abs(sceneLocation.y) > boundary || abs(sceneLocation.z) > boundary {
            controlPanelController.selectedPosition = nil
//            print("Cleared the selected position")
            
            return
        }

        // Determine the face that was clicked on, by maximising the dot product between the
        // location in the scene and the direction for that face.
        
        let selectedFace = RubiksCube.Face.allCases.max() { face1, face2 in
            sceneLocation.dot(face1.direction) < sceneLocation.dot(face2.direction)
        }!
        
        // Determine the mouse coordinates relative to the face.
        
        let sceneX = sceneLocation.x
        let sceneY = sceneLocation.y
        let sceneZ = sceneLocation.z
        
        let dirX = selectedFace.direction.x // either 0, +1 or -1
        let dirY = selectedFace.direction.y // ...
        let dirZ = selectedFace.direction.z // ...
        
        // Note: this expression was worked out with pen and paper, by writing down
        // what the (x,y) coordinates need to be for each direction. There's no clever
        // maths going on here as far as I'm aware, e.g. no nice cross product.
        let faceX = sceneX *  dirZ + sceneY * dirX + sceneZ * -dirY
        let faceY = sceneX * -dirY + sceneY * dirZ + sceneZ * -dirX
        
        // Determine the exact position on the cube.
        
        let halfLength = view.rubiksCubeRenderer.cubeLength / 2
        let cubeletLength = view.rubiksCubeRenderer.cubeletLength
        
        let selectedPosition = RubiksCube.Position(face: selectedFace,
                                                   x: Int(floor((faceX + halfLength) / cubeletLength)),
                                                   y: Int(floor((faceY + halfLength) / cubeletLength)))

        controlPanelController.selectedPosition = selectedPosition
//        print("Set the selected position to \(selectedPosition)")
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        let view = self.view as! MainView
        
        // Don't allow the cube to be manually rotated when it's being animated.
        if view.cubeRotator != nil { return }
        
        // Find out how far the mouse has been dragged.
        let deltaX = Double(event.deltaX)
        let deltaY = Double(-event.deltaY) // invert deltaY, due to a "bug" in the rightMouseDragged event
        let magnitude = hypot(deltaX, deltaY)
        
        // Calculate the axis to rotate the cube around, which is `delta` normalised
        // and rotated by a 1/4 turn anticlockwise around the z axis.
        let axis = Vector3(-deltaY, deltaX, 0) / magnitude
        if !axis.isFinite { return } // guard against small values of `delta`
        
        // Calculate the angle to rotate the cube by.
        let dragFactor = 0.00785 // factor chosen to give a "nice feel" when using the app
        let angle = magnitude * dragFactor
        
        // Apply the rotation to the cube.
        let rotationAsAxisAndAngle = AxisAngle(axis: axis, angle: angle)
        let rotationAsQuaternion = Quaternion(fromRotation: rotationAsAxisAndAngle)
        let newOrientation = (rotationAsQuaternion * view.cubeOrientation).direction
        view.cubeOrientation = newOrientation
    }
    
    override func scrollWheel(with event: NSEvent) {
        let scrollAmount = Double(event.scrollingDeltaY)
        let scrollFactor = 0.002 // factor chosen to give a "nice feel" when using the app
        
        let view = self.view as! MainView
        view.cubeDistance -= scrollAmount * scrollFactor
    }
}
