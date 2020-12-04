//
//  Color.swift
//  Decipher
//
//  Created by Jack Copsey on 28/11/2020.
//

import Cocoa

/// A simple implementation of a color in RGBA space.
struct Color {
    typealias Scalar = Double
    
    private var _data: (Scalar, Scalar, Scalar, Scalar)
    
    /// The red component of the color.
    var red: Scalar {
        get { _data.0 }
        set { _data.0 = newValue }
    }
    
    /// The green component of the color.
    var green: Scalar {
        get { _data.1 }
        set { _data.1 = newValue }
    }
    
    /// The blue component of the color.
    var blue: Scalar {
        get { _data.2 }
        set { _data.2 = newValue }
    }
    
    /// The opacity of the color, also known as the alpha component.
    var opacity: Scalar {
        get { _data.3 }
        set { _data.3 = newValue }
    }
    
    /// Construct the color black at full opacity.
    init() {
        self._data = (0, 0, 0, 1)
    }
    
    /// Construct the color with the given red, green and blue components
    /// at full opacity.
    init(red: Scalar, green: Scalar, blue: Scalar) {
        self._data = (red, green, blue, 1)
    }
    
    /// Construct the color with the given components.
    init(red: Scalar, green: Scalar, blue: Scalar, opacity: Scalar) {
        self._data = (red, green, blue, opacity)
    }
}
