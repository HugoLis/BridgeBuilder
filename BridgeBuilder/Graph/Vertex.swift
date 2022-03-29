//
//  Vertex.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 21/12/21.
//

import Foundation
import CoreGraphics

/// Vertex of the graph. Represents a truss joint.
class Vertex {

    /// Unique identifier for a vertex.
    ///
    /// Vertices from different graphs can share the same id. So, it's important to create new IDs to vertices
    /// brought from other graphs.
    let id: UUID

    /// Position in space of the vertex.
    var position = CGPoint()

    /// True if the x coordinate of the vertex should be fixed during simulation. Vertex may still be able to
    /// move vertically if y coordinate is not constrained.
    ///
    /// Support points for a structure can have one or more fixed coordinates, like supports of a bridge,
    /// tower or cantilever. Most vertices aren't fixed and can move during simulation.
    var isXSimulationFixed: Bool

    /// True if the y coordinate of the vertex should be fixed during simulation. Vertex may still be able to
    /// move horizontally if x coordinate is not constrained.
    ///
    /// Support points for a structure can have one or more fixed coordinates, like supports of a bridge,
    /// tower or cantilever. Most vertices aren't fixed and can move during simulation.
    var isYSimulationFixed: Bool

    /// True if the x coordinate of the vertex should remain constant during evolutionary modifications.
    ///
    /// It is used to guarantee horizontally aligned vertices that can represent the floor section of a bridge
    /// structure. Most vertices should not have a constant x.
    var isXEvolutionFixed: Bool

    /// True if the y coordinate of the vertex should remain constant during evolutionary modifications.
    ///
    /// It is used to guarantee horizontally aligned vertices that can represent the floor section of a bridge
    /// structure. Most vertices should not have a constant y.
    var isYEvolutionFixed: Bool

    /// Force that will be applied to the node during simulation.
    var force: CGVector? = nil

    /// Last four digits from the id of the Vertex. Used for debug and visualization porpuses.
    var shortID: String {
        String(id.uuidString.suffix(2))
    }

    /// Creates a vertex at a given position with optional constraints.
    ///
    /// Anchor points should be fully evolution fixed and have at least one simulation fixed axis. Floor
    /// vertices of a bridge, for example, should have the x evolution fixed.
    /// - Parameters:
    ///   - position: Position of the vertex.
    ///   - isXSimulationFixed: Indicates if the x component of the vertex position should remain
    ///     constant during simulation.
    ///   - isYSimulationFixed: Indicates if the y component of the vertex position should remain
    ///     constant during simulation.
    ///   - isXEvolutionFixed: Indicates if the x coordinate of the position should remain constant,
    ///     like supports on a pole for a catilever.
    ///   - isYEvolutionFixed: Indicates if the y coordinate of the position should remain constant,
    ///     like the floor of a bridge.
    ///   - force: Force to be applied to the vertex during simulation. Defaults to nil and should not be
    ///     this way unless when copying a vertex.
    ///   - id: ID of the vertex. Defaults to nil, so a random identifier will be created. Should not be
    ///     touched unless when creating a copy of the graph.
    init(position: CGPoint, isXSimulationFixed: Bool, isYSimulationFixed: Bool, isXEvolutionFixed: Bool, isYEvolutionFixed: Bool, force: CGVector? = nil, id: UUID? = nil) {
        self.position = position
        self.isXSimulationFixed = isXSimulationFixed
        self.isYSimulationFixed = isYSimulationFixed
        self.isXEvolutionFixed = isXEvolutionFixed
        self.isYEvolutionFixed = isYEvolutionFixed
        self.force = force
        self.id = id ?? UUID()
    }
}


// MARK: - Neighbor Vertex

extension Vertex {

    /// Finds the neighbor vertex of a given edge.
    /// - Parameter edge: edge between the vertex and a neighbor vertex.
    /// - Returns: The neighbor vertex.
    func neighbor(fromEdge edge: Edge) -> Vertex {
        let vertices = Array(edge.vertices)
        // returns the vertex from the edge that is not equal to self.
        return (vertices[0] != self) ? vertices[0] : vertices [1]
    }
}


// MARK: - Hashable

extension Vertex: Hashable {
    static func == (lhs: Vertex, rhs: Vertex) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
