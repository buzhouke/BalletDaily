//
//  TagService.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  常用标签数据服务 - 记录用户常用的课程名、老师名、地点
//

import Foundation
internal import CoreData

/// 常用标签数据服务
/// 负责 FrequentTag 的所有数据操作
/// 用于实现智能输入提示，记录用户常用的选项
class TagService {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }
    
    // MARK: - Create / Update
    
    /// 记录标签使用（如果已存在则增加使用次数，否则创建新标签）
    /// - Parameters:
    ///   - type: 标签类型
    ///   - value: 标签值
    func recordTagUsage(type: TagType, value: String) {
        // 检查是否已存在
        if let existingTag = fetchTag(type: type, value: value) {
            // 已存在，增加使用次数
            existingTag.usageCount += 1
            existingTag.lastUsedAt = Date()
        } else {
            // 不存在，创建新标签
            let newTag = FrequentTag(context: context)
            newTag.id = UUID()
            newTag.tagType = type.rawValue
            newTag.value = value
            newTag.usageCount = 1
            newTag.lastUsedAt = Date()
        }
        
        save()
    }
    
    // MARK: - Read
    
    /// 获取指定类型的所有标签（按使用次数降序）
    /// - Parameter type: 标签类型
    /// - Returns: 标签数组
    func fetchTags(type: TagType) -> [FrequentTag] {
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tagType == %@", type.rawValue)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \FrequentTag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \FrequentTag.lastUsedAt, ascending: false)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 获取标签列表失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取指定类型的前 N 个常用标签
    /// - Parameters:
    ///   - type: 标签类型
    ///   - limit: 数量限制
    /// - Returns: 标签数组
    func fetchTopTags(type: TagType, limit: Int = 10) -> [FrequentTag] {
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tagType == %@", type.rawValue)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \FrequentTag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \FrequentTag.lastUsedAt, ascending: false)
        ]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 获取常用标签失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 搜索标签（模糊匹配）
    /// - Parameters:
    ///   - type: 标签类型
    ///   - keyword: 搜索关键词
    ///   - limit: 数量限制
    /// - Returns: 标签数组
    func searchTags(type: TagType, keyword: String, limit: Int = 10) -> [FrequentTag] {
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "tagType == %@ AND value CONTAINS[cd] %@",
            type.rawValue,
            keyword
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \FrequentTag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \FrequentTag.lastUsedAt, ascending: false)
        ]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 搜索标签失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取指定类型和值的标签
    /// - Parameters:
    ///   - type: 标签类型
    ///   - value: 标签值
    /// - Returns: 标签对象，如果不存在则返回 nil
    func fetchTag(type: TagType, value: String) -> FrequentTag? {
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "tagType == %@ AND value == %@",
            type.rawValue,
            value
        )
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("❌ 获取标签失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 获取指定类型的标签值列表（只返回值，不返回完整对象）
    /// - Parameters:
    ///   - type: 标签类型
    ///   - limit: 数量限制
    /// - Returns: 标签值数组
    func fetchTagValues(type: TagType, limit: Int = 10) -> [String] {
        let tags = fetchTopTags(type: type, limit: limit)
        return tags.map { $0.value ?? "" }.filter { !$0.isEmpty }
    }
    
    /// 获取标签建议（返回标签值的字符串数组）
    /// - Parameters:
    ///   - typeString: 标签类型字符串
    ///   - limit: 数量限制
    /// - Returns: 标签值数组
    func getSuggestions(for typeString: String, limit: Int = 10) -> [String] {
        guard let type = TagType(rawValue: typeString) else {
            return []
        }
        return fetchTagValues(type: type, limit: limit)
    }
    
    /// 搜索标签（返回标签值的字符串数组）
    /// - Parameters:
    ///   - typeString: 标签类型字符串
    ///   - query: 搜索关键词
    ///   - limit: 数量限制
    /// - Returns: 标签值数组
    func searchTags(type typeString: String, query: String, limit: Int = 10) -> [String] {
        guard let type = TagType(rawValue: typeString) else {
            return []
        }
        let tags = searchTags(type: type, keyword: query, limit: limit)
        return tags.map { $0.value ?? "" }.filter { !$0.isEmpty }
    }
    
    /// 记录标签（便捷方法，接受字符串类型）
    /// - Parameters:
    ///   - typeString: 标签类型字符串
    ///   - value: 标签值
    func recordTag(type typeString: String, value: String) {
        guard let type = TagType(rawValue: typeString) else {
            return
        }
        recordTagUsage(type: type, value: value)
    }
    
    // MARK: - Delete
    
    /// 删除标签
    /// - Parameter tag: 要删除的标签对象
    func deleteTag(_ tag: FrequentTag) {
        context.delete(tag)
        save()
    }
    
    /// 删除指定类型的所有标签
    /// - Parameter type: 标签类型
    func deleteAllTags(type: TagType) {
        let tags = fetchTags(type: type)
        tags.forEach { context.delete($0) }
        save()
    }
    
    /// 删除使用次数低于阈值的标签（清理不常用的标签）
    /// - Parameters:
    ///   - type: 标签类型（可选，如果为 nil 则清理所有类型）
    ///   - threshold: 使用次数阈值
    func deleteInfrequentTags(type: TagType? = nil, threshold: Int32 = 2) {
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        
        if let type = type {
            fetchRequest.predicate = NSPredicate(
                format: "tagType == %@ AND usageCount < %d",
                type.rawValue,
                threshold
            )
        } else {
            fetchRequest.predicate = NSPredicate(format: "usageCount < %d", threshold)
        }
        
        do {
            let tags = try context.fetch(fetchRequest)
            tags.forEach { context.delete($0) }
            save()
            print("✅ 已清理 \(tags.count) 个不常用标签")
        } catch {
            print("❌ 清理不常用标签失败: \(error.localizedDescription)")
        }
    }
    
    /// 删除长期未使用的标签
    /// - Parameters:
    ///   - type: 标签类型（可选）
    ///   - days: 天数阈值（默认 90 天）
    func deleteOldTags(type: TagType? = nil, days: Int = 90) {
        let thresholdDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        
        if let type = type {
            fetchRequest.predicate = NSPredicate(
                format: "tagType == %@ AND lastUsedAt < %@",
                type.rawValue,
                thresholdDate as NSDate
            )
        } else {
            fetchRequest.predicate = NSPredicate(
                format: "lastUsedAt < %@",
                thresholdDate as NSDate
            )
        }
        
        do {
            let tags = try context.fetch(fetchRequest)
            tags.forEach { context.delete($0) }
            save()
            print("✅ 已清理 \(tags.count) 个长期未使用的标签")
        } catch {
            print("❌ 清理长期未使用标签失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Statistics
    
    /// 获取指定类型的标签总数
    /// - Parameter type: 标签类型
    /// - Returns: 标签数量
    func getTagsCount(type: TagType) -> Int {
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "tagType == %@", type.rawValue)
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("❌ 获取标签数量失败: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// 获取所有标签的总数
    /// - Returns: 标签总数
    func getTotalTagsCount() -> Int {
        let fetchRequest: NSFetchRequest<FrequentTag> = FrequentTag.fetchRequest()
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("❌ 获取标签总数失败: \(error.localizedDescription)")
            return 0
        }
    }
    
    // MARK: - Private Helpers
    
    private func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("❌ 保存标签失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - Convenience Extension

extension TagService {
    
    /// 记录课程信息为常用标签
    /// - Parameter session: 课程对象
    func recordSession(_ session: BalletSession) {
        // 记录课程名称
        if let name = session.name, !name.isEmpty {
            recordTagUsage(type: .className, value: name)
        }
        
        // 记录老师姓名
        if let instructor = session.instructor, !instructor.isEmpty {
            recordTagUsage(type: .instructor, value: instructor)
        }
        
        // 记录上课地点
        if let location = session.location, !location.isEmpty {
            recordTagUsage(type: .location, value: location)
        }
    }
}

