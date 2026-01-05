//
//  NoteEditView.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  笔记编辑视图
//

import SwiftUI
internal import CoreData

/// 笔记编辑视图
struct NoteEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    // MARK: - Properties
    
    let session: BalletSession
    let note: BalletSessionNote?
    let initialType: NoteType
    
    private let noteService: NoteService
    
    // MARK: - State
    
    @State private var selectedType: NoteType
    @State private var content: String
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage: String = ""
    
    // MARK: - Computed
    
    private var isEditing: Bool {
        note != nil
    }
    
    private var title: String {
        isEditing ? "编辑笔记" : "新建笔记"
    }
    
    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    
    init(
        session: BalletSession,
        note: BalletSessionNote? = nil,
        initialType: NoteType = .general,
        context: NSManagedObjectContext
    ) {
        self.session = session
        self.note = note
        self.initialType = initialType
        self.noteService = NoteService(context: context)
        
        // 初始化 State
        if let note = note {
            _selectedType = State(initialValue: NoteType(rawValue: note.noteType ?? "general") ?? .general)
            _content = State(initialValue: note.content ?? "")
        } else {
            _selectedType = State(initialValue: initialType)
            _content = State(initialValue: "")
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // 笔记类型选择
                Section {
                    Picker("笔记类型", selection: $selectedType) {
                        ForEach(NoteType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // 笔记内容输入
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: selectedType.icon)
                                .foregroundColor(selectedType.color)
                            Text(selectedType.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .scrollContentBackground(.hidden)
                    }
                } header: {
                    Text("笔记内容")
                } footer: {
                    Text("记录你的课程感想、技术要点或需要改进的地方")
                        .font(.caption)
                }
                
                // 时间信息（仅编辑模式）
                if let note = note {
                    Section {
                        HStack {
                            Text("创建时间")
                            Spacer()
                            Text(note.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                .foregroundColor(.secondary)
                        }
                        
                        if let updatedAt = note.updatedAt,
                           updatedAt > (note.createdAt ?? Date()) {
                            HStack {
                                Text("最后修改")
                                Spacer()
                                Text(updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveNote()
                    }
                    .disabled(!canSave || isSaving)
                }
            }
            .alert("错误", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isSaving {
                    LoadingView(message: "保存中...")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        guard canSave else { return }
        
        isSaving = true
        
        do {
            if let note = note {
                // 更新现有笔记
                noteService.updateNote(note, content: content)
                noteService.updateNote(note, type: selectedType)
            } else {
                // 创建新笔记
                noteService.addNote(to: session, type: selectedType, content: content)
            }
            
            dismiss()
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
            showingError = true
        }
        
        isSaving = false
    }
}

// MARK: - Previews

#Preview("New Note") {
    let context = PersistenceController.preview.container.viewContext
    let session = makePreviewSession(in: context)
    
    return NoteEditView(
        session: session,
        note: nil,
        initialType: .feeling,
        context: context
    )
}

#Preview("Edit Note") {
    let context = PersistenceController.preview.container.viewContext
    let session = makePreviewSession(in: context)
    let note = makePreviewNote(for: session, in: context)
    
    return NoteEditView(
        session: session,
        note: note,
        initialType: .technique,
        context: context
    )
}

// MARK: - Preview Helpers

private func makePreviewSession(in context: NSManagedObjectContext) -> BalletSession {
    let session = BalletSession(context: context)
    session.id = UUID()
    session.createdAt = Date()
    session.updatedAt = Date()
    session.sessionDate = Date()
    session.duration = 3600
    session.name = "芭蕾基础"
    session.isManualEntry = true
    
    return session
}

private func makePreviewNote(for session: BalletSession, in context: NSManagedObjectContext) -> BalletSessionNote {
    let note = BalletSessionNote(context: context)
    note.id = UUID()
    note.createdAt = Date()
    note.updatedAt = Date()
    note.noteType = NoteType.technique.rawValue
    note.content = "Grand Battement 的腿要伸直，脚背要绷紧。"
    note.order = 0
    note.session = session
    
    return note
}

