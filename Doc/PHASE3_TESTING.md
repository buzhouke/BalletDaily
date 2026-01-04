# Phase 3: 基础 UI - 测试指南

**创建日期**：2026年1月1日

---

## 📋 测试准备

### 前提条件
- ✅ Xcode 15.0+
- ✅ iOS 16.0+ 模拟器或真机
- ✅ Phase 1 和 Phase 2 已完成

### 测试环境
```
Xcode: 15.0+
iOS Deployment Target: 16.0
Swift: 5.9+
```

---

## 🧪 测试项目

### 1. 导航结构测试

#### 测试目标
验证主导航的三个 Tab 是否正常工作

#### 测试步骤
1. 在 Xcode 中运行应用（Cmd + R）
2. 应用启动后，默认显示"课程"Tab
3. 点击底部的"趋势"Tab
4. 验证切换到趋势分析页面
5. 点击底部的"设置"Tab
6. 验证切换到设置页面
7. 再次点击"课程"Tab 返回

#### 预期结果
- ✅ Tab 切换流畅无卡顿
- ✅ 每个 Tab 显示正确的内容
- ✅ Tab 图标和文字清晰可见
- ✅ 选中的 Tab 有高亮显示

---

### 2. 设置页面测试

#### 测试目标
验证设置页面的所有功能

#### 测试步骤

**HealthKit 集成**
1. 进入"设置"Tab
2. 查看"启用 HealthKit"开关状态
3. 查看"授权状态"显示
4. 如果未授权，点击"请求 HealthKit 权限"按钮
5. 在弹出的权限对话框中选择"允许"
6. 验证授权状态变为绿色对勾

**显示偏好**
1. 在设置页面向下滚动到"显示偏好"部分
2. 点击"默认趋势视图"选择器
3. 切换不同的选项（本周/本月/本年）
4. 验证选择被保存
5. 点击"主题"选择器
6. 切换不同的主题（系统/浅色/深色）
7. 验证主题立即生效

**数据管理**
1. 查看"导出数据"按钮（目前是占位符）
2. 查看"iCloud 同步"状态显示

**关于信息**
1. 查看版本号显示（1.0.0）
2. 点击"GitHub 仓库"链接（会打开浏览器）

**开发测试**
1. 点击"📊 测试读取训练记录"
2. 在控制台查看输出
3. 点击"📥 测试导入芭蕾课程"
4. 在控制台查看导入结果
5. 点击"🔄 测试健康数据同步"
6. 在控制台查看同步结果

#### 预期结果
- ✅ 所有设置项正常显示
- ✅ Toggle 和 Picker 交互正常
- ✅ HealthKit 权限请求正常
- ✅ 主题切换立即生效
- ✅ 测试按钮功能正常
- ✅ 控制台输出正确的测试信息

---

### 3. 空状态视图测试

#### 测试目标
验证各种空状态视图的显示效果

#### 测试步骤

**在 Xcode Preview 中测试**
1. 打开 `EmptyStateView.swift` 文件
2. 在 Canvas 中查看 Preview（Cmd + Option + Enter）
3. 查看以下预览：
   - 空课程列表
   - 空笔记列表
   - 空趋势数据
   - 搜索无结果
   - HealthKit 未授权

**在运行时测试**
1. 进入"课程"Tab（目前是占位符，未来会显示空状态）
2. 进入"趋势"Tab（目前是占位符）

#### 预期结果
- ✅ 所有空状态 Preview 正常显示
- ✅ 图标、标题、消息清晰可见
- ✅ 按钮（如果有）可以点击
- ✅ 布局在不同屏幕尺寸下正常

---

### 4. 加载状态视图测试

#### 测试目标
验证加载状态视图的显示效果

#### 测试步骤

**在 Xcode Preview 中测试**
1. 打开 `LoadingView.swift` 文件
2. 在 Canvas 中查看 Preview
3. 查看以下预览：
   - 默认加载
   - 加载课程
   - 加载健康数据
   - 同步数据

**在运行时测试**
1. 在设置页面点击"测试导入芭蕾课程"
2. 观察加载过程（虽然很快）

