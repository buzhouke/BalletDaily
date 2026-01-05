//
//  HealthMetricsService.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  健康指标数据服务 - 管理 HealthMetrics 的存储
//

import Foundation
internal import CoreData
import HealthKit

/// 健康指标数据服务
/// 负责将 HealthKit 数据保存到 Core Data
class HealthMetricsService {
    
    // MARK: - Properties
    
    private let context: NSManagedObjectContext
    private let healthKitManager: HealthKitManager
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext, healthKitManager: HealthKitManager) {
        self.context = context
        self.healthKitManager = healthKitManager
    }
    
    // MARK: - Create & Update
    
    /// 为课程创建或更新健康指标数据
    /// - Parameters:
    ///   - session: 芭蕾课程
    ///   - workout: HealthKit 训练详情
    /// - Returns: 健康指标对象
    @discardableResult
    func createOrUpdateMetrics(
        for session: BalletSession,
        from workout: WorkoutDetails
    ) async -> HealthMetrics? {
        // 如果已有指标，先删除旧数据
        if let existingMetrics = session.healthMetrics {
            context.delete(existingMetrics)
        }
        
        // 创建新的健康指标
        let metrics = HealthMetrics(context: context)
        metrics.id = UUID()
        metrics.syncedAt = Date()
        metrics.session = session
        
        // 获取基础数据（使用 ?? 0 处理可选值）
        metrics.activeEnergy = workout.totalEnergyBurned ?? 0
        
        // 异步获取心率数据
        do {
            let heartRateStats = try await healthKitManager.fetchHeartRateStats(for: workout)
            metrics.avgHeartRate = heartRateStats.average ?? 0
            metrics.minHeartRate = heartRateStats.min ?? 0
            metrics.maxHeartRate = heartRateStats.max ?? 0
            
            // 获取心率时间序列数据用于绘图
            let heartRateSamples = try await healthKitManager.fetchHeartRateSamples(
                from: workout.startDate,
                to: workout.endDate
            )
            
            // 将心率样本序列化为 JSON 存储
            if !heartRateSamples.isEmpty {
                metrics.heartRateData = encodeHeartRateSamples(heartRateSamples)
            }
            
        } catch {
            print("⚠️ 获取心率数据失败: \(error.localizedDescription)")
        }
        
        // 保存
        save()
        
        return metrics
    }
    
    /// 从 HealthKit Workout 导入健康数据到课程
    /// - Parameters:
    ///   - session: 芭蕾课程
    ///   - workoutUUID: HealthKit 训练记录的 UUID
    @discardableResult
    func importHealthData(for session: BalletSession, workoutUUID: UUID) async -> HealthMetrics? {
        // 查找对应的 workout
        do {
            let workouts = try await healthKitManager.fetchRecentWorkouts(limit: 100)
            guard let workout = workouts.first(where: { $0.id == workoutUUID }) else {
                print("❌ 未找到对应的训练记录")
                return nil
            }
            
            // 关联 HealthKit UUID
            session.healthKitWorkoutUUID = workoutUUID.uuidString
            session.updatedAt = Date()
            
            // 创建健康指标
            return await createOrUpdateMetrics(for: session, from: workout)
            
        } catch {
            print("❌ 导入健康数据失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Read
    
    /// 获取课程的健康指标
    /// - Parameter session: 芭蕾课程
    /// - Returns: 健康指标对象，如果不存在则返回 nil
    func fetchMetrics(for session: BalletSession) -> HealthMetrics? {
        return session.healthMetrics
    }
    
    /// 解码心率时间序列数据
    /// - Parameter metrics: 健康指标对象
    /// - Returns: 心率样本数组
    func decodeHeartRateSamples(from metrics: HealthMetrics) -> [HeartRateSample]? {
        guard let data = metrics.heartRateData else { return nil }
        
        do {
            return try JSONDecoder().decode([HeartRateSample].self, from: data)
        } catch {
            print("❌ 解码心率数据失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Delete
    
    /// 删除健康指标
    /// - Parameter metrics: 要删除的健康指标对象
    func deleteMetrics(_ metrics: HealthMetrics) {
        context.delete(metrics)
        save()
    }
    
    // MARK: - Sync
    
    /// 同步课程的健康数据（从 HealthKit 重新获取）
    /// - Parameter session: 芭蕾课程
    func syncHealthData(for session: BalletSession) async -> Bool {
        guard let uuidString = session.healthKitWorkoutUUID,
              let workoutUUID = UUID(uuidString: uuidString) else {
            print("⚠️ 课程未关联 HealthKit 训练记录")
            return false
        }
        
        let result = await importHealthData(for: session, workoutUUID: workoutUUID)
        return result != nil
    }
    
    // MARK: - Batch Operations
    
    /// 批量同步多个课程的健康数据
    /// - Parameter sessions: 芭蕾课程数组
    /// - Returns: 成功同步的数量
    func batchSyncHealthData(for sessions: [BalletSession]) async -> Int {
        var successCount = 0
        
        for session in sessions {
            if await syncHealthData(for: session) {
                successCount += 1
            }
        }
        
        return successCount
    }
    
    // MARK: - Private Helpers
    
    /// 保存上下文
    private func save() {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch {
            print("❌ 保存健康数据失败: \(error.localizedDescription)")
        }
    }
    
    /// 将心率样本编码为 JSON 数据
    private func encodeHeartRateSamples(_ samples: [HeartRateSample]) -> Data? {
        do {
            return try JSONEncoder().encode(samples)
        } catch {
            print("❌ 编码心率数据失败: \(error.localizedDescription)")
            return nil
        }
    }
}
