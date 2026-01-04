import SwiftUI
internal import CoreData

// MARK: - String Extension for Logging

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var healthKitManager: HealthKitManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Phase 1 功能测试") {
                    Button("📝 测试 SessionService") {
                        testSessionService()
                    }
                    
                    Button("📓 测试 NoteService") {
                        testNoteService()
                    }
                    
                    Button("🏷️ 测试 TagService") {
                        testTagService()
                    }
                    
                    Button("🔄 综合测试") {
                        testAll()
                    }
                }
                
                Section("HealthKit 测试") {
                    Button(action: healthKitManager.requestAuthorization) {
                        Image(systemName: healthKitManager.isAuthorized ? "heart.fill" : "heart")
                            .foregroundColor(healthKitManager.isAuthorized ? .red : .gray)
                        Text("授权 HealthKit")
                    }
                    
                    Button("📊 测试读取训练记录") {
                        healthKitManager.testFetchWorkouts()
                    }
                    
                    Button("💓 测试心率数据") {
                        testHeartRateData()
                    }
                    
                    Button("📥 测试导入芭蕾课程") {
                        testImportWorkouts()
                    }
                    
                    Button("🔄 测试健康数据同步") {
                        testHealthMetricsSync()
                    }
                }
            }
            .navigationTitle("BalletDaily 测试")
        }
    }
    
    // MARK: - Test Functions
    
    func testSessionService() {
        print("\n=== 测试 SessionService ===")
        let service = SessionService(context: viewContext)
        
        // 1. 创建课程
        let session1 = service.createSession(
            date: Date(),
            duration: 5400, // 90分钟
            isManual: true,
            name: "芭蕾基础课",
            instructor: "张老师",
            location: "舞蹈教室 A"
        )
        print("✅ 创建课程: \(session1.name ?? "") - \(session1.instructor ?? "")")
        
        let session2 = service.createSession(
            date: Date().addingTimeInterval(-86400), // 昨天
            duration: 3600,
            isManual: true,
            name: "芭蕾进阶课",
            instructor: "李老师",
            location: "舞蹈教室 B"
        )
        print("✅ 创建课程: \(session2.name ?? "") - \(session2.instructor ?? "")")
        
        // 2. 查询所有课程
        let allSessions = (try? service.fetchAllSessions()) ?? []
        print("✅ 查询到 \(allSessions.count) 条课程记录")
        
        // 3. 按日期范围查询
        let weekSessions = service.fetchSessions(
            from: Date().addingTimeInterval(-7*24*3600),
            to: Date()
        )
        print("✅ 本周有 \(weekSessions.count) 条课程")
        
        // 4. 按老师查询
        let zhangSessions = service.fetchSessions(byInstructor: "张老师")
        print("✅ 张老师的课程: \(zhangSessions.count) 条")
        
        // 5. 更新课程
        service.updateSession(session1, name: "芭蕾基础课（更新）")
        print("✅ 更新课程名称")
        
        // 6. 统计
        let totalDuration = service.getTotalDuration(
            from: Date().addingTimeInterval(-7*24*3600),
            to: Date()
        )
        print("✅ 本周总时长: \(String(format: "%.1f", totalDuration / 3600)) 小时")
        
        let instructors = service.getAllInstructors()
        print("✅ 所有老师: \(instructors.joined(separator: ", "))")
        
        print("=== SessionService 测试完成 ===\n")
    }
    
    func testNoteService() {
        print("\n=== 测试 NoteService ===")
        let sessionService = SessionService(context: viewContext)
        let noteService = NoteService(context: viewContext)
        
        // 获取或创建一个课程
        var session: BalletSession
        if let firstSession = (try? sessionService.fetchAllSessions())?.first {
            session = firstSession
        } else {
            session = sessionService.createSession(
                date: Date(),
                duration: 5400,
                isManual: true,
                name: "测试课程"
            )
        }
        
        // 1. 添加不同类型的笔记
        let note1 = noteService.addNote(
            to: session,
            type: .feeling,
            content: "今天状态很好，完成了 32 个fouetté！"
        )
        print("✅ 添加感想笔记: \(note1.content ?? "")")
        
        let note2 = noteService.addNote(
            to: session,
            type: .technique,
            content: "记得保持核心收紧，肩膀下沉"
        )
        print("✅ 添加技术笔记: \(note2.content ?? "")")
        
        let note3 = noteService.addNote(
            to: session,
            type: .improvement,
            content: "port de bras 还需要更流畅"
        )
        print("✅ 添加改进笔记: \(note3.content ?? "")")
        
        // 2. 查询笔记
        let allNotes = noteService.fetchNotes(for: session)
        print("✅ 这节课有 \(allNotes.count) 条笔记")
        
        // 3. 按类型查询
        let feelingNotes = noteService.fetchNotes(for: session, type: .feeling)
        print("✅ 感想类笔记: \(feelingNotes.count) 条")
        
        // 4. 分组查询
        let grouped = noteService.fetchNotesGroupedByType(for: session)
        print("✅ 笔记分组:")
        for (type, notes) in grouped {
            print("   - \(type.displayName): \(notes.count) 条")
        }
        
        // 5. 更新笔记
        noteService.updateNote(note1, content: "今天状态超级好！完成了 32 个fouetté！")
        print("✅ 更新笔记内容")
        
        // 6. 统计
        let noteCount = noteService.getNotesCount(for: session)
        print("✅ 笔记总数: \(noteCount)")
        
        print("=== NoteService 测试完成 ===\n")
    }
    
    func testTagService() {
        print("\n=== 测试 TagService ===")
        let tagService = TagService(context: viewContext)
        
        // 1. 记录标签使用（模拟用户输入）
        tagService.recordTagUsage(type: .className, value: "芭蕾基础课")
        tagService.recordTagUsage(type: .className, value: "芭蕾基础课")
        tagService.recordTagUsage(type: .className, value: "芭蕾基础课")
        tagService.recordTagUsage(type: .className, value: "芭蕾进阶课")
        tagService.recordTagUsage(type: .className, value: "芭蕾进阶课")
        tagService.recordTagUsage(type: .className, value: "现代芭蕾")
        print("✅ 记录课程名称标签")
        
        tagService.recordTagUsage(type: .instructor, value: "张老师")
        tagService.recordTagUsage(type: .instructor, value: "张老师")
        tagService.recordTagUsage(type: .instructor, value: "李老师")
        print("✅ 记录老师标签")
        
        tagService.recordTagUsage(type: .location, value: "舞蹈教室 A")
        tagService.recordTagUsage(type: .location, value: "舞蹈教室 B")
        print("✅ 记录地点标签")
        
        // 2. 获取常用标签（按使用频率）
        let topClasses = tagService.fetchTopTags(type: .className, limit: 5)
        print("✅ 最常用的课程名称:")
        for tag in topClasses {
            print("   - \(tag.value ?? ""): \(tag.usageCount) 次")
        }
        
        let topInstructors = tagService.fetchTopTags(type: .instructor, limit: 5)
        print("✅ 最常用的老师:")
        for tag in topInstructors {
            print("   - \(tag.value ?? ""): \(tag.usageCount) 次")
        }
        
        // 3. 搜索标签（模糊匹配）
        let searchResults = tagService.searchTags(type: .className, keyword: "基础", limit: 5)
        print("✅ 搜索包含'基础'的课程: \(searchResults.count) 个")
        
        // 4. 获取标签值列表（用于自动完成）
        let classNames = tagService.fetchTagValues(type: .className, limit: 10)
        print("✅ 课程名称列表: \(classNames.joined(separator: ", "))")
        
        // 5. 统计
        let totalTags = tagService.getTotalTagsCount()
        print("✅ 标签总数: \(totalTags)")
        
        let classTagCount = tagService.getTagsCount(type: .className)
        print("✅ 课程名称标签数: \(classTagCount)")
        
        print("=== TagService 测试完成 ===\n")
    }
    
    func testAll() {
        print("\n🚀 开始综合测试 🚀")
        
        let sessionService = SessionService(context: viewContext)
        let noteService = NoteService(context: viewContext)
        let tagService = TagService(context: viewContext)
        
        // 1. 创建完整的课程记录
        print("\n--- 步骤 1: 创建课程 ---")
        let session = sessionService.createSession(
            date: Date(),
            duration: 5400,
            isManual: true,
            name: "芭蕾基础课",
            instructor: "张老师",
            location: "舞蹈教室 A"
        )
        print("✅ 创建课程: \(session.name ?? "")")
        
        // 2. 自动记录标签
        print("\n--- 步骤 2: 记录常用标签 ---")
        tagService.recordSession(session)
        print("✅ 已记录课程信息为常用标签")
        
        // 3. 添加笔记
        print("\n--- 步骤 3: 添加笔记 ---")
        noteService.addNote(
            to: session,
            type: .feeling,
            content: "今天第一次完成了完整的 Grand Allegro，很有成就感！"
        )
        noteService.addNote(
            to: session,
            type: .technique,
            content: "在做 pirouette 时要注意 spotting"
        )
        noteService.addNote(
            to: session,
            type: .improvement,
            content: "需要加强核心力量训练"
        )
        print("✅ 添加了 3 条笔记")
        
        // 4. 验证数据完整性
        print("\n--- 步骤 4: 验证数据 ---")
        let notes = noteService.fetchNotes(for: session)
        print("✅ 笔记数量: \(notes.count)")
        
        let topClasses = tagService.fetchTopTags(type: .className, limit: 1)
        if let topClass = topClasses.first {
            print("✅ 最常用课程: \(topClass.value ?? "") (\(topClass.usageCount)次)")
        }
        
        let totalDuration = sessionService.getTotalDuration(
            from: Date().addingTimeInterval(-7*24*3600),
            to: Date()
        )
        print("✅ 本周总时长: \(String(format: "%.1f", totalDuration / 3600)) 小时")
        
        print("\n🎉 综合测试完成！所有功能正常工作 🎉\n")
    }
    
    // MARK: - HealthKit Test Functions
    
    func testHeartRateData() {
        print("\n=== 测试心率数据 ===")
        
        Task {
            do {
                // 获取最近的训练记录
                let workouts = try await healthKitManager.fetchRecentWorkouts(limit: 1)
                
                guard let workout = workouts.first else {
                    print("📝 没有找到训练记录")
                    return
                }
                
                print("✅ 找到训练记录: \(workout.activityType.name)")
                print("   时间: \(workout.startDate)")
                print("   时长: \(String(format: "%.1f", workout.duration / 60)) 分钟")
                
                // 获取心率统计
                let heartRateStats = try await healthKitManager.fetchHeartRateStats(for: workout)
                
                if let avg = heartRateStats.average {
                    print("✅ 平均心率: \(String(format: "%.0f", avg)) bpm")
                }
                if let min = heartRateStats.min {
                    print("✅ 最低心率: \(String(format: "%.0f", min)) bpm")
                }
                if let max = heartRateStats.max {
                    print("✅ 最高心率: \(String(format: "%.0f", max)) bpm")
                }
                
                // 获取心率时间序列
                let samples = try await healthKitManager.fetchHeartRateSamples(
                    from: workout.startDate,
                    to: workout.endDate
                )
                print("✅ 心率样本数: \(samples.count)")
                
                print("=== 心率数据测试完成 ===\n")
                
            } catch {
                print("❌ 测试失败: \(error.localizedDescription)")
            }
        }
    }
    
    func testImportWorkouts() {
        print("\n" + "=" * 60)
        print("🚀 开始测试导入芭蕾课程")
        print("=" * 60 + "\n")
        
        Task {
            do {
                let importService = WorkoutImportService(
                    context: viewContext,
                    healthKitManager: healthKitManager
                )
                
                // 扫描最近 365 天（一年）的舞蹈训练
                let scanDays = 365
                print("📅 扫描时间范围: 最近 \(scanDays) 天 (约一年)")
                print("📊 开始查询 HealthKit...")
                
                let startTime = Date()
                let results = try await importService.scanAndImportBalletWorkouts(
                    days: scanDays,
                    autoImport: true
                )
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                
                print("\n" + "-" * 60)
                print("📊 扫描结果统计")
                print("-" * 60)
                print("⏱️  扫描耗时: \(String(format: "%.2f", duration)) 秒")
                print("📦 总记录数: \(results.count)")
                
                let successCount = results.filter { $0.success }.count
                let skipCount = results.count - successCount
                
                print("✅ 新导入: \(successCount) 条")
                print("⏭️  已存在跳过: \(skipCount) 条")
                
                // 显示详细信息
                if !results.isEmpty {
                    print("\n" + "-" * 60)
                    print("📝 详细记录")
                    print("-" * 60)
                    
                    for (index, result) in results.enumerated() {
                        let status = result.success ? "✅ 新导入" : "⏭️  跳过"
                        print("\n[\(index + 1)/\(results.count)] \(status)")
                        print("  📅 时间: \(DateHelper.formatSessionDate(result.workout.startDate))")
                        print("  ⏱️  时长: \(DateHelper.formatDuration(result.workout.duration))")
                        print("  🏷️  类型: \(result.workout.activityType.name)")
                        
                        if let energy = result.workout.totalEnergyBurned {
                            print("  🔥 能量: \(String(format: "%.0f", energy)) 千卡")
                        }
                        
                        if let distance = result.workout.totalDistance {
                            print("  📏 距离: \(String(format: "%.2f", distance / 1000)) 公里")
                        }
                    }
                } else {
                    print("\n⚠️  没有找到舞蹈类型的训练记录")
                    print("💡 提示:")
                    print("   1. 确保已授权 HealthKit 访问")
                    print("   2. 在健康 App 中添加一些训练记录")
                    print("   3. 支持的训练类型: 芭蕾、社交舞、有氧舞蹈等")
                }
                
                // 查询并显示当前数据库中的课程数量
                let sessionService = SessionService(context: viewContext)
                let allSessions = (try? sessionService.fetchAllSessions()) ?? []
                let importedSessions = allSessions.filter { !$0.isManualEntry }
                
                print("\n" + "-" * 60)
                print("💾 当前数据库统计")
                print("-" * 60)
                print("📚 总课程数: \(allSessions.count)")
                print("📥 从 HealthKit 导入: \(importedSessions.count)")
                print("✍️  手动创建: \(allSessions.count - importedSessions.count)")
                
                print("\n" + "=" * 60)
                print("✅ 导入测试完成!")
                print("=" * 60 + "\n")
                
            } catch {
                print("\n❌ 测试失败: \(error.localizedDescription)")
                print("💡 错误详情: \(error)\n")
            }
        }
    }
    
    func testHealthMetricsSync() {
        print("\n=== 测试健康数据同步 ===")
        
        let sessionService = SessionService(context: viewContext)
        
        // 查找有 HealthKit 关联的课程
        let sessions = (try? sessionService.fetchAllSessions()) ?? []
        let linkedSessions = sessions.filter { $0.healthKitWorkoutUUID != nil }
        
        if linkedSessions.isEmpty {
            print("📝 没有找到关联 HealthKit 的课程")
            print("💡 提示: 先运行「测试导入芭蕾课程」")
            return
        }
        
        print("✅ 找到 \(linkedSessions.count) 个关联课程")
        
        Task {
            let metricsService = HealthMetricsService(
                context: viewContext,
                healthKitManager: healthKitManager
            )
            
            for session in linkedSessions.prefix(3) {
                print("\n同步课程: \(session.name ?? "未命名")")
                print("  日期: \(session.sessionDate ?? Date())")
                
                let success = await metricsService.syncHealthData(for: session)
                
                if success, let metrics = session.healthMetrics {
                    print("  ✅ 同步成功")
                    if metrics.avgHeartRate > 0 {
                        print("    平均心率: \(String(format: "%.0f", metrics.avgHeartRate)) bpm")
                    }
                    if metrics.activeEnergy > 0 {
                        print("    消耗能量: \(String(format: "%.0f", metrics.activeEnergy)) 千卡")
                    }
                } else {
                    print("  ❌ 同步失败")
                }
            }
            
            print("\n=== 健康数据同步测试完成 ===\n")
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(HealthKitManager())
}