#### 预期结果
- ✅ 所有加载状态 Preview 正常显示
- ✅ ProgressView 动画流畅
- ✅ 加载消息清晰可见
- ✅ 布局居中显示

---

### 5. 主题系统测试

#### 测试目标
验证主题颜色和深色模式支持

#### 测试步骤

**颜色资源测试**
1. 打开 `Theme.swift` 文件
2. 在 Canvas 中查看"主题色板" Preview
3. 验证所有颜色正常显示

**深色模式测试**
1. 在模拟器中打开"设置"
2. 进入"开发者" → "Dark Appearance"
3. 切换深色模式
4. 返回 BalletDaily 应用
5. 验证颜色自动切换
6. 进入应用设置页面
7. 切换主题为"深色"
8. 验证主题立即生效

**或者在 Xcode 中测试**
1. 在 Canvas 中，点击右下角的外观切换按钮
2. 切换到深色模式
3. 验证所有 Preview 的深色外观

#### 预期结果
- ✅ 所有颜色在 Assets 中正确配置
- ✅ 主题色板 Preview 正常显示
- ✅ 深色模式下颜色自动切换
- ✅ 颜色对比度符合标准
- ✅ 整体视觉柔和不刺眼

---

### 6. 日期工具测试

#### 测试目标
验证日期格式化和计算功能

#### 测试步骤

**创建测试代码**

在 `ContentView.swift` 或创建新的测试文件中添加：

```swift
import SwiftUI

struct DateHelperTestView: View {
    let testDate = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    let duration: TimeInterval = 5400 // 1.5小时
    
    var body: some View {
        List {
            Section("日期格式化") {
                Text("Session: \(DateHelper.formatSessionDate(testDate))")
                Text("Short: \(DateHelper.formatShortDate(testDate))")
                Text("Full: \(DateHelper.formatFullDate(testDate))")
                Text("Time: \(DateHelper.formatTime(testDate))")
                Text("DateTime: \(DateHelper.formatDateTime(testDate))")
            }
            
            Section("时长格式化") {
                Text("Duration: \(DateHelper.formatDuration(duration))")
                Text("Short: \(DateHelper.formatDurationShort(duration))")
            }
            
            Section("相对时间") {
                Text("Today: \(DateHelper.relativeString(from: testDate))")
                Text("Yesterday: \(DateHelper.relativeString(from: yesterday))")
                Text("Last week: \(DateHelper.relativeString(from: lastWeek))")
            }
            
            Section("日期计算") {
                Text("Start of week: \(DateHelper.formatShortDate(testDate.startOfWeek))")
                Text("End of week: \(DateHelper.formatShortDate(testDate.endOfWeek))")
                Text("Start of month: \(DateHelper.formatShortDate(testDate.startOfMonth))")
                Text("End of month: \(DateHelper.formatShortDate(testDate.endOfMonth))")
            }
        }
        .navigationTitle("DateHelper 测试")
    }
}
```

**运行测试**
1. 在 Xcode 中运行测试视图
2. 验证各种日期格式化输出
3. 检查相对时间计算是否正确
4. 验证日期计算结果

#### 预期结果
- ✅ 日期格式符合中文习惯
- ✅ 时长格式清晰易读
- ✅ 相对时间计算准确
- ✅ 日期范围计算正确

---

## 🎨 视觉检查清单

### 导航和布局
- [ ] Tab 图标清晰可见
- [ ] Tab 文字大小适中
- [ ] 选中状态明显
- [ ] 页面切换无闪烁

### 设置页面
- [ ] Form 分组清晰
- [ ] Toggle 开关易于点击
- [ ] Picker 选择器正常工作
- [ ] 链接颜色明显

### 空状态视图
- [ ] 图标大小合适
- [ ] 标题字体清晰
- [ ] 消息易于阅读
- [ ] 按钮醒目

### 加载状态视图
- [ ] ProgressView 动画流畅
- [ ] 加载消息清晰
- [ ] 居中对齐

