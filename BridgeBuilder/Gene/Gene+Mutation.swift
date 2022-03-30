//
//  Gene+Mutation.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 22/02/22.
//

// This file contains multiple Gene extensions for mutation, like moving, adding
// and removing edges and vertices.

import Foundation
import CoreGraphics

// MARK: Vertices Within Range

extension Gene {

    /// Gets all vertices within range to a point. If there is a vertex too close to the point, nil will be returned.
    /// - Parameters:
    ///   - point: Position that vertices will be checked against to determine if they are
    ///     within range to it.
    ///   - verticesToIgnore: Vertices from the graph to ignore while finding vertices within range.
    ///     This is used to prevent the function from finding a vertex too close to the point when trying to
    ///     find vertices within range to another vertex from the graph, for example.
    /// - Returns: Vertices within range the point. Or nil if there is at least one vertex too close to the point.
    private func getVerticesWithinRange(to point: CGPoint, of graph: Graph, ignoring verticesToIgnore: [Vertex] = []) -> [Vertex]? {
        // Stores all vertices within connection range to the point.
        // If the point is too close to another existing vertex, return nil.
        var verticesWithinRange: [Vertex] = []

        for vertex in Set(graph.allVertices).subtracting(Set(verticesToIgnore)) {
            let distanceToVertex = point.distance(to: vertex.position)

            // If the new vertex position would be too close to another vertex,
            // the new vertex cannot not be added.
            if distanceToVertex < Gene.connectionRange.lowerBound { return nil }

            if Gene.connectionRange.contains(distanceToVertex) {
                verticesWithinRange.append(vertex)
            }
        }
        return verticesWithinRange
    }
}

//MARK: - Vertex Addition

extension Gene {
    /// Creates a random new vertex connected to at least two other vertices respecting maximum edge
    /// length and minimum distance between vertices.
    /// - Parameter shouldIgnoreSolvability: If true, does not check if graph is solvable
    ///   after the operation. Defaults to false.
    func addRandomVertex(shouldIgnoreSolvability: Bool = false) {
        var didCreateVertex = false
        var counter = 0
        while !didCreateVertex {
            didCreateVertex = tryToAddRandomVertex(shouldIgnoreSolvability: shouldIgnoreSolvability)

            counter += 1
            if counter >= Gene.tryoutLimit {
                if Gene.logFailures {
                    print("Gene.addRandomVertex(). Failed too many times while trying to add a random vertex.")
                }
                return
            }
        }
    }

    /// Tries to add a new vertex to the graph by spliting an existing edge. The newly created vertex is
    /// connected to other vertices within range maintaining some preexiting properties, like simulation
    /// fixed axis and edge area.
    /// - Parameters:
    ///   - edge: Edge that will be split. Actually it is removed and replaced by
    ///     other two edges connected to the desired position
    ///   - position: The position of the new vertex. Expected to be on the
    ///     original edge line.
    ///   - graph: Graph which we will try to add the vertex to.
    ///   - shouldIgnoreSolvability: If true, does not check if graph is solvable
    ///     after the operation. Defaults to false.
    /// - Returns: A graph with the new vertex if the operation was successful.
    ///   Otherwise, nil.
    private func tryToAddVertexBySplitting(edge: Edge, at position: CGPoint, of graph: Graph, shouldIgnoreSolvability: Bool = false) -> Graph? {
        // Stores all vertices within connection range to the new vertex position.
        // If the new vertex would be too close to another existing vertex, the
        // vertices array will be nil and the operation will be cancelled.
        guard let verticesWithinRange = getVerticesWithinRange(to: position, of: graph) else {
            return nil
        }

        // There should be at least 3 vertices within range of the new vertex.
        // Two of these are the vertices of the original edge, and at least one
        // more connection will be required for triangulation of the new vertex.
        // More than 3 connections may be needed, so a vertex triangulation check
        // will be performed before adding the new vertex.
        guard verticesWithinRange.count >= 3 else { return nil }

        assert(edge.vertices.isSubset(of: Set(verticesWithinRange)), "Original vertices of edge that would be split are not part of vertices within connection range of the new vertex.")
        //Original edge vertices.
        let edgeVertices = Array(edge.vertices)

        // Vertices to connect to new vertex, not including original edge vertices.
        let verticesToConnect = verticesWithinRange.filter {
            $0 != edgeVertices[0] && $0 != edgeVertices[1]
        }

        let graphCopy = graph.copy()
        graphCopy.remove(edge: edge)

        let isXEvolutionFixed = edgeVertices.allSatisfy { $0.isXEvolutionFixed }
        let isYEvolutionFixed = edgeVertices.allSatisfy { $0.isYEvolutionFixed }

        let newVertex = addVertex(to: graphCopy, at: position, connectedTo: verticesToConnect, withXEvolutionFixed: isXEvolutionFixed, withYEvolutionFixed: isYEvolutionFixed)

        // Adds connection from new vertex to original edge vertice, maintaining
        // original edge area.
        graphCopy.addEdge(between: newVertex, and: edgeVertices[0], elasticity: Gene.edgeElasticity, area: edge.area)
        graphCopy.addEdge(between: newVertex, and: edgeVertices[1], elasticity: Gene.edgeElasticity, area: edge.area)

        // Checks if the graph copy is rigid before assigning it to the gene graph.
        // If it is not rigid, cancel the operation.
        if !shouldIgnoreSolvability {
            if graphCopy.isUnstable() { return nil }
            guard graphCopy.isVertexTriangulated(newVertex) else { return nil }
            guard Simulation(graph: graphCopy).isSolvable() else { return nil }
        }

        return graphCopy
    }

