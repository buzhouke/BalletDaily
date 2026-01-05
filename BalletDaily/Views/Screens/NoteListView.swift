//
//  NoteListView.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  课程笔记列表视图
//

import SwiftUI
internal import CoreData

/// 课程笔记列表视图
struct NoteListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: NoteListViewModel
    @State private var showingNoteEdit = false
    @State private var editingNote: BalletSessionNote?
    @State private var selectedNoteType: NoteType = .general
    
    init(session: BalletSession, context: NSManagedObjectContext? = nil) {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: NoteListViewModel(session: session, context: ctx))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.hasNotes {
                    notesList
                } else {
                    emptyState
                }
            }
            .navigationTitle("课程笔记")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editingNote = nil
                        selectedNoteType = .general
                        showingNoteEdit = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNoteEdit) {
                NoteEditView(
                    session: viewModel.session,
                    note: editingNote,
                    initialType: selectedNoteType,
                    context: viewContext
                )
            }
            .alert("删除笔记", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("取消", role: .cancel) { }
                Button("删除", role: .destructive) {
                    viewModel.deleteNote()
                }
            } message: {
                Text(viewModel.deleteConfirmationMessage)
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
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "加载中...")
                }
            }
            .onChange(of: showingNoteEdit) { _, newValue in
                if !newValue {
                    // 编辑完成后重新加载数据
                    viewModel.loadNotes()
                }
            }
        }
    }
    
    // MARK: - Notes List
    
    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                ForEach(viewModel.noteTypes, id: \.self) { type in
                    Section {
                        noteTypeSection(type: type)
                    } header: {
                        noteTypeSectionHeader(type: type)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Note Type Section
    
    private func noteTypeSectionHeader(type: NoteType) -> some View {
        HStack {
            Image(systemName: type.icon)
                .foregroundColor(type.color)
                .font(.title3)
            
            Text(type.displayName)
                .font(.headline)
            
            Text("(\(viewModel.notes(for: type).count))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func noteTypeSection(type: NoteType) -> some View {
        VStack(spacing: 12) {
            ForEach(viewModel.notes(for: type)) { note in
                NoteRow(note: note, type: type)
                    .onTapGesture {
                        editingNote = note
                        selectedNoteType = type
                        showingNoteEdit = true
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            viewModel.confirmDelete(note)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        EmptyStateView(
            icon: "note.text",
            title: "还没有笔记",
            message: "点击右上角的 + 按钮添加第一条课程笔记",
            actionTitle: "添加笔记",
            action: {
                editingNote = nil
                selectedNoteType = .general
                showingNoteEdit = true
            }
        )
    }
    
    // MARK: - Session Property
    
    /// 当前课程（用于 NoteEditView）
    private var session: BalletSession {
        viewModel.session
    }
}

// MARK: - Note Row

struct NoteRow: View {
    let note: BalletSessionNote
    let type: NoteType
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 图标
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(type.color)
                .frame(width: 32)
            
            // 内容
            VStack(alignment: .leading, spacing: 6) {
                Text(note.content ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                // 时间戳
                Text(note.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
            
            // 编辑指示器
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Previews

#Preview("With Notes") {
    let context = PersistenceController.preview.container.viewContext
    let session = makeSessionWithNotes(in: context)
    
    return NavigationStack {
        NoteListView(session: session, context: context)
    }
}

#Preview("Empty") {
    let context = PersistenceController.preview.container.viewContext
    let session = makeEmptySession(in: context)
    
    return NavigationStack {
        NoteListView(session: session, context: context)
    }
}

// MARK: - Preview Helpers

private func makeSessionWithNotes(in context: NSManagedObjectContext) -> BalletSession {
    let session = BalletSession(context: context)
    session.id = UUID()
    session.createdAt = Date()
    session.updatedAt = Date()
    session.sessionDate = Date()
    session.duration = 3600
    session.name = "芭蕾基础"
    session.instructor = "李老师"
    session.isManualEntry = true
    
    // 添加不同类型的笔记
    let noteService = NoteService(context: context)
    
    noteService.addNote(to: session, type: .feeling, content: "今天的课程感觉很好，动作流畅了很多。")
    noteService.addNote(to: session, type: .technique, content: "Grand Battement 的腿要伸直，脚背要绷紧。")
    noteService.addNote(to: session, type: .technique, content: "Pirouette 转圈时，头要快速跟上，保持视线聚焦。")
    noteService.addNote(to: session, type: .improvement, content: "Arabesque 的平衡还需要加强练习。")
    noteService.addNote(to: session, type: .achievement, content: "今天成功完成了连续三个 Fouette！")
    
    return session
}

private func makeEmptySession(in context: NSManagedObjectContext) -> BalletSession {
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

