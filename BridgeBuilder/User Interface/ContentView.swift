//
//  ContentView.swift
//  BridgeBuilder
//
//  Created by Hugo on 29/03/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Form {
            Section(header: Text("Blabla Parameters")) {
                Text("Hello, world!")
            }

            Section {
                Text("Hello, world!")
                Text("Hello, world!")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