    /// Tries to create a random new vertex connected to at least two other vertices respecting maximum
    /// edge length and minimum distance between vertices.
    /// - Parameter shouldIgnoreSolvability: If true, does not check if graph is solvable
    ///   after the operation. Defaults to false.
    /// - Returns: True if a vertex was successfully created. False it fails to do so.
    private func tryToAddRandomVertex(shouldIgnoreSolvability: Bool = false) -> Bool {
        let graphCopy = graph.copy()

        // Randomly chooses a vertex, if the graph is not empty
        guard let randomVertex = graphCopy.allVertices.randomElement() else { return false }

        // Randomly chooses a point within possible connection range to the vertex.
        let randomDistance = CGFloat.random(in: Gene.connectionRange)
        let randomAngle = CGFloat.random(in: 0...(2 * .pi))
        let randomOffset = PolarPoint(radius: randomDistance, angle: randomAngle).cgPoint
        let newVertexPosition = randomVertex.position + randomOffset

        // Stores all vertices within connection range to the new vertex position.
        // If the new vertex would be too close to another existing vertex, the
        // vertices array will be nil and the operation will be cancelled.
        guard var verticesWithinRange = getVerticesWithinRange(to: newVertexPosition, of: graphCopy) else {
            return false
        }

        // If the new vertex is too close to an edge, try to add the vertex by
        // spliting the existing edge and connecting it to at least two vertices.
        for edge in graphCopy.allEgdes {
            let vertices = Array(edge.vertices)
            let edgeIntersection = newVertexPosition.normalIntersectionWithLine(of: vertices[0].position, and: vertices[1].position)
            let distanceToEdge = newVertexPosition.distance(to: edgeIntersection)
            if distanceToEdge < Gene.maxDistanceToSplitEdge {
                if let newGraph = tryToAddVertexBySplitting(edge: edge, at: edgeIntersection, of: graphCopy) {
                    graph = newGraph
                    return true
                } else {
                    return false
                }
            }
        }

        // If there are less than two possible connections to the new vertex,
        // the new vertex cannot not be added.
        guard verticesWithinRange.count >= 2 else { return false }

        // Sorts vertices within range according to their distances to the new
        // vertex position.
        verticesWithinRange.sort {
            $0.position.distance(to: newVertexPosition) < $1.position.distance(to: newVertexPosition)
        }

        // Creates array of vertices to connect with at least the closest two
        // vertices whitin range to the new vertex position.
        var verticesToConnect = verticesWithinRange[...1]
        verticesWithinRange.removeFirst(2)

        // Connects to a random number of additional vertices.
        //let additionalVerticesToConnect = RandomInt.reversedHalfNormal(in: 0...verticesWithinRange.count)
        //let additionalVerticesToConnect = Int.random(in: 0...verticesWithinRange.count)
        let additionalVerticesToConnect = RandomInt.normal(in: 0...verticesWithinRange.count)
        if additionalVerticesToConnect > 0 {
            for _ in 1...additionalVerticesToConnect {
                verticesToConnect.append(verticesWithinRange.removeFirst())
            }
        }
        addVertex(to: graphCopy, at: newVertexPosition, connectedTo: Array(verticesToConnect))

        // If the new graph is solvable, assign it to the gene's graph and return
        // true. Otherwise, cancel the operation and return false.
        if !shouldIgnoreSolvability {
            guard Simulation(graph: graph).isSolvable() else { return false }
        }
        graph = graphCopy
        return true
    }

