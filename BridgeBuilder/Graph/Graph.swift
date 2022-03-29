//
//  Graph.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 21/12/21.
//

import Foundation

/// Undirected graph using adjacency list that represents a truss structure.
class Graph {

    /// Adjacency list of the graph. Vertices are the keys and the values are Edges of the key Vertex.
    var adjacencyList: [Vertex:[Edge]] = [:]

    /// Vertices of the graph, which are the keys of the adjacency list.
    var allVertices: [Vertex] {
        return Array(adjacencyList.keys)
    }

    /// All unique edges of the graph, which are the values of the adjacency list without duplicates.
    var allEgdes: [Edge] {
        // Get all values of the adjacency list
        let duplicatedEdges = Array(adjacencyList.values).flatMap { $0 }

        // Remove edges duplicates by converting the array to a set and then
        // back to an array.
        return Array(Set(duplicatedEdges))
    }

    /// Creates a new vertex with an empty array of edges on the adjacency list.
    /// - Parameter position: position of the vertex.
    /// - Parameters:
    ///   - position: Position of the vertex.
    ///   - isXSimulationFixed: True if the x coordinate of the vertex should be fixed during
    ///     simulation. Defaults to false.
    ///   - isYSimulationFixed: True if the x coordinate of the vertex should be fixed during
    ///     simulation. Defaults to false.
    ///   - isXEvolutionFixed: If true, keeps the y coordinate of the vertex constant during evolutionary
    ///     modifications. Defaults to false.
    ///   - isYEvolutionFixed: If true, keeps the y coordinate of the vertex constant during evolutionary
    ///     modifications. Defaults to false.
    ///   - force: Force to be applied to the vertex during simulation. Defaults to nil and should not be
    ///     this way unless when copying a vertex.
    ///   - id: ID of the vertex. Defaults to nil, so a random identifier will be created. Should not be
    ///     touched unless when creating a copy of the graph.
    /// - Returns: The newly created vertex.
    func createVertex(
            position: CGPoint,
            isXSimulationFixed: Bool = false,
            isYSimulationFixed: Bool = false,
            isXEvolutionFixed: Bool = false,
            isYEvolutionFixed: Bool = false,
            force: CGVector? = nil,
            id: UUID? = nil
    ) -> Vertex {
        let vertex = Vertex(
            position: position,
            isXSimulationFixed: isXSimulationFixed,
            isYSimulationFixed: isYSimulationFixed,
            isXEvolutionFixed: isXEvolutionFixed,
            isYEvolutionFixed: isYEvolutionFixed,
            force: force,
            id: id
        )
        adjacencyList[vertex] = []
        return vertex
    }

    /// Returns the edges for a given edge of the graph
    /// - Parameter vertex: The vertex of which we want to find it's edges.
    func edges(of vertex: Vertex) -> [Edge] {
        return adjacencyList[vertex] ?? []
    }

    /// Returns all neighbors of a vertex.
    /// - Parameter vertex: Vertex we want to find its neighbors.
    /// - Returns: Neighbors of the given vertex.
    func neighbors(of vertex: Vertex) -> [Vertex] {
        let edges = edges(of: vertex)
        return edges.map { vertex.neighbor(fromEdge: $0) }
    }

    /// Checks if two vertices share an edge (are neighbors).
    ///
    /// Order of parameters is not really important, but we iterate through neighbors of vertex A trying to
    /// find if vertex B is present.
    /// - Parameters:
    ///   - vertexA: A vertex.
    ///   - vertexB: Another vertex.
    /// - Returns: True if given vertices are neighbors. Otherwise false.
    func areVerticesNeighbors(_ vertexA: Vertex, _ vertexB: Vertex) -> Bool {
        for edge in edges(of: vertexA) {
            if vertexA.neighbor(fromEdge: edge) == vertexB { return true }
        }
        return false
    }

    /// Removes a vertex and all of its edges from the graph.
    /// - Parameter vertex: Vertex to be removed.
    func remove(vertex: Vertex) {
        // Removes all edges of the vertex from the adjacency list.
        for edge in adjacencyList[vertex] ?? [] {
            remove(edge: edge)
        }
        // Then removes the vertex itself from the adjacency list.
        adjacencyList.removeValue(forKey: vertex)
    }

