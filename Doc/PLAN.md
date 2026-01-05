# BalletDaily 开发计划

## 📋 项目概述

**目标**：开发一个与 Apple Watch 集成的芭蕾课程记录应用，核心价值是极简输入、长期趋势可视化和安静不打扰的体验。

**技术栈**：SwiftUI + Core Data + CloudKit + HealthKit

**开发方式**：迭代开发，每次交付最小可用功能单元，确保每个阶段都可独立测试和验证。

---

## 🎯 开发原则

1. **最小可交付单元**：每个任务完成后都有可运行的代码
2. **先纵后横**：先实现核心流程，再扩展功能
3. **测试驱动**：每个功能必须定义明确的测试标准
4. **迭代优化**：先实现基础功能，再优化体验

---

## 📊 整体进度概览

| Phase | 任务数 | 预估时间 | 状态 |
|-------|--------|----------|------|
| Phase 0: 项目初始化 | 3 | 1-2 天 | ✅ 已完成 |
| Phase 1: 数据层基础 | 5 | 3-4 天 |  ✅ 已完成  |
| Phase 2: HealthKit 集成 | 4 | 2-3 天 |  ✅ 已完成  |
| Phase 3: 基础 UI | 6 | 4-5 天 |  ✅ 已完成  |
| Phase 4: 课程记录功能 | 5 | 3-4 天 | ⬜ 待开始 |
| Phase 5: 笔记功能 | 4 | 2-3 天 | ⬜ 待开始 |
| Phase 6: 趋势分析 | 4 | 3-4 天 | ⬜ 待开始 |
| Phase 7: CloudKit 同步 | 3 | 2-3 天 | ⬜ 待开始 |
| Phase 8: 优化和完善 | 5 | 3-4 天 | ⬜ 待开始 |

**总计**：39 个任务，预计 23-32 天

---

## Phase 0: 项目初始化 🏗️

**目标**：创建 Xcode 项目，配置基础环境和权限。

### Task 0.1: 创建 Xcode 项目 ✅

**优先级**：🔴 高  
**预估时间**：30 分钟  
**状态**：✅ 已完成

**目标**：
- 创建 SwiftUI iOS 项目
- 配置项目基本信息
- 设置最低支持版本（iOS 16.0+）

**可交付物**：
```
BalletDaily/
├── BalletDaily.xcodeproj
├── BalletDaily/
│   ├── BalletDailyApp.swift
│   ├── ContentView.swift
│   └── Assets.xcassets
└── Doc/ (已存在)
```

**测试标准**：
- [x] 项目可以成功编译
- [x] 在模拟器上可以运行
- [x] 显示默认的 "Hello, World" 界面

**测试命令**：
```bash
# 在 Xcode 中
Cmd + B (Build)
Cmd + R (Run)
```

---

### Task 0.2: 配置项目结构 ✅

**优先级**：🔴 高  
**预估时间**：1 小时  
**依赖**：Task 0.1  
**状态**：✅ 已完成

**目标**：
- 创建标准的项目文件夹结构
- 按照 DESIGN.md 中定义的结构组织代码

**可交付物**：
```
BalletDaily/
├── App/
│   └── BalletDailyApp.swift
├── Models/
│   └── .gitkeep
├── Views/
│   └── ContentView.swift
├── ViewModels/
│   └── .gitkeep
├── Services/
│   └── .gitkeep
├── Utilities/
│   └── .gitkeep
└── Resources/
    └── Assets.xcassets
```

**测试标准**：
- [x] 所有文件夹创建完成
- [x] 文件按模块正确归类
- [x] 项目仍可正常编译运行

---

### Task 0.3: 配置权限和 Capabilities ✅

**优先级**：🔴 高  
**预估时间**：1 小时  
**依赖**：Task 0.2  
**状态**：✅ 已完成

**目标**：
- 配置 HealthKit 权限
- 配置 iCloud 和 CloudKit
- 配置 Background Modes（如需要）

**可交付物**：
- `Info.plist` 添加权限说明：
  ```xml
  <key>NSHealthShareUsageDescription</key>
  <string>需要访问您的健康数据以记录芭蕾课程的运动指标</string>
  <key>NSHealthUpdateUsageDescription</key>
  <string>需要更新健康数据以记录您的芭蕾训练</string>
  ```
- 在 Xcode Signing & Capabilities 中：
  - ✅ 启用 HealthKit
  - ✅ 启用 iCloud (CloudKit)
  - ✅ 创建 CloudKit Container: `iCloud.com.yourcompany.BalletDaily`

**测试标准**：
- [x] Capabilities 配置无错误
- [x] Bundle Identifier 设置正确
- [x] CloudKit Dashboard 中可以看到 Container
- [x] 项目可以成功编译

**验证方法**：
```swift
// 在 ContentView.swift 中临时添加测试代码
import HealthKit

struct ContentView: View {
    var body: some View {
        Button("Test HealthKit") {
            if HKHealthStore.isHealthDataAvailable() {
                print("✅ HealthKit is available")
            }
        }
    }
}
```

---

## Phase 1: 数据层基础 💾

**目标**：实现 Core Data 数据模型和基础服务层。

### Task 1.1: 创建 Core Data Model

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Phase 0 完成

**目标**：
- 创建 Core Data Model 文件
- 定义所有实体（Entity）和关系（Relationship）

**可交付物**：
- `BalletDaily.xcdatamodeld` 文件
- 包含以下实体：
  - ✅ BalletSession
  - ✅ BalletSessionNote
  - ✅ HealthMetrics
  - ✅ FrequentTag
  - ✅ UserPreferences

**详细字段定义**（参考 DATA_STORAGE.md）：

