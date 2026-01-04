import SwiftUI
internal import CoreData

/// 主界面的 Tab 导航视图
struct MainTabView: View {
    @State private var selectedTab: Tab = .sessions
    
    enum Tab {
        case sessions  // 课程列表
        case trends    // 趋势分析
        case settings  // 设置
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            SessionListView()
                .tabItem {
                    Label("课程", systemImage: "figure.dance")
                }
                .tag(Tab.sessions)
            
            TrendView()
                .tabItem {
                    Label("趋势", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.trends)
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(HealthKitManager())
}

