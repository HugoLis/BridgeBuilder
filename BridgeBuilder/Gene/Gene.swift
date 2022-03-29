//
//  Gene.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 25/12/21.
//

import Foundation

/// Truss model/gene of a structure. A class that allows the creation, mutation and crossover of graphs while
/// keeping them rigid trusses. Maximum edge length and minimum distances between vertices are also
/// followed.
class Gene {

    /// Graph that models the truss structure.
    var graph: Graph

    /// Total mass of material used by the truss, in kg.
    var usedMaterial: CGFloat {
        return graph.allEgdes.reduce(0) { $0 + $1.volume * Gene.edgeDensity }
    }

    /// Maximum length of an edge, in meters.
    ///
    /// Defaults to 10m.
    static var maxEdgeLength: CGFloat = 10

    /// Minimum distance between two given joints (vertices), in meters.
    ///
    /// Defaults to 1m.
    static var minVertexDistance: CGFloat = 1

    /// Distance range of vertex connection to other vertices.
    static var connectionRange: ClosedRange<CGFloat> {
        return minVertexDistance...maxEdgeLength
    }

    /// Maximum distance from a point to an edge to justify it's split. A new vertex needs to be at least this
    /// distance to an edge to split the edge.
    static var maxDistanceToSplitEdge: CGFloat {
        return minVertexDistance/5
    }

    /// Range of possible values for the cross sectional area of the truss element (edge).
    static var edgeAreaRange: ClosedRange<CGFloat> = 10e-3...10e-3

    /// Maximum radius of the circle area used to exchange vertices during crossover. A bigger value will
    /// allow bigger exchange areas more nodes exchange.
    ///
    /// Defaults to 10, which is also the default `maxEdgeLength`. Should not be lower than
    /// `minVertexDistance`.
    static var maxCrossoverRadius: CGFloat = 10

    /// Number of times a function will try to perform an action before giving up.
    ///
    /// For example, when removing a vertex or an edge, it may be impossible to remove anything from the
    /// graph while keeping it rigid.
    static var tryoutLimit = 20

    /// Young's modulus or elasticity of the truss elements (edges), in Pa. Varies across materials.
    ///
    /// We use a default structural steel value of 210 GPa.
    static var edgeElasticity: CGFloat = 210e9

    /// Edge density in kg/m^3. Varies across materials.
    ///
    /// Used to add edge weight forces to the nodes of the graph. By default, we use a default structural
    /// steel value of 7850 kg/m^3.
    static var edgeDensity: CGFloat = 7850

    /// Multiplier to weight forces of the gene.
    ///
    /// Used to change element weights importance. Defaults to 1.
    static var weightMultiplier: CGFloat = 1

    /// When true, prints gene operations failures after tryout limit. Used for
    /// debugging.
    static var logFailures = false

    /// Creates a truss gene with a starting graph.
    /// - Parameters:
    ///   - graph: A starting graph which should already model a rigid truss. It should follow
    ///     distances, length, area and elasticity constraints. Defaults to an empty graph.
    init(graph: Graph = Graph()) {
        self.graph = graph
    }

    /// Sets static Gene parameters, like maximum edge length, minumum distance between vertices and
    /// edge material properties.
    ///
    /// All parameters default to nil, which will cause the program to use the Gene's static default values.
    /// See Gene's static properties for more information.
    /// - Parameters:
    ///   - maxEdgeLength: Maximum length of an edge (truss member).
    ///   - minVertexDistance: Minimum distance between vertices (joints).
    ///   - edgeAreaRange: Range of values for the cross sectional area of the truss element (edge).
    ///   - maxCrossoverRadius: Maximum radius of the circle area used to exchange vertices
    ///     during crossover.
    ///   - tryoutLimit: Number of times a function will try to perform an action before giving up.
    ///   - edgeElasticity: Young's modulus of the truss elements (edges).
    ///   - edgeDensity: Density of the edge's material in kg/m^3.
    ///   - weightMultiplier: Multiplier to weight forces of the gene.
    static func setParameters(
        maxEdgeLength: CGFloat? = nil,
        minVertexDistance: CGFloat? = nil,
        edgeAreaRange: ClosedRange<CGFloat>? = nil,
        maxCrossoverRadius: CGFloat? = nil,
        tryoutLimit: Int? = nil,
        edgeElasticity: CGFloat? = nil,
        edgeDensity: CGFloat? = nil,
        weightMultiplier: CGFloat? = nil
    ) {
        if maxEdgeLength != nil { self.maxEdgeLength = maxEdgeLength! }
        if minVertexDistance != nil { self.minVertexDistance = minVertexDistance! }
        if edgeAreaRange != nil { self.edgeAreaRange = edgeAreaRange! }
        if maxCrossoverRadius != nil { self.maxCrossoverRadius = maxCrossoverRadius!}
        if edgeElasticity != nil { self.edgeElasticity = edgeElasticity! }
        if tryoutLimit != nil { self.tryoutLimit = tryoutLimit! }
        if edgeDensity != nil { self.edgeDensity = edgeDensity! }
        if weightMultiplier != nil { self.weightMultiplier = weightMultiplier! }
    }

    /// Adds weight forces to the graph vertices by dividing the weight of each edge into its two connected
    /// vertices.
    func addWeightForces() {
        for edge in graph.allEgdes {
            let weight = edge.volume * Gene.edgeDensity
            // Assuming earth's standard acceleration of gravity.
            let weightForce = weight * 9.80665 * Gene.weightMultiplier

            // Divides the weight force into the two vertices of the edge.
            for vertex in edge.vertices {
                if vertex.force == nil { vertex.force = CGVector() }
                vertex.force!.dy = vertex.force!.dy - weightForce/2
            }
        }
    }
}
