//
//  EvolutionChamber.swift
//  GeneticBuilder
//
//  Created by Hugo Lispector on 28/02/22.
//

import Foundation

/// Class that will perform the evolution process with a population of genes. Mutation, crossover and selection
/// of best performing individuals will be over generations.
class EvolutionChamber {

    /// Number of individuals that should be kept in the population during the evolution process.
    let populationSize: Int

    /// Maximum number of generations before the evolution process is stopped.
    let generationLimit: Int

    /// Percentage of the population that is replaced after each generation.
    var replacementPercentage: CGFloat

    /// Closure used to create a new Evolvable individual of the population.
    let makeIndividualHandler: () -> Evolvable

    /// Population to be evolved. Individuals of the population must conform to `Evolvable`, so they
    /// are genes with a fitness function.
    var population: [Evolvable] = []

    /// Stores a copy of the individual with the current best fitness.
    var bestIndividual: Evolvable

    /// Records best fitnesses on the Y axis and their generations on the X axis.
    var bestFitnessAndGeneration: [CGPoint] = []

    /// Records fitnesses mean on the Y axis and their generations on the X axis.
    var fitnessMeanAndGeneration: [CGPoint] = []

    /// Records fitnesses standard deviation on the Y axis and their generations
    /// on X axis.
    var fitnessStandardDeviationAndGeneration: [CGPoint] = []

    /// Index of the individual representing the 20% position of the population.
    var topPercentIndex: Int {
        Int(round(Double(populationSize) * 0.2)) - 1
    }

    /// Creates an evolution chamber with given population size, generation limit and a handler for creating
    /// new Evolvable individuals.
    /// - Parameters:
    ///   - populationSize: Number of individuals that should be kept in the population during the
    ///     evolution process.
    ///   - generationLimit: Maximum number of generations before the evolution process stops.
    ///   - replacementPercentage: Percentage of the population that is
    ///     replaced after each generation.
    ///   - makeIndividualHandler: Closure that creates an Evolvable individual.
    init(populationSize: Int, generationLimit: Int, replacementPercentage: CGFloat, makeIndividualHandler: @escaping () -> Evolvable) {
        self.populationSize = populationSize
        self.generationLimit = generationLimit
        self.replacementPercentage = replacementPercentage
        self.makeIndividualHandler = makeIndividualHandler

        while population.count < populationSize {
            population.append(makeIndividualHandler())
        }

        // Initializes the best individual with a copy of any member from the
        // population. It will be changed after the first fitness evaluation.
        self.bestIndividual = population[0].copy()
    }

    /// Performs various mutation operations to a given gene. Used during
    /// evolution main loop.
    /// - Parameter gene: Gene that will suffer mutation.
    private func mutate(gene: Gene) {
        var shouldIgnoreArea = false
        if Gene.edgeAreaRange.lowerBound == Gene.edgeAreaRange.upperBound {
            shouldIgnoreArea = true
        }
        switch Int.random(in: 0...(shouldIgnoreArea ? 5 : 6)) {
        case 0:
            for _ in 0...Int.random(in: 1...3) { gene.removeRandomVertex() }
        case 1:
            for _ in 0...Int.random(in: 1...3) { gene.addRandomVertex() }
        case 2:
            for _ in 0...Int.random(in: 1...3) { gene.removeRandomEdge() }
        case 3:
            for _ in 0...Int.random(in: 1...3) { gene.addRandomEdge() }
        case 4:
            for _ in 0...Int.random(in: 1...3) { gene.moveRandomVertex() }
        case 5:
            for _ in 0...Int.random(in: 0...3) { gene.removeRandomVertex() }
            for _ in 0...Int.random(in: 0...3) { gene.addRandomVertex() }
            for _ in 0...Int.random(in: 0...3) { gene.removeRandomEdge() }
            for _ in 0...Int.random(in: 0...3) { gene.addRandomEdge() }
            for _ in 0...Int.random(in: 0...3) { gene.moveRandomVertex() }
            if !shouldIgnoreArea {
                for _ in 0...Int.random(in: 1...3) { gene.varyRandomEdgeArea() }
            }
        case 6:
            for _ in 0...Int.random(in: 1...3) { gene.varyRandomEdgeArea() }
        default:
            break
        }
    }

