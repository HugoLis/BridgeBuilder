//
//  Simulation.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 09/01/22.
//

import Foundation
import CoreGraphics

import PythonKit


/// Abstraction that translates a truss graph into a Nusa TrussModel and allows it's simulation, plots and
/// more without the need to interact with PythonObjects on other abstraction layers.
class Simulation {

    /// Nusa's TrussModel. The core model that holds, nodes, elements, forces and much more. Used to
    /// plot the truss, simulate forces, displacements and stresses.
    var model: PythonObject

    /// Used for maintaining a fixed frame across multiple plots, for example
    /// for creating an evolution animation. It should have 4 values which
    /// represent [minX, maxX, minY, maxY].
    static var fixedPlotFrame: [CGFloat] = [-1, 1, -1, 1]

    /// Path to folder that will contain most bridges plots, with automatic
    /// frames.
    static let mainPlotsPath = #"/Users/hugo/Desktop/Main Plots"#

    /// Path to folder that will contain bridges plots with a fixed frame and
    /// metrics evolution, like best fitness for each generation.
    static let specialPlotsPath = #"/Users/hugo/Desktop/Special Plots"#

    init(graph: Graph) {
        // Dictionary that associates a vertex id to respective nusa node.
        var nusaNodes: [UUID:PythonObject] = [:] // [Vertex.id:Nusa.Node]
        // Stores vertices from graphs as Nusa Nodes dictionary.
        for vertex in graph.allVertices {
            let node = Nusa.Node([vertex.position.x, vertex.position.y])
            nusaNodes[vertex.id] = node
        }

        // Stores edges of the graph as Nusa (Truss) Elements.
        var nusaElements: [PythonObject] = [] // [Nusa.Truss]
        for edge in graph.allEgdes {
            let vertices = Array(edge.vertices)
            let nodeA = nusaNodes[vertices[0].id] // nusa node
            let nodeB = nusaNodes[vertices[1].id] // nusa node
            let element = Nusa.Truss([nodeA, nodeB], edge.elasticity, edge.area)
            nusaElements.append(element)
        }

        // Adds nodes and elements to the nusa model.
        model = Nusa.TrussModel()
        for node in Array(nusaNodes.values) {
            model.add_node(node)
        }
        for element in nusaElements {
            model.add_element(element)
        }

        // Adds forces and constraints to the nusa model.
        for vertex in graph.allVertices {
            if let force = vertex.force {
                model.add_force(nusaNodes[vertex.id], [force.dx, force.dy])
            }

            if vertex.isXSimulationFixed && vertex.isYSimulationFixed{
                model.add_constraint(nusaNodes[vertex.id], ux: 0, uy: 0)
            }
            else if vertex.isXSimulationFixed {
                model.add_constraint(nusaNodes[vertex.id], ux: 0)
            }
            else if vertex.isYSimulationFixed {
                model.add_constraint(nusaNodes[vertex.id], uy: 0)
            }
        }

    }


    /// Checks if the truss model is solvable. More information about that in
    /// the NusaPlus method documentation.
    /// - Returns: True, if the model is solvable. False, otherwise.
    func isSolvable() -> Bool {
        return Bool(NusaPlus.isModelSolvable(model))!
    }

    /// Simulates the nusa model. Required before retrieving stresses, displacements and other simulated
    /// attributes.
    func solve() {
        model.solve()
    }

    /// Gets the maximum stress of an edge after simulation.
    /// - Returns: Maximum stress of an edge.
    func maxStress() -> Double {
        let solvedElements = Array(model.get_elements())
        let stresses = solvedElements.map { abs(Double($0.s)!) }
        return stresses.max()!
    }

    /// Gets a mean stress from the N most stressed elements.
    /// - Parameter count: Number of element stresses consider.
    /// - Returns: Mean stress of the N most stresses elements.
    func maxStressesMean(count: Int) -> Double {
        let solvedElements = Array(model.get_elements())
        let stresses = solvedElements.map { abs(Double($0.s)!) }
        let maxStresses = Array(stresses.sorted().reversed()[...(count-1)])
        return maxStresses.reduce(0.0, +)/Double(count)
    }

    /*
    /// Gets a sum of the stresses by giving bigger stresses more weight. Stresses
    /// are sorted and then divided by a value proportional to their indexes.
    /// This way, we give more weight to bigger stresses, and less importance to
    /// small stresses.
    func stressesWeightedMean() -> CGFloat {
        let solvedElements = Array(model.get_elements())
        let stresses = solvedElements.map { abs(Double($0.s)!) }
        let sortedStresses = stresses.sorted(by: >)

        var weightedStressSum: CGFloat = 0
        var weight: CGFloat = 1
        var weightsSum: CGFloat = 0
        for stress in Array(sortedStresses[0...8]) {
            weightedStressSum += stress * weight
            weightsSum += weight

            //Update weight
            //multiplier /= 2
            weight /= 1.5
            //weight /= 1.1
            //divider += 1
        }

        return weightedStressSum// /weightsSum
    }*/

    /// Gets the mean stress of the edges after simulation.
    /// - Returns: Mean stress of the edges.
    func meanStress() -> Double {
        let solvedElements = Array(model.get_elements())
        let stresses = solvedElements.map { abs(Double($0.s)!) }
        return stresses.reduce(0, +)/Double(stresses.count)
    }


