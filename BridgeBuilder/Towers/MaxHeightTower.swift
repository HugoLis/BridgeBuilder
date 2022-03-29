//
//  MaxHeightTower.swift
//  GeneticBuilder
//
//  Created by Hugo on 05/03/22.
//

import Foundation

// Experimental class used for creating towers.
class MaxHeightTower: Tower, Evolvable {

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

    /// Initializes a maximum height tower from a given graph. Used during
    /// bridge copy, so no checks are performed to the graph.
    /// - Parameters:
    ///   - stressLimit: Maximum stress an edge can handle before failure.
    ///   - materialLimit: Limit of material mass, in kg, to be used to build
    ///     the bridge.
    ///   - graph: Graph of the tower, usually a copy of an existing graph.
    private init(stressLimit: CGFloat, materialLimit: CGFloat, graph: Graph) {
        self.stressLimit = stressLimit
        self.materialLimit = materialLimit
        super.init(fromGraph: graph)
    }

    init(stressLimit: CGFloat, materialLimit: CGFloat, supportsXPositions: [CGFloat]) {
        self.stressLimit = stressLimit
        self.materialLimit = materialLimit
        super.init(suportsXPositions: supportsXPositions)
    }

    func fitness() -> CGFloat {
        // It's very important to reset forces when preparing for a simulation.
        //graph.resetForces()

         addWeightForces()
         let simulation = Simulation(graph: graph)
         simulation.solve()

        // The score is the y position of the heighest vertex.
        let heighestVertex = graph.allVertices.max { $0.position.y < $1.position.y }!
        var score = heighestVertex.position.y

        // If the material usage is above the allowed limit, adds a big fitness
        // penalty that will make the bridge nonviable.
        if usedMaterial > materialLimit { score -= 10e10 }

         // If the maximum stress is above the allowed limit, adds a big fitness
         // penalty that will make the bridge nonviable.
         calculatedMaxStress = simulation.maxStress()
         if calculatedMaxStress > stressLimit { score -= 10e10 }

        calculatedFitness = score
        return score
    }

    func copy() -> Evolvable {
        return MaxHeightTower(
            stressLimit: stressLimit,
            materialLimit: materialLimit,
            graph: graph.copy()
        )
    }

    
}
