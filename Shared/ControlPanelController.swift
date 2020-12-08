//
//  ControlPanelController.swift
//  RubiksCubeSimulator
//
//  Created by Jack Copsey on 04/12/2020.
//

import Cocoa

class ControlPanelController: NSObject {
    // Stored properties
    
    var selectedPosition: RubiksCube.Position? = nil {
        didSet {
            _updateValueAtSelectedPositionDropdown()
            _updateSelectedPositionText()
        }
    }
    
    // Computed properties
    
    var faceToRotate: RubiksCube.Face? {
        if let tag = faceToRotateDropdown.selectedItem?.tag {
            let face = RubiksCube.Face(rawValue: tag)
            assert(face != nil, "Could not determine face to rotate from user selection")
            return face!
        }
        return nil
    }
    
    var depthToRotateAt: Int? {
        depthToRotateAtDropdown.selectedItem?.tag
    }
    
    var numberOfTurns: Int? {
        Int(numberOfTurnsTextField.stringValue)
    }
    
    var frontFace: RubiksCube.Face? {
        if let tag = frontFaceDropdown.selectedItem?.tag {
            let face = RubiksCube.Face(rawValue: tag)
            assert(face != nil, "Could not determine front face from user selection")
            return face!
        }
        return nil
    }
    
    var topFace: RubiksCube.Face? {
        if let tag = topFaceDropdown.selectedItem?.tag {
            let face = RubiksCube.Face(rawValue: tag)
            assert(face != nil, "Could not determine top face from user selection")
            return face!
        }
        return nil
    }
    
    var valueAtSelectedPosition: RubiksCube.Value? {
        valueAtSelectedPositionDropdown.selectedItem?.tag
    }
    
    var cubeSize: Int? {
        cubeSizeDropdown.selectedItem?.tag
    }
    
    // User interface
    
    @IBOutlet weak var mainViewController: MainViewController!
    
    @IBOutlet weak var faceToRotateDropdown: NSPopUpButton!
    @IBOutlet weak var depthToRotateAtDropdown: NSPopUpButton!
    @IBOutlet weak var numberOfTurnsTextField: NSTextField!
    @IBOutlet weak var rotateButton: NSButton!
    
    @IBOutlet weak var frontFaceDropdown: NSPopUpButton!
    @IBOutlet weak var topFaceDropdown: NSPopUpButton!
    @IBOutlet weak var orientButton: NSButton!
    
    @IBOutlet weak var selectedPositionText: NSTextField!
    @IBOutlet weak var valueAtSelectedPositionDropdown: NSPopUpButton!
    @IBOutlet weak var valueAtSelectedPositionDropdownLabel: NSTextField!
    
    @IBOutlet weak var cubeSizeDropdown: NSPopUpButton!
    
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!
    @IBOutlet weak var scrambleButton: NSButton!
    
    // Intialization
    
    override func awakeFromNib() {
        // Initialize the elements in the control panel.
        
        _updateSelectedPositionText()
        _updateValueAtSelectedPositionDropdown()
        _updateCubeSizeDropdown()
    }
    
    // User Actions
    
    @IBAction func rotateLayerOfRubiksCube(_ sender: Any) {
        let mainView = mainViewController.view as! MainView
        
        // Access properties from the user interface.
        let faceToRotate = self.faceToRotate!
        let depthToRotateAt = self.depthToRotateAt!
        let layer = RubiksCube.Layer(face: faceToRotate, depth: depthToRotateAt)
        let numberOfTurns = self.numberOfTurns!
        
        // If the face is odd, reverse the direction of rotation. This is needed because the
        // cube's frame of reference is reflected on each successive face.
        let numberOfTurnsAfterReflection: Int
        if faceToRotate.rawValue % 2 == 0 {
            numberOfTurnsAfterReflection = numberOfTurns
        } else {
            numberOfTurnsAfterReflection = -numberOfTurns
        }
        
        // Apply the rotation.
        mainView.setUpLayerRotation(layer: layer, turns: numberOfTurnsAfterReflection)
    }
    
    @IBAction func chooseFrontFace(_ sender: Any) {
        _updateTopFaceDropdown()
        _updateOrientButton()
    }
    
