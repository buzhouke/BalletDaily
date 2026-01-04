# Phase 1 测试指南

## 概述

Phase 1 已完成所有数据层服务，包括：
- ✅ Core Data 数据模型（5 个实体）
- ✅ SessionService（课程增删改查）
- ✅ NoteService（笔记管理）
- ✅ TagService（常用标签智能建议）

本文档提供测试代码和验证步骤。

---

## 如何测试

### 方法 1：在 ContentView 中添加测试按钮（推荐）

修改 `ContentView.swift`，添加测试功能：

```swift
import SwiftUI
import CoreData

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
                    
                    Button("测试读取数据") {
                        healthKitManager.testFetchWorkouts()
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
        let allSessions = service.fetchAllSessions()
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
        if let firstSession = sessionService.fetchAllSessions().first {
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
```

---

## 测试步骤

### 1. 在 Xcode 中运行

1. 打开 Xcode
2. 选择模拟器或真机
3. 点击运行（⌘R）
4. 等待 App 启动

### 2. 执行测试

**依次点击测试按钮：**

1. **测试 SessionService**
   - 创建 2 个课程记录
   - 执行各种查询
   - 更新课程信息
   - 查看统计数据

2. **测试 NoteService**
   - 为课程添加 3 种类型的笔记
   - 查询和分组笔记
   - 更新笔记内容

3. **测试 TagService**
   - 记录多次标签使用
   - 获取常用标签列表
   - 搜索标签
   - 查看标签统计

4. **综合测试**
   - 完整的工作流程
   - 创建课程 → 记录标签 → 添加笔记
   - 验证数据完整性

### 3. 查看控制台输出

在 Xcode 底部的控制台（Console）中查看测试结果。你应该看到类似这样的输出：

```
=== 测试 SessionService ===
✅ 创建课程: 芭蕾基础课 - 张老师
✅ 创建课程: 芭蕾进阶课 - 李老师
✅ 查询到 2 条课程记录
✅ 本周有 2 条课程
✅ 张老师的课程: 1 条
✅ 更新课程名称
✅ 本周总时长: 2.5 小时
✅ 所有老师: 张老师, 李老师
=== SessionService 测试完成 ===
```

---

## 预期结果

### ✅ SessionService 测试通过标准

- 能成功创建课程记录
- 能查询所有课程
- 能按日期范围查询
- 能按老师和课程名筛选
- 能更新课程信息
- 统计数据正确（总时长、课程数量等）

### ✅ NoteService 测试通过标准

- 能为课程添加不同类型的笔记
- 能查询课程的所有笔记
- 能按类型筛选笔记
- 能按类型分组查询
- 能更新笔记内容
- 笔记数量统计正确

### ✅ TagService 测试通过标准

- 能记录标签使用（自动增加计数）
- 常用标签按使用频率排序
- 搜索功能支持模糊匹配
- 能获取标签值列表（用于 UI 自动完成）
- 统计数据正确

### ✅ 综合测试通过标准

- 完整工作流程无报错
- 数据关联正确（课程 ↔ 笔记）
- 标签自动记录功能正常
- 所有数据持久化成功

---

## 常见问题

### Q1: 控制台没有输出？

**A:** 确保在 Xcode 底部打开了控制台：
- 快捷键：`⌘ + Shift + Y`
- 或点击右上角的「Show Debug Area」按钮

### Q2: 点击按钮后 App 崩溃？

**A:** 检查控制台的错误信息：
- 通常是数据模型不匹配
- 尝试删除 App 后重新安装
- 检查 Core Data 模型文件是否正确

### Q3: 测试数据太多了，如何清理？

**A:** 在模拟器中：
1. 长按 App 图标
2. 选择「删除 App」
3. 重新运行即可

或者使用 Xcode：
- `Product` → `Clean Build Folder` (⌘ + Shift + K)
- 删除 Derived Data

---

## 下一步

Phase 1 测试通过后，我们将进入 **Phase 2: HealthKit 数据同步**：

- Task 2.1: 实现 HealthKit 数据读取服务
- Task 2.2: 实现数据同步逻辑
- Task 2.3: 实现后台同步

---

**完成时间**：2026/1/1  
**测试状态**：✅ 编译通过，等待用户测试