    /// Adds a vertex to a graph at a given position and connect the edge with other given existing vertices.
    /// - Parameters:
    ///   - graph: Graph to which the vertex will be added. Defaults to nil, so the Gene graph is used.
    ///   - position: Position of the new vertex.
    ///   - vertices: Vertices to be connected to the new vertex.
    ///   - isXEvolutionFixed: True if the new vertex x cordinate is evolution fixed. Defaults to false.
    ///   - isYEvolutionFixed: True if the new vertex y cordinate is evolution fixed. Defaults to false.
    @discardableResult
    private func addVertex(
        to graph: Graph? = nil,
        at position: CGPoint,
        connectedTo vertices: [Vertex],
        withXEvolutionFixed isXEvolutionFixed: Bool = false,
        withYEvolutionFixed isYEvolutionFixed: Bool = false
    ) -> Vertex {

        let graph = graph ?? self.graph
        let newVertex = graph.createVertex(
            position: position,
            isXEvolutionFixed: isXEvolutionFixed,
            isYEvolutionFixed: isYEvolutionFixed
        )

        for vertex in vertices {
            graph.addEdge(between: newVertex, and: vertex, elasticity: Gene.edgeElasticity, area: CGFloat.random(in: Gene.edgeAreaRange))
        }
        return newVertex
    }
}


// MARK: - Vertex Removal

extension Gene {

    func removeRandomVertex() {
        var didRemoveVertex = false
        var counter = 0
        while !didRemoveVertex {
            didRemoveVertex = tryToRemoveRandomVertex()

            counter += 1

            if counter >= Gene.tryoutLimit {
                if Gene.logFailures {
                    print("Gene.removeRandomVertex(). Failed too many times while trying to remove a random vertex. Probably there is no vertex that can be removed while maintaining a rigid structure.")
                }
                return
            }
        }
    }

    /// Tries to remove a random vertex while protecting simulation fixed vertices and trying to connect
    /// evolution fixed neighbors of evolution fixed edges to be removed.
    /// - Returns: True if the vertex was removed. False if the operation was canceled.
    private func tryToRemoveRandomVertex() -> Bool {
        // Get a random vertex if the graph if the graph is not empty.
        guard let vertex = graph.allVertices.randomElement() else { return false }

        // Make sure not to delete any of our simulation fixed points. They are
        // needed anchors for the truss.
        if vertex.isXSimulationFixed || vertex.isYSimulationFixed { return false }

        if vertex.isXEvolutionFixed && vertex.isYEvolutionFixed { return false }

        if vertex.isXEvolutionFixed || vertex.isYEvolutionFixed {
            // Tries to remove vertex and connect evolution fixed neighbors.
            return tryToRemoveEvolutionFixedVertex(vertex)
        }

        let neighbors = graph.neighbors(of: vertex)
        let graphCopy = graph.copy()
        graphCopy.remove(vertex: vertex)

        //Checks if the graph copy is rigid before assigning it to the gene graph.
        if graphCopy.isUnstable() { return false }
        for neighbor in neighbors {
            guard graphCopy.isVertexTriangulated(neighbor) else { return false }
        }
        guard Simulation(graph: graphCopy).isSolvable() else { return false }

        graph = graphCopy
        return true
    }

