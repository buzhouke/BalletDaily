# Xcode 项目结构配置指南

## ⚠️ 重要提示

文件夹结构已经在文件系统中创建完成，但 Xcode 项目文件还需要更新引用。

## 📂 当前文件结构

```
BalletDaily/
├── App/
│   └── BalletDailyApp.swift          ✅ 应用入口
├── Models/
│   └── .gitkeep                      📦 待添加数据模型
├── Views/
│   ├── ContentView.swift             ✅ 主视图
│   ├── Components/                   📦 可复用组件
│   └── Screens/                      📦 各个页面
├── ViewModels/
│   └── .gitkeep                      📦 视图模型
├── Services/
│   └── Persistence.swift             ✅ Core Data 配置
├── Utilities/
│   └── .gitkeep                      📦 工具类
├── Resources/
│   └── Assets.xcassets/              ✅ 资源文件
└── BalletDaily.xcdatamodeld/         ✅ Core Data 模型
```

## 🔧 在 Xcode 中重新组织文件引用

### 方法 1：简单重启（推荐）

1. **关闭 Xcode**
2. **重新打开项目**：
   ```bash
   open /Users/raymond/Documents/Repo/BalletDaily/BalletDaily.xcodeproj
   ```
3. **Xcode 可能会提示找不到文件** → 点击 "Locate" 选择新位置
4. **或者删除红色的文件引用，重新添加**

### 方法 2：手动重新组织（学习推荐）

在 Xcode 左侧文件导航器（Project Navigator）中：

#### 步骤 1：删除旧的文件引用
1. 选中顶层的 `BalletDaily` 文件夹（黄色图标）
2. 删除以下文件的引用（右键 → Delete → Remove Reference）：
   - `BalletDailyApp.swift`
   - `ContentView.swift`
   - `Persistence.swift`
   - `Assets.xcassets`

#### 步骤 2：创建 Group 结构
1. 右键点击 `BalletDaily` 项目
2. `New Group` → 创建以下 Group：
   - `App`
   - `Models`
   - `Views`
     - `Components`（在 Views 下再创建）
     - `Screens`（在 Views 下再创建）
   - `ViewModels`
   - `Services`
   - `Utilities`
   - `Resources`

#### 步骤 3：重新添加文件
1. 选中对应的 Group
2. 右键 → `Add Files to "BalletDaily"`
3. 导航到文件系统中对应的文件夹
4. 选择文件，**取消勾选** "Copy items if needed"
5. 点击 Add

需要添加的文件：
- `App` Group → 添加 `App/BalletDailyApp.swift`
- `Views` Group → 添加 `Views/ContentView.swift`
- `Services` Group → 添加 `Services/Persistence.swift`
- `Resources` Group → 添加 `Resources/Assets.xcassets`

### 方法 3：使用提供的脚本（自动化）

我会提供一个更新 Xcode 项目的脚本。

## ✅ 验证配置是否成功

完成后，在 Xcode 中：
1. 按 `Cmd + B` 编译项目
2. 应该没有错误
3. 按 `Cmd + R` 运行
4. 应用正常启动

如果有文件找不到的错误：
- 检查文件路径
- 重新添加文件引用
- 确保文件在正确的文件夹中

## 📝 下一步

配置完成后，继续 Task 0.3：配置权限和 Capabilities