### 主题颜色
- [ ] 主色调柔和不刺眼
- [ ] 背景色舒适
- [ ] 文字对比度适中
- [ ] 深色模式协调

---

## 📱 兼容性测试

### 测试设备

**模拟器**
- [ ] iPhone SE (3rd generation) - 小屏幕
- [ ] iPhone 15 - 标准屏幕
- [ ] iPhone 15 Pro Max - 大屏幕
- [ ] iPad (10th generation) - 平板

**iOS 版本**
- [ ] iOS 16.0
- [ ] iOS 17.0
- [ ] iOS 17.2（最新）

**外观模式**
- [ ] 浅色模式
- [ ] 深色模式
- [ ] 自动切换

---

## 🐛 常见问题排查

### 问题：颜色资源未加载

**症状**：应用中颜色显示为默认颜色或黑色

**解决方法**：
1. 确认所有 ColorSet 文件夹存在
2. 确认每个 ColorSet 包含 Contents.json
3. 在 Xcode 中清理构建文件夹（Cmd + Shift + K）
4. 重新构建项目（Cmd + B）

### 问题：Tab 图标不显示

**症状**：Tab 栏只显示文字，图标缺失

**解决方法**：
1. 确认使用的是 SF Symbols 系统图标
2. 检查图标名称拼写是否正确
3. 确认 iOS 版本支持该图标

### 问题：设置项不保存

**症状**：更改设置后重启应用，设置恢复默认值

**解决方法**：
1. 确认使用了 @AppStorage
2. 检查 key 名称是否一致
3. 在模拟器中重置内容和设置，重新测试

### 问题：深色模式不生效

**症状**：切换深色模式后颜色不改变

**解决方法**：
1. 确认 ColorSet 中配置了深色模式颜色
2. 检查 Contents.json 中的 appearances 配置
3. 确认使用的是 Color() 而不是硬编码颜色值

---

## ✅ 测试完成检查表

### 功能测试
- [ ] 主导航三个 Tab 正常切换
- [ ] 设置页面所有项目正常工作
- [ ] HealthKit 权限请求成功
- [ ] 主题切换立即生效
- [ ] 测试按钮功能正常
- [ ] 空状态视图正确显示
- [ ] 加载状态视图正确显示
- [ ] 日期工具输出正确

### 视觉测试
- [ ] 所有颜色显示正确
- [ ] 深色模式正常工作
- [ ] 布局在不同屏幕尺寸下正常
- [ ] 字体大小适中易读
- [ ] 图标清晰可见
- [ ] 整体视觉柔和舒适

### 兼容性测试
- [ ] 在小屏幕设备上测试通过
- [ ] 在大屏幕设备上测试通过
- [ ] 在 iPad 上测试通过
- [ ] iOS 16.0 测试通过
- [ ] iOS 17.x 测试通过

### 性能测试
- [ ] Tab 切换流畅无卡顿
- [ ] 页面加载快速
- [ ] 动画流畅
- [ ] 无内存警告

---

## 📊 测试报告模板

```
Phase 3 测试报告
================

测试日期：________
测试人员：________
测试环境：
- Xcode 版本：________
- iOS 版本：________
- 测试设备：________

测试结果：
- 导航结构：[ ] 通过 [ ] 失败
- 设置页面：[ ] 通过 [ ] 失败
- 空状态视图：[ ] 通过 [ ] 失败
- 加载状态视图：[ ] 通过 [ ] 失败
- 主题系统：[ ] 通过 [ ] 失败
- 日期工具：[ ] 通过 [ ] 失败

发现的问题：
1. ___________________________
2. ___________________________
3. ___________________________

总体评价：
___________________________
___________________________

测试结论：[ ] 通过 [ ] 需要修复
```

---

## 🎯 下一步

测试通过后，可以开始 **Phase 4: 课程记录功能** 的开发。

Phase 4 将基于 Phase 3 的 UI 框架，实现：
- 带真实数据的课程列表
- 课程详情展示
- 课程创建和编辑
- 搜索和筛选功能

---

**祝测试顺利！** 🎉

