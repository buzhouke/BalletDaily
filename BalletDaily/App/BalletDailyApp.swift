//
//  BalletDailyApp.swift
//  BalletDaily
//
//  Created by Raymond White on 2026/1/1.
//

import SwiftUI
import CoreData

@main
struct BalletDailyApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