    // MARK: - Plots

    /// Saves an image of the the nusa model plot with forces and areas
    /// to the given location.
    /// - Parameters:
    ///   - path: Path to save image.
    ///   - name: Name of the image.
    ///   - isProportional: Plots proportional thicknesses (areas) and force
    ///     arrows lengths. Defaults to true.
    ///   - plotFrame: Fixed frame used for plots with fixed frame. It should
    ///     have 4 values and they represent [minX, maxX, minY, maxY].
    func saveModelPlot(toPath path: String, withName name: String = "", isProportional: Bool = true, plotFrame: [CGFloat] = []) {
        let figure = NusaPlus.plot_model(truss_model: model, is_proportional: isProportional, fixed_frame: plotFrame)
        Simulation.saveFigure(toPath: path, withName: name)
        figure.clear()
        Pyplot.close(figure)
    }

    /// Plots the nusa model with forces and areas with Pyplot and buffers it.
    /// Requires `Simulation.showPlots()` afterwards.
    /// - Parameters:
    ///   - isProportional:Plots proportional thicknesses (areas) and force
    ///   arrows lengths. Defaults to true.
    func plotModel(isProportional: Bool = true) {
        let _ = NusaPlus.plot_model(truss_model: model, is_proportional: isProportional)
    }

    /// Saves an image of the the nusa model and deformed shape plot with forces
    /// and areas to the given location.
    /// - Parameters:
    ///   - path: Path to save image.
    ///   - name: Name of the image.
    ///   - deformingFactor: Visual deformation factor. Defaults to 1.
    ///   - isProportional: Plots proportional thicknesses (areas) and force
    ///     arrows lengths. Defaults to true.
    ///   - showsStresses: Shows stresses colors in deformed shape. Still needs
    ///     to be refined and show a color bar. Defaults to false.
    ///   - stressLimit: Maximum stress before the plot shows maximum/minimum
    ///     stress colors. Defaults to 0, so the maximum stress becomes relative
    ///     to each plot maximum stress.
    ///   - plotFrame: Fixed frame used for plots with fixed frame. It should
    ///     have 4 values and they represent [minX, maxX, minY, maxY].
    func saveDeformedShapePlot(toPath path: String, withName name: String = "", deformingFactor: Double = 1, isProportional: Bool = true, showsStresses: Bool = false, stressLimit: CGFloat = 0, plotFrame: [CGFloat] = []) {
        let figure = NusaPlus.plot_deformed_shape(model, deformingFactor, isProportional, showsStresses, stressLimit, plotFrame)
        Simulation.saveFigure(toPath: path, withName: name)
        figure.clear()
        Pyplot.close(figure)
    }

    /// Plots the nusa model and deformed shape with Pyplot and buffers it. Requires `showPlots()`
    /// afterwards (which calls `Pyplot.show()`).
    /// - Parameters:
    ///   - deformingFactor: Visual deformation factor. Defaults to 1.
    ///   - isProportional: Plots proportional thicknesses (areas) and force arrows lengths. Defaults
    ///     to true.
    ///   - showsStresses: Shows stresses colors in deformed shape. Still needs to be refined and
    ///     show a color bar. Defaults to false.
    func plotDeformedShape(deformingFactor: Double = 1, isProportional: Bool = true, showsStresses: Bool = false) {
        let _ = NusaPlus.plot_deformed_shape(model, deformingFactor, isProportional, showsStresses)
    }

    /// Plots lines from two arrays of numbers: X and Y and saves it.
    static func saveXYPlot(x: [CGFloat], y: [CGFloat], xLabel: String, yLabel: String, showsMarkers: Bool, path: String, name: String) {
        let figure = Pyplot.figure()
        let axes = figure.add_subplot(111)
        axes.set_xlabel(xLabel)
        axes.set_ylabel(yLabel)
        axes.ticklabel_format(style: "sci", axis: "y", scilimits: [0,0])
        axes.plot(x, y, color: "b")
        if showsMarkers {
            axes.scatter(x.last!, y.last!, marker: "D", color: "b")
            axes.scatter(x.dropLast(), y.dropLast(), marker: "o", color: "b")
        }
        //Pyplot.show()
        Simulation.saveFigure(toPath: path, withName: name)

        figure.clear()
        Pyplot.close(figure)
    }

    /// Chooses a non interactive backend for Matplotlib.
    static func useNonInteractiveBackend() {
        Matplotlib.use("agg")
    }

    /// Saves the last pyplot plot to as an image on disk.
    /// - Parameters:
    ///   - path: Path to folder where the image should be saved. Ex:
    ///     "/Users/hugo/Desktop/evolution"
    ///   - name: Name of the image. It will be appended by the current date.
    static func saveFigure(toPath path: String, withName name: String) {
        let currentDate = String(Date().timeIntervalSinceReferenceDate).replacingOccurrences(of: ".", with: "")
        Pyplot.savefig("\(path)/\(currentDate) \(name).pdf", dpi: 300)
        Pyplot.savefig("\(path)/\(currentDate) \(name).png", dpi: 300)
    }

    /// Shows the plots by calling `Pyplot.show()`. Make sure matplotlib is not
    /// using a non-interactive backend, like "agg", and that `shouldSaveFigure`
    /// is set to false in `plotModel`.
    static func showPlots() {
        Pyplot.show()
    }

}
