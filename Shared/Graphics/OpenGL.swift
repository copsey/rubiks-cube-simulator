//
//  OpenGL.swift
//  Decipher
//
//  Created by Jack Copsey on 23/11/2020.
//

import Cocoa
import OpenGL.GL
import GLKit

struct GL {
    typealias Scalar = GLdouble
    typealias Vector = Vector3<GLdouble>
    typealias Vertex = Vector3<GLdouble>
    
    static var clearColor: Color {
        get {
            var buffer = Array<GLdouble>(repeating: 0, count: 4)
            glGetDoublev(GLenum(GL_COLOR_CLEAR_VALUE), &buffer)
            
            return Color(red: buffer[0], green: buffer[1], blue: buffer[2], opacity: buffer[3])
        }
        
        set {
            let red = GLclampf(newValue.red)
            let green = GLclampf(newValue.green)
            let blue = GLclampf(newValue.blue)
            let alpha = GLclampf(newValue.opacity)
            glClearColor(red, green, blue, alpha)
        }
    }
    
    static var renderColor: Color {
        get {
            var buffer = Array<GLdouble>(repeating: 0, count: 3)
            glGetDoublev(GLenum(GL_CURRENT_COLOR), &buffer)
            
            return Color(red: buffer[0], green: buffer[1], blue: buffer[2])
        }
        
        set {
            let red = GLclampf(newValue.red)
            let green = GLclampf(newValue.green)
            let blue = GLclampf(newValue.blue)
            glColor3f(red, green, blue)
        }
    }
    
    static var clearDepth: GLclampd {
        get {
            var depth = GLclampd()
            glGetDoublev(GLenum(GL_DEPTH_BUFFER_BIT), &depth)
            return depth
        }
        
        set {
            glClearDepth(newValue)
        }
    }
    
    static func beginTriangles() {
        glBegin(GLenum(GL_TRIANGLES))
    }
    
    static func beginTriangleStrip() {
        glBegin(GLenum(GL_TRIANGLE_STRIP))
    }
    
    static func beginQuads() {
        glBegin(GLenum(GL_QUADS))
    }
    
    static func beginQuadStrip() {
        glBegin(GLenum(GL_QUAD_STRIP))
    }
    
    static func beginPolygon() {
        glBegin(GLenum(GL_POLYGON))
    }
    
    static func endShape() {
        glEnd()
    }
    
    static func addVertex(_ vertex: Vertex) {
        withUnsafePointer(to: vertex) {
            glVertex3dv(UnsafeRawPointer($0).assumingMemoryBound(to: GLdouble.self))
        }
    }
    
    static func translate(by v: Vector3<GLdouble>) {
        glTranslated(v.x, v.y, v.z)
    }
    
    static func translate(x: GLdouble, y: GLdouble, z: GLdouble) {
        glTranslated(x, y, z)
    }
    
    static func rotate(by axisAndAngle: AxisAngle<GLdouble>) {
        Self.rotate(angle: axisAndAngle.angle, axis: axisAndAngle.axis)
    }
    
    static func rotate(angle: GLdouble, axis: Vector) {
        let angleInDegrees = angle * 180 / .pi
        glRotated(angleInDegrees, axis.x, axis.y, axis.z)
    }
    
    static func pushMatrix() {
        glPushMatrix()
    }
    
    static func popMatrix() {
        glPopMatrix()
    }
    
    static func multiplyMatrix(by matrix: Matrix4x4<Scalar>) {
        withUnsafePointer(to: matrix) {
            glMultTransposeMatrixd(UnsafeRawPointer($0).assumingMemoryBound(to: GLdouble.self))
        }
    }
    
    static func clear() {
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
    }
    
    static func flush() {
        glFlush()
    }
    
    static func setViewport(x: GLint, y: GLint, width: GLsizei, height: GLsizei) {
        glViewport(x, y, width, height)
    }
    
    static func setFrustum(left: GLdouble, right: GLdouble, bottom: GLdouble, top: GLdouble,
                           near: GLdouble, far: GLdouble) {
        glMatrixMode(GLenum(GL_PROJECTION))
        
        glLoadIdentity()
        glFrustum(left, right, bottom, top, near, far)

        glMatrixMode(GLenum(GL_MODELVIEW))
    }
    
    static func resetModelviewMatrix() {
        glLoadIdentity()
    }
    
    static func unproject(_ viewportPoint: Vector) -> Vector {
        var viewport = (GLint(), GLint(), GLint(), GLint())
        
        withUnsafeMutablePointer(to: &viewport) {
            let buffer = UnsafeMutableRawPointer($0).assumingMemoryBound(to: GLint.self)
            glGetIntegerv(GLenum(GL_VIEWPORT), buffer)
        }
        
        var modelviewMatrix = Matrix4x4<GLfloat>()
        
        withUnsafeMutablePointer(to: &modelviewMatrix) {
            let buffer = UnsafeMutableRawPointer($0).assumingMemoryBound(to: GLfloat.self)
            glGetFloatv(GLenum(GL_MODELVIEW_MATRIX), buffer)
        }
        
        var projectionMatrix = Matrix4x4<GLfloat>()
        
        withUnsafeMutablePointer(to: &projectionMatrix) {
            let buffer = UnsafeMutableRawPointer($0).assumingMemoryBound(to: GLfloat.self)
            glGetFloatv(GLenum(GL_PROJECTION_MATRIX), buffer)
        }
        
        let viewportPointAsGLK = GLKVector3(v: (GLfloat(viewportPoint.x),
                                                GLfloat(viewportPoint.y),
                                                GLfloat(viewportPoint.z)))
        
        let modelviewMatrixAsGLK = GLKMatrix4(m: modelviewMatrix.data)
        let projectionMatrixAsGLK = GLKMatrix4(m: projectionMatrix.data)
        
        let scenePoint: Vector = withUnsafeMutablePointer(to: &viewport) {
            let viewportBuffer = UnsafeMutableRawPointer($0).assumingMemoryBound(to: GLint.self)
            let scenePointAsGLK = GLKMathUnproject(viewportPointAsGLK, modelviewMatrixAsGLK, projectionMatrixAsGLK,
                                                   viewportBuffer, nil)
            return Vector(GLdouble(scenePointAsGLK.x), GLdouble(scenePointAsGLK.y), GLdouble(scenePointAsGLK.z))
        }
        
        return scenePoint
    }
    
    static func readDepthComponent(x: GLint, y: GLint) -> GLfloat {
        var depth = GLfloat()
        glReadPixels(x, y, 1, 1, GLenum(GL_DEPTH_COMPONENT), GLenum(GL_FLOAT), &depth)
        
        return depth
    }
}
