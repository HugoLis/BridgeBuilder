//
//  Tower.swift
//  GeneticBuilder
//
//  Created by Hugo on 05/03/22.
//

import Foundation
import CoreGraphics

// Experimental.
class Tower: Gene {

    /// Creates a new tower from a graph. Used to create copies of the tower so
    /// there are no enforcement to verify the tower is valid during initialization.
    /// - Parameter graph: The graph o a bridge. Usually from a copy of another
    ///   graph.
    init(fromGraph graph: Graph) {
        super.init(graph: graph)
    }

    /// Creates a starter tower with the given x position for supports. The y
    /// possitions for the supports are always zero.
    /// - Parameter suportsXPositions: Positions of the anchor points of the
    ///   tower.
    init(suportsXPositions: [CGFloat]) {
        assert(suportsXPositions.count >= 2, "A tower needs at least two support points.")

        // Adds support points to the graph.
        var graph = Graph()
        for xPosition in suportsXPositions {
            let _ = graph.createVertex(
                position: CGPoint(x: xPosition, y: 0),
                isXSimulationFixed: true,
                isYSimulationFixed: true,
                isXEvolutionFixed: true,
                isYEvolutionFixed: true
            )
        }

        let proxyGene = Gene(graph: graph)

        // Increases the number of vertices in the graph by adding random
        // vertices.
        for _ in 1...3*suportsXPositions.count {
            proxyGene.addRandomVertex(shouldIgnoreSolvability: true)
        }

        // Not sure why this is needed since graph is passed by reference, but
        // it's not working without it.
        graph = proxyGene.graph
        
        // To be safe, if the graph still not solvable, keep adding random
        // vertices until it becomes solvable. This is probably not needed.
        while !Simulation(graph: graph).isSolvable() {
            proxyGene.addRandomVertex(shouldIgnoreSolvability: true)
        }

        super.init(graph: graph)
    }

}
