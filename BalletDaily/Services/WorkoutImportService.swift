//
//  WorkoutImportService.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  训练记录导入服务 - 自动识别和导入芭蕾课程
//

import Foundation
internal import CoreData
import HealthKit

/// 训练记录导入服务
/// 负责从 HealthKit 自动识别并导入芭蕾课程
class WorkoutImportService {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private let healthKitManager: HealthKitManager
    private let sessionService: SessionService
    private let healthMetricsService: HealthMetricsService
    
    // MARK: - Initialization
    
    init(
        context: NSManagedObjectContext,
        healthKitManager: HealthKitManager
    ) {
        self.context = context
        self.healthKitManager = healthKitManager
        self.sessionService = SessionService(context: context)
        self.healthMetricsService = HealthMetricsService(
            context: context,
            healthKitManager: healthKitManager
        )
    }
    
    // MARK: - Import Methods
    
    /// 扫描并导入新的芭蕾课程
    /// - Parameters:
    ///   - days: 扫描最近多少天的数据（默认 30 天）
    ///   - autoImport: 是否自动导入（true）还是仅返回可导入列表（false）
    /// - Returns: 导入的课程数组
    func scanAndImportBalletWorkouts(
        days: Int = 30,
        autoImport: Bool = true
    ) async throws -> [ImportResult] {
        // 计算日期范围
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            throw ImportError.invalidDateRange
        }
        
        // 查询舞蹈类型的训练记录
        let workouts = try await healthKitManager.fetchDanceWorkouts(
            from: startDate,
            to: endDate
        )
        
        print("📊 找到 \(workouts.count) 条舞蹈训练记录")
        
        // 过滤出尚未导入的训练
        let newWorkouts = filterUnimportedWorkouts(workouts)
        print("🆕 其中 \(newWorkouts.count) 条尚未导入")
        
        if autoImport {
            // 自动导入
            return await importWorkouts(newWorkouts)
        } else {
            // 仅返回可导入列表
            return newWorkouts.map { ImportResult(workout: $0, session: nil, success: false) }
        }
    }
    
    /// 导入单个训练记录
    /// - Parameter workout: 训练详情
    /// - Returns: 导入结果
    @discardableResult
    func importWorkout(_ workout: WorkoutDetails) async -> ImportResult {
        // 检查是否已导入
        if isWorkoutImported(workout) {
            print("⚠️ 训练记录已存在，跳过导入")
            return ImportResult(workout: workout, session: nil, success: false)
        }
        
        // 创建课程记录
        let session = sessionService.createSession(
            date: workout.startDate,
            duration: workout.duration,
            isManual: false,
            name: "芭蕾课程", // 默认名称，用户可后续修改
            instructor: nil,
            location: nil
        )
        
        // 关联 HealthKit UUID
        session.healthKitWorkoutUUID = workout.id.uuidString
        
        // 导入健康数据
        let metrics = await healthMetricsService.createOrUpdateMetrics(
            for: session,
            from: workout
        )
        
        let success = metrics != nil
        
        if success {
            print("✅ 成功导入训练记录: \(workout.startDate)")
        } else {
            print("⚠️ 导入训练记录成功，但健康数据获取失败")
        }
        
        return ImportResult(workout: workout, session: session, success: success)
    }
    
    /// 批量导入训练记录
    /// - Parameter workouts: 训练详情数组
    /// - Returns: 导入结果数组
    func importWorkouts(_ workouts: [WorkoutDetails]) async -> [ImportResult] {
        var results: [ImportResult] = []
        
        for workout in workouts {
            let result = await importWorkout(workout)
            results.append(result)
        }
        
        let successCount = results.filter { $0.success }.count
        print("🎉 批量导入完成: 成功 \(successCount)/\(workouts.count)")
        
        return results
    }
    
    /// 重新同步已导入课程的健康数据
    /// - Parameter session: 芭蕾课程
    /// - Returns: 是否同步成功
    func resyncHealthData(for session: BalletSession) async -> Bool {
        guard session.healthKitWorkoutUUID != nil else {
            print("⚠️ 课程未关联 HealthKit 训练记录")
            return false
        }
        
        return await healthMetricsService.syncHealthData(for: session)
    }
    
    // MARK: - Query Methods
    
    /// 获取可导入的训练记录列表
    /// - Parameter days: 查询最近多少天的数据
    /// - Returns: 可导入的训练详情数组
    func getImportableWorkouts(days: Int = 30) async throws -> [WorkoutDetails] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            throw ImportError.invalidDateRange
        }
        
        let workouts = try await healthKitManager.fetchDanceWorkouts(
            from: startDate,
            to: endDate
        )
        
        return filterUnimportedWorkouts(workouts)
    }
    
    /// 检查训练记录是否已导入
    /// - Parameter workout: 训练详情
    /// - Returns: 是否已导入
    func isWorkoutImported(_ workout: WorkoutDetails) -> Bool {
        let fetchRequest: NSFetchRequest<BalletSession> = BalletSession.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "healthKitWorkoutUUID == %@",
            workout.id.uuidString
        )
        fetchRequest.fetchLimit = 1
        
        do {
            let count = try context.count(for: fetchRequest)
            return count > 0
        } catch {
            print("❌ 检查导入状态失败: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Private Helpers
    
    /// 过滤出尚未导入的训练记录
    private func filterUnimportedWorkouts(_ workouts: [WorkoutDetails]) -> [WorkoutDetails] {
        return workouts.filter { !isWorkoutImported($0) }
    }
}

// MARK: - Models

/// 导入结果
struct ImportResult {
    let workout: WorkoutDetails
    let session: BalletSession?
    let success: Bool
    
    var message: String {
        if success {
            return "✅ 成功导入"
        } else if session != nil {
            return "⚠️ 部分成功（健康数据获取失败）"
        } else {
            return "❌ 导入失败"
        }
    }
}

/// 导入错误
enum ImportError: LocalizedError {
    case invalidDateRange
    case workoutAlreadyImported
    case importFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDateRange:
            return "无效的日期范围"
        case .workoutAlreadyImported:
            return "训练记录已导入"
        case .importFailed(let reason):
            return "导入失败: \(reason)"
        }
    }
}

