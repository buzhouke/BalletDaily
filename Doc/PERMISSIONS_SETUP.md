# HealthKit 权限配置指南

## 📋 Task 0.3: 配置权限和 Capabilities

本指南将帮助您在 Xcode 中配置 HealthKit 权限，这是 BalletDaily 读取健康数据的必要步骤。

---

## ⚠️ 重要提示

由于您是 iOS 开发新手，我会提供**详细的截图式描述**。请严格按照步骤操作。

---

## 🎯 配置目标

1. ✅ 启用 HealthKit Capability
2. ✅ 添加隐私权限描述
3. ✅ 验证配置正确

---

## 📱 步骤 1：启用 HealthKit Capability

### 1.1 打开项目设置

1. **在 Xcode 左侧的文件导航器（Project Navigator）中**
2. **点击最顶部的 `BalletDaily` 项目图标**（蓝色图标）
3. 这会打开项目设置界面

### 1.2 选择正确的 Target

在中间区域：
- 确保选择 **TARGETS** 下的 `BalletDaily`（不是 PROJECTS）
- 应该能看到多个标签：General, Signing & Capabilities, Resource Tags 等

### 1.3 切换到 Signing & Capabilities 标签

1. **点击顶部的 `Signing & Capabilities` 标签**
2. 您会看到当前已有的 Capabilities（可能为空或只有 Automatic Signing）

### 1.4 添加 HealthKit Capability

1. **点击左上角的 `+ Capability` 按钮**
2. **在弹出的列表中搜索 "HealthKit"**
3. **双击 "HealthKit"** 添加

### 1.5 验证 HealthKit 已添加

添加成功后，您应该看到：
```
Signing & Capabilities
├── Signing
│   └── Team: 微微 王 (Personal Team)
└── HealthKit
    ☑️ Clinical Health Records (可以不勾选，我们不需要)
    ☑️ Background Delivery (可以不勾选，暂时不需要)
```

---

## 📝 步骤 2：配置隐私权限描述

HealthKit 需要向用户解释为什么需要访问健康数据。我们需要添加两个权限描述。

### 2.1 打开 Info 配置

有两种方法：

**方法 A：通过 Info 标签（推荐）**
1. 确保仍在项目设置中（步骤 1.1-1.2）
2. 点击 **`Info` 标签**（在 Signing & Capabilities 旁边）
3. 您会看到一个列表，包含各种配置项

**方法 B：通过 Info.plist 文件（如果存在）**
1. 在左侧文件导航器中查找 `Info.plist`
2. 双击打开

### 2.2 添加 HealthKit 读取权限描述

#### 在 Info 标签中添加：

1. **找到列表中的某一行，鼠标悬停**
2. **点击该行最左侧的 `+` 按钮**（添加新行）
3. **在新行中选择或输入**：
   ```
   Privacy - Health Share Usage Description
   ```
   或者直接输入 key：
   ```
   NSHealthShareUsageDescription
   ```

4. **在右侧 Value 列输入中文说明**：
   ```
   需要访问您的健康数据以记录芭蕾课程的运动指标
   ```

5. **Type 应该是 `String`**

### 2.3 添加 HealthKit 更新权限描述

重复步骤 2.2，添加第二个权限：

1. **再次点击 `+` 添加新行**
2. **选择或输入**：
   ```
   Privacy - Health Update Usage Description
   ```
   或者 key：
   ```
   NSHealthUpdateUsageDescription
   ```

3. **Value 输入**：
   ```
   需要更新健康数据以记录您的芭蕾训练信息
   ```

### 2.4 验证权限描述已添加

在 Info 标签中，您应该看到：
```
Key                                              | Type   | Value
------------------------------------------------|--------|------------------------------------------
NSHealthShareUsageDescription                    | String | 需要访问您的健康数据以记录芭蕾课程的运动指标
NSHealthUpdateUsageDescription                   | String | 需要更新健康数据以记录您的芭蕾训练信息
```

---

## 🔍 步骤 3：验证配置

### 3.1 检查 Capabilities

1. 返回 **Signing & Capabilities** 标签
2. 确认 **HealthKit** 已经出现在列表中
3. 没有红色错误提示

### 3.2 编译项目

1. 按 **`Cmd + B`** 编译项目
2. 应该没有错误
3. 如果有警告可以忽略（只要不是错误）

### 3.3 运行测试

1. 按 **`Cmd + R`** 运行项目
2. 应该能正常启动
3. **注意**：此时不会弹出 HealthKit 权限请求（因为我们还没有写请求权限的代码）

---

## 📋 配置检查清单

完成后，请确认以下各项：

### Xcode 配置
- [ ] **Signing & Capabilities** 中有 HealthKit
- [ ] **Info** 标签中有 `NSHealthShareUsageDescription`
- [ ] **Info** 标签中有 `NSHealthUpdateUsageDescription`
- [ ] 两个描述都是中文说明文字
- [ ] 项目可以成功编译（Cmd + B）
- [ ] 应用可以正常运行（Cmd + R）

### 文件系统
- [ ] 项目结构没有被破坏
- [ ] 所有文件仍在正确位置

---

## 🆘 常见问题

### Q1: 找不到 "+ Capability" 按钮
**A**: 确保您：
1. 选择的是 **TARGETS** 下的 `BalletDaily`（不是 PROJECTS）
2. 在 **Signing & Capabilities** 标签（不是 Info）
3. 按钮通常在左上角，靠近标签栏

### Q2: 添加权限描述时找不到对应的 Key
**A**: 有两种方式：
1. **推荐**：在下拉列表中滚动查找 "Privacy - Health..."
2. **手动输入**：直接输入完整的 key 名称（如 `NSHealthShareUsageDescription`）

### Q3: 编译报错 "No such module 'HealthKit'"
**A**: 这说明 HealthKit Capability 没有正确添加，请重新执行步骤 1。

### Q4: Info 标签里已经有很多配置项，不知道插在哪里
**A**: 可以插在任何位置，顺序不重要。通常添加在列表最后。

---

## 📖 技术说明（供理解）

### 为什么需要这些配置？

#### HealthKit Capability
- iOS 要求访问敏感数据（如健康数据）的应用必须在项目中明确声明
- Capability 会在编译时链接 HealthKit 框架
- 这是 Apple 的安全机制

#### 隐私权限描述
- iOS 13+ 强制要求所有权限请求必须有中文说明
- 当应用首次请求 HealthKit 权限时，系统会显示这些文字给用户
- 如果缺少这些描述，应用会在请求权限时崩溃

#### NSHealthShareUsageDescription vs NSHealthUpdateUsageDescription
- **Share（读取）**：从健康 App 读取数据（如心率、步数）
- **Update（写入）**：向健康 App 写入数据（如训练记录）
- 我们的应用主要是读取，但也可能写入训练数据，所以两个都需要

---

## ✅ 完成后的下一步

配置完成后：
1. ✅ 标记 Task 0.3 为完成
2. ✅ Phase 0（项目初始化）全部完成
3. ✅ 可以开始 Phase 1（数据层基础）

在 Phase 2 中，我们会编写代码实际请求 HealthKit 权限并读取数据。现在只是完成了基础配置。

---

## 💡 提示

如果您在配置过程中遇到任何问题：
1. 截图发给我，我会帮您诊断
2. 说明您看到了什么，卡在哪一步
3. 不要随意修改其他配置项

**准备好了吗？请按照上述步骤在 Xcode 中操作！** 🚀

