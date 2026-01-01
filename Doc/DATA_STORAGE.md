# BalletDaily 数据存储和查询方案

## 一、技术方案选择

### 1.1 存储方案对比

| 方案 | 优势 | 劣势 | 适用场景 |
|------|------|------|----------|
| **Core Data + iCloud (CloudKit)** | • 原生支持<br>• 自动同步多设备<br>• 无需服务器<br>• 免费额度充足 | • 需要 Apple ID<br>• 仅限 Apple 生态 | ✅ **推荐方案**（前期） |
| **SwiftData + iCloud** | • 最新技术<br>• 代码更简洁<br>• 自动同步 | • iOS 17+ 限制<br>• 相对较新 | 可考虑（未来迁移） |
| **纯本地 Core Data** | • 简单稳定<br>• 无网络依赖 | • 无多设备同步<br>• 数据丢失风险 | 不推荐 |
| **自建服务器** | • 完全控制<br>• 跨平台 | • 开发成本高<br>• 运维成本<br>• 前期不需要 | 后期扩展选项 |

### 1.2 推荐方案：Core Data + CloudKit

**选择理由：**
1. ✅ **零成本起步**：前期无需服务器，使用 Apple 的免费 CloudKit 服务
2. ✅ **自动多设备同步**：iPhone 和 iPad 自动同步数据
3. ✅ **原生集成**：与 HealthKit、Core Data 无缝配合
4. ✅ **用户无感知**：符合"安静不打扰"原则，后台自动同步
5. ✅ **隐私保护**：数据存储在用户的 iCloud 私有数据库，非公共数据库
6. ✅ **免费额度充足**：
   - 1GB 资源存储
   - 10GB 数据库存储
   - 2GB/天 数据传输
   - 对于个人记录应用完全够用

**限制说明：**
- 需要用户登录 Apple ID
- 仅支持 Apple 生态系统
- 网络不佳时同步可能延迟（但本地数据始终可用）

## 二、数据库表结构设计

### 2.1 核心实体（Entity）设计

#### Entity 1: `BalletSession` (芭蕾课程)
课程记录的核心实体，关联健康数据和用户笔记。

| 字段名 | 类型 | 是否必填 | 说明 | 索引 |
|--------|------|----------|------|------|
| `id` | UUID | ✅ | 主键，唯一标识 | Primary Key |
| `createdAt` | Date | ✅ | 记录创建时间 | Index |
| `updatedAt` | Date | ✅ | 最后更新时间 | - |
| `sessionDate` | Date | ✅ | 课程实际日期时间 | Index |
| `duration` | Double | ✅ | 课程时长（秒） | - |
| `className` | String? | ❌ | 课程名称（可选） | Index |
| `instructor` | String? | ❌ | 老师姓名（可选） | Index |
| `location` | String? | ❌ | 上课地点（可选） | - |
| `isManualEntry` | Bool | ✅ | 是否手动创建（区分自动识别） | - |
| `healthKitWorkoutUUID` | String? | ❌ | 关联的 HealthKit Workout UUID | Index |

**关系：**
- → `BalletSessionNote`（一对多）：一节课可以有多条笔记
- → `HealthMetrics`（一对一）：关联健康指标数据

---

#### Entity 2: `BalletSessionNote` (课程笔记)
记录用户对课程的笔记、感想、学习要点等。

| 字段名 | 类型 | 是否必填 | 说明 | 索引 |
|--------|------|----------|------|------|
| `id` | UUID | ✅ | 主键 | Primary Key |
| `sessionId` | UUID | ✅ | 外键，关联 `BalletSession.id` | Foreign Key |
| `createdAt` | Date | ✅ | 创建时间 | Index |
| `updatedAt` | Date | ✅ | 更新时间 | - |
| `noteType` | String | ✅ | 笔记类型（见下方枚举） | Index |
| `content` | String | ✅ | 笔记内容 | - |
| `order` | Int16 | ✅ | 排序顺序 | - |

**笔记类型枚举 (`NoteType`)：**
```swift
enum NoteType: String {
    case general = "general"           // 一般笔记
    case feeling = "feeling"           // 课后感想
    case technique = "technique"       // 技术要点
    case improvement = "improvement"   // 需要改进的地方
    case achievement = "achievement"   // 课堂成就/突破
    case music = "music"               // 音乐/配乐相关
}
```

