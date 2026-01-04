import SwiftUI
internal import CoreData

/// 设置页面
struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("enableHealthKit") private var enableHealthKit = true
    @AppStorage("enableAutoSync") private var enableAutoSync = true
    @AppStorage("syncDays") private var syncDays = 365
    @AppStorage("lastSyncDate") private var lastSyncTimestamp: Double = 0
    @AppStorage("defaultTrendView") private var defaultTrendView = "week"
    @AppStorage("theme") private var theme = "system"
    
    @State private var isSyncing = false
    @State private var syncStatus = ""
    @State private var showingSyncAlert = false
    @State private var syncAlertMessage = ""
    @State private var showingQuickEdit = false
    @State private var importedSessions: [BalletSession] = []
    
    private var lastSyncDate: Date? {
        lastSyncTimestamp > 0 ? Date(timeIntervalSince1970: lastSyncTimestamp) : nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 标签管理
                Section {
                    NavigationLink {
                        PresetTagsView()
                    } label: {
                        Label("预设标签", systemImage: "tag.fill")
                    }
                } header: {
                    Text("标签管理")
                } footer: {
                    Text("管理课程名称、老师、地点等预设标签，支持自定义 Emoji 图标。")
                }
                
                // HealthKit 同步
                Section {
                    // 授权状态
                    HStack {
                        Text("授权状态")
                        Spacer()
                        if healthKitManager.isAuthorized {
                            Label("已授权", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        } else {
                            Label("未授权", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                    }
                    
                    // 请求权限按钮
                    if !healthKitManager.isAuthorized {
                        Button {
                            healthKitManager.requestAuthorization()
                        } label: {
                            Label("请求访问权限", systemImage: "hand.raised.fill")
                        }
                    }
                    
                    // 自动同步开关
                    if healthKitManager.isAuthorized {
                        Toggle("自动同步训练记录", isOn: $enableAutoSync)
                    }
                    
                    // 同步范围设置
                    if healthKitManager.isAuthorized {
                        Picker("同步时间范围", selection: $syncDays) {
                            Text("最近 30 天").tag(30)
                            Text("最近 90 天").tag(90)
                            Text("最近半年").tag(180)
                            Text("最近一年").tag(365)
                            Text("所有数据").tag(3650)
                        }
                    }
                    
                    // 上次同步时间
                    if let lastSync = lastSyncDate {
                        HStack {
                            Text("上次同步")
                            Spacer()
                            Text(formatLastSyncTime(lastSync))
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        }
                    }
                    
                    // 立即同步按钮
                    if healthKitManager.isAuthorized {
                        Button {
                            performSync()
                        } label: {
                            HStack {
                                if isSyncing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                Text(isSyncing ? "同步中..." : "立即同步")
                            }
                        }
                        .disabled(isSyncing)
                        
                        // 同步状态
                        if !syncStatus.isEmpty {
                            Text(syncStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("HealthKit 同步")
                } footer: {
                    if healthKitManager.isAuthorized {
                        if enableAutoSync {
                            Text("✅ 自动同步已启用。应用启动时会自动导入新的训练记录。\n🔍 同步范围：\(syncDaysDescription)")
                        } else {
                            Text("ℹ️ 自动同步已关闭。请点击「立即同步」手动导入训练记录。")
                        }
                    } else {
                        Text("授权后可以自动导入 Apple Watch 记录的芭蕾训练数据和心率等健康指标。")
                    }
                }
                
                // 显示偏好
                Section("显示偏好") {
                    Picker("默认趋势视图", selection: $defaultTrendView) {
                        Text("本周").tag("week")
                        Text("本月").tag("month")
                        Text("本年").tag("year")
                    }
                    
                    Picker("主题", selection: $theme) {
                        Text("跟随系统").tag("system")
                        Text("浅色").tag("light")
                        Text("深色").tag("dark")
                    }
                }
                
                // 数据管理
                Section("数据管理") {
                    Button("导出数据") {
                        // TODO: Phase 6 实现
                    }
                    
                    HStack {
                        Text("iCloud 同步")
                        Spacer()
                        Text("未启用")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("GitHub 仓库", destination: URL(string: "https://github.com")!)
                }
                
            }
            .navigationTitle("设置")
            .alert("同步完成", isPresented: $showingSyncAlert) {
                if !importedSessions.isEmpty {
                    Button("稍后编辑", role: .cancel) {
                        importedSessions = []
                    }
                    Button("立即编辑") {
                        showingQuickEdit = true
                    }
                } else {
                    Button("确定", role: .cancel) { }
                }
            } message: {
                Text(syncAlertMessage)
            }
            .sheet(isPresented: $showingQuickEdit) {
                QuickEditImportedSessionsView(sessions: importedSessions, context: viewContext)
            }
            .onAppear {
                // 如果启用自动同步，在首次打开设置时检查是否需要同步
                checkAndAutoSync()
            }
        }
    }
    
    // MARK: - 同步相关方法
    
    /// 执行同步
    private func performSync() {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncStatus = "正在扫描训练记录..."
        
        Task {
            do {
                let importService = WorkoutImportService(
                    context: viewContext,
                    healthKitManager: healthKitManager
                )
                
                print("\n" + "=" * 60)
                print("🔄 开始同步 HealthKit 数据")
                print("=" * 60)
                print("📅 同步范围: 最近 \(syncDays) 天")
                print("⏰ 开始时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))")
                
                let startTime = Date()
                let results = try await importService.scanAndImportBalletWorkouts(
                    days: syncDays,
                    autoImport: true
                )
                let endTime = Date()
                
                let duration = endTime.timeIntervalSince(startTime)
                let successCount = results.filter { $0.success }.count
                let skipCount = results.count - successCount
                
                // 更新上次同步时间
                await MainActor.run {
                    lastSyncTimestamp = Date().timeIntervalSince1970
                }
                
                print("\n" + "-" * 60)
                print("✅ 同步完成")
                print("-" * 60)
                print("⏱️  耗时: \(String(format: "%.2f", duration)) 秒")
                print("📦 总记录: \(results.count)")
                print("✅ 新导入: \(successCount) 条")
                print("⏭️  已存在: \(skipCount) 条")
                
                // 显示详细记录（最多5条）
                if !results.isEmpty {
                    print("\n最近导入的记录:")
                    for (index, result) in results.prefix(5).enumerated() {
                        let status = result.success ? "✅" : "⏭️"
                        print("  \(status) [\(index + 1)] \(DateHelper.formatSessionDate(result.workout.startDate)) - \(DateHelper.formatDuration(result.workout.duration))")
                    }
                    if results.count > 5 {
                        print("  ... 还有 \(results.count - 5) 条记录")
                    }
                }
                
                print("=" * 60 + "\n")
                
                await MainActor.run {
                    isSyncing = false
                    if successCount > 0 {
                        syncStatus = "✅ 成功导入 \(successCount) 条新记录"
                        
                        // 获取新导入的课程
                        let newSessions = results.filter { $0.success }.compactMap { $0.session }
                        importedSessions = newSessions
                        
                        // 如果有新导入的课程，显示快速编辑选项
                        if !newSessions.isEmpty {
                            syncAlertMessage = "成功导入 \(successCount) 条新的训练记录！\n\n是否要为这些课程添加名称和老师信息？"
                            showingSyncAlert = true
                        } else {
                            syncAlertMessage = "成功导入 \(successCount) 条新的训练记录！\n\n已跳过 \(skipCount) 条已存在的记录。"
                            showingSyncAlert = true
                        }
                    } else if results.isEmpty {
                        syncStatus = "ℹ️ 没有找到训练记录"
                        syncAlertMessage = "在选择的时间范围内没有找到舞蹈类型的训练记录。\n\n请确保在健康 App 中有芭蕾、舞蹈等类型的训练记录。"
                        showingSyncAlert = true
                    } else {
                        syncStatus = "ℹ️ 所有记录已是最新"
                        syncAlertMessage = "找到 \(results.count) 条训练记录，但都已经导入过了。"
                        showingSyncAlert = true
                    }
                    
                    // 5秒后清除状态消息
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        syncStatus = ""
                    }
                }

            } catch {
                print("\n❌ 同步失败: \(error.localizedDescription)\n")
                await MainActor.run {
                    isSyncing = false
                    syncStatus = "❌ 同步失败"
                    syncAlertMessage = "同步失败：\(error.localizedDescription)\n\n请检查 HealthKit 权限是否已授予。"
                    showingSyncAlert = true
                }
            }
        }
    }
    
    /// 检查并自动同步（如果需要）
    private func checkAndAutoSync() {
        // 只有在启用自动同步且已授权的情况下才执行
        guard enableAutoSync && healthKitManager.isAuthorized else {
            return
        }
        
        // 如果从未同步过，或者距离上次同步超过24小时，则自动同步
        let shouldSync: Bool
        if let lastSync = lastSyncDate {
            let hoursSinceLastSync = Date().timeIntervalSince(lastSync) / 3600
            shouldSync = hoursSinceLastSync > 24
        } else {
            shouldSync = true
        }
        
        if shouldSync {
            print("🔄 自动同步触发（距上次同步超过24小时）")
            performSync()
        }
    }
    
    /// 格式化上次同步时间
    private func formatLastSyncTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        
        if days > 0 {
            return "\(days) 天前"
        } else if hours > 0 {
            return "\(hours) 小时前"
        } else {
            return "刚刚"
        }
    }
    
    /// 同步天数描述
    private var syncDaysDescription: String {
        switch syncDays {
        case 30: return "最近 30 天"
        case 90: return "最近 90 天"
        case 180: return "最近半年"
        case 365: return "最近一年"
        case 3650: return "所有数据"
        default: return "最近 \(syncDays) 天"
        }
    }
}

// MARK: - String Extension

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(HealthKitManager())
}

