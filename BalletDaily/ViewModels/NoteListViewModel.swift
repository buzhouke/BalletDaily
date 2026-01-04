//
//  NoteListViewModel.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  笔记列表视图的数据管理
//

import Foundation
import SwiftUI
internal import CoreData
import Combine

/// 笔记列表 ViewModel
@MainActor
class NoteListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 按类型分组的笔记
    @Published var groupedNotes: [NoteType: [BalletSessionNote]] = [:]
    
    /// 是否正在加载
    @Published var isLoading = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 显示删除确认对话框
    @Published var showingDeleteConfirmation = false
    
    // MARK: - Private Properties
    
    let session: BalletSession
    private let noteService: NoteService
    private var noteToDelete: BalletSessionNote?
    
    // MARK: - Computed Properties
    
    /// 有笔记的类型列表（按预定义顺序）
    var noteTypes: [NoteType] {
        NoteType.allCases.filter { groupedNotes[$0]?.isEmpty == false }
    }
    
    /// 是否有笔记
    var hasNotes: Bool {
        !groupedNotes.isEmpty && groupedNotes.values.contains(where: { !$0.isEmpty })
    }
    
    /// 笔记总数
    var totalNotesCount: Int {
        groupedNotes.values.reduce(0) { $0 + $1.count }
    }
    
    // MARK: - Initialization
    
    init(session: BalletSession, context: NSManagedObjectContext) {
        self.session = session
        self.noteService = NoteService(context: context)
        loadNotes()
    }
    
    // MARK: - Data Loading
    
    /// 加载笔记数据
    func loadNotes() {
        isLoading = true
        errorMessage = nil
        
        // 获取按类型分组的笔记
        groupedNotes = noteService.fetchNotesGroupedByType(for: session)
        
        isLoading = false
    }
    
    // MARK: - Actions
    
    /// 删除笔记（显示确认对话框）
    func confirmDelete(_ note: BalletSessionNote) {
        noteToDelete = note
        showingDeleteConfirmation = true
    }
    
    /// 执行删除操作
    func deleteNote() {
        guard let note = noteToDelete else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            noteService.deleteNote(note)
            
            // 重新加载数据
            loadNotes()
            
            // 清除待删除笔记
            noteToDelete = nil
        } catch {
            errorMessage = "删除笔记失败：\(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 获取指定类型的笔记列表
    func notes(for type: NoteType) -> [BalletSessionNote] {
        return groupedNotes[type] ?? []
    }
    
    /// 获取删除确认信息
    var deleteConfirmationMessage: String {
        if let note = noteToDelete,
           let typeString = note.noteType,
           let type = NoteType(rawValue: typeString) {
            return "确定要删除这条\(type.displayName)吗？"
        }
        return "确定要删除这条笔记吗？"
    }
}

