import Foundation
import SwiftUI
internal import CoreData
import Combine
import Charts

/// 课程详情视图模型
@MainActor
class SessionDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var session: BalletSession
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingDeleteConfirmation = false
    
    // MARK: - Dependencies
    
    private let sessionService: SessionService
    private let healthMetricsService: HealthMetricsService
    private let context: NSManagedObjectContext
    
    // MARK: - Computed Properties
    
    /// 课程名称显示
    var displayName: String {
        session.name ?? "未命名课程"
    }
    
    /// 老师显示
    var instructorDisplay: String {
        session.instructor ?? "未指定"
    }
    
    /// 地点显示
    var locationDisplay: String {
        session.location ?? "未指定"
    }
    
    /// 日期显示
    var dateDisplay: String {
        DateHelper.formatSessionDate(session.sessionDate ?? Date())
    }
    
    /// 时长显示
    var durationDisplay: String {
        DateHelper.formatDuration(session.duration)
    }
    
    /// 时间范围显示（如果有开始和结束时间）
    var timeRangeDisplay: String? {
        guard let sessionDate = session.sessionDate else { return nil }
        let endDate = sessionDate.addingTimeInterval(session.duration)
        return DateHelper.formatTimeRange(start: sessionDate, end: endDate)
    }
    
    /// 是否有健康数据
    var hasHealthMetrics: Bool {
        session.healthMetrics != nil
    }
    
    /// 健康数据
    var healthMetrics: HealthMetrics? {
        session.healthMetrics
    }
    
    /// 心率数据点
    var heartRateData: [HeartRateDataPoint] {
        guard let metrics = session.healthMetrics,
              let data = metrics.heartRateData,
              let sessionDate = session.sessionDate else {
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            let samples = try decoder.decode([HeartRateSample].self, from: data)
            
            // 限制数据点数量（最多300个点，用于图表性能）
            let maxPoints = 300
            let stride = max(1, samples.count / maxPoints)
            
            return samples.enumerated()
                .filter { $0.offset % stride == 0 }
                .map { _, sample in
                    HeartRateDataPoint(
                        time: sample.date.timeIntervalSince(sessionDate),
                        heartRate: sample.value
                    )
                }
        } catch {
            print("❌ Failed to decode heart rate data: \(error)")
            return []
        }
    }
    
    /// 笔记数量
    var notesCount: Int {
        session.notesArray.count
    }
    
    /// 最近的笔记预览（最多3条）
    var recentNotes: [BalletSessionNote] {
        Array(session.notesArray.prefix(3))
    }
    
    // MARK: - Initialization
    
    init(session: BalletSession, context: NSManagedObjectContext) {
        self.session = session
        self.context = context
        self.sessionService = SessionService(context: context)
        self.healthMetricsService = HealthMetricsService(context: context, healthKitManager: HealthKitManager())
    }
    
    // MARK: - Actions
    
    /// 重新加载数据
    func loadData() {
        // 刷新课程对象，确保笔记等关系数据是最新的
        context.refresh(session, mergeChanges: true)
        objectWillChange.send()
    }
    
    /// 删除课程
    func deleteSession() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try sessionService.deleteSession(session)
            isLoading = false
            return true
        } catch {
            errorMessage = "删除课程失败：\(error.localizedDescription)"
            print("❌ Failed to delete session: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// 同步健康数据
    func syncHealthMetrics() async {
        guard let workoutUUID = session.healthKitWorkoutUUID else {
            errorMessage = "这是手动创建的课程，没有关联的 HealthKit 数据"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // TODO: 实现从 HealthKit 重新同步数据
        // 这需要 HealthKitManager 和 WorkoutImportService
        
        isLoading = false
    }
}

// MARK: - Heart Rate Data Point

struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let time: TimeInterval  // 相对于课程开始的秒数
    let heartRate: Double
    
    var timeDisplay: String {
        let minutes = Int(time / 60)
        return "\(minutes)分钟"
    }
}

// MARK: - BalletSession Extension

extension BalletSession {
    /// 获取排序后的笔记数组
    var notesArray: [BalletSessionNote] {
        let set = notes as? Set<BalletSessionNote> ?? []
        return set.sorted { $0.order < $1.order }
    }
}

