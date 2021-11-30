//
//  BitcoinWebSocketApp.swift
//  BitcoinWebSocket
//
//  Created by Terry Chen on 2021/11/30.
//

import SwiftUI

@main
struct BitcoinWebSocketApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
