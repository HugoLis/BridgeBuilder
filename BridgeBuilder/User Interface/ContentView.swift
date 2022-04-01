//
//  ContentView.swift
//  BridgeBuilder
//
//  Created by Hugo on 29/03/22.
//

import SwiftUI

/// Main interface view for adjusting bridge evolution parameters.
struct ContentView: View {

    // Edges textfield parameters.
    @State var maxEdgeLength = "15" {
        didSet { Gene.maxEdgeLength = Double(maxEdgeLength) ?? 15 }
    }
    @State var edgeElasticity = "210e9" {
        didSet { Gene.edgeElasticity = Double(edgeElasticity) ?? 210e9 }
    }
    @State var edgeDensity = "7850" {
        didSet { Gene.edgeDensity = Double(edgeDensity) ?? 7850 }
    }

    // Vertices textfield parameters.
    @State var minVertexDistance = "3" {
        didSet { Gene.minVertexDistance = Double(minVertexDistance) ?? 3 }
    }

    // Evolution textfield parameters.
    @State var populationSize = "100"
    @State var generationLimit = "300"
    @State var replacementRate = "0.3"
    @State var crossoverRadius = "30" {
        didSet { Gene.maxCrossoverRadius = Double(crossoverRadius) ?? 15 }
    }

    // Bridge textfield parameters.
    @State var load = "2e6"
    @State var stressLimit = "300e6"
    @State var floorSupportsX = "-30, 30"
    @State var extraSupportsX = "0"
    @State var extraSupportsY = "-20"

    /// Array of floor supports points.
    var floorSupports: [CGPoint] {
        let floorXPositionsStrings = floorSupportsX.components(separatedBy: ", ")
        return floorXPositionsStrings.map { CGPoint(x: Double($0) ?? 0, y: 0) }
    }

    /// Array of extra supports points.
    var extraSupports: [CGPoint] {
        let extraXPositionsStrings = extraSupportsX.components(separatedBy: ", ")
        let extraYPositionsStrings = extraSupportsY.components(separatedBy: ", ")
        let extraPositionsStrings = Array(zip(extraXPositionsStrings, extraYPositionsStrings))
        return extraPositionsStrings.map {
            CGPoint(x: Double($0.0) ?? 0, y: Double($0.1) ?? 0)
        }
    }

    var body: some View {
        // Navigation view with a form for editing evolution parameters on the
        // left and a detail view with a live visualization of bridge support points.
        NavigationView {
            ScrollView {
                // Parameters editing form.
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
                        TextField(text: $extraSupportsX, prompt: Text("Ex: 0")) {
                            Text("Extra supports X's:")
                        }
                        TextField(text: $extraSupportsY, prompt: Text("Ex: -20")) {
                            Text("Extra supports Y's:")
                        }
                    }
                    Spacer()
                }
            }
            .padding()
            .frame(minWidth: 300)

            // Detail view for live visualization of bridge support points.
            let scaler: CGFloat = 4
            ZStack {
                // Floor supports triangles.
                ForEach(Array(zip(floorSupports, floorSupports.indices)), id: \.1) { point, index in
                    ZStack {
                        Image(systemName: "arrowtriangle.up.fill")
                            .foregroundColor(.green)
                            .font(.title)
                            .offset(x: point.x * scaler, y: +9 - point.y * scaler)
                        if index == 0 {
                            Image(systemName: "arrowtriangle.right.fill")
                                .foregroundColor(.green)
                                .font(.title)
                                .offset(x: -9 + point.x * scaler, y: -point.y * scaler)
                        }
                    }
                }
                let leftFloor = floorSupports.map{ $0.x }.min() ?? 0
                let rightFloor = floorSupports.map{ $0.x }.max() ?? 0
                // Floor line.
                Rectangle()
                    .foregroundColor(.blue)
                    .frame(width: (rightFloor-leftFloor) * scaler, height: 2)
                    .offset(x: (leftFloor + rightFloor)/2 * scaler, y: -floorSupports[0].y * scaler)

                // Extra supports triangles.
                ForEach(Array(zip(extraSupports, extraSupports.indices)), id: \.1) { point, index in
                    Image(systemName: "arrowtriangle.up.fill")
                        .foregroundColor(.green)
                        .font(.title)
                        .offset(x: point.x * scaler, y: +9 - point.y * scaler)
                }
            }
            .offset(y: -15 * scaler)
            .navigationTitle("Bridge Builder")
            // Toolbar with a button that starts the evolution process.
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        startEvolutionProcess()
                    } label: {
                        Text("Run \(Image(systemName: "play.fill"))")
                    }
                }
            }
        }
    }

    /// Starts the evolution process with the parameters set by the user.
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
