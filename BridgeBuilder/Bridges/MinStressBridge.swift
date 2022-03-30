//
//  MinStressBridge.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 26/02/22.
//

import Foundation
import CoreGraphics

/// A bridge that minimizes truss element stresses for a given load and a maximum
/// allowed material usage.
class MinStressBridge: Bridge, Evolvable {

    /// Load force in Newtons to be applied to the bridge during fitness evaluation. It will be equally split
    /// through the floor vertices of the bridge that are not supports.
    var load: CGFloat

    /// Limit of material mass, in kg, to be used to build the bridge. Bridges
    /// that use more material than this limit will receive a penalty during
    /// fitness evaluation.
    var materialLimit: CGFloat

    /// Stores the last calculated fitness. Initializes at minus infinity.
    var calculatedFitness = -CGFloat.infinity

    /// Stores the last calculated max stress. Initializes at infinity.
    var calculatedMaxStress = CGFloat.infinity

    /// Initializes a minumum stress bridge from a given graph. Used during
    /// bridge copy, so no checks are performed to the graph.
    /// - Parameters:
    ///   - load: Load force in Newtons to be applied to the bridge during
    ///     fitness evaluation.
    ///   - materialLimit: Limit of material mass, in kg, to be used to build
    ///     the bridge.
    ///   - graph: Graph of the bridge, usually a copy of an existing graph.
    ///   - floorYPosition: Y position of the bridge floor.
    private init(load: CGFloat, materialLimit: CGFloat, graph: Graph, floorYPosition: CGFloat) {
        self.load = load
        self.materialLimit = materialLimit
        super.init(graph: graph, floorYPosition: floorYPosition)
    }

    /// Initializes a minumum stress bridge with a given load, material limit
    /// and support points.
    /// - Parameters:
    ///   - load: Load force in Newtons to be applied to the bridge during
    ///     fitness evaluation.
    ///   - materialLimit: Load force in Newtons to be applied to the bridge
    ///     during fitness evaluation.
    ///   - floorSupports: Anchor points of the bridge floor. They must have the
    ///     same y value.
    ///   - extraSupports: Extra anchor points of the bridge. They can be placed
    ///     anywhere.
    init(load: CGFloat, materialLimit: CGFloat, floorSupports: [CGPoint], extraSupports: [CGPoint] = []) {
        self.load = load
        self.materialLimit = materialLimit
        super.init(floorSupports: floorSupports, extraSupports: extraSupports)
    }

    /// Fitness function that values lowest stress possible on the bridge.
    /// - Returns: A score based on the oposite of the most stressed bridge
    ///   elements. Greater values mean better performance (lower stresses).
    func fitness() -> CGFloat {
        // It's very important to reset forces when preparing for a simulation.
        graph.resetForces()

        addWeightForces()
        addLoadForces(totalLoad: load)
        let simulation = Simulation(graph: graph)
        simulation.solve()

        // A mean of stresses was also tried, but the algorithm discovered it
        // could simply create as many useless edges attached to the anchor points
        // as possible in order to decrease the stress mean.

        // The score is the oposite of the mean of the most stressed truss
        // elements.
        let maxStressesMean = simulation.maxStressesMean(count: 3)
        var score = -maxStressesMean

        calculatedMaxStress = simulation.maxStress()

        // If the material usage is above the allowed limit, adds a big fitness
        // penalty that will make the bridge nonviable.
        if usedMaterial > materialLimit { score -= 10e10 }

        calculatedFitness = score
        return score
    }

    /// Creates a copy by value of the current bridge.
    /// - Returns: A copy by value of the current bridge.
    func copy() -> Evolvable {
        return MinStressBridge(
            load: load,
            materialLimit: materialLimit,
            graph: graph.copy(),
            floorYPosition: floorYPosition
        )
    }

}
