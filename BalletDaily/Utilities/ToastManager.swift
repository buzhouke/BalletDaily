//
//  ToastManager.swift
//  BalletDaily
//
//  Created on 2026/1/4
//  Toast 消息管理器
//

import SwiftUI
import Combine

/// Toast 消息类型
enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

/// Toast 消息
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let type: ToastType
    let message: String
    let duration: TimeInterval
    
    init(type: ToastType, message: String, duration: TimeInterval = 2.0) {
        self.type = type
        self.message = message
        self.duration = duration
    }
}

/// Toast 管理器
@MainActor
class ToastManager: ObservableObject {
    @Published var currentToast: ToastMessage?
    
    private var hideTask: Task<Void, Never>?
    
    /// 显示 Toast 消息
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 2.0) {
        // 取消之前的隐藏任务
        hideTask?.cancel()
        
        // 显示新消息
        currentToast = ToastMessage(type: type, message: message, duration: duration)
        
        // 设置自动隐藏
        hideTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if !Task.isCancelled {
                currentToast = nil
            }
        }
    }
    
    /// 显示成功消息
    func success(_ message: String, duration: TimeInterval = 2.0) {
        show(message, type: .success, duration: duration)
    }
    
    /// 显示错误消息
    func error(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .error, duration: duration)
    }
    
    /// 显示警告消息
    func warning(_ message: String, duration: TimeInterval = 2.5) {
        show(message, type: .warning, duration: duration)
    }
    
    /// 显示信息消息
    func info(_ message: String, duration: TimeInterval = 2.0) {
        show(message, type: .info, duration: duration)
    }
    
    /// 隐藏当前 Toast
    func hide() {
        hideTask?.cancel()
        currentToast = nil
    }
}

/// Toast 视图
struct ToastView: View {
    let toast: ToastMessage
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.type.icon)
                .font(.title3)
                .foregroundColor(toast.type.color)
            
            Text(toast.message)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

/// Toast 修饰符
struct ToastModifier: ViewModifier {
    @ObservedObject var toastManager: ToastManager
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            VStack {
                Spacer()
                
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: toastManager.currentToast)
                        .padding(.bottom, 20)
                }
            }
        }
    }
}

extension View {
    /// 添加 Toast 支持
    func toast(_ toastManager: ToastManager) -> some View {
        modifier(ToastModifier(toastManager: toastManager))
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var toastManager = ToastManager()
        
        var body: some View {
            VStack(spacing: 20) {
                Button("成功消息") {
                    toastManager.success("操作成功完成！")
                }
                
                Button("错误消息") {
                    toastManager.error("操作失败，请重试")
                }
                
                Button("警告消息") {
                    toastManager.warning("请注意这个操作")
                }
                
                Button("信息消息") {
                    toastManager.info("这是一条提示信息")
                }
            }
            .toast(toastManager)
        }
    }
    
    return PreviewWrapper()
}