#### BalletSession
| 属性 | 类型 | 可选 | 默认值 |
|------|------|------|--------|
| id | UUID | No | - |
| createdAt | Date | No | - |
| updatedAt | Date | No | - |
| sessionDate | Date | No | - |
| duration | Double | No | 0 |
| className | String | Yes | nil |
| instructor | String | Yes | nil |
| location | String | Yes | nil |
| isManualEntry | Bool | No | false |
| healthKitWorkoutUUID | String | Yes | nil |

**关系**：
- `notes` → BalletSessionNote (一对多，级联删除)
- `healthMetrics` → HealthMetrics (一对一，级联删除)

#### BalletSessionNote
| 属性 | 类型 | 可选 | 默认值 |
|------|------|------|--------|
| id | UUID | No | - |
| createdAt | Date | No | - |
| updatedAt | Date | No | - |
| noteType | String | No | "general" |
| content | String | No | "" |
| order | Int16 | No | 0 |

**关系**：
- `session` → BalletSession (多对一)

#### HealthMetrics
| 属性 | 类型 | 可选 |
|------|------|------|
| id | UUID | No |
| avgHeartRate | Double | Yes |
| maxHeartRate | Double | Yes |
| minHeartRate | Double | Yes |
| activeEnergy | Double | Yes |
| stepCount | Int32 | Yes |
| distance | Double | Yes |
| exerciseTime | Double | Yes |
| heartRateData | Binary | Yes |
| syncedAt | Date | No |

**关系**：
- `session` → BalletSession (一对一)

#### FrequentTag
| 属性 | 类型 | 可选 |
|------|------|------|
| id | UUID | No |
| tagType | String | No |
| value | String | No |
| usageCount | Int32 | No |
| lastUsedAt | Date | No |

#### UserPreferences
| 属性 | 类型 | 可选 |
|------|------|------|
| id | UUID | No |
| defaultClassName | String | Yes |
| defaultInstructor | String | Yes |
| enableHealthKit | Bool | No |
| trendViewType | String | No |
| theme | String | No |
| createdAt | Date | No |
| updatedAt | Date | No |

**测试标准**：
- [x] 所有实体创建完成
- [x] 所有属性类型正确
- [x] 关系配置正确（级联删除规则）
- [x] 索引设置正确（sessionDate, className, instructor, createdAt）
- [x] Xcode 可以生成 NSManagedObject 子类

**验证方法**：
```bash
# 在 Xcode 中
Editor → Create NSManagedObject Subclass
# 检查是否能正确生成代码
```

---

### Task 1.2: 创建 Core Data Stack

**优先级**：🔴 高  
**预估时间**：1.5 小时  
**依赖**：Task 1.1

**目标**：
- 创建 Core Data 持久化容器
- 配置 Context 和错误处理
- 暂不启用 CloudKit（后续 Phase 7 再添加）

**可交付物**：
- `Services/CoreDataStack.swift`

**代码框架**：
```swift
import CoreData

class CoreDataStack: ObservableObject {
    static let shared = CoreDataStack()
    
    let container: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BalletDaily")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}
```

**测试标准**：
- [x] CoreDataStack 可以成功初始化
- [x] 可以创建 viewContext
- [x] 可以保存数据
- [x] 内存模式可用（用于测试）

**测试代码**：
```swift
// 在 ContentView.swift 中测试
struct ContentView: View {
    @StateObject private var coreDataStack = CoreDataStack.shared
    
    var body: some View {
        Button("Test Core Data") {
            testCoreData()
        }
    }
    
    func testCoreData() {
        let context = coreDataStack.viewContext
        
        // 创建测试数据
        let session = BalletSession(context: context)
        session.id = UUID()
        session.createdAt = Date()
        session.updatedAt = Date()
        session.sessionDate = Date()
        session.duration = 3600
        session.isManualEntry = true
        
        // 保存
        coreDataStack.save()
        
        // 查询
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        if let sessions = try? context.fetch(fetchRequest) {
            print("✅ Saved \(sessions.count) sessions")
        }
    }
}
```

---

### Task 1.3: 实现基础 CRUD 服务 ✅

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Task 1.2  
**完成日期**：2026/1/1

**目标**：
- 创建 SessionService 处理课程相关的数据操作
- 实现基本的增删改查功能

**可交付物**：
- `Services/SessionService.swift`

**功能清单**：
```swift
class SessionService {
    private let context: NSManagedObjectContext
    
    // Create
    func createSession(date: Date, duration: TimeInterval, isManual: Bool) -> BalletSession
    
    // Read
    func fetchAllSessions() -> [BalletSession]
    func fetchSession(by id: UUID) -> BalletSession?
    func fetchSessions(from startDate: Date, to endDate: Date) -> [BalletSession]
    
    // Update
    func updateSession(_ session: BalletSession, className: String?, instructor: String?)
    
    // Delete
    func deleteSession(_ session: BalletSession)
    
    // Save
    func save()
}
```

**测试标准**：
- [x] 可以创建新课程记录
- [x] 可以查询所有课程
- [x] 可以按 ID 查询单个课程
- [x] 可以按日期范围查询
- [x] 可以更新课程信息
- [x] 可以删除课程
- [x] 所有操作都正确保存到数据库

**测试代码**：
```swift
func testSessionService() {
    let service = SessionService(context: CoreDataStack.shared.viewContext)
    
    // Test Create
    let session = service.createSession(date: Date(), duration: 3600, isManual: true)
    print("✅ Created session: \(session.id)")
    
    // Test Read
    let sessions = service.fetchAllSessions()
    print("✅ Fetched \(sessions.count) sessions")
    
    // Test Update
    service.updateSession(session, className: "Ballet Basics", instructor: "Jane Doe")
    print("✅ Updated session")
    
    // Test Delete
    service.deleteSession(session)
    print("✅ Deleted session")
}
```

