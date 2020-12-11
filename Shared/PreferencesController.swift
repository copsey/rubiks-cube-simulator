//
//  PreferencesController.swift
//
//  Created by Jack Copsey on 03/12/2020.
//

import Cocoa

class PreferencesController: NSObject {
    // Stored properties
    
    var backgroundColor: Color
    var cubeletLevelOfDetail: Int
    var stickerLevelOfDetail: Int
    
    var renderAsOutlines: Bool {
        didSet {
            // Update the user defaults.
            UserDefaults.standard.set(renderAsOutlines, forKey: "renderAsOutlines")
            
            // Update the main view.
            let view = mainViewController.view as! MainView
            view.polygonMode = self.polygonMode
        }
    }
    
    // Computed properties
    
    var polygonMode: GLenum {
        renderAsOutlines ? GL.PolygonMode.line : GL.PolygonMode.fill
    }
    
    // UI elements
    
    @IBOutlet weak var mainViewController: MainViewController!
    
    @IBOutlet weak var backgroundColorWell: NSColorWell!
    @IBOutlet weak var defaultBackgroundColorButton: NSButton!
    @IBOutlet weak var cubeletLevelOfDetailSlider: NSSlider!
    @IBOutlet weak var stickerLevelOfDetailSlider: NSSlider!
    @IBOutlet weak var renderAsOutlinesCheckbox: NSButton!
    
    // Initialization
    
    override init() {
        // Provide default values for the user preferences.
        
        let bgColor = MainView.defaultBackgroundColor
        
        let userDefaults: [String: Any] = [
            "backgroundColor": ["red": bgColor.red, "green": bgColor.green, "blue": bgColor.blue],
            "cubeletLevelOfDetail": 4,
            "stickerLevelOfDetail": 4,
            "renderAsOutlines": false
        ]
        
        UserDefaults.standard.register(defaults: userDefaults)
        
        // Load the user preferences.
        
        let backgroundColorAsDictionary = UserDefaults.standard.dictionary(forKey: "backgroundColor")!
        self.backgroundColor = Color(red: (backgroundColorAsDictionary["red"] ?? 0.0) as! Double,
                                    green: (backgroundColorAsDictionary["green"] ?? 0.0) as! Double,
                                    blue: (backgroundColorAsDictionary["blue"] ?? 0.0) as! Double)
        self.cubeletLevelOfDetail = UserDefaults.standard.integer(forKey: "cubeletLevelOfDetail")
        self.stickerLevelOfDetail = UserDefaults.standard.integer(forKey: "stickerLevelOfDetail")
        self.renderAsOutlines = UserDefaults.standard.bool(forKey: "renderAsOutlines")
        
        super.init()
    }
    
    override func awakeFromNib() {
        // Update the preferences window.
        
        backgroundColorWell.color = NSColor(red: CGFloat(backgroundColor.red),
                                            green: CGFloat(backgroundColor.green),
                                            blue: CGFloat(backgroundColor.blue),
                                            alpha: 1)
        cubeletLevelOfDetailSlider.integerValue = cubeletLevelOfDetail
        stickerLevelOfDetailSlider.integerValue = stickerLevelOfDetail
        renderAsOutlinesCheckbox.state = renderAsOutlines ? .on : .off
    }
    
    // User actions
    
    @IBAction func setBackgroundColor(_ sender: Any) {
        // Get the new color from the color well.
        let newColorAsNSColor = self.backgroundColorWell.color
        let newColor = Color(red: Double(newColorAsNSColor.redComponent),
                             green: Double(newColorAsNSColor.greenComponent),
                             blue: Double(newColorAsNSColor.blueComponent))
        
        // Update the user defaults.
        let backgroundColorAsDictionary = ["red": newColor.red, "green": newColor.green, "blue": newColor.blue]
        UserDefaults.standard.set(backgroundColorAsDictionary, forKey: "backgroundColor")
        
        // Update the main view.
        let view = self.mainViewController.view as! MainView
        view.backgroundColor = newColor
    }
    
    @IBAction func resetBackgroundColorToDefault(_ sender: Any) {
        // Get the default background color.
        let newColor = MainView.defaultBackgroundColor
        
        // Update the user defaults.
        let backgroundColorAsDictionary = ["red": newColor.red, "green": newColor.green, "blue": newColor.blue]
        UserDefaults.standard.set(backgroundColorAsDictionary, forKey: "backgroundColor")
        
        // Update the main view.
        let view = self.mainViewController.view as! MainView
        view.backgroundColor = newColor
        
        // Update the preferences window.
        let newColorAsNSColor = NSColor(red: CGFloat(newColor.red),
                                        green: CGFloat(newColor.green),
                                        blue: CGFloat(newColor.blue),
                                        alpha: 1)
        self.backgroundColorWell.color = newColorAsNSColor
    }
    
    @IBAction func setCubeletLevelOfDetail(_ sender: Any) {
        // Get the new level of detail from the slider.
        let newLevelOfDetail = self.cubeletLevelOfDetailSlider.integerValue
        
        // Update the user defaults.
        UserDefaults.standard.set(newLevelOfDetail, forKey: "cubeletLevelOfDetail")
        
        // Update the main view.
        let view = self.mainViewController.view as! MainView
        view.rubiksCubeRenderer.cubeletLevelOfDetail = newLevelOfDetail
        view.needsDisplay = true
    }
    
    @IBAction func setStickerLevelOfDetail(_ sender: Any) {
        // Get the new level of detail from the slider.
        let newLevelOfDetail = self.stickerLevelOfDetailSlider.integerValue
        
        // Update the user defaults.
        UserDefaults.standard.set(newLevelOfDetail, forKey: "stickerLevelOfDetail")
        
        // Update the view.
        let view = self.mainViewController.view as! MainView
        view.rubiksCubeRenderer.stickerLevelOfDetail = newLevelOfDetail
        view.needsDisplay = true
    }
    
    @IBAction func setRenderAsOutlines(_ sender: Any) {
        renderAsOutlines = (renderAsOutlinesCheckbox.state == .on)
    }
}
