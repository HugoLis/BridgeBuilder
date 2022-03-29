//
//  Bridge.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 09/01/22.
//

import Foundation

/// Bridge class that contains a crucial random solvable bridge creator. Other types of bridges will inherit
/// from this class.
class Bridge: Gene {

    /// Y coordinate of the bridge floor.
    ///
    /// Used in `addLoadForces()` to determine the floor vertices, so they can receive load forces.
    let floorYPosition: CGFloat

    /// Creates a new bridge from a graph and a floor y position. Used to create copies of the bridge so
    /// there are no enforcement to verify the bridge is valid during initialization.
    /// - Parameters:
    ///   - graph: The graph o a bridge. Usually from a copy of another graph.
    ///   - floorYPosition: Y position of the floor of the bridge.
    init(graph: Graph, floorYPosition: CGFloat) {
        self.floorYPosition = floorYPosition
        super.init(graph: graph)
    }

    // Creates a random solvable  bridge with the given anchor points. All anchor
    // points are totally evolution fixed and simulation fixed on the y axis. Only
    // the first floor anchor point is also simulation fixed on the x axis.
    //
    // Having only one totally simulation-fixed point is a common practice when
    // developing bridge trusses, so the bridge has some room to expand
    // horizontally.
    /// - Parameters:
    ///   - floorSupports: Anchor points of the bridge floor. They must have the same y value.
    ///   - extraSupports: Extra anchor points of the bridge. They can be placed anywhere.
    init(floorSupports: [CGPoint], extraSupports: [CGPoint] = []) {
        assert(floorSupports.count >= 2, "Can't create a bridge with less than two floor support points.")
        assert(floorSupports.dropFirst().allSatisfy({ $0.y == floorSupports.first!.y }), "Can't create a bridge with floor supports with different y positions.")

        floorYPosition = floorSupports.first!.y

        // MARK: PART 1: Floor
        // Create floor line between floor supports.

        let graph = Graph()
        var floorSupportVertices: [Vertex] = []

        // Creates the floor support vertices in the graph.
        for floorSupport in floorSupports {
            // The first floor support is not only y simulation fixed, but also
            // x simulation fixed.
            let isXSimulationFixed = (floorSupport == floorSupports.first!) ? true : false
            let floorSupportVertex = graph.createVertex(
                position: floorSupport,
                isXSimulationFixed: isXSimulationFixed,
                isYSimulationFixed: true,
                isXEvolutionFixed: true,
                isYEvolutionFixed: true
            )
            floorSupportVertices.append(floorSupportVertex)
        }

        // Sorts the floor support vertices from left to right.
        floorSupportVertices.sort { $0.position.x < $1.position.x }

        // Connects the floor with edges, from left to right, by adding new
        // vertices in a connected horizontal line.
        var currentVertex = floorSupportVertices.first!
        for currentTarget in floorSupportVertices.dropFirst() {
            var didConnectToTarget = false
            while !didConnectToTarget {

                // Generates a random length for a new floor vertex and sums it
                // to the vertex to the left.
                let newXPosition = currentVertex.position.x + RandomCGFloat.reversedHalfNormal(in: Gene.connectionRange)

                // If the new vertex position does not reach the next target,
                // create a new connected vertex. Otherwise connect to the next
                // target if the distance between vertices is not too small.
                if newXPosition < currentTarget.position.x {
                    let newVertex = graph.createVertex(
                        position: CGPoint(x: newXPosition, y: currentVertex.position.y),
                        isYEvolutionFixed: true
                    )
                    graph.addEdge(
                        between: currentVertex,
                        and: newVertex,
                        elasticity: Gene.edgeElasticity,
                        area: Gene.edgeAreaRange.lowerBound
                    )
                    currentVertex = newVertex
                } else {
                    // If the new X position is too close to the target vertex,
                    // remove the last added vertex and edge and do not create a
                    // new edge. Otherwise, add an edge from the current vertex
                    // to the target.
                    if currentTarget.position.x - currentVertex.position.x >= Gene.minVertexDistance {
                        graph.addEdge(
                            between: currentVertex,
                            and: currentTarget,
                            elasticity: Gene.edgeElasticity,
                            area: Gene.edgeAreaRange.lowerBound
                        )
                        currentVertex = currentTarget
                        didConnectToTarget = true
                    } else {
                        if !currentVertex.isXEvolutionFixed &&  !currentVertex.isXEvolutionFixed {
                            let vertexToRemove = currentVertex
                            currentVertex = graph.neighbors(of: currentVertex).first!
                            graph.remove(vertex: vertexToRemove)
                        }
                    }
                }
            }
        }

        // Adds extra support vertices to the graph, as long as they are not too
        // close to the floor line segment
        var extraSupportVertices: [Vertex] = []
        for extraSupport in extraSupports {
            assert(extraSupport.distance(toLineSegmentOf: floorSupportVertices.first!.position, and: floorSupportVertices.last!.position) > Gene.minVertexDistance, "Extra support point is too close to the floor line of the bridge.")
            let newVertex = graph.createVertex(
                position: extraSupport,
                isYSimulationFixed: true,
                isXEvolutionFixed: true,
                isYEvolutionFixed: true
            )
            extraSupportVertices.append(newVertex)
        }

        // MARK: PART 2: Extra Supports
        // Create lines between extra supports and their nearest neighbors.

        // Connects the extra supports, one by one, to the closest vertex to them.
        for extraSupportVertex in extraSupportVertices {

            // The target vertex is the closest vertex to the extra support.
            let targetVertex = Set(graph.allVertices).subtracting(Set(extraSupportVertices)).min {
                extraSupportVertex.position.distance(to: $0.position) < extraSupportVertex.position.distance(to: $1.position)
            }!
            var currentVertex = extraSupportVertex
            var didConnectToTarget = false

            // Angle from current to target vertex.
            let angleToTarget = (targetVertex.position - currentVertex.position).angle

            while !didConnectToTarget {
                let positionOffset = PolarPoint(radius: RandomCGFloat.reversedHalfNormal(in: Gene.connectionRange), angle: angleToTarget).cgPoint
                let newPosition = currentVertex.position + positionOffset

                // If the new position does not pass over the target, create a
                // new vertex and connect it to the line. We check that by making
                // sure the angle between the new vertex and the target are still
                // the same and not 180º apart.
                let newAngle = (targetVertex.position - newPosition).angle
                if deltaAngle(a: newAngle, b: angleToTarget) < 0.1 {
                    let newVertex = graph.createVertex(position: newPosition)
                    graph.addEdge(
                        between: currentVertex,
                        and: newVertex,
                        elasticity: Gene.edgeElasticity,
                        area: Gene.edgeAreaRange.lowerBound
                    )
                    currentVertex = newVertex
                } else {
                    // If the new position is too close to the target vertex,
                    // remove the last added vertex and edge and do not create a
                    // new edge. Otherwise, add an edge from the current vertex
                    // to the target.
                    if newPosition.distance(to: targetVertex.position) >= Gene.minVertexDistance {
                        graph.addEdge(
                            between: currentVertex,
                            and: targetVertex,
                            elasticity: Gene.edgeElasticity,
                            area: Gene.edgeAreaRange.lowerBound
                        )
                        currentVertex = targetVertex
                        didConnectToTarget = true
                    } else {
                        if currentVertex != extraSupportVertex {
                            let vertexToRemove = currentVertex
                            currentVertex = graph.neighbors(of: currentVertex).first!
                            graph.remove(vertex: vertexToRemove)
                        }
                    }
                }
            }
        }

        // MARK: PART 3: Triangulation
        // Creates new vertices between the existing ones, so the graph becomes
        // mostly triangulated.

        // Skeleton vertices are vertices from the floor or extra supports lines.
        let skeletonVertices = graph.allVertices
        // Skeleton vertices are vertices from the floor or extra supports lines.
        let skeletonEdges = graph.allEgdes

        // This randomizers determine in which side of the line the new vertices
        // and edges will be created.
        let upDownRandomizer = Bool.random()
        let leftRightRandomizer = Bool.random()
        for skeletonEdge in skeletonEdges {
            let vertices = Array(skeletonEdge.vertices).sorted {
                if $0.position.x != $1.position.x {
                    return $0.position.x < $1.position.x
                } else {
                    return $0.position.y < $1.position.y
                }
            }
            let lineLength = RandomCGFloat.reversedHalfNormal(in: Gene.connectionRange.lowerBound...(Gene.connectionRange.upperBound * sqrt(3)/2))
            //let lineLength = RandomCGFloat.normal(in: Gene.connectionRange.lowerBound...(Gene.connectionRange.upperBound * sqrt(3)/2))
            //let lineLength = CGFloat.random(in: Gene.connectionRange.lowerBound...(Gene.connectionRange.upperBound * sqrt(3)/2))

            let verticesMiddle = (vertices[0].position + vertices[1].position)/2
            let verticesAngle = (vertices[1].position - vertices[0].position).angle
            var angleOffset: CGFloat
            if ((-0.00001)...0.00001).contains(verticesAngle) {
                angleOffset = upDownRandomizer ? -CGFloat.pi/2 : CGFloat.pi/2
            } else {
                angleOffset = leftRightRandomizer ? -CGFloat.pi/2 : CGFloat.pi/2
            }

            let newVertexAngle = verticesAngle + angleOffset
            let newVertexPosition = PolarPoint(radius: lineLength, angle: newVertexAngle).cgPoint + verticesMiddle

            // Get vertices within range. If a point is too close to another
            // vertex, cancel the operation.
            var verticesWithinRange: [Vertex] = []
            for vertex in graph.allVertices {
                let distanceToVertex = newVertexPosition.distance(to: vertex.position)

                // If the new vertex position would be too close to another vertex,
                // the new vertex cannot not be added.
                if distanceToVertex < Gene.connectionRange.lowerBound {
                    verticesWithinRange = []
                    break
                }

                if Gene.connectionRange.contains(distanceToVertex) {
                    verticesWithinRange.append(vertex)
                }
            }

            if verticesWithinRange.count >= 2 {
                let newVertex = graph.createVertex(position: newVertexPosition)
                for vertexWithinRange in verticesWithinRange {
                    graph.addEdge(between: newVertex, and: vertexWithinRange, elasticity: Gene.edgeElasticity, area: Gene.edgeAreaRange.lowerBound)
                }
            }
        }

        // MARK: PART 4: Assuring Solvability
        // Make sure the graph is solvable before creating the initial bridge.
        //
        // If after initial triangulation of the graph skelethon it is still not
        // solvable, keep adding random vertices near the skeleton until the
        // graph becomes solvable.
        //
        // This is only for safety, not sure if it's needed.
        while !Simulation(graph: graph).isSolvable() {
            let randomVertex = skeletonVertices.randomElement()!

            // Randomly chooses a point within possible connection range to the vertex.
            let randomDistance = CGFloat.random(in: Gene.connectionRange)
            let randomAngle = CGFloat.random(in: 0...(2 * .pi))
            let randomOffset = PolarPoint(radius: randomDistance, angle: randomAngle).cgPoint
            let newVertexPosition = randomVertex.position + randomOffset

            // If the new vertex is too close to an edge, we don't add the vertex
            // and we continue the while loop.
            for edge in graph.allEgdes {
                let vertices = Array(edge.vertices)
                let edgeIntersection = newVertexPosition.normalIntersectionWithLine(of: vertices[0].position, and: vertices[1].position)
                let distanceToEdge = newVertexPosition.distance(to: edgeIntersection)
                if distanceToEdge < Gene.maxDistanceToSplitEdge { continue }
            }

            // Stores all vertices within connection range to the point.
            // If the point is too close to another existing vertex, continue.
            var verticesWithinRange: [Vertex] = []
            for vertex in graph.allVertices {
                let distanceToVertex = newVertexPosition.distance(to: vertex.position)

                // If the new vertex position would be too close to another
                // vertex, the new vertex cannot not be added. We stop the for
                // loop and make vertices within range empty to continue the
                // while loop.
                if distanceToVertex < Gene.connectionRange.lowerBound {
                    verticesWithinRange = []
                    break
                }

                if Gene.connectionRange.contains(distanceToVertex) {
                    verticesWithinRange.append(vertex)
                }
            }

            // If there are at least to vertices within connection range to the
            // new vertex, we add the new vertex and connect it to the possible
            // vertices within connection range.
            if verticesWithinRange.count >= 2 {
                let newVertex = graph.createVertex(position: newVertexPosition)
                for vertexToConnect in verticesWithinRange {
                    graph.addEdge(between: newVertex, and: vertexToConnect, elasticity: Gene.edgeElasticity, area: Gene.edgeAreaRange.lowerBound)
                }
            }
        }

        super.init(graph: graph)
    }
}


// MARK: Adding Load

extension Bridge {

    /// Evenly distributes a load force through all floor vertices of the bridge that are not supports.
    /// - Parameter totalLoad: Total load on the bridge, in Newtons, pointing down.
    func addLoadForces(totalLoad: CGFloat) {
        let verticesToAddLoad = graph.allVertices.filter {
            let isFloor = abs($0.position.y - floorYPosition) < 0.0001
            let isSupport = $0.isXSimulationFixed || $0.isYSimulationFixed
            return isFloor && !isSupport
        }

        let vertexLoad = totalLoad / CGFloat(verticesToAddLoad.count)
        for vertex in verticesToAddLoad {
            if vertex.force == nil { vertex.force = CGVector() }
            vertex.force!.dy = vertex.force!.dy - vertexLoad
        }
    }

}