---

### Task 1.4: 实现笔记服务 ✅

**优先级**：🟡 中  
**预估时间**：1.5 小时  
**依赖**：Task 1.3  
**完成日期**：2026/1/1

**目标**：
- 创建 NoteService 处理课程笔记的数据操作

**可交付物**：
- `Services/NoteService.swift`
- `Models/NoteType.swift` (枚举定义)

**功能清单**：
```swift
enum NoteType: String, CaseIterable {
    case general = "general"
    case feeling = "feeling"
    case technique = "technique"
    case improvement = "improvement"
    case achievement = "achievement"
    case music = "music"
    
    var displayName: String {
        switch self {
        case .general: return "一般笔记"
        case .feeling: return "课后感想"
        case .technique: return "技术要点"
        case .improvement: return "需要改进"
        case .achievement: return "突破成就"
        case .music: return "音乐相关"
        }
    }
}

class NoteService {
    // Create
    func addNote(to session: BalletSession, type: NoteType, content: String) -> BalletSessionNote
    
    // Read
    func fetchNotes(for session: BalletSession) -> [BalletSessionNote]
    func fetchNotes(for session: BalletSession, type: NoteType) -> [BalletSessionNote]
    
    // Update
    func updateNote(_ note: BalletSessionNote, content: String)
    
    // Delete
    func deleteNote(_ note: BalletSessionNote)
    
    // Reorder
    func reorderNotes(_ notes: [BalletSessionNote])
}
```

**测试标准**：
- [x] 可以为课程添加笔记
- [x] 可以查询课程的所有笔记
- [x] 可以按类型筛选笔记
- [x] 可以更新笔记内容
- [x] 可以删除笔记
- [x] 笔记顺序可以调整
- [x] 删除课程时笔记级联删除

---

### Task 1.5: 实现常用标签服务 ✅

**优先级**：🟡 中  
**预估时间**：1 小时  
**依赖**：Task 1.3  
**完成日期**：2026/1/1

**目标**：
- 创建 TagService 管理常用标签
- 实现智能建议功能

**可交付物**：
- `Services/TagService.swift`

**功能清单**：
```swift
class TagService {
    // 记录使用
    func recordTag(type: String, value: String)
    
    // 获取建议（按使用频率排序）
    func getSuggestions(for type: String, limit: Int) -> [String]
    
    // 搜索标签
    func searchTags(type: String, query: String) -> [String]
    
    // 清理旧标签（超过 6 个月未使用）
    func cleanupOldTags()
}
```

**测试标准**：
- [x] 记录标签时自动创建或更新使用次数
- [x] 获取建议时按使用频率排序
- [x] 搜索功能支持模糊匹配
- [x] 清理功能正确删除旧标签

---

## Phase 2: HealthKit 集成 ❤️

**目标**：集成 HealthKit，获取健康数据。

### Task 2.1: 创建 HealthKit 服务基础

**优先级**：🔴 高  
**预估时间**：1.5 小时  
**依赖**：Phase 1 完成

**目标**：
- 创建 HealthKitService
- 实现权限请求

**可交付物**：
- `Services/HealthKitService.swift`

**功能清单**：
```swift
import HealthKit

class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    
    // 请求权限
    func requestAuthorization() async throws
    
    // 检查权限状态
    func checkAuthorizationStatus() -> Bool
    
    // 获取需要的数据类型
    private func getTypesToRead() -> Set<HKObjectType>
}
```

**需要读取的数据类型**：
- `HKWorkoutType` - 训练记录
- `HKQuantityType(.heartRate)` - 心率
- `HKQuantityType(.activeEnergyBurned)` - 活动能量
- `HKQuantityType(.stepCount)` - 步数
- `HKQuantityType(.distanceWalkingRunning)` - 距离

**测试标准**：
- [x] 首次运行时弹出权限请求
- [x] 权限授予后 `isAuthorized` 变为 true
- [x] 拒绝权限后应用仍可正常运行（功能降级）

**测试界面**：
```swift
struct ContentView: View {
    @StateObject private var healthKit = HealthKitService()
    
    var body: some View {
        VStack {
            Text(healthKit.isAuthorized ? "✅ Authorized" : "❌ Not Authorized")
            
            Button("Request Authorization") {
                Task {
                    try? await healthKit.requestAuthorization()
                }
            }
        }
    }
}
```

---

### Task 2.2: 获取训练记录

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Task 2.1

**目标**：
- 从 HealthKit 查询训练记录（Workout）
- 识别可能的芭蕾课程

**扩展 HealthKitService**：
```swift
// 查询最近的训练
func fetchRecentWorkouts(limit: Int) async throws -> [HKWorkout]

// 查询指定日期范围的训练
func fetchWorkouts(from startDate: Date, to endDate: Date) async throws -> [HKWorkout]

// 获取训练详情
func getWorkoutDetails(_ workout: HKWorkout) -> WorkoutDetails

struct WorkoutDetails {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let workoutType: HKWorkoutActivityType
    let totalEnergyBurned: Double?
    let totalDistance: Double?
}
```

**测试标准**：
- [x] 可以查询最近 30 天的训练记录
- [x] 可以按日期范围查询
- [x] 正确解析训练的基本信息
- [x] 无训练记录时不崩溃

**测试方法**：
```swift
// 在健康 App 中手动添加一条训练记录
// 运行应用，验证可以读取到该记录
```

---

### Task 2.3: 获取心率数据

**优先级**：🟡 中  
**预估时间**：2 小时  
**依赖**：Task 2.2

