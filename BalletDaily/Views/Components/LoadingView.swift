import SwiftUI

/// 加载状态视图组件
/// 用于显示数据加载中的状态
struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 预设样式

extension LoadingView {
    /// 加载课程数据
    static var loadingSessions: LoadingView {
        LoadingView(message: "加载课程数据...")
    }
    
    /// 加载健康数据
    static var loadingHealthData: LoadingView {
        LoadingView(message: "正在从 HealthKit 获取数据...")
    }
    
    /// 加载趋势数据
    static var loadingTrends: LoadingView {
        LoadingView(message: "计算趋势数据...")
    }
    
    /// 同步数据
    static var syncing: LoadingView {
        LoadingView(message: "正在同步...")
    }
    
    /// 通用加载
    static var loading: LoadingView {
        LoadingView()
    }
}

#Preview("默认加载") {
    LoadingView()
}

#Preview("加载课程") {
    LoadingView.loadingSessions
}

#Preview("加载健康数据") {
    LoadingView.loadingHealthData
}

#Preview("同步数据") {
    LoadingView.syncing
}

