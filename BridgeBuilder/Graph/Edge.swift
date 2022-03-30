//
//  Edge.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 24/12/21.
//

import Foundation
import CoreGraphics

/// Edges of the graph. Represents a truss element, which is a connection between joints (vertices).
///
/// Carries properties like cross sectional area and material elasticity. Some further computed properties can
/// be useful, like total volume of material being used.
class Edge {

    /// Two vertices connected by the edge.
    var vertices: Set<Vertex>

    /// Elasticity coeficient (Young's modulus).
    var elasticity: Double

    /// Cross sectional area of the edge.
    var area: Double

    /// Current length of the edge.
    var length: CGFloat {
        let verticesArray = Array(vertices)
        return verticesArray[0].position.distance(to: verticesArray[1].position)
    }

    /// Current volume of the edge.
    var volume: CGFloat {
        CGFloat(area) * length
    }

    /// Initializes an edge with two vertices, elasticity coeficient and cross sectional area. Order of vertices
    /// doesn't matter.
    /// - Parameters:
    ///   - vertexA: A vertex connected by the edge.
    ///   - vertexB: Another vertex connected by the edge
    ///   - elasticity: Young's modulus of the edge.
    ///   - area: Cross sectional area of the edge.
    init(vertexA: Vertex, vertexB: Vertex, elasticity: Double, area: Double) {
        self.vertices = [vertexA, vertexB]
        self.elasticity = elasticity
        self.area = area
    }
}


//MARK: - Hashable

extension Edge: Hashable {

    static func == (lhs: Edge, rhs: Edge) -> Bool {
        let equalVertices = (lhs.vertices == rhs.vertices)
        let equalElasticities = (lhs.elasticity == rhs.elasticity)
        let equalAreas = (lhs.area == rhs.area)
        return equalVertices && equalElasticities && equalAreas
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(vertices)
        hasher.combine(elasticity)
        hasher.combine(area)
    }
}