    /// Adds an undirected edge between two vertices. Order of vertices doesn't matter.
    /// - Parameters:
    ///   - vertexA: A vertex to be connected.
    ///   - vertexB: Another vertex to be connected.
    ///   - elasticity: Elasticity (Young's modulus) of the edge.
    ///   - area: Cross sectional area of the edge.
    func addEdge(between vertexA: Vertex, and vertexB: Vertex, elasticity: Double, area: Double) {
        let edge = Edge(vertexA: vertexA, vertexB: vertexB, elasticity: elasticity, area: area)
        sanityCheck(newEdge: edge)

        adjacencyList[vertexA]?.append(edge)
        adjacencyList[vertexB]?.append(edge)
    }

    /// Performs various sanity checks before adding a new edge to the graph.
    /// - Parameter edge: New edge that we want to sanity check before adding it to the graph.
    private func sanityCheck(newEdge edge: Edge) {
        let vertices = Array(edge.vertices)

        assert(vertices.count == 2, "Tried to create a new edge with \(vertices.count) vertices. All edges must have exactly 2 vertices.")

        let vertexA = vertices[0]
        let vertexB = vertices[1]

        assert(vertexA != vertexB, "Tried to create an edge from a vertex to itself, which doesn't makes sense.")
        assert(adjacencyList[vertexA] != nil, "Tried to create an edge for a node that was not created yet. Use `createVertex(…)` to do that.")
        assert(adjacencyList[vertexB] != nil, "Tried to create an edge for a node that was not created yet. Use `createVertex(…)` to do that.")

        for edgeA in adjacencyList[vertexA] ?? [] {
            assert(edgeA.vertices != edge.vertices, "Tried to create more the one edge with same vertices." )
        }
        for edgeB in adjacencyList[vertexB] ?? [] {
            assert(edgeB.vertices != edge.vertices, "Tried to create more the one edge with same vertices." )
        }
    }

    /// Removes an edge between two vertices. Order of vertices doesn't matter.
    /// If the edge does not exist, then nothing is done.
    /// - Parameter edge: edge to be removed from the graph.
    func remove(edge: Edge) {
        for vertex in edge.vertices {
            adjacencyList[vertex] = adjacencyList[vertex]?.filter { $0 != edge }
        }
    }


    /// Prints connections between vertices of the graph using their short IDs. Does not show position.
    func printConnections() {
        for vertex in adjacencyList.keys {
            let terminator = (adjacencyList[vertex] ?? [] != []) ? "" : "\n"
            print("\(vertex.shortID): ", terminator: terminator)
            for edge in adjacencyList[vertex] ?? [] {
                let vertices = Array(edge.vertices)
                let destination = (vertices[0] == vertex) ? vertices[1] : vertices [0]
                print("\(destination.shortID)", terminator: "")
                if edge != adjacencyList[vertex]?.last {
                    print(" > ", terminator: "")
                } else { print("") }
            }
        }
    }
}

//MARK: - Testing Rigidness
extension Graph {
    /// Checks if `edges + reaction forces < 2 * vertices`, which can tell us if some graphs
    /// (trusses) are unstable for sure. We assume 3 reaction forces, which is the worst case.
    /// - Returns: True if the graph is unstable. False if we are not sure about
    ///   the stability of the graph.
    func isUnstable() -> Bool {
        let edges = allEgdes.count
        let vertices = allVertices.count

        // 3 is the minimum required value. If the test can pass with 3, it can
        // also pass with more forces. Alternatively, we could count the total
        // simulation fixed x's and y's of the vertices.
        let reactionForces = 3
        return edges + reactionForces < 2 * vertices
    }

    /// Checks if two vertices (origin and target) from the graph are second degree neighbors. This means there
    /// is one third vertex that connects the origin and the target vertices.
    /// - Parameters:
    ///   - origin: Origin vertex.
    ///   - target: Target vertex.
    /// - Returns: True if the input vertices are second degree neighbors. Otherwise, returns false.
    private func areVerticesSecondNeighbors(origin: Vertex, target: Vertex) -> Bool {
        for neighbor in neighbors(of: origin) {
            let secondNeighbors = neighbors(of: neighbor)
            for secondNeighbor in secondNeighbors {
                if secondNeighbor == target { return true }
            }
        }
        return false
    }

    /// Checks if a vertex is fully triangulated. This means all of its neighbors are also second degree
    /// neighbors and, thus, all form triangles with the vertex.
    /// - Parameter vertex: Input vertex
    /// - Returns: True if the vertex is triangulated. Otherwise, returns false.
    func isVertexTriangulated(_ vertex: Vertex) -> Bool {
        // Every neighbor of a vertex must have a path of depth 2 back to the
        // originator vertice.
        let neighbors = neighbors(of: vertex)
        guard !neighbors.isEmpty else { return false }

        for neighbor in neighbors {
            if !areVerticesSecondNeighbors(origin: neighbor, target: vertex) {
                return false
            }
        }
        return true
    }