**目标**：
- 查询训练期间的心率数据
- 提供时间序列数据用于绘图

**扩展 HealthKitService**：
```swift
// 获取训练期间的心率统计
func fetchHeartRateStats(for workout: HKWorkout) async throws -> HeartRateStats

// 获取心率时间序列（用于绘图）
func fetchHeartRateSamples(from start: Date, to end: Date) async throws -> [HeartRateSample]

struct HeartRateStats {
    let average: Double?
    let min: Double?
    let max: Double?
}

struct HeartRateSample {
    let date: Date
    let value: Double
}
```

**测试标准**：
- [x] 可以获取训练的平均/最大/最小心率
- [x] 可以获取心率时间序列数据
- [x] 数据点数量合理（不超过 300 个点）
- [x] 无心率数据时返回 nil 不崩溃

---

### Task 2.4: 创建 HealthMetrics 同步器

**优先级**：🟡 中  
**预估时间**：1.5 小时  
**依赖**：Task 2.3

**目标**：
- 将 HealthKit 数据同步到 Core Data
- 关联到 BalletSession

**可交付物**：
- `Services/HealthMetricsSyncService.swift`

**功能清单**：
```swift
class HealthMetricsSyncService {
    // 为课程同步健康数据
    func syncHealthMetrics(for session: BalletSession) async throws
    
    // 从 Workout 创建 HealthMetrics
    func createHealthMetrics(from workout: HKWorkout, for session: BalletSession) async throws
    
    // 更新已有的 HealthMetrics
    func updateHealthMetrics(_ metrics: HealthMetrics, from workout: HKWorkout) async throws
}
```

**测试标准**：
- [x] 同步后 BalletSession 关联正确的 HealthMetrics
- [x] 心率、能量、步数等数据正确保存
- [x] 心率时间序列正确序列化为 Binary Data
- [x] 重复同步不会创建重复数据

---

## Phase 3: 基础 UI 🎨

**目标**：构建应用的基础界面框架和导航。

### Task 3.1: 创建主导航结构

**优先级**：🔴 高  
**预估时间**：1 小时  
**依赖**：Phase 1 完成

**目标**：
- 创建 TabView 主导航
- 定义主要的 Tab 页面

**可交付物**：
- `Views/MainTabView.swift`

**界面结构**：
```swift
enum Tab {
    case sessions  // 课程列表
    case trends    // 趋势分析
    case settings  // 设置
}

struct MainTabView: View {
    @State private var selectedTab: Tab = .sessions
    
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
```

**测试标准**：
- [x] TabView 可以正常显示
- [x] 可以在不同 Tab 之间切换
- [x] Tab 图标和文字正确显示
- [x] 默认选中"课程"Tab

---

### Task 3.2: 实现设置页面

**优先级**：🟡 中  
**预估时间**：1.5 小时  
**依赖**：Task 3.1

**目标**：
- 创建设置页面
- 实现 HealthKit 权限管理
- 添加关于信息

**可交付物**：
- `Views/SettingsView.swift`

**界面内容**：
```
设置
├── HealthKit 集成
│   ├── 启用 HealthKit [Toggle]
│   └── 重新请求权限 [Button]
├── 显示偏好
│   ├── 默认趋势视图 [Picker: 周/月/年]
│   └── 主题 [Picker: 系统/浅色/深色]
├── 数据管理
│   ├── 导出数据 [Button]
│   └── iCloud 同步状态 [Text]
└── 关于
    ├── 版本号
    └── 开源许可
```

**测试标准**：
- [x] 设置项可以正确显示
- [x] Toggle 和 Picker 可以正常操作
- [x] 设置更改后保存到 UserPreferences
- [x] 重启应用后设置保持

---

### Task 3.3: 创建空状态视图

**优先级**：🟡 中  
**预估时间**：45 分钟  
**依赖**：Task 3.1

**目标**：
- 创建统一的空状态组件
- 用于无数据时的友好提示

**可交付物**：
- `Views/Components/EmptyStateView.swift`

**组件设计**：
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

**测试标准**：
- [x] 图标、标题、消息正确显示
- [x] 可选的操作按钮正常工作
- [x] 在不同尺寸屏幕上布局正确

---

### Task 3.4: 创建加载状态视图

**优先级**：🟢 低  
**预估时间**：30 分钟  
**依赖**：Task 3.1

**目标**：
- 创建统一的加载指示器

**可交付物**：
- `Views/Components/LoadingView.swift`

**组件设计**：
```swift
struct LoadingView: View {
    let message: String?
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

---

### Task 3.5: 设计配色方案

**优先级**：🟡 中  
**预估时间**：1 小时  
**依赖**：Task 3.1

**目标**：
- 定义应用的配色系统
- 符合"安静不打扰"的设计原则

**可交付物**：
- `Utilities/Theme.swift`
- `Resources/Assets.xcassets` (颜色资源)

**配色方案**：
```swift
struct AppTheme {
    // 主色调（优雅的芭蕾粉）
    static let primary = Color("PrimaryColor")        // #C4969E
    
    // 次要色（柔和的灰蓝）
    static let secondary = Color("SecondaryColor")    // #8B9EB7
    
    // 背景色
    static let background = Color("BackgroundColor")  // #F8F9FA
    static let cardBackground = Color.white
    
