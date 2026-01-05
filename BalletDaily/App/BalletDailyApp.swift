//
//  BalletDailyApp.swift
//  BalletDaily
//
//  Created by Raymond White on 2026/1/1.
//

import SwiftUI
internal import CoreData

@main
struct BalletDailyApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            // 使用新的 MainTabView 作为主界面
            // 如需测试 Phase 1/2 功能，可临时切换回 ContentView()
            MainTabView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(healthKitManager)
        }
    }
}