    /// Checks if the graph is triangulated by assuring that every vertex of the graph is triangulated as well.
    ///
    /// This method is not very optimized.
    /// - Returns: True is the graph is triangulated. Otherwise, false.
    func isTriangulated() -> Bool {
        let vertices = allVertices
        guard !vertices.isEmpty else { return false }

        for vertex in allVertices {
            if !isVertexTriangulated(vertex) {
                return false
            }
        }
        return true
    }
}

// MARK: Copy
extension Graph {

    /// Creates a graph copy by value, including the IDs of the vertices from the original graph.
    /// - Returns: A copy by value of the graph that has no references to the original object.
    func copy() -> Graph {
        let graphCopy = Graph()

        // A dictionary that relates an original vertex to its copy. Used to
        // create edges copies with reference to the new vertices instead of the
        // original ones.
        var originalToCopyVertices: [Vertex:Vertex] = [:]

        // Creates all vertices copies in the graph copy and relates them to
        // their original versions in the originalToCopy dictionary.
        for vertex in allVertices {
            let vertexCopy = graphCopy.createVertex(
                position: vertex.position,
                isXSimulationFixed: vertex.isXSimulationFixed,
                isYSimulationFixed: vertex.isYSimulationFixed,
                isXEvolutionFixed: vertex.isXEvolutionFixed,
                isYEvolutionFixed: vertex.isYEvolutionFixed,
                force: vertex.force,
                id: vertex.id
            )
            originalToCopyVertices[vertex] = vertexCopy
        }

        // Creates all edges using the copy vertices from the originalToCopy
        // dictionary.
        for edge in allEgdes {
            let vertices = Array(edge.vertices)
            graphCopy.addEdge(
                between: originalToCopyVertices[vertices[0]]!,
                and: originalToCopyVertices[vertices[1]]!,
                elasticity: edge.elasticity,
                area: edge.area
            )
        }

        return graphCopy
    }
}


// MARK: Resetting Forces

extension Graph {

    /// Sets all vertices forces to nil.
    func resetForces() {
        for vertex in allVertices { vertex.force = nil }
    }
}

// MARK: Bounding Box
extension Graph {

    /// Gets the bounding box of a graph with a given proportional margin.
    /// - Parameter margin: Multiplier to the sides of the bounding box.
    /// - Returns: An array with 4 elements [minX, maxX, minY, maxY].
    ///

    /// Gets the bounding box of a graph with a given proportional margin and
    /// desired aspect ratio.
    /// - Parameters:
    ///   - margin: Multiplier to the sides of the bounding box.
    ///   - ratio: Desired aspect ratio of the plot (width/height), by fitting
    ///     the bounding box in it.
    /// - Returns: An array with 4 elements [minX, maxX, minY, maxY].
    func getBoundingBox(margin: CGFloat = 4/3, ratio: CGFloat = 4/3) -> [CGFloat] {

        var minX = allVertices.map { $0.position.x }.min { $0 < $1 }!
        var maxX = allVertices.map { $0.position.x }.max { $0 < $1 }!
        var minY = allVertices.map { $0.position.y }.min { $0 < $1 }!
        var maxY = allVertices.map { $0.position.y }.max { $0 < $1 }!

        var deltaX = maxX - minX
        var deltaY = maxY - minY

        let boxRatio = deltaX/deltaY
        if boxRatio > ratio {
            deltaY = deltaX / ratio
        } else {
            deltaX = deltaY * ratio
        }

        let midX = (minX + maxX)/2
        let midY = (minY + maxY)/2

        deltaX *= margin
        deltaY *= margin

        minX = midX - deltaX/2
        maxX = midX + deltaX/2
        minY = midY - deltaY/2
        maxY = midY + deltaY/2

        return [minX, maxX, minY, maxY]
    }
}

/*
 //Graph basic usage
 let graph = Graph()

 let v1 = graph.createVertex(position: CGPoint(x: -10, y: -10))
 let v2 = graph.createVertex(position: CGPoint(x: 20, y: 20))
 let v3 = graph.createVertex(position: CGPoint(x: 30, y: -50))
 let v4 = graph.createVertex(position: CGPoint(x: -80, y: 0))

 graph.addUndirectedEdge(between: v1, and: v2)
 graph.addUndirectedEdge(between: v1, and: v3)
 graph.addUndirectedEdge(between: v1, and: v4)
 graph.addUndirectedEdge(between: v2, and: v4)

 graph.printConnections()
 graph.removeUndirectedEdge(between: v1, and: v2)
 graph.printConnections()
 */