    /// Tries to remove a simulation fixed vertex and connect its evolution fixed neighbors
    /// - Parameter vertex: X or y simulation fixed vertex to be removed.
    /// - Returns: True if the removal of the vertex and connection of evolution fixed neighbors was
    ///   performed. returns false if the operation could not be performed.
    private func tryToRemoveEvolutionFixedVertex(_ vertex: Vertex) -> Bool {
        let neighbors = graph.neighbors(of: vertex)
        var evolutionFixedNeighbors: [Vertex] = []

        if vertex.isXEvolutionFixed {
            evolutionFixedNeighbors = neighbors.filter { $0.isXEvolutionFixed }
        }
        if vertex.isYEvolutionFixed {
            evolutionFixedNeighbors = neighbors.filter { $0.isYEvolutionFixed }
        }

        if evolutionFixedNeighbors.count < 2 { return false }
        assert(evolutionFixedNeighbors.count >= 2, "Has \(evolutionFixedNeighbors.count) x evolution fixed neighbors. The expected value is 2.")

        // Get mean area of the edges from vertex to the other 2 simulation
        // fixed vertices.
        let evolutionFixedEdges = graph.edges(of: vertex).filter {
            $0.vertices.contains(evolutionFixedNeighbors[0]) ||
            $0.vertices.contains(evolutionFixedNeighbors[1])
        }
        let meanEdgeArea = (evolutionFixedEdges[0].area + evolutionFixedEdges[1].area)/2

        // Remove the vertex and its edges on the graph copy.
        let graphCopy = graph.copy()
        graphCopy.remove(vertex: vertex)

        // If the distance between the evolution fixed vertices is within range
        // and the vertices are not already connected, add the edge.
        guard evolutionFixedNeighbors[0].position.distance(to: evolutionFixedNeighbors[1].position) <= Gene.maxEdgeLength else { return false }

        if !graph.areVerticesNeighbors(evolutionFixedNeighbors[0], evolutionFixedNeighbors[1]) {
            graphCopy.addEdge(between: evolutionFixedNeighbors[0], and: evolutionFixedNeighbors[1], elasticity: Gene.edgeElasticity, area: meanEdgeArea)
        }

        // Check if all original neighbors of the removed vertex are still
        // rigid before assigning the graph copy to the gene graph. If
        // vertices are not fully triangulated, cancel the operation.
        //
        // Check if is unstable won't hurt but is not really needed. In the end
        // we are removing 1 edge and 1 vertex. So the graph will pass the test.
        if graphCopy.isUnstable() { return false }
        for neighbor in neighbors {
            guard graphCopy.isVertexTriangulated(neighbor) else { return false }
        }
        guard Simulation(graph: graphCopy).isSolvable() else { return false }

        graph = graphCopy
        return true
    }
}


// MARK: - Edge Addition

extension Gene {

    /// Adds a random edge between two vertices within connection range that weren't previously connected.
    func addRandomEdge() {
        var didAddEdge = false
        var counter = 0
        while !didAddEdge {
            didAddEdge = tryToAddRandomEdge()

            counter += 1
            if counter >= Gene.tryoutLimit {
                if Gene.logFailures {
                    print("Gene.addRandomEdge(). Failed too many times while trying to add a random edge. Probably all vertices within range are already connected.")
                }
                return
            }
        }
    }

    /// Tries to add a random edge to the graph while respecting connection range.
    /// - Parameter avoidOverlaidEdges: If true, avoids connection of evolution fixed vertices on
    ///   the same axis, since this would create an edge right over other existing edges. Defaults to false
    ///   since I believe usualy overlaid edges are a bad structural  design and can cause visual confusion.
    /// - Returns: True if the operation succeeds. Otherwise false.
    private func tryToAddRandomEdge(avoidOverlaidEdges: Bool = true) -> Bool {

        // Chooses a random vertex if the graph is not empty.
        guard let randomVertex = graph.allVertices.randomElement() else { return false }

        // Finds vertices within connection range to the random vertex that are
        // not connected to the random vertex yet.
        guard let verticesWithinRange = getVerticesWithinRange(to: randomVertex.position, of: graph, ignoring: [randomVertex]) else {
            return false
        }
        let possibleVerticesToConnect = verticesWithinRange.filter {
            !graph.areVerticesNeighbors(randomVertex, $0)
        }

        // If the array of possibles vertices to connect is not empty, chooses a
        // vertex to be connected to the random vertex.
        guard let vertexToConnect = possibleVerticesToConnect.randomElement() else {
            return false
        }

        // To prevent overlaid edges, to not connect edges that have the same
        // axis evolution fixed.
        if avoidOverlaidEdges {
            if randomVertex.isXEvolutionFixed && vertexToConnect.isXEvolutionFixed { return false }
            if randomVertex.isYEvolutionFixed && vertexToConnect.isYEvolutionFixed { return false }
        }

        graph.addEdge(between: randomVertex, and: vertexToConnect, elasticity: Gene.edgeElasticity, area: RandomCGFloat.normal(in: Gene.edgeAreaRange))
        return true
    }
}


// MARK: - Edge Removal

extension Gene {

    /// Removes a random edge from the graph while maintaining all vertices triangulated.
    func removeRandomEdge() {
        var didRemoveEdge = false
        var counter = 0
        while !didRemoveEdge {
            didRemoveEdge = tryToRemoveRandomEdge()

            counter += 1
            if counter >= Gene.tryoutLimit {
                if Gene.logFailures {
                    print("Gene.removeRandomEdge(). Failed too many times while trying to remove a random edge. Probably there is no edge that can be removed while maintaining a rigid structure.")
                }
                return
            }
        }
    }

