//
//  ContentView.swift
//  BridgeBuilder
//
//  Created by Hugo on 29/03/22.
//

import SwiftUI

struct ContentView: View {

    // Gene parameters
    @State var maxEdgeLength = "15" {
        didSet {
            Gene.maxEdgeLength = Double(maxEdgeLength) ?? 15
        }
    }

    @State var edgeElasticity = "210e9" {
        didSet {
            Gene.edgeElasticity = Double(edgeElasticity) ?? 210e9
        }
    }

    // Evolution Chamber parameters
    @State var populationSize = "100"

    var body: some View {
        NavigationView {
            Form {
                Text("Edge Parameters")
                    .font(.body.bold())
                Section() {
                    TextField(text: $maxEdgeLength, prompt: Text("Ex: 15")) {
                        Text("Maximum length:")
                    }
                    TextField(text: $edgeElasticity, prompt: Text("Ex: 210e9")) {
                        Text("Elasticity:")
                    }
                }
                Text("Evolution Parameters")
                    .font(.body.bold())
                    .padding(.top, 12)
                Section() {
                    TextField(text: $populationSize, prompt: Text("Ex: 100")) {
                        Text("Elasticity:")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        
                    } label: {
                        HStack {
                            Label("Run", systemImage: "play.fill")
                        }
                    }
                }
            }
            .padding()
            .frame(minWidth: 300)
            .navigationTitle("Title")

            Text("Detail View")
        }
    }

    func startEvolutionProcess() {
        let evolutionChamber = EvolutionChamber(
            populationSize: Int(populationSize) ?? 100,
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
        evolutionChamber.run()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