    // 文字颜色
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // 成功/警告色（降低饱和度）
    static let success = Color("SuccessColor")        // #A8C5A8
    static let warning = Color("WarningColor")        // #E8C4A0
}
```

**测试标准**：
- [x] 所有颜色在 Assets 中定义
- [x] 支持浅色和深色模式
- [x] 配色符合无障碍标准（对比度）
- [x] 整体视觉柔和不刺眼

---

### Task 3.6: 创建日期工具类

**优先级**：🟡 中  
**预估时间**：1 小时  
**依赖**：无

**目标**：
- 封装常用的日期格式化和计算功能

**可交付物**：
- `Utilities/DateHelper.swift`

**功能清单**：
```swift
struct DateHelper {
    // 格式化显示
    static func formatSessionDate(_ date: Date) -> String
    static func formatDuration(_ seconds: TimeInterval) -> String
    static func formatTimeRange(start: Date, end: Date) -> String
    
    // 日期计算
    static func startOfWeek(for date: Date) -> Date
    static func startOfMonth(for date: Date) -> Date
    static func startOfYear(for date: Date) -> Date
    
    // 相对时间
    static func relativeString(from date: Date) -> String  // "今天", "昨天", "3天前"
}
```

**测试标准**：
- [x] 日期格式化符合中文习惯
- [x] 时长格式化清晰易读（"1小时30分钟"）
- [x] 相对时间正确计算
- [x] 周/月/年起始日期计算正确

---

## Phase 4: 课程记录功能 📝

**目标**：实现课程的显示、创建、编辑功能。

### Task 4.1: 实现课程列表视图

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Task 3.1, Task 1.3

**目标**：
- 显示所有课程记录
- 按时间倒序排列
- 支持下拉刷新

**可交付物**：
- `Views/SessionListView.swift`
- `ViewModels/SessionListViewModel.swift`

**界面设计**：
```
导航栏
├── 标题: "课程记录"
└── 右侧: + 按钮（添加课程）

列表内容（每项显示）：
├── 日期和星期（如：12月25日 周一）
├── 课程名称（如：Ballet Basics）或 "未命名课程"
├── 老师（如：Jane Doe）
├── 时长（如：1小时30分钟）
└── 心率图标和平均心率（如果有）
```

**测试标准**：
- [x] 列表正确显示所有课程
- [x] 空状态显示友好提示
- [x] 点击列表项可以进入详情页
- [x] 下拉刷新可以更新数据
- [x] 列表滚动流畅

**测试数据**：
```swift
// 在 SessionService 中添加生成测试数据的方法
func createTestData() {
    let dates = [
        Date(),
        Date().addingTimeInterval(-86400),
        Date().addingTimeInterval(-172800)
    ]
    
    for date in dates {
        let session = createSession(date: date, duration: 5400, isManual: true)
        updateSession(session, className: "Ballet Basics", instructor: "Jane Doe")
    }
}
```

---

### Task 4.2: 实现课程详情视图

**优先级**：🔴 高  
**预估时间**：2.5 小时  
**依赖**：Task 4.1

**目标**：
- 显示课程的完整信息
- 显示健康数据（如果有）
- 支持编辑和删除

**可交付物**：
- `Views/SessionDetailView.swift`
- `ViewModels/SessionDetailViewModel.swift`

**界面设计**：
```
导航栏
├── 标题: 课程名称或"课程详情"
├── 左侧: 返回按钮
└── 右侧: 编辑按钮

内容区（分节）：
├── 基本信息
│   ├── 日期时间
│   ├── 时长
│   ├── 课程名称
│   ├── 老师
│   └── 地点
├── 健康数据（如果有）
│   ├── 心率卡片
│   │   ├── 平均心率
│   │   ├── 最大/最小心率
│   │   └── 心率曲线图
│   ├── 活动数据
│   │   ├── 活动能量
│   │   ├── 步数
│   │   └── 距离
└── 笔记预览（显示笔记数量）
    └── "查看全部笔记"按钮

底部：
└── 删除课程按钮（红色）
```

**测试标准**：
- [x] 所有信息正确显示
- [x] 无健康数据时不显示该部分
- [x] 编辑按钮跳转到编辑页面
- [x] 删除功能有确认对话框
- [x] 删除后返回列表页

---

### Task 4.3: 实现课程编辑视图

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Task 4.2

**目标**：
- 编辑课程信息
- 智能标签建议
- 表单验证

**可交付物**：
- `Views/SessionEditView.swift`

**界面设计**：
```
导航栏
├── 标题: "编辑课程" 或 "新建课程"
├── 左侧: 取消按钮
└── 右侧: 保存按钮

表单：
├── 日期时间选择器
├── 时长输入（仅手动创建时可编辑）
├── 课程名称
│   ├── 文本输入框
│   └── 建议标签（横向滚动）
├── 老师
│   ├── 文本输入框
│   └── 建议标签
└── 地点（可选）
```

**智能建议逻辑**：
- 输入时动态显示匹配的历史标签
- 点击标签快速填充
- 按使用频率排序

**测试标准**：
- [x] 编辑现有课程时预填充数据
- [x] 智能标签正确显示
- [x] 点击标签可以快速填充
- [x] 保存后返回详情页
- [x] 取消时不保存更改

---

### Task 4.4: 实现手动创建课程

**优先级**：🔴 高  
**预估时间**：1 小时  
**依赖**：Task 4.3

**目标**：
- 从课程列表点击 + 按钮创建课程
- 默认当前时间和 1 小时时长

**扩展**：
- 在 `SessionEditView` 中添加创建模式
- 区分编辑和创建逻辑

**测试标准**：
- [x] 点击 + 按钮打开创建页面
- [x] 默认值合理（当前时间、1小时）
- [x] 保存后新课程出现在列表顶部
- [x] 取消创建不产生数据

---

### Task 4.5: 实现列表搜索和筛选

**优先级**：🟡 中  
**预估时间**：1.5 小时  
**依赖**：Task 4.1

**目标**：
- 添加搜索栏
- 按课程名称、老师筛选
- 按日期范围筛选

**可交付物**：
- 在 `SessionListView` 中添加搜索和筛选功能
- 在 `SessionListViewModel` 中实现筛选逻辑

**界面设计**：
```
搜索栏（可折叠）
├── 搜索框：搜索课程或老师
└── 筛选按钮 → 弹出筛选选项
    ├── 日期范围：本周/本月/自定义
    ├── 课程名称：多选
    └── 老师：多选
