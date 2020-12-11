//
//  PreferencesController.swift
//
//  Created by Jack Copsey on 03/12/2020.
//

import Cocoa

class PreferencesController: NSObject {
    @IBOutlet weak var mainViewController: MainViewController!
    
    var backgroundColor: Color {
        didSet {
            // Update the user defaults.
            let backgroundColorAsDictionary = ["red": backgroundColor.red,
                                               "green": backgroundColor.green,
                                               "blue": backgroundColor.blue]
            UserDefaults.standard.set(backgroundColorAsDictionary, forKey: "backgroundColor")
            
            // Update the main view.
            let view = self.mainViewController.view as! MainView
            view.backgroundColor = self.backgroundColor
        }
    }
    
    @IBOutlet weak var backgroundColorWell: NSColorWell!
    
    var cubeletLevelOfDetail: Int {
        didSet {
            // Update the user defaults.
            UserDefaults.standard.set(cubeletLevelOfDetail, forKey: "cubeletLevelOfDetail")
            
            // Update the main view.
            let view = self.mainViewController.view as! MainView
            view.rubiksCubeRenderer.cubeletLevelOfDetail = self.cubeletLevelOfDetail
            view.needsDisplay = true
        }
    }
    
    @IBOutlet weak var cubeletLevelOfDetailSlider: NSSlider!
    
    var stickerLevelOfDetail: Int {
        didSet {
            // Update the user defaults.
            UserDefaults.standard.set(stickerLevelOfDetail, forKey: "stickerLevelOfDetail")
            
            // Update the main view.
            let view = self.mainViewController.view as! MainView
            view.rubiksCubeRenderer.stickerLevelOfDetail = self.stickerLevelOfDetail
            view.needsDisplay = true
        }
    }
    
    @IBOutlet weak var stickerLevelOfDetailSlider: NSSlider!
    
    var renderAsOutlines: Bool {
        didSet {
            // Update the user defaults.
            UserDefaults.standard.set(renderAsOutlines, forKey: "renderAsOutlines")
            
            // Update the main view.
            let view = mainViewController.view as! MainView
            view.polygonMode = self.polygonMode
        }
    }
    
    @IBOutlet weak var renderAsOutlinesCheckbox: NSButton!
    
    var polygonMode: GLenum {
        renderAsOutlines ? GL.PolygonMode.line : GL.PolygonMode.fill
    }
    
    // MARK:- Initialization
    
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
        backgroundColor = Color(red: (backgroundColorAsDictionary["red"] ?? 0.0) as! Double,
                                green: (backgroundColorAsDictionary["green"] ?? 0.0) as! Double,
                                blue: (backgroundColorAsDictionary["blue"] ?? 0.0) as! Double)
        cubeletLevelOfDetail = UserDefaults.standard.integer(forKey: "cubeletLevelOfDetail")
        stickerLevelOfDetail = UserDefaults.standard.integer(forKey: "stickerLevelOfDetail")
        renderAsOutlines = UserDefaults.standard.bool(forKey: "renderAsOutlines")
        
        super.init()
    }
    
    override func awakeFromNib() {
        // Update the main view.
        
        let view = mainViewController.view as! MainView
        view.polygonMode = self.polygonMode
        view.backgroundColor = self.backgroundColor
        view.rubiksCubeRenderer.cubeletLevelOfDetail = self.cubeletLevelOfDetail
        view.rubiksCubeRenderer.stickerLevelOfDetail = self.stickerLevelOfDetail
        
        // Update the preferences window.
        
        backgroundColorWell.color = NSColor(red: CGFloat(backgroundColor.red),
                                            green: CGFloat(backgroundColor.green),
                                            blue: CGFloat(backgroundColor.blue),
                                            alpha: 1)
        cubeletLevelOfDetailSlider.integerValue = cubeletLevelOfDetail
        stickerLevelOfDetailSlider.integerValue = stickerLevelOfDetail
        renderAsOutlinesCheckbox.state = renderAsOutlines ? .on : .off
    }
    
    // MARK:- User actions
    
    @IBAction func setBackgroundColor(_ sender: Any) {
        let backgroundColorAsNSColor = backgroundColorWell.color
        backgroundColor = Color(red: Double(backgroundColorAsNSColor.redComponent),
                                green: Double(backgroundColorAsNSColor.greenComponent),
                                blue: Double(backgroundColorAsNSColor.blueComponent))
    }
    
    @IBAction func resetBackgroundColorToDefault(_ sender: Any) {
        backgroundColor = MainView.defaultBackgroundColor
        
        // Update the preferences window.
        let backgroundColorAsNSColor = NSColor(red: CGFloat(backgroundColor.red),
                                               green: CGFloat(backgroundColor.green),
                                               blue: CGFloat(backgroundColor.blue),
                                               alpha: 1)
        backgroundColorWell.color = backgroundColorAsNSColor
    }
    
    @IBAction func setCubeletLevelOfDetail(_ sender: Any) {
        cubeletLevelOfDetail = cubeletLevelOfDetailSlider.integerValue
    }
    
    @IBAction func setStickerLevelOfDetail(_ sender: Any) {
        stickerLevelOfDetail = stickerLevelOfDetailSlider.integerValue
    }
    
    @IBAction func setPolygonMode(_ sender: Any) {
        renderAsOutlines = (renderAsOutlinesCheckbox.state == .on)
    }
}
