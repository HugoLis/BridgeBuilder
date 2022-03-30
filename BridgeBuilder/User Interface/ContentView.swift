//
//  ContentView.swift
//  BridgeBuilder
//
//  Created by Hugo on 29/03/22.
//

import SwiftUI

struct ContentView: View {

    // Edges parameters
    @State var maxEdgeLength = "15" {
        didSet { Gene.maxEdgeLength = Double(maxEdgeLength) ?? 15 }
    }
    @State var edgeElasticity = "210e9" {
        didSet { Gene.edgeElasticity = Double(edgeElasticity) ?? 210e9 }
    }
    @State var edgeDensity = "7850" {
        didSet { Gene.edgeDensity = Double(edgeDensity) ?? 7850 }
    }

    // Vertices parameters
    @State var minVertexDistance = "3" {
        didSet { Gene.minVertexDistance = Double(minVertexDistance) ?? 3 }
    }

    // Evolution parameters
    @State var populationSize = "100"
    @State var generationLimit = "300"
    @State var replacementRate = "0.3"
    @State var crossoverRadius = "30" {
        didSet { Gene.maxCrossoverRadius = Double(crossoverRadius) ?? 15 }
    }

    // Bridge parameters
    @State var load = "2e6"
    @State var stressLimit = "300e6"
    @State var floorSupportsX = "-30, 30"
    @State var extraSupportsX = "0"
    @State var extraSupportsY = "-10"

    var floorSupports: [CGPoint] {
        let floorXPositionsStrings = floorSupportsX.components(separatedBy: ", ")
        return floorXPositionsStrings.map { CGPoint(x: Double($0) ?? 0, y: 0) }
    }

    var extraSupports: [CGPoint] {
        let extraXPositionsStrings = extraSupportsX.components(separatedBy: ", ")
        let extraYPositionsStrings = extraSupportsY.components(separatedBy: ", ")
        let extraPositionsStrings = Array(zip(extraXPositionsStrings, extraYPositionsStrings))
        return extraPositionsStrings.map {
            CGPoint(x: Double($0.0) ?? 0, y: Double($0.1) ?? 0)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
            Form {
                Text("Edges")
                    .font(.body.bold())
                Section() {
                    TextField(text: $maxEdgeLength, prompt: Text("Ex: 15")) {
                        Text("Maximum length:")
                    }
                    TextField(text: $edgeElasticity, prompt: Text("Ex: 210e9")) {
                        Text("Elasticity:")
                    }
                    TextField(text: $edgeDensity, prompt: Text("Ex: 7850")) {
                        Text("Density:")
                    }
                }
                Text("Vertices")
                    .font(.body.bold())
                    .padding(.top, 12)
                Section() {
                    TextField(text: $maxEdgeLength, prompt: Text("Ex: 3")) {
                        Text("Minimum distance:")
                    }
                }
                Text("Evolution Chamber")
                    .font(.body.bold())
                    .padding(.top, 12)
                Section() {
                    TextField(text: $edgeElasticity, prompt: Text("Ex: 100")) {
                        Text("Elasticity:")
                    }
                    TextField(text: $generationLimit, prompt: Text("Ex: 300")) {
                        Text("Generation limit:")
                    }
                    TextField(text: $replacementRate, prompt: Text("Ex: 0.3")) {
                        Text("Replacement rate:")
                    }
                    TextField(text: $crossoverRadius, prompt: Text("Ex: 30")) {
                        Text("Crossover radius:")
                    }
                }
                Text("Bridge")
                    .font(.body.bold())
                    .padding(.top, 12)
                Section() {
                    TextField(text: $load, prompt: Text("Ex: 2e6")) {
                        Text("Load:")
                    }
                    TextField(text: $stressLimit, prompt: Text("Ex: 300e6")) {
                        Text("Stress limit:")
                    }
                    TextField(text: $floorSupportsX, prompt: Text("Ex: -30, 30")) {
                        Text("Floor supports X's:")
                    }
                    TextField(text: $extraSupportsX, prompt: Text("Ex: 20")) {
                        Text("Extra supports X's:")
                    }
                    TextField(text: $extraSupportsY, prompt: Text("Ex: -20")) {
                        Text("Extra supports Y's:")
                    }
                }
                Spacer()
            }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        startEvolutionProcess()
                    } label: {
                        Text("Run \(Image(systemName: "play.fill"))")
                    }
                }
            }
            .padding()
            .frame(minWidth: 300)

            Text("Detail View")
                .navigationTitle("Bridge Builder")
        }
    }

    func startEvolutionProcess() {
        let evolutionChamber = EvolutionChamber(
            populationSize: Int(populationSize) ?? 100,
            generationLimit: Int(generationLimit) ?? 300,
            replacementPercentage: Double(replacementRate) ?? 0.3,
            makeIndividualHandler: {
                MinMaterialBridge(
                    load: Double(replacementRate) ?? 0.3,
                    stressLimit: Double(stressLimit) ?? 300e6,
                    floorSupports: floorSupports,
                    extraSupports: extraSupports
                )
            }
        )
        evolutionChamber.run()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
