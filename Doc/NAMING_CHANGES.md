# 属性命名变更说明

## 🔧 重要变更

为避免与 Swift 保留字和 NSManagedObject 方法冲突，我们修改了部分属性名称：

### BalletSession 实体

**变更**：`className` → `name`

**原因**：
- `className` 是 NSObject 的方法，会导致冲突
- `name` 更简洁，语义清晰

**代码中使用**：
```swift
let session = BalletSession(context: context)
session.name = "Ballet Basics"  // ✅ 正确
// session.className = "..."     // ❌ 错误（已删除）
```

### UserPreferences 实体

**变更**：`defaultClassName` → `defaultName`

**原因**：保持与 BalletSession 命名一致

**代码中使用**：
```swift
let preferences = UserPreferences(context: context)
preferences.defaultName = "Ballet Basics"  // ✅ 正确
// preferences.defaultClassName = "..."     // ❌ 错误（已删除）
```

---

## 📊 完整的属性列表

### BalletSession
- `id`: UUID
- `createdAt`: Date
- `updatedAt`: Date
- `sessionDate`: Date
- `duration`: Double
- **`name`**: String? ⭐ (原 className)
- `instructor`: String?
- `location`: String?
- `isManualEntry`: Boolean
- `healthKitWorkoutUUID`: String?

### UserPreferences
- `id`: UUID
- `createdAt`: Date
- `updatedAt`: Date
- **`defaultName`**: String? ⭐ (原 defaultClassName)
- `defaultInstructor`: String?
- `enableHealthKit`: Boolean
- `trendViewType`: String
- `theme`: String

---

## ✅ 测试

更新后，请执行：
1. 清理构建：`Cmd + Shift + K`
2. 重新编译：`Cmd + B`
3. 应该没有错误了！

所有之前的"className conflicts"错误都应该消失。

