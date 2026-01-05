import SwiftUI

/// 空状态视图组件
/// 用于在没有数据时显示友好的提示信息
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
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
                .padding(.horizontal)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 预设样式

extension EmptyStateView {
    /// 空课程列表
    static func noSessions(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "figure.dance",
            title: "还没有课程记录",
            message: "点击右上角的 + 按钮\n记录你的第一节芭蕾课程",
            actionTitle: "添加课程",
            action: action
        )
    }
    
    /// 空笔记列表
    static func noNotes(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "note.text",
            title: "还没有笔记",
            message: "记录课后感想、技术要点\n让进步清晰可见",
            actionTitle: "添加笔记",
            action: action
        )
    }
    
    /// 空趋势数据
    static var noTrendData: EmptyStateView {
        EmptyStateView(
            icon: "chart.line.uptrend.xyaxis",
            title: "暂无趋势数据",
            message: "记录更多课程后\n这里将展示你的进步趋势"
        )
    }
    
    /// 搜索无结果
    static var noSearchResults: EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "没有找到匹配的结果",
            message: "试试其他搜索关键词"
        )
    }
    
    /// HealthKit 未授权
    static func healthKitNotAuthorized(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "heart.text.square",
            title: "需要 HealthKit 授权",
            message: "授权后可以自动导入\nApple Watch 记录的训练数据",
            actionTitle: "前往授权",
            action: action
        )
    }
}

#Preview("空课程列表") {
    EmptyStateView.noSessions {
        print("Add session tapped")
    }
}

#Preview("空笔记列表") {
    EmptyStateView.noNotes {
        print("Add note tapped")
    }
}

#Preview("空趋势数据") {
    EmptyStateView.noTrendData
}

#Preview("搜索无结果") {
    EmptyStateView.noSearchResults
}

#Preview("HealthKit 未授权") {
    EmptyStateView.healthKitNotAuthorized {
        print("Authorize tapped")
    }
}

