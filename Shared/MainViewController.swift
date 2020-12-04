//
//  MainViewController.swift
//  Decipher
//
//  Created by Jack Copsey on 25/11/2020.
//

import Cocoa

class MainViewController: NSViewController {
    // Stored properties
    
    var selectedPosition: RubiksCube.Position? = nil {
        didSet {
            self.updateStickerColorDropdown()
            self.updateSelectedStickerLabel()
        }
    }
    
    // Computed properties
    
    var frontFace: RubiksCube.Face? { self.frontFaceDropdown.selectedItem?.tag }
    var topFace: RubiksCube.Face? { self.topFaceDropdown.selectedItem?.tag }
    
    // UI elements
    
    @IBOutlet weak var preferencesController: PreferencesController!
    
    @IBOutlet weak var faceToRotateDropdown: NSPopUpButton!
    @IBOutlet weak var depthToRotateAtDropdown: NSPopUpButton!
    @IBOutlet weak var numberOfTurnsTextField: NSTextField!
    @IBOutlet weak var rotateButton: NSButton!
    
    @IBOutlet weak var frontFaceDropdown: NSPopUpButton!
    @IBOutlet weak var topFaceDropdown: NSPopUpButton!
    @IBOutlet weak var orientButton: NSButton!
    
    @IBOutlet weak var selectedPositionLabel: NSTextField!
    @IBOutlet weak var stickerColorLabel: NSTextField!
    @IBOutlet weak var stickerColorDropdown: NSPopUpButton!
    
    @IBOutlet weak var cubeLengthDropdown: NSPopUpButton!
    
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!
    @IBOutlet weak var scrambleButton: NSButton!
    
    // Initialization
    
    override func awakeFromNib() {
        let view = self.view as! MainView
        
        // Update the main view.
        
        view.backgroundColor = self.preferencesController.backgroundColor
        view.rubiksCubeRenderer.cubeletLevelOfDetail = self.preferencesController.cubeletLevelOfDetail
        view.rubiksCubeRenderer.stickerLevelOfDetail = self.preferencesController.stickerLevelOfDetail
        
        // Update the control panel.
        
        self.updateSelectedStickerLabel()
        self.updateStickerColorDropdown()
        self.updateCubeLengthDropdown()
        
        // Bring the main window to the front.
        
        view.window?.makeKeyAndOrderFront(nil)
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
            self.selectedPosition = nil
//            print("Cleared the selected position")
            
            return
        }

        // Determine the face that was clicked on, by maximising the dot product between the
        // location in the scene and the direction for that face.
        
        let selectedFace = (0..<6).max() {
            let u = direction(forFace: $0)
            let v = direction(forFace: $1)
            return sceneLocation.dot(u) < sceneLocation.dot(v)
        }!
        
        // Determine the mouse coordinates relative to the face.
        
        let sceneX = sceneLocation.x
        let sceneY = sceneLocation.y
        let sceneZ = sceneLocation.z
        
        let directionForSelectedFace = direction(forFace: selectedFace)
        let dirX = directionForSelectedFace.x // either 0, +1 or -1
        let dirY = directionForSelectedFace.y // ...
        let dirZ = directionForSelectedFace.z // ...
        
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

        self.selectedPosition = selectedPosition
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
        
