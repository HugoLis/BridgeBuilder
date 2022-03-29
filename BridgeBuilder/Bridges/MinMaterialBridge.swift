//
//  MinMaterialBridge.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 26/02/22.
//

import Foundation

/// A bridge that minimizes material for a given load and a maximum allowed
/// truss element stress.
class MinMaterialBridge: Bridge, Evolvable {

    /// Load force in Newtons to be applied to the bridge during fitness
    /// evaluation. It will be equally split through the floor vertices of the
    /// bridge that are not supports.
    var load: CGFloat

    /// A value in Pa (which is N/m^2) that determines a maximum stress an edge
    /// can handle before we consider that it has failed a load test. Could be a
    /// yield or ultimate strength, for example. Varies across
    /// materials.
    var stressLimit: CGFloat

    /// Stores the last calculated fitness. Initializes at minus infinity.
    var calculatedFitness = -CGFloat.infinity

    /// Stores the last calculated max stress. Initializes at infinity.
    var calculatedMaxStress = CGFloat.infinity

    /// Initializes a minumum material bridge from a given graph. Used during
    /// bridge copy, so no checks are performed to the graph.
    /// - Parameters:
    ///   - load: Load force in Newtons to be applied to the bridge during
    ///     fitness evaluation.
    ///   - stressLimit: Maximum stress an edge can handle before failure.
    ///   - graph: Graph of the bridge, usually a copy of an existing graph.
    ///   - floorYPosition: Y position of the bridge floor.
    private init(load: CGFloat, stressLimit: CGFloat, graph: Graph, floorYPosition: CGFloat) {
        self.load = load
        self.stressLimit = stressLimit
        super.init(graph: graph, floorYPosition: floorYPosition)
    }

    /// Initializes a minumum stress bridge with a given load, material limit and support points.
    /// - Parameters:
    ///   - load: Load force in Newtons to be applied to the bridge during
    ///     fitness evaluation.
    ///   - stressLimit: Maximum stress an edge can handle before failure.
    ///     Defaults to the structural steel yield value of 300 MPa.
    ///   - floorSupports: Anchor points of the bridge floor. They must have the
    ///     same y value.
    ///   - extraSupports: Extra anchor points of the bridge. They can be placed
    ///     anywhere.
    init(load: CGFloat, stressLimit: CGFloat = 300e6, floorSupports: [CGPoint], extraSupports: [CGPoint] = []) {
        self.load = load
        self.stressLimit = stressLimit
        super.init(floorSupports: floorSupports, extraSupports: extraSupports)
    }


    /// Fitness function that values lowest material usage possible on the bridge.
    /// - Returns: A score based on the oposite of material usage. Greater
    ///   values mean better performance (less material used).
    func fitness() -> CGFloat {
        // It's very important to reset forces when preparing for a simulation.
        graph.resetForces()

        addWeightForces()
        addLoadForces(totalLoad: load)
        let simulation = Simulation(graph: graph)
        simulation.solve()

        // The score is the oposite of used material.
        var score = -usedMaterial

        // If the maximum stress is above the allowed limit, adds a big fitness
        // penalty that will make the bridge nonviable.
        calculatedMaxStress = simulation.maxStress()
        if calculatedMaxStress > stressLimit { score -= 10e10 }

        calculatedFitness = score
        return score
    }

    func copy() -> Evolvable {
        return MinMaterialBridge(
            load: load,
            stressLimit: stressLimit,
            graph: graph.copy(),
            floorYPosition: floorYPosition
        )
    }
}