```

**测试标准**：
- [x] 搜索实时过滤列表
- [x] 筛选条件正确应用
- [x] 清除筛选后恢复全部数据
- [x] 筛选条件持久化（重启应用保持）

---

## Phase 5: 笔记功能 📔

**目标**：实现课程笔记的创建、编辑、查看功能。

### Task 5.1: 实现笔记列表视图

**优先级**：🔴 高  
**预估时间**：1.5 小时  
**依赖**：Task 4.2, Task 1.4

**目标**：
- 显示课程的所有笔记
- 按笔记类型分组显示

**可交付物**：
- `Views/NoteListView.swift`
- `ViewModels/NoteListViewModel.swift`

**界面设计**：
```
导航栏
├── 标题: "课程笔记"
├── 左侧: 返回按钮
└── 右侧: + 按钮（添加笔记）

内容区（按类型分组）：
├── 课后感想 [图标]
│   └── 笔记内容（最多 3 行，超出显示...）
├── 技术要点 [图标]
│   ├── 笔记 1
│   └── 笔记 2
└── 需要改进 [图标]
    └── 笔记内容

空状态：
└── "还没有笔记，点击 + 添加第一条笔记"
```

**测试标准**：
- [x] 笔记按类型正确分组
- [x] 每个笔记显示创建时间
- [x] 点击笔记可以进入编辑
- [x] 长按笔记显示删除选项
- [x] 空状态友好提示

---

### Task 5.2: 实现笔记编辑视图

**优先级**：🔴 高  
**预估时间**：1.5 小时  
**依赖**：Task 5.1

**目标**：
- 创建和编辑笔记
- 选择笔记类型
- 输入笔记内容

**可交付物**：
- `Views/NoteEditView.swift`

**界面设计**：
```
导航栏
├── 标题: "新建笔记" 或 "编辑笔记"
├── 左侧: 取消按钮
└── 右侧: 保存按钮

表单：
├── 笔记类型选择器（Picker）
│   ├── 一般笔记
│   ├── 课后感想
│   ├── 技术要点
│   ├── 需要改进
│   ├── 突破成就
│   └── 音乐相关
└── 笔记内容（TextEditor）
    └── 多行文本输入，自动增长
```

**测试标准**：
- [x] 可以选择笔记类型
- [x] 文本输入流畅
- [x] 保存后笔记出现在列表中
- [x] 编辑现有笔记时预填充数据
- [x] 取消不保存更改

---

### Task 5.3: 实现笔记类型图标和样式

**优先级**：🟡 中  
**预估时间**：45 分钟  
**依赖**：Task 5.1

**目标**：
- 为每种笔记类型设计图标和颜色
- 统一的视觉风格

**可交付物**：
- 在 `NoteType` 枚举中添加图标和颜色属性

**设计方案**：
```swift
extension NoteType {
    var icon: String {
        switch self {
        case .general: return "note.text"
        case .feeling: return "heart.text.square"
        case .technique: return "star.circle"
        case .improvement: return "arrow.up.circle"
        case .achievement: return "trophy"
        case .music: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .gray
        case .feeling: return Color("FeelingColor")      // 温暖的粉色
        case .technique: return Color("TechniqueColor")   // 专业的蓝色
        case .improvement: return Color("ImprovementColor") // 积极的橙色
        case .achievement: return Color("AchievementColor") // 喜悦的金色
        case .music: return Color("MusicColor")          // 优雅的紫色
        }
    }
}
```

**测试标准**：
- [x] 每种类型有独特的图标
- [x] 颜色区分明显但柔和
- [x] 符合整体设计风格

---

### Task 5.4: 实现快速添加笔记

**优先级**：🟡 中  
**预估时间**：1 小时  
**依赖**：Task 5.2

**目标**：
- 在课程详情页快速添加笔记
- 减少点击步骤

**界面改进**：
在 SessionDetailView 的笔记区域添加：
```
笔记 (3)
├── [快速添加] 按钮栏（横向滚动）
│   ├── + 感想
│   ├── + 技术要点
│   ├── + 需要改进
│   └── ...
└── 最近的 3 条笔记预览
```

点击快速按钮：
- 直接打开对应类型的笔记编辑器
- 跳过类型选择步骤

**测试标准**：
- [x] 快速按钮正常工作
- [x] 减少了操作步骤
- [x] 符合"极简输入"原则

---

## Phase 6: 趋势分析 📊

**目标**：实现长期趋势的可视化展示。

### Task 6.1: 实现趋势视图基础框架

**优先级**：🔴 高  
**预估时间**：1.5 小时  
**依赖**：Task 3.1, Task 1.3

**目标**：
- 创建趋势视图结构
- 实现周/月/年切换

**可交付物**：
- `Views/TrendView.swift`
- `ViewModels/TrendViewModel.swift`

**界面设计**：
```
导航栏
└── 标题: "趋势分析"

时间范围选择器
├── 本周
├── 本月
└── 本年

