//
//  RubiksCube.swift
//  Decipher
//
//  Created by Jack Copsey on 17/11/2020.
//

import Foundation

// Core functionality

class RubiksCube {
    /// Type for a single value.
    typealias Value = Int
    
    /// Type for a face of the cube.
    typealias Face = Int
    
    /// Type for a layer of the cube.
    struct Layer {
        let face: Face
        let depth: Int
    }
    
    /// Type for a position on the cube.
    struct Position {
        let face: Face
        let x: Int
        let y: Int
    }
    
    /// How many values there are per side of the cube.
    let size: Int
    
    /// Buffer containing all of the cube's values.
    private let valueBuffer: UnsafeMutableBufferPointer<Value>
    
    /// Construct a cube of size zero.
    init() {
        self.size = 0
        self.valueBuffer = .allocate(capacity: 0)
    }
    
    /// Construct an uninitialised cube of the given size.
    /// Warning: You must first initialise each of the cube's values before trying to access it.
    private init(size: Int) {
        precondition(size >= 0, "Can't construct a cube with size less than zero")
        
        self.size = size
        self.valueBuffer = .allocate(capacity: size * size * 6)
    }
    
    /// Construct a cube of the given size filled with a specified value.
    convenience init(size: Int, filledWithValue value: Value) {
        self.init(size: size)
        
        valueBuffer.assign(repeating: value)
    }
    
    deinit {
        valueBuffer.deallocate()
    }
    
    /// Check if the given layer is valid.
    func layerIsInRange(_ layer: Layer) -> Bool {
        if layer.face < 0 || layer.face >= 6 { return false }
        if layer.depth < 0 || layer.depth >= size { return false }
        return true
    }
    
    /// Check if the given position is valid.
    func positionIsInRange(_ p: Position) -> Bool {
        if p.face < 0 || p.face >= 6 { return false }
        if p.x < 0 || p.x >= size { return false }
        if p.y < 0 || p.y >= size { return false }
        return true
    }
    
    /// Convert a position on the cube to an index in the internal array of values.
    /// Before calling this method, you should make sure the position is in range.
    private func indexFromPosition(_ p: Position) -> Int {
        p.x + p.y * size + p.face * size * size
    }
    
    /// Access the value at the given position.
    subscript(_ p: Position) -> Value {
        get {
            precondition(positionIsInRange(p), "Position is out of range")
            return valueBuffer[indexFromPosition(p)]
        }
        set {
            precondition(positionIsInRange(p), "Position is out of range")
            valueBuffer[indexFromPosition(p)] = newValue
        }
    }
    
    /// Set each value on the cube to the given constant.
    func fill(_ value: Value) {
        valueBuffer.assign(repeating: value)
    }
    
    /// Set each value on a specified face of the cube to the given constant.
    func fill(_ value: Value, onFace face: Face) {
        let start = face * size * size
        let end = (face + 1) * size * size
        
        for index in start ..< end {
            valueBuffer[index] = value
        }
    }
    
    /// Rotate the values held at the four positions a given number of times.
    private func rotate(_ position1: Position, _ position2: Position,
                        _ position3: Position, _ position4: Position,
                        count: Int) {
        let index1 = indexFromPosition(position1)
        let index2 = indexFromPosition(position2)
        let index3 = indexFromPosition(position3)
        let index4 = indexFromPosition(position4)
        
        let countMod4 = (count < 0) ? (count % 4 + 4) : (count % 4)
        
        switch countMod4 {
            case 1:
                let temp = valueBuffer[index1]
                valueBuffer[index1] = valueBuffer[index4]
                valueBuffer[index4] = valueBuffer[index3]
                valueBuffer[index3] = valueBuffer[index2]
                valueBuffer[index2] = temp
                
            case 2:
                valueBuffer.swapAt(index1, index3)
                valueBuffer.swapAt(index2, index4)
                
            case 3:
                let temp = valueBuffer[index1]
                valueBuffer[index1] = valueBuffer[index2]
                valueBuffer[index2] = valueBuffer[index3]
                valueBuffer[index3] = valueBuffer[index4]
                valueBuffer[index4] = temp
                
            default:
                return
        }
    }
    