        // Render the scene again.
        view.needsDisplay = true
    }
    
    override func scrollWheel(with event: NSEvent) {
        let view = self.view as! MainView
        
        // Move the cube closer to or further from the viewpoint, depending on
        // the scroll direction.
        let scrollAmount = Double(event.scrollingDeltaY)
        let scrollFactor = 0.002 // factor chosen to give a "nice feel" when using the app
        view.cubeDistance -= scrollAmount * scrollFactor
        
        view.needsDisplay = true
    }
    
    @IBAction func rotateLayerOfRubiksCube(_ sender: Any) {
        let view = self.view as! MainView
        
        // Access properties from the user interface.
        let face = faceToRotateDropdown.selectedItem!.tag
        let depth = depthToRotateAtDropdown.selectedItem!.tag
        let layer = RubiksCube.Layer(face: face, depth: depth)
        let numberOfTurnsExcludingReflection = numberOfTurnsTextField.integerValue
        
        // If the face is odd, reverse the direction of rotation. This is needed because the cube's frame
        // of reference is reflected on each successive face.
        let numberOfTurns: Int
        if face % 2 == 0 {
            numberOfTurns = numberOfTurnsExcludingReflection
        } else {
            numberOfTurns = -numberOfTurnsExcludingReflection
        }
        
        // Apply the rotation.
        view.setUpLayerRotation(layer: layer, turns: numberOfTurns)
    }
    
    @IBAction func chooseFrontFace(_ sender: Any) {
        let frontFace = self.frontFace
        
        // Hide all items in the top face dropdown that aren't adjacent to the front face.
        let topFaceItems = self.topFaceDropdown?.itemArray ?? []
        for item in topFaceItems {
            let face = item.tag
            item.isHidden = (frontFace == nil || face == frontFace! || (face + 3) % 6 == frontFace!)
        }
        
        // Deselect the top face if it's a hidden item.
        if self.topFaceDropdown?.selectedItem?.isHidden ?? false {
            self.topFaceDropdown.select(nil)
        }
        
        // Update the orient button.
        self.updateOrientButton()
    }
    
    @IBAction func chooseTopFace(_ sender: Any) {
        // Update the orient button.
        self.updateOrientButton()
    }
    
    @IBAction func orientRubiksCube(_ sender: Any) {
        if let frontFace = self.frontFace, let topFace = self.topFace {
            // Make sure the two faces are adjacent.
            
            if frontFace == topFace {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Make sure the front and top faces are different before trying to orient the Rubik's Cube."
                alert.runModal()
                
                return
            }
            
            if (frontFace + 3) % 6 == topFace {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Make sure the front and top faces are adjacent before trying to orient the Rubik's cube."
                alert.runModal()
                
                return
            }
            
            // Apply the orientation.
            
            let view = self.view as! MainView
            view.setUpCubeRotation(toFrontFace: frontFace, topFace: topFace)
        }
    }
    
    func updateOrientButton() {
        let topFaceSelected = self.topFaceDropdown?.selectedItem != nil
        let frontFaceSelected = self.frontFaceDropdown?.selectedItem != nil
        let shouldEnable = topFaceSelected && frontFaceSelected
        
        self.orientButton?.isEnabled = shouldEnable
    }
    
    @IBAction func updateStickerColorOfRubiksCube(_ sender: Any) {
        let view = self.view as! MainView
        
        if let selectedPosition = self.selectedPosition {
            let value = self.stickerColorDropdown.indexOfSelectedItem
            view.rubiksCube[selectedPosition] = value
            
            view.needsDisplay = true
        }
    }
    
    /// Update the text displayed in the selected sticker label.
    func updateSelectedStickerLabel() {
        let description: String
        
        if let selectedPosition = self.selectedPosition {
            let face = selectedPosition.face + 1
            let x = selectedPosition.x + 1
            let y = selectedPosition.y + 1
            
            description = "Selected sticker: (\(face),\(x),\(y))"
        } else {
            description = "No sticker is selected.\nClick on the cube to select one."
        }
        
        self.selectedPositionLabel?.stringValue = description
    }
    
    /// Update the selected item in the sticker colour dropdown, or hide the menu if appropriate.
    func updateStickerColorDropdown() {
        let view = self.view as! MainView
        
        if let selectedPosition = self.selectedPosition {
            let valueAtSelectedPosition = view.rubiksCube[selectedPosition]

            if valueAtSelectedPosition >= 0 && valueAtSelectedPosition < 6 {
                self.stickerColorDropdown?.selectItem(at: valueAtSelectedPosition)
            } else {
                self.stickerColorDropdown?.select(nil)
            }

            self.stickerColorLabel?.isHidden = false
            self.stickerColorDropdown?.isHidden = false
        } else {
            self.stickerColorLabel?.isHidden = true
            self.stickerColorDropdown?.isHidden = true
        }
    }
    
    @IBAction func changeLengthOfRubiksCube(_ sender: Any) {
        let view = self.view as! MainView
        
        if let selectedItem = self.cubeLengthDropdown.selectedItem {
            // End any layer animation in progress.
            view.finishLayerRotation()
            
            // Clear the selected position.
            self.selectedPosition = nil
            
            // Change the length of the cube.
            let newSize = selectedItem.tag
            view.rubiksCube = .solvedRubiksCube(size: newSize)
            
            // Change the options available in the depth dropdown.
            while depthToRotateAtDropdown.numberOfItems > newSize {
                let lastIndex = depthToRotateAtDropdown.numberOfItems - 1
                depthToRotateAtDropdown.removeItem(at: lastIndex)
            }
            while (depthToRotateAtDropdown.numberOfItems < newSize) {
                let newDepth = depthToRotateAtDropdown.numberOfItems
                
                depthToRotateAtDropdown.addItem(withTitle: String(newDepth + 1))
                let newItem = depthToRotateAtDropdown.lastItem!
                newItem.tag = newDepth
            }
            
            view.needsDisplay = true
        }
    }
    
    /// Update the selected item in the cube size dropdown.
    func updateCubeLengthDropdown() {
        let view = self.view as! MainView
        
        let rubiksCubeSize = view.rubiksCube.size
        self.cubeLengthDropdown?.selectItem(withTag: rubiksCubeSize)
    }
    
    @IBAction func resetRubiksCube(_ sender: Any) {
        let view = self.view as! MainView
        
        // End any layer animation in progress.
        view.finishLayerRotation()
        
        // Reset the cube.
        let rubiksCubeSize = view.rubiksCube.size
        view.rubiksCube = .solvedRubiksCube(size: rubiksCubeSize)
        
        // Update the view.
        view.needsDisplay = true
    }
    
    @IBAction func clearRubiksCube(_ sender: Any) {
        let view = self.view as! MainView
        
        // End any layer animation in progress.
        view.finishLayerRotation()
        
        // Set all values on the cube to -1.
        view.rubiksCube.fill(-1)
        
        // Update the view.
        view.needsDisplay = true
    }
    
    @IBAction func scrambleRubiksCube(_ sender: Any) {
        let view = self.view as! MainView
        
        // End any layer animation in progress.
        view.finishLayerRotation()
        
        // Scramble the cube.
        view.rubiksCube.scramble()
        
        // Update the view.
        view.needsDisplay = true
    }
}