    /// Saves relevant plots of a bridge.
    /// - Parameters:
    ///   - bridge: Bridge to be ploted.
    ///   - generation: Generation number of the bridge. Used for metadata.
    private func savePlots(ofBridge bridge: Evolvable, generation: Int) {
        guard let bridgeCopy = bridge.copy() as? Bridge else { return }

        let bridgeFrame = bridgeCopy.graph.getBoundingBox(margin: 1.4, ratio: 1.5)
        //Replacing dots of fitness with commas, because dots mess with file names.
        let fitness = CGFloat(round(bridge.calculatedFitness*100)/100)
        let fitnessString = String(describing: fitness).replacingOccurrences(of: ".", with: ",")

        // Creates a plot with all forces, not proportional because load forces
        // will be much greater than other weight forces.
        let allForcesSimulation = Simulation(graph: bridgeCopy.graph)
        allForcesSimulation.saveModelPlot(
            toPath: Simulation.mainPlotsPath,
            withName: "All Forces fit\(fitnessString) g\(generation)",
            isProportional: false,
            plotFrame: bridgeFrame
        )

        // Creates a plot of the deformed shape with stresses.
        let deformedShapeSimulation = Simulation(graph: bridgeCopy.graph)
        deformedShapeSimulation.solve()
        deformedShapeSimulation.saveDeformedShapePlot(
            toPath: Simulation.mainPlotsPath,
            withName: "Deformed fit\(fitnessString) g\(generation)",
            deformingFactor: 1,
            isProportional: true,
            showsStresses: true,
            // oesn't really matter as long as it's a bit higher than the maximum
            // stresses values for a set of simulations
            stressLimit: 0.5 * 300e6,
            plotFrame: bridgeFrame
        )

        // Creates a plot with no forces. Saves it to simple plots path as well.
        bridgeCopy.graph.resetForces()
        let noForcesSimulation = Simulation(graph: bridgeCopy.graph)
        noForcesSimulation.saveModelPlot(
            toPath: Simulation.mainPlotsPath,
            withName: "No Forces fit\(fitnessString) g\(generation)",
            isProportional: true,
            plotFrame: bridgeFrame
        )
        noForcesSimulation.saveModelPlot(
            toPath: Simulation.specialPlotsPath,
            withName: "No Forces Fixed fit\(fitnessString) g\(generation)",
            isProportional: true,
            plotFrame: Simulation.fixedPlotFrame
        )

        // Creates load only forces model plot.
        bridgeCopy.graph.resetForces()
        bridgeCopy.addLoadForces(totalLoad: 1)
        let loadForcesSimulation = Simulation(graph: bridgeCopy.graph)
        loadForcesSimulation.saveModelPlot(
            toPath: Simulation.mainPlotsPath,
            withName: "Load Forces fit\(fitnessString) g\(generation)",
            isProportional: false,
            plotFrame: bridgeFrame
        )
    }

    /// Prints relevant data about a population at a given generation.
    /// - Parameter generation: Current generation of the population
    private func evolutionReport(generation: Int) {
        print("Generation: \(generation)")
        print("Best Fitness: \(bestIndividual.calculatedFitness)")
        let currentTopFitnesses = population[...4].map { round($0.calculatedFitness*100)/100 }
        print("Current Top Fitnesses: \(currentTopFitnesses)")
        let currentTopFitnessesMean = Array(population.map { $0.calculatedFitness }[0...topPercentIndex]).average()
        print("Current Top Fitnesses Mean: \(currentTopFitnessesMean)" )
        print("Best Fitness Material: \(bestIndividual.usedMaterial)")
        print("Best Fitness Max Stress: \(bestIndividual.calculatedMaxStress)")
    }

