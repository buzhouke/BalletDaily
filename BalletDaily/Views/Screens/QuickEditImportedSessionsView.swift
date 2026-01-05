//
//  QuickEditImportedSessionsView.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  快速编辑导入的课程
//

import SwiftUI
internal import CoreData

/// 快速编辑导入的课程视图
struct QuickEditImportedSessionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let sessions: [BalletSession]
    @State private var editingData: [UUID: SessionEditData] = [:]
    @State private var currentIndex = 0
    
    private let tagService: TagService
    
    init(sessions: [BalletSession], context: NSManagedObjectContext) {
        self.sessions = sessions
        self.tagService = TagService(context: context)
        
        // 初始化编辑数据
        var data: [UUID: SessionEditData] = [:]
        for session in sessions {
            if let id = session.id {
                data[id] = SessionEditData(
                    name: session.name ?? "",
                    instructor: session.instructor ?? ""
                )
            }
        }
        _editingData = State(initialValue: data)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 进度指示器
                if sessions.count > 1 {
                    progressIndicator
                }
                
                // 当前课程编辑
                if currentIndex < sessions.count {
                    currentSessionEditor
                } else {
                    completionView
                }
            }
            .navigationTitle("快速编辑课程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳过全部") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                Text("课程 \(currentIndex + 1) / \(sessions.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            ProgressView(value: Double(currentIndex), total: Double(sessions.count))
                .tint(.blue)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Current Session Editor
    
    private var currentSessionEditor: some View {
        let session = sessions[currentIndex]
        
        return ScrollView {
            VStack(spacing: 20) {
                // 课程信息卡片
                sessionInfoCard(session: session)
                
                // 编辑表单
                editForm(session: session)
                
                // 操作按钮
                actionButtons(session: session)
            }
            .padding()
        }
    }
    
    private func sessionInfoCard(session: BalletSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "applewatch")
                    .foregroundColor(.green)
                Text("从 Apple Watch 导入")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            Divider()
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text(DateHelper.formatSessionDate(session.sessionDate ?? Date()))
                    .font(.subheadline)
            }
            
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                Text(DateHelper.formatDuration(session.duration))
                    .font(.subheadline)
            }
            
            if let metrics = session.healthMetrics, metrics.avgHeartRate > 0 {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("平均心率: \(Int(metrics.avgHeartRate)) bpm")
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func editForm(session: BalletSession) -> some View {
        guard let sessionId = session.id,
              let data = editingData[sessionId] else {
            return AnyView(EmptyView())
        }
        
        return AnyView(
            VStack(spacing: 16) {
                // 课程名称
                VStack(alignment: .leading, spacing: 8) {
                    Text("课程名称")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("例如：芭蕾基础", text: Binding(
                        get: { data.name },
                        set: { editingData[sessionId]?.name = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    // 快速选择标签
                    if !data.name.isEmpty {
                        let suggestions = tagService.searchTags(type: TagType.className.rawValue, query: data.name, limit: 5)
                        if !suggestions.isEmpty {
                            quickSelectTags(suggestions: suggestions, sessionId: sessionId, field: .className)
                        }
                    } else {
                        let suggestions = tagService.getSuggestions(for: TagType.className.rawValue, limit: 5)
                        if !suggestions.isEmpty {
                            quickSelectTags(suggestions: suggestions, sessionId: sessionId, field: .className)
                        }
                    }
                }
                
                // 老师
                VStack(alignment: .leading, spacing: 8) {
                    Text("老师")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("例如：张老师", text: Binding(
                        get: { data.instructor },
                        set: { editingData[sessionId]?.instructor = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    // 快速选择标签
                    if !data.instructor.isEmpty {
                        let suggestions = tagService.searchTags(type: TagType.instructor.rawValue, query: data.instructor, limit: 5)
                        if !suggestions.isEmpty {
                            quickSelectTags(suggestions: suggestions, sessionId: sessionId, field: .instructor)
                        }
                    } else {
                        let suggestions = tagService.getSuggestions(for: TagType.instructor.rawValue, limit: 5)
                        if !suggestions.isEmpty {
                            quickSelectTags(suggestions: suggestions, sessionId: sessionId, field: .instructor)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private func quickSelectTags(suggestions: [String], sessionId: UUID, field: EditField) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        switch field {
                        case .className:
                            editingData[sessionId]?.name = suggestion
                        case .instructor:
                            editingData[sessionId]?.instructor = suggestion
                        }
                    }) {
                        Text(suggestion)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    private func actionButtons(session: BalletSession) -> some View {
        VStack(spacing: 12) {
            // 保存并继续
            Button {
                saveAndNext(session: session)
            } label: {
                Label(currentIndex < sessions.count - 1 ? "保存并继续" : "保存并完成", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            // 跳过此课程
            Button {
                skipCurrent()
            } label: {
                Text(currentIndex < sessions.count - 1 ? "跳过此课程" : "跳过")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Completion View
    
    private var completionView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("全部完成！")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("已完成 \(sessions.count) 个课程的编辑")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("完成")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func saveAndNext(session: BalletSession) {
        // 保存当前课程的编辑
        if let sessionId = session.id, let data = editingData[sessionId] {
            let trimmedName = data.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedInstructor = data.instructor.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmedName.isEmpty {
                session.name = trimmedName
                // 记录标签
                tagService.recordTag(type: TagType.className.rawValue, value: trimmedName)
            }
            
            if !trimmedInstructor.isEmpty {
                session.instructor = trimmedInstructor
                // 记录标签
                tagService.recordTag(type: TagType.instructor.rawValue, value: trimmedInstructor)
            }
            
            session.updatedAt = Date()
            
            // 保存到 Core Data
            do {
                try viewContext.save()
                print("✅ 保存课程: \(session.name ?? "未命名")")
            } catch {
                print("❌ 保存失败: \(error.localizedDescription)")
            }
        }
        
        // 移动到下一个
        if currentIndex < sessions.count - 1 {
            currentIndex += 1
        } else {
            // 全部完成
            currentIndex = sessions.count
        }
    }
    
    private func skipCurrent() {
        if currentIndex < sessions.count - 1 {
            currentIndex += 1
        } else {
            dismiss()
        }
    }
}

// MARK: - Supporting Types

struct SessionEditData {
    var name: String
    var instructor: String
}

enum EditField {
    case className
    case instructor
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // 创建测试数据
    let sessions = (0..<3).map { i in
        let session = BalletSession(context: context)
        session.id = UUID()
        session.createdAt = Date()
        session.updatedAt = Date()
        session.sessionDate = Date().addingTimeInterval(Double(-i * 86400))
        session.duration = 3600 + Double(i * 600)
        session.isManualEntry = false
        return session
    }
    
    return QuickEditImportedSessionsView(sessions: sessions, context: context)
}

