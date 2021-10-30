//
//  TriangleMesh.swift
//
//  Created by Jack Copsey on 30/10/2021.
//

import Cocoa
import OpenGL.GL

class TriangleMesh {
	typealias Scalar = GLdouble
	typealias Vertex = Vector3<Scalar>

	var vertexes: [Vertex] = []
	var drawingOrder: [(Int, Int, Int)] = []

	func render() {
		GL.beginTriangles()

		for (index1, index2, index3) in drawingOrder {
			GL.addVertex(vertexes[index1])
			GL.addVertex(vertexes[index2])
			GL.addVertex(vertexes[index3])
		}

		GL.endShape()
	}
}
