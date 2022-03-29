//
//  Gene+Crossover.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 22/02/22.
//

import Foundation

// MARK: - Vertices Exchange

extension Gene {

    /// Copies a subgraph from a donnor graph and replaces it with the vertices in the same area of the
    /// gene's graph. The resulting graph should respect maximum edge length and minimum distance
    /// between vertices.
    /// - Parameter donnorGraph: Graph that will donate a subgraph of itself to the gene's graph.
    func crossover(with donnorGraph: Graph) {
        var didPerformCrossover = false
        var counter = 0
        while !didPerformCrossover {
            didPerformCrossover = tryToCrossover(with: donnorGraph)

            counter += 1
            if counter >= Gene.tryoutLimit {
                if Gene.logFailures {
                    print("Gene.crossover(). Failed too many times while trying to perform crossover.")
                }
                return
            }
        }
    }

    /// Tries to copy a subgraph from a donnor graph and replaces it with the vertices in the same area of
    /// the gene's graph.
    /// - Parameter donnorGraph: Graph that will donate a subgraph of itself to the gene's graph.
    /// - Returns: True if the operation succeeds. False, otherwise.
    private func tryToCrossover(with donnorGraph: Graph) -> Bool {
        // Randomly chooses a vertex of the donnor graph, if the graph is not empty.
        guard let randomVertex = graph.allVertices.randomElement() else { return false }

        // Distance around the random vertex to create
        let randomDistance = RandomCGFloat.normal(in: Gene.minVertexDistance...Gene.maxCrossoverRadius)
        //let randomDistance = CGFloat.random(in: Gene.minVertexDistance...Gene.maxCrossoverRadius)
        //let randomDistance = RandomCGFloat.reversedHalfNormal(in: Gene.minVertexDistance...Gene.maxCrossoverRadius)

        // Array of vertices of the donnor graph within random distance from the
        // random vertex, including the random vertex itself.
        let donnorVerticesWithinDistance = donnorGraph.allVertices.filter {
            randomVertex.position.distance(to: $0.position) <= randomDistance
        }

        // A subgraph copy that we will try to move to the gene's graph.
        let donnorSubgraph = Graph()

        // A dictionary that relates an original vertex to its copy. Used to
        // create edges copies with reference to the new vertices instead of the
        // original ones.
        var originalToCopyVertices: [Vertex:Vertex] = [:]

        // All edges connected to at least one donnor vertex within distance
        var partialDonnorEdges: [Edge] = []

        // Copies all donnor vertices to the subgraph copy.
        for donnorVertex in donnorVerticesWithinDistance {
            let vertexCopy = donnorSubgraph.createVertex(
                position: donnorVertex.position,
                isXSimulationFixed: donnorVertex.isXSimulationFixed,
                isYSimulationFixed: donnorVertex.isYSimulationFixed,
                isXEvolutionFixed: donnorVertex.isXEvolutionFixed,
                isYEvolutionFixed: donnorVertex.isYEvolutionFixed
            )
            originalToCopyVertices[donnorVertex] = vertexCopy
            partialDonnorEdges.append(contentsOf: donnorGraph.edges(of: donnorVertex))
        }

        // Removes duplicates of partial donnor edges
        partialDonnorEdges = Array(Set(partialDonnorEdges))

        // donnorEdges are edges connected to donnor edges within random distance
        // on both ends.
        let donnorEdges = partialDonnorEdges.filter {
            let vertices = Array($0.vertices)
            return donnorVerticesWithinDistance.contains(vertices[0]) && donnorVerticesWithinDistance.contains(vertices[1])
        }

        // Copies all edges between donnor vertices within random distance to the
        // subgraph copy. Our donnor subgraph copy is complete
        for donnorEdge in donnorEdges {
            let vertices = Array(donnorEdge.vertices)
            donnorSubgraph.addEdge(
                between: originalToCopyVertices[vertices[0]]!,
                and: originalToCopyVertices[vertices[1]]!,
                elasticity: donnorEdge.elasticity,
                area: donnorEdge.area)
        }

        // Removes vertices that are in the same area of the subgraph on a copy
        // of the gene's graph.
        let graphCopy = graph.copy()
        let verticesToRemove = graphCopy.allVertices.filter {
            randomVertex.position.distance(to: $0.position) <= randomDistance
        }
        for vertexToRemove in verticesToRemove {
            graphCopy.remove(vertex: vertexToRemove)
        }

        // Vertices and edges of the gene's graph after removing nodes in the
        // subgraph area.
        let originalVertices = graphCopy.allVertices
        let originalEdges = graphCopy.allEgdes

        // Copies subgraph to the gene's graph copy.
        for subgraphVertex in donnorSubgraph.allVertices {
            assert(graphCopy.adjacencyList[subgraphVertex] == nil, "Tried to replace an existing value when copying the subgraph to the graph in crossover.")
            graphCopy.adjacencyList[subgraphVertex] = donnorSubgraph.adjacencyList[subgraphVertex]
        }

        // Dictionary indicating vertices that could not be added to the graph
        // because they were too close to an existing vertex or edge. A true
        // value indicates it was removed.
        var subgraphRemovedVertices: Set<Vertex> = []

        // If a new vertex is too close to an existing original vertex, remove
        // that new vertex and save it to a dictionary of removed vertices.
        for subgraphVertex in donnorSubgraph.allVertices {
            for originalVertex in originalVertices {
                if subgraphVertex.position.distance(to: originalVertex.position) < Gene.minVertexDistance {
                    graphCopy.remove(vertex: subgraphVertex)
                    subgraphRemovedVertices.insert(subgraphVertex)
                }
            }
        }

        // If a new vertex is too close to an existing original edge, remove
        // that new vertex. It's safe to remove an already removed vertex.
        for subgraphVertex in donnorSubgraph.allVertices {
            for originalEdge in originalEdges {
                let vertices = Array(originalEdge.vertices)
                let edgeIntersection = subgraphVertex.position.normalIntersectionWithLine(of: vertices[0].position, and: vertices[1].position)
                let distanceToEdge = subgraphVertex.position.distance(to: edgeIntersection)
                if distanceToEdge < Gene.maxDistanceToSplitEdge {
                    graphCopy.remove(vertex: subgraphVertex)
                    subgraphRemovedVertices.insert(subgraphVertex)
                }
            }
        }

        // If no vertices could be added, the operation failed.
        let addedVertices = Set(donnorSubgraph.allVertices).subtracting(subgraphRemovedVertices)
        if addedVertices.isEmpty { return false }

        // Connect new added vertices to from 1 to 3 vertices within range that
        // are outside the subgraph.
        for addedVertex in addedVertices {
            var newVertexConnections = 0
            let newVertexConnectionsLimit = Int.random(in: 1...3)
            for originalVertex in originalVertices {
                if newVertexConnections == newVertexConnectionsLimit {
                    break }
                let distanceToVertex = addedVertex.position.distance(to: originalVertex.position)
                if Gene.connectionRange.contains(distanceToVertex) {
                    graphCopy.addEdge(
                        between: addedVertex,
                        and: originalVertex,
                        elasticity: Gene.edgeElasticity,
                        area: RandomCGFloat.normal(in: Gene.edgeAreaRange)
                    )
                    newVertexConnections += 1
                }
            }
        }

        // Checks if every singly-axis-evolution-fixed vertex is connected to
        // at least one other evolution fixed vertex on the perpendicular axis
        // with a greater axis value and one with a smaller axis value. This
        // guarantees a continuous line across the evolution free axis.
        let singlyEvolutionFixedAxisVertices = graphCopy.allVertices.filter {
            if $0.isXEvolutionFixed && !$0.isYEvolutionFixed { return true }
            if $0.isYEvolutionFixed && !$0.isXEvolutionFixed { return true }
            return false
        }

        for vertex in singlyEvolutionFixedAxisVertices {
            if vertex.isXEvolutionFixed {
                let evolutionFixedNeighbors = graphCopy.neighbors(of: vertex).filter {
                    $0.isXEvolutionFixed
                }
                print(evolutionFixedNeighbors.count, "fixed neighbors")
                guard evolutionFixedNeighbors.contains(where: {
                    $0.position.y > vertex.position.y
                }) else { return false }
                guard evolutionFixedNeighbors.contains(where:  {
                    $0.position.y < vertex.position.y
                }) else { return false }
            }
            if vertex.isYEvolutionFixed {
                let evolutionFixedNeighbors = graphCopy.neighbors(of: vertex).filter {
                    $0.isYEvolutionFixed
                }
                guard evolutionFixedNeighbors.contains(where: {
                    $0.position.x > vertex.position.x
                }) else { return false }
                guard evolutionFixedNeighbors.contains(where: {
                    $0.position.x < vertex.position.x
                }) else { return false }
            }
        }

        // If the new graph with the addition of the subgraph is unstable or is
        // not solvable, cancel the operation. Otherwise, update the gene's
        // graph.
        if graphCopy.isUnstable() { return false }
        guard Simulation(graph: graphCopy).isSolvable() else { return false }
        
        graph = graphCopy
        return true
    }
}
