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
                
                // 运动数据同步
                Section {
                    // 自动同步开关
                    Toggle("自动同步训练记录", isOn: $enableAutoSync)
                    
                    // 同步范围设置
                    Picker("同步时间范围", selection: $syncDays) {
                        Text("最近 30 天").tag(30)
                        Text("最近 90 天").tag(90)
                        Text("最近半年").tag(180)
                        Text("最近一年").tag(365)
                        Text("所有数据").tag(3650)
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
                } header: {
                    Text("运动数据同步")
                } footer: {
                    if enableAutoSync {
                        Text("✅ 自动同步已启用。应用启动时会自动导入新的训练记录。\n🔍 同步范围：\(syncDaysDescription)\n\n💡 需要授权访问「健康」App 中的训练数据。如果同步失败，请前往系统设置授权。")
                    } else {
                        Text("ℹ️ 自动同步已关闭。点击「立即同步」可手动导入训练记录。\n\n💡 需要授权访问「健康」App 中的训练数据。")
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
                
                // 检查是否是权限问题
                let isAuthError = (error as? HealthKitError) == .notAuthorized ||
                                 (error as NSError).domain == "com.apple.healthkit" ||
                                 error.localizedDescription.contains("授权") ||
                                 error.localizedDescription.contains("权限")
                
                await MainActor.run {
                    isSyncing = false
                    syncStatus = "❌ 同步失败"
                    
                    if isAuthError {
                        // 权限问题，提供引导
                        syncAlertMessage = """
                        需要授权访问「健康」App 中的训练数据才能同步。
                        
                        请按以下步骤操作：
                        1. 打开「设置」App
                        2. 滚动到「健康」
                        3. 点击「数据存取与设备」
                        4. 找到「BalletDaily」
                        5. 开启「训练」权限
                        
                        完成后返回应用重新尝试同步。
                        """
                    } else {
                        // 其他错误
                        syncAlertMessage = "同步失败：\(error.localizedDescription)\n\n如果问题持续出现，请检查网络连接或联系支持。"
                    }
                    
                    showingSyncAlert = true
                }
            }
        }
    }
    
    /// 检查并自动同步（如果需要）
    private func checkAndAutoSync() {
        // 只有在启用自动同步的情况下才执行
        guard enableAutoSync else {
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
            // 直接尝试同步，如果没有权限会在同步时友好提示
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

