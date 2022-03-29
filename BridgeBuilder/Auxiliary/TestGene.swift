//
//  TestGene.swift
//  GeneticBuilder
//
//  Created by Hugo on 21/01/22.
//

import Foundation

/// Class with sample genes used for testing purposes.
class TestGene {
    static func gambrel() -> Gene {
        let e = 29e6
        let a = 0.1

        let graph = Graph()
        let n1 = graph.createVertex(position: CGPoint(x: 0, y: 0), isXSimulationFixed: true, isYSimulationFixed: true, isXEvolutionFixed: true, isYEvolutionFixed: true)
        let n2 = graph.createVertex(position: CGPoint(x: 8*12, y: 6*12))
        let n3 = graph.createVertex(position: CGPoint(x: 8*12, y: 0), isYEvolutionFixed: true)
        let n4 = graph.createVertex(position: CGPoint(x: 16*12, y: 8*12+4))
        let n5 = graph.createVertex(position: CGPoint(x: 16*12, y: 0), isYEvolutionFixed: true)
        let n6 = graph.createVertex(position: CGPoint(x: 24*12, y: 6*12))
        let n7 = graph.createVertex(position: CGPoint(x: 24*12, y: 0), isYEvolutionFixed: true)
        let n8 = graph.createVertex(position: CGPoint(x: 32*12, y: 0), isYSimulationFixed: true, isXEvolutionFixed: true, isYEvolutionFixed: true)

        let load = 2000
        n3.force = CGVector(dx: 0, dy: -load/3)
        n5.force = CGVector(dx: 0, dy: -load/3)
        n7.force = CGVector(dx: 0, dy: -load/3)

        graph.addEdge(between: n1, and: n2, elasticity: e, area: a)
        graph.addEdge(between: n1, and: n3, elasticity: e, area: a)
        graph.addEdge(between: n2, and: n3, elasticity: e, area: a)
        graph.addEdge(between: n2, and: n4, elasticity: e, area: a)
        graph.addEdge(between: n2, and: n5, elasticity: e, area: a)
        graph.addEdge(between: n3, and: n5, elasticity: e, area: a)
        graph.addEdge(between: n4, and: n5, elasticity: e, area: a)
        graph.addEdge(between: n4, and: n6, elasticity: e, area: a)
        graph.addEdge(between: n5, and: n6, elasticity: e, area: a)
        graph.addEdge(between: n5, and: n7, elasticity: e, area: a)
        graph.addEdge(between: n6, and: n7, elasticity: e, area: a)
        graph.addEdge(between: n6, and: n8, elasticity: e, area: a)
        graph.addEdge(between: n7, and: n8, elasticity: e, area: a)

        return Gene(graph: graph)
    }

    static func gambrel2() -> Gene {
        let e = 29e6
        let a = 0.1

        let graph = Graph()
        let n1 = graph.createVertex(position: CGPoint(x: 0, y: 0), isXSimulationFixed: true, isYSimulationFixed: true, isXEvolutionFixed: true, isYEvolutionFixed: true)
        let n2 = graph.createVertex(position: CGPoint(x: 9*12, y: 5*12))
        let n3 = graph.createVertex(position: CGPoint(x: 7*12, y: 0), isYEvolutionFixed: true)
        let n4 = graph.createVertex(position: CGPoint(x: 15*12, y: 9*12+4))
        let n5 = graph.createVertex(position: CGPoint(x: 18*12, y: 0), isYEvolutionFixed: true)
        let n6 = graph.createVertex(position: CGPoint(x: 22*11, y: 7*12))
        let n7 = graph.createVertex(position: CGPoint(x: 25*10, y: 0), isYEvolutionFixed: true)
        let n8 = graph.createVertex(position: CGPoint(x: 30*13, y: 0), isYSimulationFixed: true, isXEvolutionFixed: true, isYEvolutionFixed: true)

        let load = 2000
        n3.force = CGVector(dx: 0, dy: -load/3)
        n5.force = CGVector(dx: 0, dy: -load/3)
        n7.force = CGVector(dx: 0, dy: -load/3)

        graph.addEdge(between: n1, and: n2, elasticity: e, area: a)
        graph.addEdge(between: n1, and: n3, elasticity: e, area: a)
        graph.addEdge(between: n2, and: n3, elasticity: e, area: a)
        graph.addEdge(between: n2, and: n4, elasticity: e, area: a)
        graph.addEdge(between: n2, and: n5, elasticity: e, area: a)
        graph.addEdge(between: n3, and: n5, elasticity: e, area: a)
        graph.addEdge(between: n4, and: n5, elasticity: e, area: a)
        graph.addEdge(between: n4, and: n6, elasticity: e, area: a)
        graph.addEdge(between: n5, and: n6, elasticity: e, area: a)
        graph.addEdge(between: n5, and: n7, elasticity: e, area: a)
        graph.addEdge(between: n6, and: n7, elasticity: e, area: a)
        graph.addEdge(between: n6, and: n8, elasticity: e, area: a)
        graph.addEdge(between: n7, and: n8, elasticity: e, area: a)

        return Gene(graph: graph)
    }

    static func failGambrel() -> Gene {
        let e = 29e6
        let a = 0.1

        let graph = Graph()
        let n3 = graph.createVertex(position: CGPoint(x: 7*12, y: 0), isYEvolutionFixed: true)
        let n4 = graph.createVertex(position: CGPoint(x: 15*12, y: 9*12+4))
        let n5 = graph.createVertex(position: CGPoint(x: 18*12, y: 0), isYEvolutionFixed: true)
        let n6 = graph.createVertex(position: CGPoint(x: 22*11, y: 7*12))
        let n7 = graph.createVertex(position: CGPoint(x: 25*10, y: 0), isYEvolutionFixed: true)
        let n8 = graph.createVertex(position: CGPoint(x: 30*13, y: 0), isYSimulationFixed: true, isXEvolutionFixed: true, isYEvolutionFixed: true)

        let load = 2000
        n3.force = CGVector(dx: 0, dy: -load/3)
        n5.force = CGVector(dx: 0, dy: -load/3)
        n7.force = CGVector(dx: 0, dy: -load/3)

        graph.addEdge(between: n4, and: n6, elasticity: e, area: a)
        graph.addEdge(between: n5, and: n6, elasticity: e, area: a)
        graph.addEdge(between: n5, and: n7, elasticity: e, area: a)
        graph.addEdge(between: n6, and: n7, elasticity: e, area: a)
        graph.addEdge(between: n6, and: n8, elasticity: e, area: a)
        graph.addEdge(between: n7, and: n8, elasticity: e, area: a)

        return Gene(graph: graph)
    }

}