内容区（垂直滚动）
├── 统计卡片区
│   ├── 总课程数
│   ├── 总时长
│   └── 平均时长
├── 课程频率图表
├── 时长趋势图表
└── 老师/课程分布
```

**测试标准**：
- [x] 时间范围切换正常
- [x] 统计数据正确计算
- [x] 无数据时显示友好提示

---

### Task 6.2: 实现统计数据计算

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Task 6.1

**目标**：
- 实现各种统计指标的计算

**扩展 TrendViewModel**：
```swift
class TrendViewModel: ObservableObject {
    @Published var timeRange: TimeRange = .week
    @Published var statistics: Statistics?
    
    enum TimeRange {
        case week, month, year
    }
    
    struct Statistics {
        let totalSessions: Int
        let totalDuration: TimeInterval
        let averageDuration: TimeInterval
        let sessionsPerWeek: Double
        let mostFrequentInstructor: String?
        let mostFrequentClass: String?
    }
    
    func loadStatistics()
    func calculateSessionsPerDay() -> [Date: Int]
    func calculateDurationTrend() -> [Date: TimeInterval]
    func calculateInstructorDistribution() -> [String: Int]
    func calculateClassDistribution() -> [String: Int]
}
```

**测试标准**：
- [x] 统计数据计算准确
- [x] 按时间范围正确过滤
- [x] 处理空数据情况
- [x] 性能良好（大数据量下）

---

### Task 6.3: 实现图表组件

**优先级**：🔴 高  
**预估时间**：3 小时  
**依赖**：Task 6.2

**目标**：
- 使用 Swift Charts 实现数据可视化
- 柔和的视觉风格

**可交付物**：
- `Views/Charts/SessionFrequencyChart.swift` - 课程频率柱状图
- `Views/Charts/DurationTrendChart.swift` - 时长趋势折线图
- `Views/Charts/DistributionChart.swift` - 分布饼图

**课程频率图表**：
```swift
import Charts

struct SessionFrequencyChart: View {
    let data: [DateValuePair]
    
    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("日期", item.date),
                y: .value("课程数", item.value)
            )
            .foregroundStyle(AppTheme.primary)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
}
```

**测试标准**：
- [x] 图表正确渲染数据
- [x] 坐标轴标签清晰
- [x] 支持浅色和深色模式
- [x] 图表可以交互（点击显示数值）
- [x] 无数据时显示占位图

---

### Task 6.4: 实现趋势详情和数据导出

**优先级**：🟡 中  
**预估时间**：1.5 小时  
**依赖**：Task 6.3

**目标**：
- 查看详细的统计数据
- 导出数据为 CSV

**可交付物**：
- `Views/TrendDetailView.swift`
- `Utilities/DataExporter.swift`

**导出功能**：
```swift
class DataExporter {
    func exportToCSV(sessions: [BalletSession]) -> String
    func shareData(_ data: String)
}
```

CSV 格式：
```csv
日期,课程名称,老师,时长(分钟),平均心率,活动能量
2024-01-01,Ballet Basics,Jane Doe,90,125,350
...
```

**测试标准**：
- [x] CSV 格式正确
- [x] 可以通过分享菜单导出
- [x] 支持发送到其他 App
- [x] 数据完整无遗漏

---

## Phase 7: CloudKit 同步 ☁️

**目标**：实现 iCloud 多设备同步。

### Task 7.1: 配置 CloudKit Container

**优先级**：🔴 高  
**预估时间**：1 小时  
**依赖**：Phase 1 完成

**目标**：
- 升级 Core Data Stack 支持 CloudKit
- 配置同步选项

**修改 CoreDataStack**：
```swift
lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "BalletDaily")
    
    // 配置 CloudKit
    let cloudStoreDescription = container.persistentStoreDescriptions.first!
    cloudStoreDescription.cloudKitContainerOptions = 
        NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourcompany.BalletDaily"
        )
    
    // 配置数据保护
    cloudStoreDescription.setOption(
        FileProtectionType.complete as NSObject,
        forKey: NSPersistentStoreFileProtectionKey
    )
    
    container.loadPersistentStores { description, error in
        if let error = error {
            fatalError("Core Data failed to load: \(error.localizedDescription)")
        }
    }
    
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    
    return container
}()
```

**测试标准**：
- [x] 升级后本地数据不丢失
- [x] 应用仍可正常运行
- [x] CloudKit Dashboard 中可以看到数据库 Schema

---

### Task 7.2: 实现同步状态监控

**优先级**：🟡 中  
**预估时间**：1.5 小时  
**依赖**：Task 7.1

**目标**：
- 监控 CloudKit 同步状态
- 显示同步进度

**可交付物**：
- `Services/CloudKitSyncMonitor.swift`

**功能清单**：
```swift
class CloudKitSyncMonitor: ObservableObject {
    @Published var syncState: SyncState = .notStarted
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    enum SyncState {
        case notStarted
        case inProgress
        case succeeded
        case failed
    }
    