**设计考量：**
- 分离笔记表，支持一节课多条不同类型的笔记
- 用户可以在课后随时添加/编辑笔记
- 支持按笔记类型筛选和查看

---

#### Entity 3: `HealthMetrics` (健康指标)
从 HealthKit 同步的健康数据，与课程会话关联。

| 字段名 | 类型 | 是否必填 | 说明 | 索引 |
|--------|------|----------|------|------|
| `id` | UUID | ✅ | 主键 | Primary Key |
| `sessionId` | UUID | ✅ | 外键，关联 `BalletSession.id` | Foreign Key |
| `avgHeartRate` | Double? | ❌ | 平均心率（bpm） | - |
| `maxHeartRate` | Double? | ❌ | 最大心率（bpm） | - |
| `minHeartRate` | Double? | ❌ | 最小心率（bpm） | - |
| `activeEnergy` | Double? | ❌ | 活动能量（千卡） | - |
| `stepCount` | Int32? | ❌ | 步数 | - |
| `distance` | Double? | ❌ | 距离（米） | - |
| `exerciseTime` | Double? | ❌ | 运动时间（分钟） | - |
| `heartRateData` | Binary? | ❌ | 心率时间序列数据（JSON 压缩） | - |
| `syncedAt` | Date | ✅ | 数据同步时间 | - |

**设计考量：**
- 与 `BalletSession` 一对一关系
- `heartRateData` 存储完整时间序列，用于绘制心率曲线
- 可选字段，因为用户可能拒绝 HealthKit 授权

---

#### Entity 4: `FrequentTag` (常用标签)
存储用户常用的课程名称和老师，用于快速输入。

| 字段名 | 类型 | 是否必填 | 说明 | 索引 |
|--------|------|----------|------|------|
| `id` | UUID | ✅ | 主键 | Primary Key |
| `tagType` | String | ✅ | 标签类型（`className` 或 `instructor`） | Index |
| `value` | String | ✅ | 标签值 | Index |
| `usageCount` | Int32 | ✅ | 使用次数 | - |
| `lastUsedAt` | Date | ✅ | 最后使用时间 | - |

**设计考量：**
- 自动记录用户输入的课程名称和老师
- 按使用频率排序，提供智能建议
- 符合"极简输入"原则

---

#### Entity 5: `UserPreferences` (用户偏好设置)
存储应用的个性化设置和偏好。

| 字段名 | 类型 | 是否必填 | 说明 |
|--------|------|----------|------|
| `id` | UUID | ✅ | 主键（单例模式） |
| `defaultClassName` | String? | ❌ | 默认课程名称 |
| `defaultInstructor` | String? | ❌ | 默认老师 |
| `enableHealthKit` | Bool | ✅ | 是否启用 HealthKit |
| `trendViewType` | String | ✅ | 默认趋势视图（week/month/year） |
| `theme` | String | ✅ | 主题配色 |
| `createdAt` | Date | ✅ | 创建时间 |
| `updatedAt` | Date | ✅ | 更新时间 |

---

### 2.2 实体关系图（ER Diagram）

```
┌─────────────────────┐
│  BalletSession      │
│  ─────────────────  │
│  id (PK)            │
│  sessionDate        │
│  duration           │
│  className          │
│  instructor         │
│  ...                │
└─────────┬───────────┘
          │ 1
          │
          │ n
┌─────────┴───────────┐         ┌─────────────────────┐
│ BalletSessionNote   │         │   HealthMetrics     │
│  ─────────────────  │         │  ─────────────────  │
│  id (PK)            │         │  id (PK)            │
│  sessionId (FK)     │◄───1:1──┤  sessionId (FK)     │
│  noteType           │         │  avgHeartRate       │
│  content            │         │  activeEnergy       │
│  ...                │         │  ...                │
└─────────────────────┘         └─────────────────────┘

┌─────────────────────┐         ┌─────────────────────┐
│   FrequentTag       │         │  UserPreferences    │
│  ─────────────────  │         │  ─────────────────  │
│  id (PK)            │         │  id (PK)            │
│  tagType            │         │  defaultClassName   │
│  value              │         │  enableHealthKit    │
│  usageCount         │         │  ...                │
└─────────────────────┘         └─────────────────────┘
```

## 三、CloudKit 集成方案

### 3.1 CloudKit 配置

