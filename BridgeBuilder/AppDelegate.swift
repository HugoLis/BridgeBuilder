//
//  AppDelegate.swift
//  BridgeBuilder
//
//  Created by Hugo on 28/03/22.
//

import UIKit
import PythonKit

// Imports Python Packages.
let Sys = Python.import("sys")
let Warnings = Python.import("warnings")
let Nusa = Python.import("nusa")
let Matplotlib = Python.import("matplotlib")
let Pyplot = Python.import("matplotlib.pyplot")

// NusaPlus receives it's value when app finishes launching.
var NusaPlus = PythonObject(-1)

class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        print("Here we go...")

        // Ignores PythonKit warnings.
        Warnings.filterwarnings("ignore", #".*"is" with a literal*"#)

        // Imports Python Files.
        setSysFolder(folderName: "/BridgeBuilder")
        NusaPlus = Python.import("NusaPlus")

        func setSysFolder(folderName: String) {
            let currentFile = URL(fileURLWithPath: #file)
            let projectRoot = currentFile
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .path

            let folderPath = projectRoot + folderName
            Sys.path.append(folderPath)
        }

        // Disables debug logging of failled evolutionary operators.
        Gene.logFailures = false

        // This prevents plots from remaining buffered in memory.
        Simulation.useNonInteractiveBackend()

        // Sets global parameters for the genes.
        Gene.setParameters(
            maxEdgeLength: 15,
            minVertexDistance: 3,
            edgeAreaRange: 10e-3...10e-3,
            maxCrossoverRadius: 30,
            tryoutLimit: 20,
            edgeElasticity: 210e9,
            edgeDensity: 7850,
            weightMultiplier: 1
        )

        // MARK: Min Material Bridge
        // /*
        let evolutionChamber = EvolutionChamber(
            populationSize: 120,
            generationLimit: 600,
            replacementPercentage: 0.3,
            makeIndividualHandler: {
                MinMaterialBridge(
                    load: 6e6,
                    stressLimit: 300e6,
                    floorSupports: [CGPoint(x: -40, y: 0), CGPoint(x: 40, y: 0)],
                    extraSupports: [CGPoint(x: -10, y: -15), CGPoint(x: 10, y: -15)]
                )
            }
        )
        // */

        // MARK: Min Stress Bridge
        /*
         let evolutionChamber = EvolutionChamber(
         populationSize: 120, //80
         generationLimit: 600,
         replacementPercentage: 0.3 //0.4
         ,
         makeIndividualHandler: {
         MinStressBridge(
         load: 4e6,//2.5e6,
         materialLimit: 25000,
         floorSupports: [CGPoint(x: -30, y: 0), CGPoint(x: 30, y: 0)],
         extraSupports: [CGPoint(x: -15, y: -25)]
         )
         }
         )
         */

        // MARK: Max Load Bridge.
        /*
         let evolutionChamber = EvolutionChamber(
         populationSize: 50,
         generationLimit: 300,
         replacementPercentage: 0.4,
         makeIndividualHandler: {
         MaxLoadBridge(
         stressLimit: 300e6,
         materialLimit: 25000,
         floorSupports: [CGPoint(x: -30, y: 0), CGPoint(x: 30, y: 0)]/*,
                                                                      extraSupports: [CGPoint(x: -15, y: -25)]*/
         )
         }
         )
         */

        // Sets the fixed plot frame, for fixed frame plots, based on the mean of sample
        // structures.
        Simulation.fixedPlotFrame = evolutionChamber.getMeanBoundingBox(margin: 1.667, ratio: 4/3, sampleSize: 15)

        // Starts evolution loop.
        evolutionChamber.run()

        return true
    }
}
