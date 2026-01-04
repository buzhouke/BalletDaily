import SwiftUI
internal import CoreData
import Combine

/// 课程编辑/创建视图
struct SessionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: SessionEditViewModel
    @State private var showingNoteEdit = false
    @State private var quickNoteType: NoteType = .general
    
    let mode: EditMode
    
    init(session: BalletSession? = nil, context: NSManagedObjectContext? = nil) {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        self.mode = session == nil ? .create : .edit
        _viewModel = StateObject(wrappedValue: SessionEditViewModel(
            session: session,
            context: ctx
        ))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 日期和时间
                dateTimeSection
                
                // 时长
                durationSection
                
                // 课程信息
                sessionInfoSection
                
                // 笔记区域（仅编辑模式）
                if mode == .edit {
                    notesSection
                }
            }
            .navigationTitle(mode == .create ? "添加课程" : "编辑课程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            if await viewModel.save() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .sheet(isPresented: $showingNoteEdit) {
                NoteEditView(
                    session: viewModel.session,
                    note: nil,
                    initialType: quickNoteType,
                    context: viewContext
                )
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "保存中...")
                }
            }
        }
    }
    
    // MARK: - Date and Time Section
    
    private var dateTimeSection: some View {
        Section("日期和时间") {
            DatePicker(
                "日期",
                selection: $viewModel.sessionDate,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }
    
    // MARK: - Duration Section
    
    private var durationSection: some View {
        Section("时长") {
            if mode == .edit && !viewModel.session.isManualEntry {
                // 从 HealthKit 导入的课程，时长不可编辑
                HStack {
                    Text("时长")
                    Spacer()
                    Text(DateHelper.formatDuration(viewModel.duration))
                        .foregroundColor(.secondary)
                }
                
                Text("从 Apple Watch 导入的课程时长无法修改")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // 手动创建的课程，可以编辑时长
                Picker("时长", selection: $viewModel.durationMinutes) {
                    ForEach(DurationOption.allCases) { option in
                        Text(option.displayName).tag(option.minutes)
                    }
                }
                .pickerStyle(.wheel)
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        Section {
            Text("在编辑课程的同时，您也可以添加笔记")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NoteType.allCases, id: \.self) { type in
                        quickAddNoteButton(for: type)
                    }
                }
            }
        } header: {
            Text("课程笔记")
        }
    }
    
    private func quickAddNoteButton(for type: NoteType) -> some View {
        Button {
            quickNoteType = type
            showingNoteEdit = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(type.color.opacity(0.15))
            .foregroundColor(type.color)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(type.color.opacity(0.4), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Session Info Section
    
    private var sessionInfoSection: some View {
        Group {
            Section("课程信息") {
                // 课程名称
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("课程名称", text: $viewModel.name)
                        
                        if !viewModel.name.isEmpty {
                            Button {
                                viewModel.name = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if !viewModel.nameSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.nameSuggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        viewModel.name = suggestion
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
                }
                
                // 老师
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        TextField("老师", text: $viewModel.instructor)
                        
                        if !viewModel.instructor.isEmpty {
                            Button {
                                viewModel.instructor = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    if !viewModel.instructorSuggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewModel.instructorSuggestions, id: \.self) { suggestion in
                                    Button(action: {
                                        viewModel.instructor = suggestion
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
                }
                
                // 地点
                HStack {
                    TextField("地点", text: $viewModel.location)
                    
                    if !viewModel.location.isEmpty {
                        Button {
                            viewModel.location = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 机构
                HStack {
                    TextField("机构", text: $viewModel.organization)
                    
                    if !viewModel.organization.isEmpty {
                        Button {
                            viewModel.organization = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    enum EditMode {
        case create
        case edit
    }
}

// MARK: - View Model

@MainActor
class SessionEditViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var sessionDate: Date
    @Published var durationMinutes: Int
    @Published var name: String
    @Published var instructor: String
    @Published var location: String
    @Published var organization: String
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    let session: BalletSession
    private let sessionService: SessionService
    private let tagService: TagService
    private let context: NSManagedObjectContext
    private let isNewSession: Bool
    
    // MARK: - Computed Properties
    
    var duration: TimeInterval {
        TimeInterval(durationMinutes * 60)
    }
    
    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 课程名称建议
    var nameSuggestions: [String] {
        guard !name.isEmpty else {
            return tagService.getSuggestions(for: TagType.className.rawValue, limit: 5)
        }
        return tagService.searchTags(type: TagType.className.rawValue, query: name)
    }
    
    /// 老师建议
    var instructorSuggestions: [String] {
        guard !instructor.isEmpty else {
            return tagService.getSuggestions(for: TagType.instructor.rawValue, limit: 5)
        }
        return tagService.searchTags(type: TagType.instructor.rawValue, query: instructor)
    }
    
    // MARK: - Initialization
    
    init(session: BalletSession?, context: NSManagedObjectContext) {
        self.context = context
        self.sessionService = SessionService(context: context)
        self.tagService = TagService(context: context)
        
        if let session = session {
            // 编辑模式
            self.session = session
            self.isNewSession = false
            self.sessionDate = session.sessionDate ?? Date()
            self.durationMinutes = Int(session.duration / 60)
            self.name = session.name ?? ""
            self.instructor = session.instructor ?? ""
            self.location = session.location ?? ""
            self.organization = session.organization ?? ""
        } else {
            // 创建模式
            let newSession = BalletSession(context: context)
            newSession.id = UUID()
            newSession.createdAt = Date()
            newSession.updatedAt = Date()
            newSession.isManualEntry = true
            
            self.session = newSession
            self.isNewSession = true
            self.sessionDate = Date()
            self.durationMinutes = 60 // 默认1小时
            self.name = ""
            self.instructor = ""
            self.location = ""
            self.organization = ""
        }
    }
    
    // MARK: - Actions
    
    func save() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // 更新 session 数据
        session.sessionDate = sessionDate
        session.duration = duration
        session.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        session.instructor = instructor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : instructor.trimmingCharacters(in: .whitespacesAndNewlines)
        session.location = location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : location.trimmingCharacters(in: .whitespacesAndNewlines)
        session.organization = organization.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : organization.trimmingCharacters(in: .whitespacesAndNewlines)
        session.updatedAt = Date()
        
        do {
            try sessionService.saveContext()
            
            // 记录常用标签
            if let sessionName = session.name, !sessionName.isEmpty {
                tagService.recordTag(type: TagType.className.rawValue, value: sessionName)
            }
            if let instructor = session.instructor {
                tagService.recordTag(type: TagType.instructor.rawValue, value: instructor)
            }
            if let location = session.location {
                tagService.recordTag(type: TagType.location.rawValue, value: location)
            }
            
            isLoading = false
            return true
        } catch {
            if isNewSession {
                // 如果是新建失败，删除创建的对象
                context.delete(session)
            }
            
            errorMessage = "保存失败：\(error.localizedDescription)"
            print("❌ Failed to save session: \(error)")
            isLoading = false
            return false
        }
    }
}

// MARK: - Duration Options

enum DurationOption: Int, CaseIterable, Identifiable {
    case min30 = 30
    case min45 = 45
    case min60 = 60
    case min75 = 75
    case min90 = 90
    case min105 = 105
    case min120 = 120
    case min150 = 150
    case min180 = 180
    
    var id: Int { rawValue }
    
    var minutes: Int { rawValue }
    
    var displayName: String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)小时\(mins)分钟"
        } else if hours > 0 {
            return "\(hours)小时"
        } else {
            return "\(mins)分钟"
        }
    }
}

// MARK: - Previews

#Preview("Create") {
    SessionEditView(context: PersistenceController.preview.container.viewContext)
}

#Preview("Edit") {
    let context = PersistenceController.preview.container.viewContext
    
    let session = BalletSession(context: context)
    session.id = UUID()
    session.createdAt = Date()
    session.updatedAt = Date()
    session.sessionDate = Date()
    session.duration = 5400
    session.name = "芭蕾基础"
    session.instructor = "李老师"
    session.location = "北京舞蹈学院"
    session.isManualEntry = true
    
    
    let preview = SessionEditView(context: context)
        return preview}