    private func plotStatistics(generation: Int) {
        // If the last added fitness was not on the last generation, create a
        // duplicate point of the best value in the last generation.
        let lastFitnessPoint = bestFitnessAndGeneration.last!
        var bestFitnessAndGenerationCopy = bestFitnessAndGeneration
        if Int(lastFitnessPoint.x) != generation {
            bestFitnessAndGenerationCopy.append(CGPoint(x: CGFloat(generation), y: lastFitnessPoint.y))
        }
        Simulation.saveXYPlot(
            x: bestFitnessAndGenerationCopy.map { $0.x },
            y: bestFitnessAndGenerationCopy.map { $0.y },
            xLabel: "Generation",
            yLabel: "Best Fitness",
            showsMarkers: true,
            path: Simulation.specialPlotsPath,
            name: "Best fitness evolution g\(generation)"
        )
        Simulation.saveXYPlot(
            x: fitnessMeanAndGeneration.map { $0.x },
            y: fitnessMeanAndGeneration.map { $0.y },
            xLabel: "Generation",
            yLabel: "Fitness Mean",
            showsMarkers: false,
            path: Simulation.specialPlotsPath,
            name: "Fitness mean evolution top20% g\(generation)"
        )
        Simulation.saveXYPlot(
            x: fitnessStandardDeviationAndGeneration.map { $0.x },
            y: fitnessStandardDeviationAndGeneration.map { $0.y },
            xLabel: "Generation",
            yLabel: "Fitness Standard Deviation",
            showsMarkers: false,
            path: Simulation.specialPlotsPath,
            name: "Fitness standard deviation evolution top20% g\(generation)"
        )
    }

    /// Prints relevant data about a population at its final generation state.
    private func dataReport() {
        // Gets best fitness and its generation. If there is no new best fitness
        // in the last generation, we copy the previous best fitness, so here we
        // check if the two last fitnesses are different. If they are, we consider
        // the last point as best fitness and generation. Otherwise, we consider
        // the second last point as best fitness and generation.
        var bestFitnessPoint = CGPoint(x: -1, y: -1)
        guard bestFitnessAndGeneration.count >= 2 else { return }
        let lastFitness = bestFitnessAndGeneration.last!
        let secondLastFitness = bestFitnessAndGeneration[bestFitnessAndGeneration.count-2]
        if abs(lastFitness.y - secondLastFitness.y) > 0.0001 {
            bestFitnessPoint = bestFitnessAndGeneration.last!
        } else {
            bestFitnessPoint = secondLastFitness
        }

        print("<< Data Report >>")
        print("Best Fitness: \(bestFitnessPoint.y), generation: \(Int(round(bestFitnessPoint.x)))")

        let bestFitnessMeanPoint = fitnessMeanAndGeneration.max { $0.y < $1.y }!
        print("Best Fitness Mean: \(bestFitnessMeanPoint.y), generation: \(Int(round(bestFitnessMeanPoint.x))) ")
        print("Final Fitness Mean: \(fitnessMeanAndGeneration.last!.y), generation: \(Int(round(fitnessMeanAndGeneration.last!.x))) ")

        let minFitnessDeviationPoint = fitnessStandardDeviationAndGeneration.min { $0.y < $1.y }!
        print("Minimum Fitness Standard Deviation: \(minFitnessDeviationPoint.y), generation: \(Int(round(minFitnessDeviationPoint.x))) ")
        print("Final Fitness Standard Deviation: \(fitnessStandardDeviationAndGeneration.last!.y), generation: \(Int(round(fitnessStandardDeviationAndGeneration.last!.x)))")
    }

    /// Gets the mean bounding box for a bridge specification by taking the mean
    /// bounding box of multiple sample bridges.
    /// - Parameters:
    ///   - margin: Additional margins to be multiplied by the box sides.
    ///   - ratio: Ratio of the rectangle (width/height)
    ///   - sampleSize: Number of sample bridges to use.
    /// - Returns: A bounding box as an array: [minX, maxX, minY, maxY]
    func getMeanBoundingBox(margin: CGFloat, ratio: CGFloat, sampleSize: Int = 10) -> [CGFloat] {
        var sampleBridges: [Gene] = []
        for _ in 1...sampleSize {
            sampleBridges.append(makeIndividualHandler())
        }
        let sampleBoundingBoxes = sampleBridges.map{ $0.graph.getBoundingBox(margin: margin, ratio: ratio) }
        let boundingBoxSum = sampleBoundingBoxes.reduce([0,0,0,0], { [$0[0]+$1[0], $0[1] + $1[1], $0[2] + $1[2], $0[3] + $1[3]] })
        let count = CGFloat(sampleBridges.count)
        let meanBoundingBox = [boundingBoxSum[0]/count, boundingBoxSum[1]/count, boundingBoxSum[2]/count, boundingBoxSum[3]/count]
        return meanBoundingBox
    }

