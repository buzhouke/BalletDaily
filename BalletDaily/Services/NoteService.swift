//
//  NoteService.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  笔记数据服务 - 处理课程笔记的增删改查
//

import Foundation
internal import CoreData

/// 笔记数据服务
/// 负责 BalletSessionNote 的所有数据操作
class NoteService {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }
    
    // MARK: - Create
    
    /// 为课程添加笔记
    /// - Parameters:
    ///   - session: 课程对象
    ///   - type: 笔记类型
    ///   - content: 笔记内容
    /// - Returns: 创建的笔记对象
    @discardableResult
    func addNote(
        to session: BalletSession,
        type: NoteType,
        content: String
    ) -> BalletSessionNote {
        let note = BalletSessionNote(context: context)
        note.id = UUID()
        note.createdAt = Date()
        note.updatedAt = Date()
        note.noteType = type.rawValue
        note.content = content
        note.session = session
        
        // 设置排序顺序（当前笔记数量 + 1）
        let currentNotes = fetchNotes(for: session)
        note.order = Int16(currentNotes.count)
        
        // 更新课程的 updatedAt
        session.updatedAt = Date()
        
        save()
        
        return note
    }
    
    // MARK: - Read
    
    /// 获取课程的所有笔记
    /// - Parameter session: 课程对象
    /// - Returns: 笔记数组，按 order 排序
    func fetchNotes(for session: BalletSession) -> [BalletSessionNote] {
        let fetchRequest: NSFetchRequest<BalletSessionNote> = BalletSessionNote.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSessionNote.order, ascending: true),
            NSSortDescriptor(keyPath: \BalletSessionNote.createdAt, ascending: true)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 获取笔记列表失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 按类型获取课程的笔记
    /// - Parameters:
    ///   - session: 课程对象
    ///   - type: 笔记类型
    /// - Returns: 笔记数组
    func fetchNotes(for session: BalletSession, type: NoteType) -> [BalletSessionNote] {
        let fetchRequest: NSFetchRequest<BalletSessionNote> = BalletSessionNote.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "session == %@ AND noteType == %@",
            session,
            type.rawValue
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSessionNote.order, ascending: true)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 按类型获取笔记失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取课程笔记，按类型分组
    /// - Parameter session: 课程对象
    /// - Returns: 字典，键为笔记类型，值为笔记数组
    func fetchNotesGroupedByType(for session: BalletSession) -> [NoteType: [BalletSessionNote]] {
        let allNotes = fetchNotes(for: session)
        var grouped: [NoteType: [BalletSessionNote]] = [:]
        
        for note in allNotes {
            if let typeString = note.noteType,
               let type = NoteType(rawValue: typeString) {
                if grouped[type] == nil {
                    grouped[type] = []
                }
                grouped[type]?.append(note)
            }
        }
        
        return grouped
    }
    
    /// 按 ID 获取笔记
    /// - Parameter id: 笔记 UUID
    /// - Returns: 笔记对象，如果不存在则返回 nil
    func fetchNote(by id: UUID) -> BalletSessionNote? {
        let fetchRequest: NSFetchRequest<BalletSessionNote> = BalletSessionNote.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("❌ 获取笔记失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Update
    
    /// 更新笔记内容
    /// - Parameters:
    ///   - note: 要更新的笔记对象
    ///   - content: 新的内容
    func updateNote(_ note: BalletSessionNote, content: String) {
        note.content = content
        note.updatedAt = Date()
        
        // 更新关联课程的 updatedAt
        note.session?.updatedAt = Date()
        
        save()
    }
    
    /// 更新笔记类型
    /// - Parameters:
    ///   - note: 要更新的笔记对象
    ///   - type: 新的笔记类型
    func updateNote(_ note: BalletSessionNote, type: NoteType) {
        note.noteType = type.rawValue
        note.updatedAt = Date()
        note.session?.updatedAt = Date()
        
        save()
    }
    
    // MARK: - Delete
    
    /// 删除笔记
    /// - Parameter note: 要删除的笔记对象
    func deleteNote(_ note: BalletSessionNote) {
        // 更新关联课程的 updatedAt
        note.session?.updatedAt = Date()
        
        context.delete(note)
        save()
    }
    
    /// 删除课程的所有笔记
    /// - Parameter session: 课程对象
    func deleteAllNotes(for session: BalletSession) {
        let notes = fetchNotes(for: session)
        notes.forEach { context.delete($0) }
        
        session.updatedAt = Date()
        save()
    }
    
    /// 删除课程指定类型的所有笔记
    /// - Parameters:
    ///   - session: 课程对象
    ///   - type: 笔记类型
    func deleteNotes(for session: BalletSession, type: NoteType) {
        let notes = fetchNotes(for: session, type: type)
        notes.forEach { context.delete($0) }
        
        session.updatedAt = Date()
        save()
    }
    
    // MARK: - Reorder
    
    /// 重新排序笔记
    /// - Parameter notes: 按新顺序排列的笔记数组
    func reorderNotes(_ notes: [BalletSessionNote]) {
        for (index, note) in notes.enumerated() {
            note.order = Int16(index)
            note.updatedAt = Date()
        }
        
        // 更新关联课程的 updatedAt
        notes.first?.session?.updatedAt = Date()
        
        save()
    }
    
    // MARK: - Statistics
    
    /// 获取课程的笔记数量
    /// - Parameter session: 课程对象
    /// - Returns: 笔记数量
    func getNotesCount(for session: BalletSession) -> Int {
        let fetchRequest: NSFetchRequest<BalletSessionNote> = BalletSessionNote.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "session == %@", session)
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("❌ 获取笔记数量失败: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// 获取指定类型笔记的数量
    /// - Parameters:
    ///   - session: 课程对象
    ///   - type: 笔记类型
    /// - Returns: 笔记数量
    func getNotesCount(for session: BalletSession, type: NoteType) -> Int {
        let fetchRequest: NSFetchRequest<BalletSessionNote> = BalletSessionNote.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "session == %@ AND noteType == %@",
            session,
            type.rawValue
        )
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("❌ 获取笔记数量失败: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Private Helpers
    
    private func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("❌ 保存笔记失败: \(error.localizedDescription)")
        }
    }
}