    /// Rotate a layer anticlockwise by the given number of turns.
    ///
    /// Note that "anticlockwise" is relative to the coordinate system of
    /// the layer: so if the x- and y-axes are swapped, then the rotation
    /// will occur in the opposite direction.
    func turn(layer: Layer, count: Int) {
        precondition(layerIsInRange(layer), "Layer (\(layer.face), \(layer.depth)) is out of range")
        
        _turnSidesOnly(layer: layer, count: count)
        
        if layer.depth == 0 {
            _turnFaceOnly(layer.face, count: count)
        }
        
        if layer.depth == size - 1 {
            let oppositeFace = (layer.face + 3) % 6
            _turnFaceOnly(oppositeFace, count: count)
        }
    }
    
    /// Rotate the values on a face anticlockwise by the given number of turns.
    /// No other values are altered, including the sides of the face.
    private func _turnFaceOnly(_ face: Face, count: Int) {
        for i in 0 ..< size / 2 {
            for j in i ..< size - 1 - i {
                let iR = size - 1 - i
                let jR = size - 1 - j
                
                let p1 = Position(face: face, x: i,  y: j)
                let p2 = Position(face: face, x: jR, y: i)
                let p3 = Position(face: face, x: iR, y: jR)
                let p4 = Position(face: face, x: j,  y: iR)
                
                rotate(p1, p2, p3, p4, count: count)
            }
        }
    }
    
    /// Rotate a layer's sides anticlockwise by the given number of turns.
    /// No other values are altered, including the layer's face if it has one.
    ///
    /// It's assumed the layer is in range; make sure to check this before calling
    /// the function!
    private func _turnSidesOnly(layer: Layer, count: Int) {
        let f1 = (layer.face + 1) % 6
        let f2 = (layer.face + 2) % 6
        let f4 = (layer.face + 4) % 6
        let f5 = (layer.face + 5) % 6
        
        let d  = layer.depth
        let dR = size - 1 - layer.depth
        
        for i in 0 ..< size {
            let p1 = Position(face: f1, x: i,  y: d)
            let p2 = Position(face: f2, x: d,  y: i)
            let p3 = Position(face: f4, x: i,  y: dR)
            let p4 = Position(face: f5, x: dR, y: i)
            
            rotate(p1, p2, p3, p4, count: count)
        }
    }
}

// Utility methods and properties

extension RubiksCube {
    /// Construct a cube where the values are not yet initialized.
    static func uninitializedRubiksCube(size: Int) -> RubiksCube {
        RubiksCube(size: size)
    }
    
    /// Construct a cube with each value set to -1.
    static func blankRubiksCube(size: Int) -> RubiksCube {
        RubiksCube(size: size, filledWithValue: -1)
    }

    /// Construct a solved cube.
    static func solvedRubiksCube(size: Int) -> RubiksCube {
        let cube = RubiksCube(size: size)
        for value in 0..<6 {
            let face = Face(value)
            cube.fill(value, onFace: face)
        }
        return cube
    }
    
    /// Returns `true` if the value at each position on the cube is equal to its face.
    /// Otherwise returns `false`.
    var isSolved: Bool {
        for faceAsInteger in 0..<6 {
            for x in 0 ..< size {
                for y in 0 ..< size {
                    let face = Face(faceAsInteger)
                    let position = Position(face: face, x: x, y: y)
                    if self[position] != faceAsInteger { return false }
                }
            }
        }
        
        return true
    }
    
    /// Rotate layers of the cube at random to get a new permutation.
    func scramble() {
        let numberOfMoves = 2 * (size * size + 1) + Int.random(in: 0...7)
        
        for _ in 0 ..< numberOfMoves {
            let face = Face(Int.random(in: 0..<6))
            let depth = Int.random(in: 0 ..< size)
            let layer = Layer(face: face, depth: depth)
            let count = Int.random(in: 1...3)
            
            turn(layer: layer, count: count)
        }
    }
}