    /// Main evolutionary loop of the algorithm.
    func run() {
        // Sort the population according to the fitness before starting the
        // evolutionary loop.
        population.sort { $0.fitness() > $1.fitness() }


        // Saves plots of the worst individual and 3 random individuals.
        let worstIndividualCopy = population.last!.copy()
        worstIndividualCopy.calculatedFitness = population.last!.calculatedFitness
        savePlots(ofBridge: worstIndividualCopy, generation: -999)
        for i in 1...3 {
            let randomIndividual = population.randomElement()!
            let randomIndividualCopy = randomIndividual.copy()
            randomIndividualCopy.calculatedFitness = randomIndividual.calculatedFitness
            savePlots(ofBridge: randomIndividual, generation: -111 * i)
        }

        bestIndividual = population.first!.copy()
        bestIndividual.calculatedFitness = population.first!.calculatedFitness
        bestIndividual.calculatedMaxStress = population.first!.calculatedMaxStress
        savePlots(ofBridge: bestIndividual, generation: 0)

        // Record fitness evolution statistics.
        bestFitnessAndGeneration.append(
            CGPoint(x: 0, y: bestIndividual.calculatedFitness)
        )
        fitnessMeanAndGeneration.append(
            CGPoint(x: 0, y: Array(population.map { $0.calculatedFitness }[0...topPercentIndex]).average())
        )
        fitnessStandardDeviationAndGeneration.append(
            CGPoint(x: 0, y: Array(population.map { $0.calculatedFitness }[0...topPercentIndex]).standardDeviation())
        )

        evolutionReport(generation: 0)

        for currentGeneration in 1...generationLimit {

            // Apply mutation to the population.
            for individual in population { mutate(gene: individual) }

            // Removes individuals with worst fitness from the population.
            let replacementPercentage = replacementPercentage
            let individualsToReplace = Int(round(replacementPercentage * CGFloat(populationSize)))
            population.removeLast(individualsToReplace)

            // Add new individuals by copying the best ones or via crossover of
            // the best individuals until the population size reaches it's
            // original value.
            while population.count < populationSize {
                let crossoverProbability = 0.95 //0.95
                if CGFloat.random(in: 0...1) <= crossoverProbability {
                    var maxParentIndex = Int(round(1.5 * Double(individualsToReplace)))
                    if maxParentIndex > population.count { maxParentIndex = individualsToReplace }

                    var possibleParents = population[..<(maxParentIndex)]
                    assert(possibleParents.count > 2, "Less than two possible parents makes crossover operation impossible.")
                    let parent1Index = possibleParents.indices.randomElement()!
                    let parent1 = possibleParents.remove(at: parent1Index)
                    let parent2 = possibleParents.randomElement()!

                    let newGene = parent1.copy()
                    newGene.crossover(with: parent2.graph)
                    population.append(newGene)
                } else {
                    population.append(population[..<(individualsToReplace)].randomElement()!.copy())
                }
            }

            // Sort population by fitness, so best individuals are at the
            // beginning of the array.
            population.sort { $0.fitness() > $1.fitness() }

            // If there is a new best individual, save it.
            if (population.first!.calculatedFitness - bestIndividual.calculatedFitness) > 0.0001 {
                bestIndividual = population.first!.copy()
                bestIndividual.calculatedFitness = population.first!.calculatedFitness
                bestIndividual.calculatedMaxStress = population.first!.calculatedMaxStress
                savePlots(ofBridge: bestIndividual, generation: currentGeneration)
                bestFitnessAndGeneration.append(CGPoint(x: CGFloat(currentGeneration), y: bestIndividual.calculatedFitness))
            }

            fitnessMeanAndGeneration.append(
                CGPoint(x: CGFloat(currentGeneration), y: Array(population.map { $0.calculatedFitness }[0...topPercentIndex]).average())
            )
            fitnessStandardDeviationAndGeneration.append(
                CGPoint(x: CGFloat(currentGeneration), y: Array(population.map { $0.calculatedFitness }[0...topPercentIndex]).standardDeviation())
            )
            evolutionReport(generation: currentGeneration)

            // Every 50 generations create statistics plots.
            if (currentGeneration != 0) && (currentGeneration % 50 == 0) {
                dataReport()
                plotStatistics(generation: currentGeneration)
            }
        }

        // If the final statistics plot was not already done by the every 50 plot,
        // the plot it.
        if (generationLimit % 50) != 0 {
            dataReport()
            plotStatistics(generation: generationLimit)
        }
    }

}
