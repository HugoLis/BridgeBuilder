//
//  BridgeBuilderApp.swift
//  BridgeBuilder
//
//  Created by Hugo on 29/03/22.
//

import SwiftUI
import AppKit

@main
struct BridgeBuilderApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 400)
        }
    }
}
