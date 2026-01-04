import Foundation
import SwiftUI
internal import CoreData
import Combine

/// 课程列表视图模型
@MainActor
class SessionListViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var sessions: [BalletSession] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedInstructor: String?
    @Published var selectedClassName: String?
    @Published var dateFilter: DateFilter = .all
    
    // MARK: - Dependencies
    
    private let sessionService: SessionService
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 过滤后的课程列表
    var filteredSessions: [BalletSession] {
        var result = sessions
        
        // 搜索文本过滤
        if !searchText.isEmpty {
            result = result.filter { session in
                let classNameMatch = session.name?.localizedCaseInsensitiveContains(searchText) ?? false
                let instructorMatch = session.instructor?.localizedCaseInsensitiveContains(searchText) ?? false
                return classNameMatch || instructorMatch
            }
        }
        
        // 老师过滤
        if let instructor = selectedInstructor {
            result = result.filter { $0.instructor == instructor }
        }
        
        // 课程名称过滤
        if let className = selectedClassName {
            result = result.filter { $0.name == className }
        }
        
        // 日期过滤
        if dateFilter != .all {
            let startDate = dateFilter.startDate
            result = result.filter { $0.sessionDate ?? Date() >= startDate }
        }
        
        return result
    }
    
    /// 所有唯一的老师名称（缓存）
    private var _cachedInstructors: [String]?
    var allInstructors: [String] {
        if let cached = _cachedInstructors {
            return cached
        }
        let instructors = sessions.compactMap { $0.instructor }
        let sorted = Array(Set(instructors)).sorted()
        _cachedInstructors = sorted
        return sorted
    }
    
    /// 所有唯一的课程名称（缓存）
    private var _cachedClassNames: [String]?
    var allClassNames: [String] {
        if let cached = _cachedClassNames {
            return cached
        }
        let classNames = sessions.compactMap { $0.name }
        let sorted = Array(Set(classNames)).sorted()
        _cachedClassNames = sorted
        return sorted
    }
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.sessionService = SessionService(context: context)
        
        // 监听 Core Data 的对象变化通知
        setupNotificationObserver()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Notification Observer
    
    /// 设置 Core Data 通知监听
    private func setupNotificationObserver() {
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self = self else { return }
                
                // 检查是否有 BalletSession 相关的变化
                let hasRelevantChanges = self.hasRelevantChanges(in: notification)
                
                if hasRelevantChanges {
                    print("🔄 检测到课程数据变化，自动刷新列表")
                    self.loadSessions()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 检查通知中是否包含相关的数据变化
    private func hasRelevantChanges(in notification: Notification) -> Bool {
        let insertedObjects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
        let updatedObjects = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []
        let deletedObjects = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []
        
        let allChangedObjects = insertedObjects.union(updatedObjects).union(deletedObjects)
        
        // 检查是否有 BalletSession 类型的对象变化
        return allChangedObjects.contains { $0 is BalletSession }
    }
    
    // MARK: - Data Loading
    
    /// 加载所有课程
    func loadSessions() {
        isLoading = true
        errorMessage = nil
        
        // 清除缓存
        _cachedInstructors = nil
        _cachedClassNames = nil
        
        do {
            sessions = try sessionService.fetchAllSessions()
            print("✅ 成功加载 \(sessions.count) 个课程")
        } catch {
            errorMessage = "加载课程失败：\(error.localizedDescription)"
            print("❌ 加载课程失败: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// 刷新数据
    func refresh() async {
        loadSessions()
    }
    
    // MARK: - Session Operations
    
    /// 删除课程
    func deleteSession(_ session: BalletSession) {
        do {
            try sessionService.deleteSession(session)
            loadSessions() // 重新加载
        } catch {
            errorMessage = "删除课程失败：\(error.localizedDescription)"
            print("❌ Failed to delete session: \(error)")
        }
    }
    
    /// 删除多个课程
    func deleteSessions(at offsets: IndexSet) {
        let sessionsToDelete = offsets.map { filteredSessions[$0] }
        
        for session in sessionsToDelete {
            deleteSession(session)
        }
    }
    
    // MARK: - Filter Management
    
    /// 清除所有过滤条件
    func clearFilters() {
        searchText = ""
        selectedInstructor = nil
        selectedClassName = nil
        dateFilter = .all
    }
    
    /// 检查是否有激活的过滤条件
    var hasActiveFilters: Bool {
        !searchText.isEmpty || selectedInstructor != nil || selectedClassName != nil || dateFilter != .all
    }
}

// MARK: - Date Filter

extension SessionListViewModel {
    enum DateFilter: String, CaseIterable, Identifiable {
        case all = "全部"
        case today = "今天"
        case week = "本周"
        case month = "本月"
        case year = "本年"
        
        var id: String { rawValue }
        
        var startDate: Date {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .all:
                return Date.distantPast
            case .today:
                return calendar.startOfDay(for: now)
            case .week:
                return calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            case .month:
                return calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
            case .year:
                return calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
            }
        }
    }
}