    /// Tries to remove a random edge from the graph while maintaining all vertices triangulated.
    /// - Returns: True if the operation succeeds. Otherwise false.
    private func tryToRemoveRandomEdge() -> Bool {
        // Chooses a random edge form the graph if the graph is not empty.
        guard let randomEdge = graph.allEgdes.randomElement() else { return false }

        let vertices = Array(randomEdge.vertices)

        // If both vertices are evolution fixed, the edge should not be removed.
        // Note that anchor points should be fully evolution fixed and have at
        // least one simulation fixed axis.
        if vertices[0].isXEvolutionFixed && vertices[1].isXEvolutionFixed { return false }
        if vertices[0].isYEvolutionFixed && vertices[1].isYEvolutionFixed { return false }

        let graphCopy = graph.copy()
        graphCopy.remove(edge: randomEdge)

        //Checks if the graph copy is rigid before assigning it to the gene graph.
        if graphCopy.isUnstable() { return false }
        for vertex in vertices {
            guard graphCopy.isVertexTriangulated(vertex) else { return false }
        }
        guard Simulation(graph: graphCopy).isSolvable() else { return false }

        graph = graphCopy
        return true
    }
}


// MARK: - Vertex Movement

extension Gene {

    /// Moves a random vertex while respecting its evolution fixed axis and keeping all of its neighbors
    /// within connection range.
    func moveRandomVertex() {
        var didMoveVertex = false
        var counter = 0
        while !didMoveVertex {
            didMoveVertex = tryToMoveRandomVertex()

            counter += 1
            if counter >= Gene.tryoutLimit {
                if Gene.logFailures {
                    print("Gene.moveRandomVertex(). Failed too many times while trying to move a random vertex. Probably there is no vertex that can be moved while maintaining its neighbors within connection range.")
                }
                return
            }
        }
    }

    /// Tries to move a random vertex while respecting its evolution fixed axis and keeping all of its neighbors
    /// within connection range.
    /// - Returns: True if a vertex was moved. False if the operation could not be completed.
    private func tryToMoveRandomVertex() -> Bool {

        // Chooses a random vertex if the graph is not empty.
        guard let randomVertex = graph.allVertices.randomElement() else { return false }

        // If the vertex position is completely evolution fixed, cancel the
        // operation.
        if randomVertex.isXEvolutionFixed && randomVertex.isYEvolutionFixed { return false }

        // Saves position of random vertex before trying to move it.
        let originalPosition = randomVertex.position

        // Randomly creates a position offset. The radius is a random number
        // between 0 and the max edge length following a half normal distribution,
        // so changes are smoother.
        var offset = PolarPoint(
            radius: RandomCGFloat.halfNormal(in: 0...Gene.maxEdgeLength),
            angle: CGFloat.random(in: 0...(2 * .pi))
        ).cgPoint

        // Constrains offset according to evolution fixed axis of the random vetex.
        if randomVertex.isXEvolutionFixed { offset.x = 0 }
        if randomVertex.isYEvolutionFixed { offset.y = 0 }

        // Adds the position offset to the random vertex before checking if the
        // new position is valid.
        randomVertex.position = randomVertex.position + offset

        // Checks if all neighbors of the random vertex are still within connection
        // range. If they are, return true. If they aren't, reset the vertex
        // position to its original value and cancel the operation.
        for neighbor in graph.neighbors(of: randomVertex) {
            let distanceToNeighbor = randomVertex.position.distance(to: neighbor.position)
            if !Gene.connectionRange.contains(distanceToNeighbor) {
                randomVertex.position = originalPosition
                return false
            }
        }
        return true
    }
}


// MARK: - Vary Edge Area

extension Gene {

    /// Changes the the area of a random edge while keeping it within the edge area range.
    func varyRandomEdgeArea() {
        // Chooses a random edge if the graph is not empty
        guard let randomEdge = graph.allEgdes.randomElement() else { return }

        // Randomly chooses an area offset subtracted by the current edge area.
        // So, when it's added to the current edge area, the resulting value is
        // within the edge area range.
        let areaOffset = RandomCGFloat.halfNormal(in: Gene.edgeAreaRange) - randomEdge.area
        randomEdge.area += areaOffset
    }
}

