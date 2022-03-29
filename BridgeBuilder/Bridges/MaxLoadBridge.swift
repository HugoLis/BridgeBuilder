//
//  MaxLoadBridge.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 26/02/22.
//

import Foundation

/// A bridge that maximizes supported load with a given material usage limit and
/// a given stress limit.
///
/// Too slow fitness evaluation to be usable realistically.
class MaxLoadBridge: Bridge, Evolvable {

    /// A value in Pa (which is N/m^2) that determines a maximum stress an edge
    /// can handle before we consider that it has failed a load test. Could be a
    /// yield or ultimate strength, for example. Varies across
    /// materials.
    var stressLimit: CGFloat

    /// Limit of material mass, in kg, to be used to build the bridge. Bridges
    /// that use more material than this limit will receive a penalty during
    /// fitness evaluation.
    var materialLimit: CGFloat

    /// Stores the last calculated fitness. Initializes at minus infinity.
    var calculatedFitness = -CGFloat.infinity

    /// Stores the last calculated max stress. Initializes at infinity.
    var calculatedMaxStress = CGFloat.infinity

    /// Initializes a maximum load bridge from a given graph. Used during
    /// bridge copy, so no checks are performed to the graph.
    /// - Parameters:
    ///   - stressLimit: Maximum stress an edge can handle before failure.
    ///   - materialLimit: Limit of material mass, in kg, to be used to build
    ///     the bridge.
    ///   - graph: Graph of the bridge, usually a copy of an existing graph.
    ///   - floorYPosition: Y position of the bridge floor.
    private init(stressLimit: CGFloat, materialLimit: CGFloat, graph: Graph, floorYPosition: CGFloat) {
        self.stressLimit = stressLimit
        self.materialLimit = materialLimit
        super.init(graph: graph, floorYPosition: floorYPosition)
    }

    /// Initializes a minumum stress bridge with a given load, material limit
    /// and support points.
    /// - Parameters:
    ///   - stressLimit: Maximum stress an edge can handle before failure.
    ///     Defaults to the structural steel yield value of 300 MPa.
    ///   - materialLimit: Load force in Newtons to be applied to the bridge
    ///     during fitness evaluation.
    ///   - floorSupports: Anchor points of the bridge floor. They must have the
    ///     same y value.
    ///   - extraSupports: Extra anchor points of the bridge. They can be placed
    ///     anywhere.
    init(stressLimit: CGFloat = 300e6, materialLimit: CGFloat , floorSupports: [CGPoint], extraSupports: [CGPoint] = []) {
        self.stressLimit = stressLimit
        self.materialLimit = materialLimit
        super.init(floorSupports: floorSupports, extraSupports: extraSupports)
    }

    /// Fitness function that values maximum load possible on the bridge.
    /// - Returns: A score based on the maximum load supported by the bridge.
    ///   Greater values mean better performance (more supported load).
    func fitness() -> CGFloat {
        var currentJump: CGFloat = 400000
        var currentLoad = 2*currentJump
        let accuracy: CGFloat = 25000

        // Maximum successful load passed.
        var left = -CGFloat.infinity

        // Minimum load failed.
        var right = CGFloat.infinity

        // Does something similar to a binary search to find the maximum supported
        // load before the bridge reaches the stress limit. The maximum supported
        // load will be stored if the `left` variable.
        while (right - left) > accuracy {
            // It's very important to reset forces when preparing for a simulation.
            graph.resetForces()
            addWeightForces()
            addLoadForces(totalLoad: currentLoad)
            let simulation = Simulation(graph: graph)
            simulation.solve()
            calculatedMaxStress = simulation.maxStress()
            if calculatedMaxStress <= stressLimit {
                left = currentLoad
                if right == CGFloat.infinity {
                    currentJump *= 2
                } else {
                    currentJump /= 2
                }
                currentLoad += currentJump
            } else {
                right = currentLoad
                currentJump /= 2
                currentLoad = left + currentJump
            }
        }

        // The score is maximum supported load by the bridge, and it's stored
        // in the the `left` variable.
        var score = left

        // If the material usage is above the allowed limit, adds a big fitness
        // penalty that will make the bridge nonviable.
        if usedMaterial > materialLimit { score -= 10e10 }

        calculatedFitness = score
        return score
    }

    /// Creates a copy by value of the current bridge.
    /// - Returns: A copy by value of the current bridge.
    func copy() -> Evolvable {
        return MaxLoadBridge(
            stressLimit: stressLimit,
            materialLimit: materialLimit,
            graph: graph.copy(),
            floorYPosition: floorYPosition
        )
    }

}