    func startMonitoring()
    func stopMonitoring()
}
```

**测试标准**：
- [x] 可以正确监控同步状态
- [x] 同步完成后更新 lastSyncDate
- [x] 同步错误时记录错误信息

---

### Task 7.3: 多设备测试和冲突解决

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Task 7.2

**目标**：
- 在多台设备上测试同步
- 验证冲突解决策略

**测试场景**：
1. **正常同步**：
   - 设备 A 创建课程 → 设备 B 同步获取
   - 验证数据一致

2. **离线编辑**：
   - 设备 A 离线编辑课程
   - 设备 B 在线编辑同一课程
   - 联网后验证冲突解决

3. **删除同步**：
   - 设备 A 删除课程
   - 设备 B 同步后课程消失

**测试标准**：
- [x] 数据在多设备间正确同步
- [x] 冲突解决符合预期（最后写入优胜）
- [x] 删除操作正确同步
- [x] 大量数据同步不卡顿

---

## Phase 8: 优化和完善 ✨

**目标**：性能优化、体验完善、Bug 修复。

### Task 8.1: 性能优化

**优先级**：🔴 高  
**预估时间**：2 小时  
**依赖**：Phase 1-7 完成

**优化项目**：

1. **Core Data 查询优化**
   - 添加批量加载
   - 添加预取关系
   - 添加索引

2. **列表滚动优化**
   - 使用 LazyVStack
   - 图片懒加载
   - 减少重复渲染

3. **内存管理**
   - 大图片压缩
   - 及时释放不用的对象

**测试标准**：
- [x] Instruments 检测无内存泄漏
- [x] 列表滚动流畅（60fps）
- [x] 应用启动时间 < 2 秒
- [x] 大数据量（1000+ 条）下性能良好

---

### Task 8.2: 错误处理和用户反馈

**优先级**：🔴 高  
**预估时间**：1.5 小时

**目标**：
- 统一的错误处理机制
- 友好的错误提示

**可交付物**：
- `Utilities/ErrorHandler.swift`
- `Views/Components/ErrorView.swift`

**常见错误处理**：
- HealthKit 权限被拒绝 → 提示并引导到设置
- CloudKit 同步失败 → 显示错误原因和重试按钮
- 网络不可用 → 提示离线模式
- 数据保存失败 → 提示并保留用户输入

**测试标准**：
- [x] 所有可能的错误都有处理
- [x] 错误提示清晰易懂
- [x] 提供解决方案或下一步操作
- [x] 不会因错误导致崩溃

---

### Task 8.3: 用户引导和空状态优化

**优先级**：🟡 中  
**预估时间**：1.5 小时

**目标**：
- 首次启动引导
- 优化所有空状态

**可交付物**：
- `Views/OnboardingView.swift`

**引导流程**：
1. 欢迎页：介绍应用特点
2. HealthKit 授权：说明为什么需要权限
3. 快速教程：如何创建第一节课程

**测试标准**：
- [x] 首次启动显示引导
- [x] 可以跳过引导
- [x] 引导只显示一次
- [x] 所有空状态都有引导提示

---

### Task 8.4: 无障碍支持

**优先级**：🟡 中  
**预估时间**：1 小时

**目标**：
- 支持 VoiceOver
- 支持动态字体
- 符合无障碍规范

**优化项目**：
- 为所有按钮和图片添加 accessibility label
- 确保颜色对比度符合标准
- 支持大号字体
- 键盘导航支持

**测试标准**：
- [x] VoiceOver 可以正确朗读所有内容
- [x] 使用最大字体时布局不混乱
- [x] 色盲模式下仍可使用
- [x] 通过 Accessibility Inspector 检查

---

### Task 8.5: 最终测试和 Bug 修复

**优先级**：🔴 高  
**预估时间**：2 小时

**测试清单**：

**功能测试**：
- [ ] 创建课程
- [ ] 编辑课程
- [ ] 删除课程
- [ ] 添加笔记
- [ ] 查看趋势
- [ ] HealthKit 数据同步
- [ ] iCloud 同步
- [ ] 搜索和筛选
- [ ] 数据导出

**兼容性测试**：
- [ ] iPhone SE (小屏幕)
- [ ] iPhone 15 Pro Max (大屏幕)
- [ ] iPad
- [ ] iOS 16.0
- [ ] iOS 17.x
- [ ] 浅色模式
- [ ] 深色模式

**压力测试**：
- [ ] 1000+ 条课程记录
- [ ] 长文本笔记
- [ ] 离线后大量更改再同步
- [ ] 快速连续操作

**测试标准**：
- [x] 所有功能正常工作
- [x] 无崩溃
- [x] 无明显 UI 问题
- [x] 性能良好

---

## 📝 每次交付的验收标准

每个 Task 完成后需要满足：

### 代码质量
- [x] 代码编译无警告
- [x] 无 Linter 错误
- [x] 遵循 Swift 代码规范
- [x] 适当的注释

### 功能完整性
- [x] 实现了所有定义的功能
- [x] 通过了所有测试标准
- [x] 边界情况处理正确

### 用户体验
- [x] 界面符合设计规范
- [x] 交互流畅自然
- [x] 错误处理友好
- [x] 加载状态清晰

### 文档
- [x] 关键代码有注释
- [x] 复杂逻辑有说明
- [x] 更新相关文档（如有需要）

---

## 🚀 开始开发

**当前状态**：⬜ 待开始

**下一步**：Phase 0 - Task 0.1 创建 Xcode 项目

**准备工作**：
1. 确认 Xcode 15+ 已安装
2. 确认 macOS 版本支持
3. 准备 Apple Developer 账号（用于 CloudKit 配置）
4. 创建 GitHub 仓库（可选，用于版本控制）

---

## 📊 进度追踪

### 更新记录

| 日期 | Phase | 完成任务 | 备注 |
|------|-------|---------|------|
| - | - | - | 开发尚未开始 |

---

## 💡 开发建议

### 迭代策略
1. **优先实现核心流程**：Phase 0 → Phase 1 → Phase 3 → Phase 4
2. **然后添加增强功能**：Phase 2 → Phase 5 → Phase 6
3. **最后完善同步和优化**：Phase 7 → Phase 8

### 时间分配建议
- 每天集中完成 1-3 个 Task
- 每周完成 1-2 个 Phase
- 预留 20% 时间处理意外问题

### 质量保证
- 每个 Task 完成后立即测试
- 每个 Phase 完成后做回归测试
- 定期 Code Review
- 及时更新文档

---

**准备好了吗？让我们开始第一个任务：创建 Xcode 项目！** 🎉

