# Core Data Model 配置完成指南

## ✅ 已完成的工作

Core Data 数据模型文件已创建完成，包含 5 个实体和完整的关系定义。

---

## 📊 数据模型结构

### Entity 1: BalletSession（芭蕾课程）
**属性**：
- `id`: UUID (主键)
- `createdAt`: Date (创建时间)
- `updatedAt`: Date (更新时间)
- `sessionDate`: Date (课程日期时间)
- `duration`: Double (时长，秒)
- `className`: String? (课程名称，可选)
- `instructor`: String? (老师，可选)
- `location`: String? (地点，可选)
- `isManualEntry`: Boolean (是否手动创建)
- `healthKitWorkoutUUID`: String? (HealthKit 训练 ID，可选)

**关系**：
- `notes` → BalletSessionNote (一对多，级联删除)
- `healthMetrics` → HealthMetrics (一对一，级联删除)

---

### Entity 2: BalletSessionNote（课程笔记）
**属性**：
- `id`: UUID (主键)
- `createdAt`: Date (创建时间)
- `updatedAt`: Date (更新时间)
- `noteType`: String (笔记类型，默认 "general")
- `content`: String (笔记内容)
- `order`: Int16 (排序顺序)

**关系**：
- `session` → BalletSession (多对一)

**笔记类型**：
- `general` - 一般笔记
- `feeling` - 课后感想
- `technique` - 技术要点
- `improvement` - 需要改进
- `achievement` - 突破成就
- `music` - 音乐相关

---

### Entity 3: HealthMetrics（健康指标）
**属性**：
- `id`: UUID (主键)
- `syncedAt`: Date (同步时间)
- `avgHeartRate`: Double? (平均心率)
- `maxHeartRate`: Double? (最大心率)
- `minHeartRate`: Double? (最小心率)
- `activeEnergy`: Double? (活动能量)
- `stepCount`: Int32? (步数)
- `distance`: Double? (距离)
- `exerciseTime`: Double? (运动时间)
- `heartRateData`: Binary? (心率时间序列)

**关系**：
- `session` → BalletSession (一对一)

---

### Entity 4: FrequentTag（常用标签）
**属性**：
- `id`: UUID (主键)
- `tagType`: String (标签类型：className 或 instructor)
- `value`: String (标签值)
- `usageCount`: Int32 (使用次数)
- `lastUsedAt`: Date (最后使用时间)

**用途**：智能建议，按使用频率排序

---

### Entity 5: UserPreferences（用户偏好）
**属性**：
- `id`: UUID (主键)
- `createdAt`: Date (创建时间)
- `updatedAt`: Date (更新时间)
- `defaultClassName`: String? (默认课程名)
- `defaultInstructor`: String? (默认老师)
- `enableHealthKit`: Boolean (是否启用 HealthKit，默认 true)
- `trendViewType`: String (默认趋势视图，默认 "week")
- `theme`: String (主题，默认 "system")

---

## 🔧 在 Xcode 中验证

### 步骤 1：打开数据模型编辑器

1. **在 Xcode 左侧文件导航器中**
2. **找到 `BalletDaily.xcdatamodeld` 文件夹**（黄色图标）
3. **点击展开，然后点击 `BalletDaily.xcdatamodel`**
4. **应该打开可视化的数据模型编辑器**

### 步骤 2：验证实体

在编辑器中，您应该看到 5 个实体：
- ✅ BalletSession
- ✅ BalletSessionNote
- ✅ HealthMetrics
- ✅ FrequentTag
- ✅ UserPreferences

### 步骤 3：查看实体详情

**点击任意实体**，右侧会显示：
- **Attributes（属性）**：所有字段及其类型
- **Relationships（关系）**：与其他实体的关系
- **Fetched Properties**：（暂时为空）

### 步骤 4：生成 NSManagedObject 类

1. **选择所有实体**（Cmd + A 或逐个点击并按住 Cmd）
2. **菜单栏：Editor → Create NSManagedObject Subclass...**
3. **选择 BalletDaily 数据模型**
4. **选择所有实体**
5. **选择 `BalletDaily` Group**
6. **点击 Create**

这会在 Models 文件夹中生成对应的 Swift 类文件。

---

## ✅ 编译测试

### 清理和编译

1. **按 `Cmd + Shift + K` 清理构建**
2. **按 `Cmd + B` 编译项目**
3. **应该没有错误** ✅

### 预期结果

- ✅ 编译成功
- ✅ 没有 Core Data 相关错误
- ✅ 可以在代码中使用这些实体

---

## 📝 数据模型特点

### 1. 完整的关系定义
- BalletSession 是核心实体
- 与 HealthMetrics 一对一
- 与 BalletSessionNote 一对多
- 级联删除确保数据一致性

### 2. 灵活的可选字段
- className, instructor, location 都是可选
- 符合"极简输入"原则
- 用户可以只记录时间，其他信息可选填

### 3. 时间戳追踪
- 所有主要实体都有 createdAt 和 updatedAt
- 便于追踪数据变更历史

### 4. 智能建议支持
- FrequentTag 记录使用频率
- 支持按使用次数排序
- 实现快速输入功能

### 5. 健康数据完整性
- 支持所有 HealthKit 基础指标
- heartRateData 存储时间序列
- 用于绘制心率曲线图

---

## 🎯 数据库设计原则

遵循 DATA_STORAGE.md 中的设计：
- ✅ 符合"极简输入"原则（可选字段）
- ✅ 支持"长期趋势"（时间戳和历史数据）
- ✅ "安静不打扰"（无复杂约束）
- ✅ 为 CloudKit 同步预留空间

---

## 🔍 关系说明

```
BalletSession (1) ←→ (1) HealthMetrics
     ↓
     ↓ (1:N)
     ↓
BalletSessionNote (N)

FrequentTag (独立表)
UserPreferences (单例表)
```

### 级联删除规则：
- 删除 BalletSession → 自动删除关联的 HealthMetrics 和所有 Notes
- 删除 BalletSessionNote → 不影响 BalletSession

---

## ✅ Task 1.1 完成标志

- [x] 创建了 5 个实体
- [x] 定义了所有必需的属性
- [x] 配置了实体间的关系
- [x] 设置了合理的默认值
- [x] 配置了级联删除规则
- [x] 项目可以成功编译

---

**下一步**：Task 1.2 - 创建 Core Data Stack（配置数据库持久化）

如果数据模型在 Xcode 中正确显示并且编译成功，Task 1.1 就完成了！