    @IBAction func chooseTopFace(_ sender: Any) {
        _updateOrientButton()
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
            
            if frontFace.isOpposite(to: topFace) {
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Make sure the front and top faces are adjacent before trying to orient the Rubik's cube."
                alert.runModal()
                
                return
            }
            
            // Apply the orientation.
            
            let mainView = mainViewController.view as! MainView
            mainView.setUpCubeRotation(toFrontFace: frontFace, topFace: topFace)
        }
    }
    
    private func _updateOrientButton() {
        let topFaceIsSelected = self.topFace != nil
        let frontFaceIsSelected = self.frontFace != nil
        orientButton.isEnabled = topFaceIsSelected && frontFaceIsSelected
    }
    
    @IBAction func selectValueAtSelectedPosition(_ sender: Any) {
        if let selectedPosition = self.selectedPosition, let valueAtSelectedPosition = self.valueAtSelectedPosition {
            let mainView = mainViewController.view as! MainView
            mainView.rubiksCube[selectedPosition] = valueAtSelectedPosition
            mainView.needsDisplay = true
        }
    }
    
    /// Update the text displayed in the selected sticker label.
    private func _updateSelectedPositionText() {
        let description: String
        
        if let selectedPosition = self.selectedPosition {
            let faceAsRawValue = selectedPosition.face.rawValue
            let x = selectedPosition.x
            let y = selectedPosition.y
            
            description = "Selected sticker: (\(faceAsRawValue + 1),\(x + 1),\(y + 1))"
        } else {
            description = "No sticker is selected.\nClick on the cube to select one."
        }
        
        selectedPositionText.stringValue = description
    }
    
    /// Update the selected item in the sticker colour dropdown, or hide the menu if appropriate.
    private func _updateValueAtSelectedPositionDropdown() {
        if let selectedPosition = self.selectedPosition {
            let mainView = mainViewController.view as! MainView
            let valueAtSelectedPosition = mainView.rubiksCube[selectedPosition]

            if valueAtSelectedPosition >= 0 && valueAtSelectedPosition < 6 {
                valueAtSelectedPositionDropdown.selectItem(withTag: valueAtSelectedPosition)
            } else {
                valueAtSelectedPositionDropdown.select(nil)
            }

            valueAtSelectedPositionDropdownLabel.isHidden = false
            valueAtSelectedPositionDropdown.isHidden = false
        } else {
            valueAtSelectedPositionDropdownLabel.isHidden = true
            valueAtSelectedPositionDropdown.isHidden = true
        }
    }
    
    private func _updateTopFaceDropdown() {
        let frontFace = self.frontFace
        
        // Hide all items in the top face dropdown that aren't adjacent to the front face.
        for item in topFaceDropdown.itemArray {
            let face = RubiksCube.Face(rawValue: item.tag)!
            item.isHidden = (frontFace == nil || face == frontFace! || face.opposite == frontFace!)
        }
        
        // Deselect the top face if it's a hidden item.
        if topFaceDropdown.selectedItem?.isHidden ?? false {
            topFaceDropdown.select(nil)
        }
    }
    
    @IBAction func changeSizeOfRubiksCube(_ sender: Any) {
        if let newSize = self.cubeSize {
            let mainView = mainViewController.view as! MainView
            
            if newSize != mainView.rubiksCube.size {
                // Update the main view.
                mainView.replaceRubiksCube(with: .solvedRubiksCube(size: newSize))
                
                // Update the control panel.
                selectedPosition = nil
                _updateDepthToRotateAtDropdown()
            }
        }
    }
    
    /// Update the selected item in the cube size dropdown.
    private func _updateCubeSizeDropdown() {
        let mainView = mainViewController.view as! MainView
        cubeSizeDropdown.selectItem(withTag: mainView.rubiksCube.size)
    }
    
    /// Change the options available in the depth dropdown.
    private func _updateDepthToRotateAtDropdown() {
        let mainView = mainViewController.view as! MainView
        let cubeSize = mainView.rubiksCube.size
        
        while depthToRotateAtDropdown.numberOfItems > cubeSize {
            let lastIndex = depthToRotateAtDropdown.numberOfItems - 1
            depthToRotateAtDropdown.removeItem(at: lastIndex)
        }
        
        while (depthToRotateAtDropdown.numberOfItems < cubeSize) {
            let newDepth = depthToRotateAtDropdown.numberOfItems
            
            depthToRotateAtDropdown.addItem(withTitle: "\(newDepth + 1)")
            let newItem = depthToRotateAtDropdown.lastItem!
            newItem.tag = newDepth
        }
    }
    
    @IBAction func resetRubiksCube(_ sender: Any) {
        let mainView = mainViewController.view as! MainView
        mainView.replaceRubiksCube(with: .solvedRubiksCube(size: mainView.rubiksCube.size))
    }
    
    @IBAction func clearRubiksCube(_ sender: Any) {
        let mainView = mainViewController.view as! MainView
        mainView.replaceRubiksCube(with: .blankRubiksCube(size: mainView.rubiksCube.size))
    }
    
    @IBAction func scrambleRubiksCube(_ sender: Any) {
        let mainView = mainViewController.view as! MainView
        mainView.finishLayerRotation()
        mainView.rubiksCube.scramble()
        mainView.needsDisplay = true
    }
}
