//
//  RubiksCube.swift
//  Decipher
//
//  Created by Jack Copsey on 17/11/2020.
//

import Foundation

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
    
    /// How many values there are per side.
    var valuesPerSide: Int {
        length
    }
    
    /// How many values there are per face.
    var valuesPerFace: Int {
        length * length
    }
    
    /// How many values there are in total.
    var numberOfValues: Int {
        length * length * 6
    }
    
    private let length: Int
    private let buffer: UnsafeMutablePointer<Value>
    
    /// Construct an uninitialised cube of the given length.
    /// Warning: You must first initialise each of the cube's values before trying to access it.
    init(length: Int) {
        precondition(length >= 0, "Can't construct a cube with length less than zero")
        self.length = length
        self.buffer = .allocate(capacity: length * length * 6)
    }
    
    deinit {
        buffer.deallocate()
    }
    
    /// Check if the given layer is valid.
    func inRange(layer: Layer) -> Bool {
        if layer.face < 0 || layer.face >= 6 { return false }
        if layer.depth < 0 || layer.depth >= self.length { return false }
        return true
    }
    
    /// Check if the given position is valid.
    func inRange(position p: Position) -> Bool {
        if p.face < 0 || p.face >= 6 { return false }
        if p.x < 0 || p.x >= self.length { return false }
        if p.y < 0 || p.y >= self.length { return false }
        return true
    }
    
    /// Convert a position on the cube to an index in the internal array of values.
    /// Before calling this method, you should make sure the position is in range.
    private func toIndex(position p: Position) -> Int {
        p.x + p.y * length + p.face * length * length
    }
    
    /// Access the value at the given position.
    subscript(position p: Position) -> Value {
        get {
            precondition(inRange(position: p), "Position is out of range")
            return buffer[toIndex(position: p)]
        }
        set {
            precondition(inRange(position: p), "Position is out of range")
            buffer[toIndex(position: p)] = newValue
        }
    }
    
    /// Get the value at the given position, or `nil` if the position is out of range.
    func getValue(atPosition p: Position) -> Value? {
        inRange(position: p) ? buffer[toIndex(position: p)] : nil
    }
    
    /// Set the value at the given position.
    /// Returns the old value, or `nil` if the position is out of range.
    func setValue(atPosition p: Position, toValue newValue: Value) -> Value? {
        if inRange(position: p) {
            let index = toIndex(position: p)
            let oldValue = buffer[index]
            buffer[index] = newValue
            return oldValue
        } else {
            return nil
        }
    }
    
    /// Set each value on the cube to the given constant.
    func fill(value: Value) {
        for index in 0..<self.numberOfValues {
            buffer[index] = value
        }
    }
    
    /// Set each value on a specific face of the cube to the given constant.
    func fill(face: Face, value: Value) {
        let start = self.valuesPerFace * face
        let end = self.valuesPerFace * (face + 1)
        
        for index in start ..< end {
            self.buffer[index] = value
        }
    }
    
    /// Rotate the values held at the four positions a given number of times.
    private func rotate(position1 p1: Position, position2 p2: Position,
                        position3 p3: Position, position4 p4: Position,
                        count: Int) {
        var temp: Value
        
        let index1 = toIndex(position: p1)
        let index2 = toIndex(position: p2)
        let index3 = toIndex(position: p3)
        let index4 = toIndex(position: p4)
        
        let countMod4 = (count < 0) ? (count % 4 + 4) : (count % 4)
        switch countMod4 {
        case 1:
            temp = buffer[index1]
            buffer[index1] = buffer[index4]
            buffer[index4] = buffer[index3]
            buffer[index3] = buffer[index2]
            buffer[index2] = temp
            
        case 2:
            temp = buffer[index1]
            buffer[index1] = buffer[index3]
            buffer[index3] = temp
            temp = buffer[index2]
            buffer[index2] = buffer[index4]
            buffer[index4] = temp
            
        case 3:
            temp = buffer[index1]
            buffer[index1] = buffer[index2]
            buffer[index2] = buffer[index3]
            buffer[index3] = buffer[index4]
            buffer[index4] = temp
            
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
        precondition(inRange(layer: layer), "Layer (\(layer.face), \(layer.depth)) is out of range")
        
        _turnSidesOnly(layer: layer, count: count)
        
        if layer.depth == 0 {
            _turnFaceOnly(layer.face, count: count)
        }
        
        if layer.depth == self.length - 1 {
            let oppositeFace = (layer.face + 3) % 6
            _turnFaceOnly(oppositeFace, count: count)
        }
    }
    
    /// Rotate the values on a face anticlockwise by the given number of turns.
    /// No other values are altered, including the sides of the face.
    private func _turnFaceOnly(_ face: Face, count: Int) {
        for i in 0 ..< length / 2 {
            for j in i ..< length - 1 - i {
                let iR = length - 1 - i
                let jR = length - 1 - j
                
                let p1 = Position(face: face, x: i,  y: j)
                let p2 = Position(face: face, x: jR, y: i)
                let p3 = Position(face: face, x: iR, y: jR)
                let p4 = Position(face: face, x: j,  y: iR)
                
                rotate(position1: p1, position2: p2, position3: p3,
                       position4: p4, count: count)
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
        let dR = self.length - 1 - layer.depth
        
        for i in 0 ..< self.length {
            let p1 = Position(face: f1, x: i,  y: d)
            let p2 = Position(face: f2, x: d,  y: i)
            let p3 = Position(face: f4, x: i,  y: dR)
            let p4 = Position(face: f5, x: dR, y: i)
            
            self.rotate(position1: p1, position2: p2, position3: p3, position4: p4, count: count)
        }
    }
}

/// Create a cube with each value set to -1.
func makeBlankRubiksCube(length: Int) -> RubiksCube {
    let cube = RubiksCube(length: length)
    cube.fill(value: -1)
    return cube
}

/// Create a solved cube.
func makeSolvedRubiksCube(length: Int) -> RubiksCube {
    let cube = RubiksCube(length: length)
    for face in 0..<6 {
        cube.fill(face: face, value: face)
    }
    return cube
}

/// Check if the cube is in a solved state.
func isSolved(rubiksCube cube: RubiksCube) -> Bool {
    let n = cube.valuesPerSide
    
    for face in 0..<6 {
        for x in 0..<n {
            for y in 0..<n {
                let p = RubiksCube.Position(face: face, x: x, y: y)
                if cube[position: p] != face { return false }
            }
        }
    }
    
    return true
}

/// Rotate layers of the cube at random to get a new permutation.
func scramble(_ cube: RubiksCube) {
    let n = cube.valuesPerSide
    let numberOfMoves = 2 * (n * n + 1) + Int.random(in: 0...7)
    
    for _ in 0 ..< numberOfMoves {
        let face = RubiksCube.Face(Int.random(in: 0..<6))
        let depth = Int.random(in: 0..<n)
        let layer = RubiksCube.Layer(face: face, depth: depth)
        let count = Int.random(in: 1...3)
        
        cube.turn(layer: layer, count: count)
    }
}
