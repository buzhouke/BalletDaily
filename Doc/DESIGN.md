# BalletDaily iOS 应用设计思路

## 一、项目概述

BalletDaily 是一个与 Apple Watch 集成的芭蕾课程记录应用，核心特点是**极简输入**、**长期趋势可视化和**安静不打扰的体验。

## 二、技术架构

### 2.1 技术栈选择

- **框架**: SwiftUI + UIKit（如需要）
- **数据存储**: 
  - Core Data（本地数据库，存储课程记录和备注）
  - HealthKit（读取 Apple Watch 的运动和健康数据）
- **平台**: 
  - iOS 主应用
  - watchOS 扩展（可选，用于快速记录）
- **最低支持版本**: iOS 16.0+ / watchOS 9.0+（推荐）

### 2.2 项目结构

```
BalletDaily/
├── BalletDaily/                    # iOS 主应用
│   ├── App/
│   │   └── BalletDailyApp.swift    # 应用入口
│   ├── Models/
│   │   ├── BalletSession.swift     # 课程会话数据模型
│   │   └── HealthData.swift        # HealthKit 数据模型
│   ├── Views/
│   │   ├── ContentView.swift       # 主视图
│   │   ├── SessionListView.swift   # 课程列表
│   │   ├── SessionDetailView.swift # 课程详情
│   │   ├── SessionEditView.swift   # 编辑课程（课程名、老师）
│   │   └── TrendView.swift         # 趋势可视化
│   ├── ViewModels/
│   │   ├── SessionListViewModel.swift
│   │   └── TrendViewModel.swift
│   ├── Services/
│   │   ├── HealthKitService.swift  # HealthKit 数据获取
│   │   ├── CoreDataService.swift   # 数据持久化
│   │   └── SessionService.swift    # 业务逻辑层
│   └── Resources/
│       └── Assets.xcassets
├── BalletDaily Watch App/          # watchOS 应用（可选）
│   └── ContentView.swift
└── BalletDaily.xcodeproj
```

## 三、核心功能设计

### 3.1 数据模型

#### BalletSession（课程会话）
```swift
- id: UUID
- date: Date                    # 课程日期时间
- duration: TimeInterval        # 课程时长（从 HealthKit 获取）
- className: String?            # 课程名称（用户可选输入）
- instructor: String?           # 老师姓名（用户可选输入）
- notes: String?                # 额外备注（可选）
- healthData: HealthData        # 关联的健康数据
```

#### HealthData（健康数据）
从 HealthKit 读取：
- 心率数据（HR）
- 活动能量（Active Energy）
- 步数（Step Count）
- 运动时间（Exercise Time）

### 3.2 主要功能模块

#### 1. 课程记录（Session Logging）
- **自动记录**: 通过 HealthKit 检测到运动会话时，自动创建记录
- **手动记录**: 用户可以手动添加课程（最少输入原则）
- **编辑功能**: 可以添加/编辑课程名称和老师
- **数据同步**: 从 HealthKit 获取该时间段的相关健康数据

#### 2. 课程列表（Session List）
- **时间线视图**: 按时间倒序显示所有课程
- **快速信息**: 显示日期、时长、课程名称
- **筛选**: 按日期范围、老师、课程名称筛选（可选功能）

#### 3. 课程详情（Session Detail）
- **基本信息**: 日期、时长、课程名称、老师
- **健康数据可视化**: 
  - 心率图表
  - 活动能量
  - 步数统计
- **编辑按钮**: 快速编辑课程名称和老师

#### 4. 趋势分析（Trend View）
- **长期视图**: 按周/月/年显示趋势
- **可视化指标**:
  - 课程频率（每周/每月次数）
  - 平均时长趋势
  - 累计时长
- **简洁设计**: 使用折线图或柱状图，避免过度游戏化

### 3.3 Apple Watch 集成

#### 方案一：被动集成（推荐）
- iOS 应用从 HealthKit 读取数据
- 用户使用 Apple Watch 自带的"体能训练"App 记录训练
- 应用自动识别并关联课程记录

#### 方案二：主动集成
- 开发 watchOS 扩展
- 提供快速记录界面
- 直接在手表上标记课程开始/结束

**推荐方案一**，因为：
- 符合"最少用户输入"原则
- 用户无需学习新界面
- 开发成本更低

## 四、用户体验设计原则

### 4.1 极简输入（Minimal User Input）
- 默认使用 HealthKit 数据，无需手动输入时长
- 课程名称和老师为可选字段
- 支持快速标签（预设常用课程名称）
- 语音输入支持（可选）

### 4.2 长期趋势可视化（Long-term Trend Visibility）
- 提供周/月/年视图切换
- 使用清晰的图表展示趋势
- 关键指标一目了然
- 支持导出数据（可选）

### 4.3 安静不打扰（Calm, Non-intrusive Experience）
- 无推送通知（除非用户主动设置）
- 简洁的界面设计，避免过多色彩
- 柔和的配色方案
- 无社交压力元素

## 五、实现步骤建议

### Phase 1: 基础架构
1. 创建 Xcode 项目（iOS + watchOS）
2. 设置 Core Data 数据模型
3. 配置 HealthKit 权限请求
4. 实现基础 UI 框架（SwiftUI）

### Phase 2: 核心功能
1. 实现 HealthKit 数据读取服务
2. 实现课程记录的数据模型和持久化
3. 实现课程列表视图
4. 实现课程详情视图

### Phase 3: 增强功能
1. 实现课程编辑功能
2. 实现趋势分析视图
3. 实现数据筛选功能

### Phase 4: 优化和测试
1. UI/UX 优化
2. 性能优化
3. 测试和 bug 修复

## 六、关键技术点

### 6.1 HealthKit 集成
- 请求权限：`HKHealthStore.requestAuthorization`
- 查询数据：`HKSampleQuery` / `HKStatisticsQuery`
- 数据类型：`HKWorkoutTypeIdentifier`, `HKQuantityTypeIdentifier`

### 6.2 Core Data
- 使用 `@FetchRequest` 在 SwiftUI 中获取数据
- 实现 `NSManagedObject` 子类
- 数据迁移策略

### 6.3 SwiftUI 最佳实践
- 使用 `@StateObject` / `@ObservedObject` 管理状态
- 使用 `@Environment` 访问 Core Data context
- 使用 Charts 框架（iOS 16+）进行数据可视化

## 七、注意事项

1. **隐私**: HealthKit 数据敏感，需明确说明数据使用方式
2. **权限**: 需要用户授权 HealthKit 访问权限
3. **数据同步**: HealthKit 数据可能延迟，需要处理异步情况
4. **离线支持**: Core Data 支持离线使用
5. **数据迁移**: 考虑未来数据模型的变更

