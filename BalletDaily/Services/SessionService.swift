//
//  SessionService.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  课程数据服务 - 处理芭蕾课程的增删改查
//

import Foundation
internal import CoreData

/// 课程数据服务
/// 负责 BalletSession 的所有数据操作
class SessionService {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    // 便捷初始化 - 使用共享的持久化控制器
    convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }
    
    // MARK: - Create
    
    /// 创建新的课程记录
    /// - Parameters:
    ///   - date: 课程日期时间
    ///   - duration: 课程时长（秒）
    ///   - isManual: 是否手动创建
    ///   - name: 课程名称（可选）
    ///   - instructor: 老师姓名（可选）
    ///   - location: 上课地点（可选）
    /// - Returns: 创建的课程对象
    @discardableResult
    func createSession(
        date: Date,
        duration: TimeInterval,
        isManual: Bool = true,
        name: String? = nil,
        instructor: String? = nil,
        location: String? = nil
    ) -> BalletSession {
        let session = BalletSession(context: context)
        session.id = UUID()
        session.createdAt = Date()
        session.updatedAt = Date()
        session.sessionDate = date
        session.duration = duration
        session.isManualEntry = isManual
        session.name = name
        session.instructor = instructor
        session.location = location
        
        save()
        
        return session
    }
    
    // MARK: - Read
    
    /// 获取所有课程记录
    /// - Parameter sortByDateDescending: 是否按日期降序排列（默认 true，最新的在前）
    /// - Returns: 课程数组
    func fetchAllSessions(sortByDateDescending: Bool = true) -> [BalletSession] {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: !sortByDateDescending)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 获取课程列表失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 按 ID 获取课程
    /// - Parameter id: 课程 UUID
    /// - Returns: 课程对象，如果不存在则返回 nil
    func fetchSession(by id: UUID) -> BalletSession? {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("❌ 获取课程失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 按日期范围获取课程
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 课程数组
    func fetchSessions(from startDate: Date, to endDate: Date) -> [BalletSession] {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "sessionDate >= %@ AND sessionDate <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: false)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 按日期范围获取课程失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 按老师筛选课程
    /// - Parameter instructor: 老师姓名
    /// - Returns: 课程数组
    func fetchSessions(byInstructor instructor: String) -> [BalletSession] {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "instructor == %@", instructor)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: false)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 按老师筛选课程失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 按课程名称筛选
    /// - Parameter name: 课程名称
    /// - Returns: 课程数组
    func fetchSessions(byName name: String) -> [BalletSession] {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: false)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 按课程名筛选失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 搜索课程（支持课程名和老师的模糊匹配）
    /// - Parameter searchText: 搜索关键词
    /// - Returns: 课程数组
    func searchSessions(keyword: String) -> [BalletSession] {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "name CONTAINS[cd] %@ OR instructor CONTAINS[cd] %@",
            keyword,
            keyword
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: false)
        ]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 搜索课程失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取最近 N 条课程记录
    /// - Parameter limit: 数量限制
    /// - Returns: 课程数组
    func fetchRecentSessions(limit: Int = 10) -> [BalletSession] {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(keyPath: \BalletSession.sessionDate, ascending: false)
        ]
        fetchRequest.fetchLimit = limit
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("❌ 获取最近课程失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Update
    
    /// 更新课程信息
    /// - Parameters:
    ///   - session: 要更新的课程对象
    ///   - name: 课程名称（可选）
    ///   - instructor: 老师姓名（可选）
    ///   - location: 地点（可选）
    func updateSession(
        _ session: BalletSession,
        name: String? = nil,
        instructor: String? = nil,
        location: String? = nil
    ) {
        if let name = name {
            session.name = name
        }
        if let instructor = instructor {
            session.instructor = instructor
        }
        if let location = location {
            session.location = location
        }
        
        session.updatedAt = Date()
        save()
    }
    
    /// 更新课程的日期和时长
    /// - Parameters:
    ///   - session: 要更新的课程对象
    ///   - date: 新的课程日期
    ///   - duration: 新的课程时长
    func updateSession(
        _ session: BalletSession,
        date: Date? = nil,
        duration: TimeInterval? = nil
    ) {
        if let date = date {
            session.sessionDate = date
        }
        if let duration = duration {
            session.duration = duration
        }
        
        session.updatedAt = Date()
        save()
    }
    
    // MARK: - Delete
    
    /// 删除课程
    /// - Parameter session: 要删除的课程对象
    func deleteSession(_ session: BalletSession) {
        context.delete(session)
        save()
    }
    
    /// 批量删除课程
    /// - Parameter sessions: 要删除的课程数组
    func deleteSessions(_ sessions: [BalletSession]) {
        sessions.forEach { context.delete($0) }
        save()
    }
    
    /// 删除指定日期范围内的所有课程
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    func deleteSessions(from startDate: Date, to endDate: Date) {
        let sessions = fetchSessions(from: startDate, to: endDate)
        deleteSessions(sessions)
    }
    
    // MARK: - Statistics
    
    /// 获取课程总数
    /// - Returns: 课程数量
    func getTotalSessionsCount() -> Int {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        
        do {
            return try context.count(for: fetchRequest)
        } catch {
            print("❌ 获取课程总数失败: \(error.localizedDescription)")
            return 0
        }
    }
    
    /// 获取指定日期范围内的课程总时长
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 总时长（秒）
    func getTotalDuration(from startDate: Date, to endDate: Date) -> TimeInterval {
        let sessions = fetchSessions(from: startDate, to: endDate)
        return sessions.reduce(0) { $0 + $1.duration }
    }
    
    /// 获取所有不同的老师列表
    /// - Returns: 老师姓名数组（去重）
    func getAllInstructors() -> [String] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BalletSession")
        fetchRequest.propertiesToFetch = ["instructor"]
        fetchRequest.returnsDistinctResults = true
        fetchRequest.resultType = .dictionaryResultType
        
        do {
            let results = try context.fetch(fetchRequest) as? [[String: Any]]
            return results?.compactMap { $0["instructor"] as? String }.filter { !$0.isEmpty } ?? []
        } catch {
            print("❌ 获取老师列表失败: \(error.localizedDescription)")
            return []
        }
    }
    
    /// 获取所有不同的课程名称列表
    /// - Returns: 课程名称数组（去重）
    func getAllClassNames() -> [String] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "BalletSession")
        fetchRequest.propertiesToFetch = ["name"]
        fetchRequest.returnsDistinctResults = true
        fetchRequest.resultType = .dictionaryResultType
        
        do {
            let results = try context.fetch(fetchRequest) as? [[String: Any]]
            return results?.compactMap { $0["name"] as? String }.filter { !$0.isEmpty } ?? []
        } catch {
            print("❌ 获取课程名称列表失败: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Persistence Helpers

    /// 保存上下文并忽略错误（内部使用）
    private func save() {
        do {
            try saveContext()
        } catch {
            print("❌ 保存数据失败: \(error.localizedDescription)")
        }
    }

    /// 对外暴露的上下文保存接口，可捕获错误
    func saveContext() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}