#### 数据库选择：**Private Database**（私有数据库）
- 每个用户的数据完全隔离
- 自动加密存储在用户的 iCloud 账户
- 无需处理用户认证，Apple ID 自动管理

#### Container 配置
```
Container Identifier: iCloud.com.yourcompany.BalletDaily
```

### 3.2 实体映射到 CloudKit Record

| Core Data Entity | CloudKit Record Type | 同步策略 |
|------------------|----------------------|----------|
| `BalletSession` | `CD_BalletSession` | 全量同步 |
| `BalletSessionNote` | `CD_BalletSessionNote` | 全量同步 |
| `HealthMetrics` | `CD_HealthMetrics` | 全量同步 |
| `FrequentTag` | `CD_FrequentTag` | 全量同步 |
| `UserPreferences` | `CD_UserPreferences` | 全量同步 |

**注意：** Core Data with CloudKit 会自动添加 `CD_` 前缀。

### 3.3 同步策略

#### 自动同步
```swift
// NSPersistentCloudKitContainer 自动处理同步
lazy var persistentContainer: NSPersistentCloudKitContainer = {
    let container = NSPersistentCloudKitContainer(name: "BalletDaily")
    
    // 配置 CloudKit
    let cloudStoreDescription = container.persistentStoreDescriptions.first
    cloudStoreDescription?.cloudKitContainerOptions = 
        NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.yourcompany.BalletDaily"
        )
    
    container.loadPersistentStores { description, error in
        if let error = error {
            print("Core Data failed to load: \(error.localizedDescription)")
        }
    }
    
    // 自动合并策略
    container.viewContext.automaticallyMergesChangesFromParent = true
    container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    
    return container
}()
```

#### 冲突解决策略
- **最后写入优胜**（Last Write Wins）：适用于个人使用场景
- **属性级合并**：`NSMergeByPropertyObjectTrumpMergePolicy`

### 3.4 数据隐私和安全

1. **端到端加密**：CloudKit Private Database 默认加密
2. **本地数据保护**：启用 Core Data 的数据保护
```swift
cloudStoreDescription?.setOption(
    FileProtectionType.complete as NSObject, 
    forKey: NSPersistentStoreFileProtectionKey
)
```

## 四、数据查询方案

### 4.1 常用查询操作

#### 1. 获取最近的课程列表（分页）
```swift
let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
fetchRequest.sortDescriptors = [
    NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: false)
]
fetchRequest.fetchLimit = 20
fetchRequest.fetchOffset = 0

// 在 SwiftUI 中使用
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: false)],
    animation: .default
)
private var sessions: FetchedResults<BalletSession>
```

#### 2. 按日期范围查询
```swift
let startDate = Calendar.current.startOfDay(for: Date())
let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!

fetchRequest.predicate = NSPredicate(
    format: "sessionDate >= %@ AND sessionDate < %@", 
    startDate as NSDate, 
    endDate as NSDate
)
```

#### 3. 按老师或课程名称筛选
```swift
fetchRequest.predicate = NSPredicate(
    format: "instructor == %@ OR className CONTAINS[cd] %@", 
    instructorName, 
    searchText
)
```

#### 4. 统计查询（趋势分析）
```swift
// 统计本周课程数量
let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
let predicate = NSPredicate(format: "sessionDate >= %@", weekAgo as NSDate)

let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
fetchRequest.predicate = predicate

let count = try? context.count(for: fetchRequest)

// 计算总时长
let sumExpression = NSExpression(forKeyPath: \BalletSession.duration)
let sumExpressionDescription = NSExpressionDescription()
sumExpressionDescription.name = "totalDuration"
sumExpressionDescription.expression = NSExpression(forFunction: "sum:", arguments: [sumExpression])
sumExpressionDescription.expressionResultType = .doubleAttributeType

fetchRequest.propertiesToFetch = [sumExpressionDescription]
fetchRequest.resultType = .dictionaryResultType

let results = try? context.fetch(fetchRequest) as? [[String: Double]]
let totalDuration = results?.first?["totalDuration"] ?? 0
```

#### 5. 关联查询（课程 + 笔记）
```swift
let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
fetchRequest.relationshipKeyPathsForPrefetching = ["notes", "healthMetrics"]

// Core Data 自动处理关联关系
// 在 SwiftUI 中直接访问
session.notes // 自动加载
session.healthMetrics // 自动加载
```

### 4.2 性能优化

#### 1. 批量加载
```swift
fetchRequest.fetchBatchSize = 20 // 每次加载 20 条
```

#### 2. 预取关系
```swift
fetchRequest.relationshipKeyPathsForPrefetching = ["notes", "healthMetrics"]
```

#### 3. 索引优化
在 Core Data Model Editor 中为以下字段添加索引：
- `sessionDate`
- `className`
- `instructor`
- `createdAt`

#### 4. 后台上下文
```swift
// 大批量操作使用后台上下文
persistentContainer.performBackgroundTask { context in
    // 执行耗时操作
    try? context.save()
}
```

## 五、数据迁移策略

### 5.1 Version 1 → Version 2
使用 Core Data 的轻量级迁移（Lightweight Migration）：
```swift
let storeDescription = NSPersistentStoreDescription()
storeDescription.shouldMigrateStoreAutomatically = true
storeDescription.shouldInferMappingModelAutomatically = true
```

### 5.2 未来扩展考虑
如果后期需要迁移到自建服务器：
1. 导出 Core Data 数据为 JSON
2. 通过 API 上传到服务器
3. 保留本地 Core Data 作为缓存层
4. 使用 CloudKit 作为过渡方案

## 六、数据备份和恢复

### 6.1 自动备份
- iCloud 自动备份（通过 CloudKit）
- 设备本地备份（通过 iTunes/Finder 备份）

### 6.2 手动导出（可选功能）
提供数据导出功能，导出为 JSON/CSV 格式：
```swift
// 示例：导出为 JSON
func exportSessionsToJSON() -> Data? {
    let sessions = fetchAllSessions()
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return try? encoder.encode(sessions)
}
```

## 七、实施检查清单

### Phase 1: 基础设置 ✅
- [ ] 在 Xcode 中启用 iCloud 和 CloudKit 权限
- [ ] 创建 CloudKit Container
- [ ] 配置 Core Data Model（.xcdatamodeld）
- [ ] 设置 `NSPersistentCloudKitContainer`

### Phase 2: 实体实现 ✅
- [ ] 实现 `BalletSession` 实体和关系
- [ ] 实现 `BalletSessionNote` 实体
- [ ] 实现 `HealthMetrics` 实体
- [ ] 实现 `FrequentTag` 实体
- [ ] 实现 `UserPreferences` 实体

### Phase 3: 数据服务层 ✅
- [ ] 实现 CoreDataService（CRUD 操作）
- [ ] 实现数据查询接口
- [ ] 实现同步状态监控
- [ ] 错误处理和日志

### Phase 4: 测试验证 ✅
- [ ] 测试多设备同步
- [ ] 测试离线操作和同步恢复
- [ ] 测试数据冲突解决
- [ ] 性能测试（大数据量）

## 八、预估数据容量

### 单条记录大小估算
- `BalletSession`: ~200 bytes
- `BalletSessionNote`: ~500 bytes（平均）
- `HealthMetrics`: ~1KB（含心率时间序列）
- `FrequentTag`: ~100 bytes

### 年度数据量估算（假设每周 3 节课）
- 156 节课/年 × 1.7KB/节 ≈ **265KB/年**
- 10 年数据 ≈ **2.65MB**

**结论**：CloudKit 免费额度（10GB）足够使用数百年。

## 九、总结

### ✅ 推荐方案
**Core Data + CloudKit（Private Database）** 完美满足 BalletDaily 的需求：

1. **符合设计原则**
   - ✅ 极简输入：自动同步，无需用户操作
   - ✅ 长期趋势：本地数据永久保存，支持历史查询
   - ✅ 安静不打扰：后台自动同步，无推送打扰

2. **技术优势**
   - ✅ 零成本：无需服务器和运维
   - ✅ 原生集成：与 Apple 生态完美配合
   - ✅ 自动多设备同步：iPhone/iPad 无缝体验
   - ✅ 数据安全：端到端加密，隐私保护

3. **可扩展性**
   - ✅ 数据模型清晰，易于未来扩展
   - ✅ 预留迁移到自建服务器的可能性
   - ✅ 支持数据导出，用户掌控数据

### 下一步行动
1. 创建 Core Data Model 文件
2. 配置 CloudKit Container
3. 实现数据服务层
4. 开始 UI 集成测试

