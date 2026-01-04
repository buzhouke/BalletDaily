//
//  HealthKitManager.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  HealthKit 集成服务 - Phase 2
//

import Foundation
import HealthKit
import Combine

/// HealthKit 管理器
/// 负责请求权限、查询训练记录和健康数据
class HealthKitManager: ObservableObject {
    
    // MARK: - Properties
    
    /// HealthKit 数据存储
    private let healthStore = HKHealthStore()
    
    /// 是否已授权
    @Published var isAuthorized = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    // MARK: - Initialization
    
    init() {
        checkHealthKitAvailability()
        // 延迟检查授权状态，确保应用完全启动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// 检查 HealthKit 是否可用
    func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            errorMessage = "HealthKit 在此设备上不可用"
            return
        }
        print("✅ HealthKit 可用")
    }
    
    /// 检查授权状态
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = false
            }
            return
        }
        
        // 检查 workout 类型的授权状态
        // 注意：对于 workout 类型，authorizationStatus 会返回 .notDetermined
        // 即使用户已经授权。我们需要实际查询一次数据来确认
        let workoutType = HKObjectType.workoutType()
        let status = healthStore.authorizationStatus(for: workoutType)
        
        print("🔍 HealthKit 授权状态检查: \(status.rawValue)")
        
        // 对于 workout 类型，如果不是明确拒绝，我们尝试查询来确认授权
        if status == .sharingDenied {
            DispatchQueue.main.async { [weak self] in
                self?.isAuthorized = false
                print("❌ HealthKit 明确拒绝授权")
            }
            return
        }
        
        // 尝试查询一条数据来确认授权状态
        // 这是唯一可靠的方法来检测读取权限
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    // 检查错误类型
                    if error.code == HKError.errorAuthorizationNotDetermined.rawValue {
                        self?.isAuthorized = false
                        print("ℹ️ HealthKit 未授权 (需要请求权限)")
                    } else if error.code == HKError.errorAuthorizationDenied.rawValue {
                        self?.isAuthorized = false
                        print("❌ HealthKit 授权被拒绝")
                    } else {
                        // 其他错误，可能是网络或其他问题，但不一定是授权问题
                        // 暂时假设未授权，但不记录为错误
                        self?.isAuthorized = false
                        print("⚠️ HealthKit 查询失败: \(error.localizedDescription)")
                    }
                } else {
                    // 查询成功（无论是否有数据），说明已授权
                    self?.isAuthorized = true
                    print("✅ HealthKit 已授权 (查询成功，找到 \(samples?.count ?? 0) 条记录)")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    /// 请求 HealthKit 授权
    func requestAuthorization() {
        print("🔐 开始请求 HealthKit 授权...")
        
        // 定义需要读取的数据类型
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),                                    // 训练记录
            HKObjectType.quantityType(forIdentifier: .heartRate)!,        // 心率
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, // 活动能量
            HKObjectType.quantityType(forIdentifier: .stepCount)!,        // 步数
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)! // 距离
        ]
        
        // 请求授权
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            print("📋 HealthKit 授权对话框返回: success=\(success), error=\(String(describing: error))")
            
            if let error = error {
                DispatchQueue.main.async {
                    self?.isAuthorized = false
                    self?.errorMessage = error.localizedDescription
                    print("❌ HealthKit 授权请求失败: \(error.localizedDescription)")
                }
            } else {
                // 注意：success=true 只表示对话框显示成功，不代表用户授权了
                // 需要延迟一点时间再检查，让系统有时间处理用户的选择
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("🔄 授权对话框关闭，重新检查授权状态...")
                    self?.checkAuthorizationStatus()
                    self?.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Workout Queries
    
    /// 查询最近的训练记录
    /// - Parameter limit: 返回的最大数量（默认 100，设置为 HKObjectQueryNoLimit 可查询所有）
    /// - Returns: 训练记录数组
    func fetchRecentWorkouts(limit: Int = 100) async throws -> [WorkoutDetails] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: nil,
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = (samples as? [HKWorkout] ?? []).map { WorkoutDetails(from: $0) }
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 按日期范围查询训练记录
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    ///   - activityType: 活动类型过滤（可选，nil 表示所有类型）
    /// - Returns: 训练记录数组
    func fetchWorkouts(
        from startDate: Date,
        to endDate: Date,
        activityType: HKWorkoutActivityType? = nil
    ) async throws -> [WorkoutDetails] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        
        // 构建日期范围谓词
        var predicates: [NSPredicate] = [
            HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        ]
        
        // 如果指定了活动类型，添加类型过滤
        if let activityType = activityType {
            predicates.append(HKQuery.predicateForWorkouts(with: activityType))
        }
        
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let workouts = (samples as? [HKWorkout] ?? []).map { WorkoutDetails(from: $0) }
                continuation.resume(returning: workouts)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 查询舞蹈类型的训练记录（芭蕾课程）
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 舞蹈训练记录数组
    ///
    /// 支持的训练类型：
    /// - 芭蕾/芭杆训练（Barre）⭐ 主要类型
    /// - 舞蹈（Dance）⭐ 主要类型
    /// - 柔韧性训练（Flexibility）
    /// - 核心训练（Core Training）
    /// - 功能性力量训练（Functional Strength）
    func fetchDanceWorkouts(from startDate: Date, to endDate: Date) async throws -> [WorkoutDetails] {
        // 查询所有与芭蕾相关的训练类型
        // 注：只包含核心相关类型，避免导入过多不相关的训练
        let balletActivityTypes: [HKWorkoutActivityType] = [
            .barre,             // ⭐ 芭蕾/芭杆训练（主要类型）
            .socialDance,       // ⭐ 社交舞蹈（替代弃用的 .dance）
            .cardioDance,       // ⭐ 有氧舞蹈
            .flexibility,       // 柔韧性训练（芭蕾常用）
            .coreTraining,      // 核心训练（芭蕾辅助训练）
            .functionalStrengthTraining  // 功能性力量训练（芭蕾辅助训练）
        ]
        
        // 查询所有训练
        let allWorkouts = try await fetchWorkouts(from: startDate, to: endDate)
        
        // 过滤出芭蕾相关的训练类型
        let balletWorkouts = allWorkouts.filter { workout in
            balletActivityTypes.contains(workout.activityType)
        }
        
        return balletWorkouts
    }
    
    // MARK: - Heart Rate Queries
    
    /// 获取训练期间的心率统计数据
    /// - Parameter workout: 训练记录
    /// - Returns: 心率统计数据
    func fetchHeartRateStats(for workout: WorkoutDetails) async throws -> HeartRateStats {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: workout.startDate,
            end: workout.endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage, .discreteMin, .discreteMax]
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                
                let stats = HeartRateStats(
                    average: statistics?.averageQuantity()?.doubleValue(for: heartRateUnit),
                    min: statistics?.minimumQuantity()?.doubleValue(for: heartRateUnit),
                    max: statistics?.maximumQuantity()?.doubleValue(for: heartRateUnit)
                )
                
                continuation.resume(returning: stats)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// 获取训练期间的心率时间序列数据（用于绘图）
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 心率样本数组
    func fetchHeartRateSamples(from startDate: Date, to endDate: Date) async throws -> [HeartRateSample] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                let heartRateSamples = (samples as? [HKQuantitySample] ?? []).map { sample in
                    HeartRateSample(
                        date: sample.startDate,
                        value: sample.quantity.doubleValue(for: heartRateUnit)
                    )
                }
                
                continuation.resume(returning: heartRateSamples)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Other Metrics
    
    /// 获取活动能量消耗
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 消耗的卡路里（千卡）
    func fetchActiveEnergy(from startDate: Date, to endDate: Date) async throws -> Double? {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.invalidType
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let energyUnit = HKUnit.kilocalorie()
                let energy = statistics?.sumQuantity()?.doubleValue(for: energyUnit)
                continuation.resume(returning: energy)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Legacy Test Method
    
    /// 测试读取最近的训练记录（旧版同步方法，保留用于测试）
    func testFetchWorkouts() {
        guard isAuthorized else {
            print("⚠️  请先授权 HealthKit")
            return
        }
        
        Task {
            do {
                // 移除限制，查询所有最近的训练记录
                let workouts = try await fetchRecentWorkouts(limit: 100)
                print("✅ 找到 \(workouts.count) 条训练记录")
                for workout in workouts {
                    print("  - \(workout.activityType.name): \(String(format: "%.1f", workout.duration / 60)) 分钟")
                    // 显示能量消耗（如果有）
                    if let energy = workout.totalEnergyBurned {
                        print("    消耗: \(String(format: "%.0f", energy)) 千卡")
                    }
                }
            } catch {
                print("❌ 查询训练记录失败: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Data Models

/// 训练详情
struct WorkoutDetails {
    let id: UUID
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval
    let activityType: HKWorkoutActivityType
    let totalEnergyBurned: Double?      // 千卡
    let totalDistance: Double?          // 米
    
    /// 从 HKWorkout 创建
    init(from workout: HKWorkout) {
        self.id = workout.uuid
        self.startDate = workout.startDate
        self.endDate = workout.endDate
        self.duration = workout.duration
        self.activityType = workout.workoutActivityType
        
        // 使用新的 API 获取能量消耗
        if let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
           let energy = workout.statistics(for: energyType)?.sumQuantity() {
            self.totalEnergyBurned = energy.doubleValue(for: .kilocalorie())
        } else {
            self.totalEnergyBurned = nil
        }
        
        // 转换距离单位为米
        if let distance = workout.totalDistance {
            self.totalDistance = distance.doubleValue(for: .meter())
        } else {
            self.totalDistance = nil
        }
    }
    
    /// 是否为芭蕾课程（舞蹈类型）
    var isBalletSession: Bool {
        return activityType == .socialDance || activityType == .cardioDance
    }
}

/// 心率统计数据
struct HeartRateStats {
    let average: Double?    // 平均心率 (bpm)
    let min: Double?        // 最低心率 (bpm)
    let max: Double?        // 最高心率 (bpm)
}

/// 心率样本（时间序列数据）
struct HeartRateSample: Codable {
    let date: Date
    let value: Double       // 心率值 (bpm)
}

/// HealthKit 错误类型
enum HealthKitError: LocalizedError {
    case notAuthorized
    case invalidType
    case noData
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "HealthKit 未授权，请先授权访问健康数据"
        case .invalidType:
            return "无效的健康数据类型"
        case .noData:
            return "未找到相关数据"
        }
    }
}

// MARK: - Extensions

extension HKWorkoutActivityType {
    /// 活动类型的中文名称
    var name: String {
        switch self {
        case .socialDance:
            return "社交舞"
        case .cardioDance:
            return "有氧舞蹈"
        case .barre:
            return "芭蕾"
        case .traditionalStrengthTraining:
            return "力量训练"
        case .functionalStrengthTraining:
            return "功能性训练"
        case .yoga:
            return "瑜伽"
        case .pilates:
            return "普拉提"
        case .walking:
            return "步行"
        case .running:
            return "跑步"
        case .cycling:
            return "骑行"
        case .swimming:
            return "游泳"
        case .flexibility:
            return "柔韧性训练"
        case .coreTraining:
            return "核心训练"
        case .crossTraining:
            return "交叉训练"
        default:
            return "其他运动"
        }
    }
    
    /// 是否为芭蕾相关的活动类型
    var isBalletRelated: Bool {
        switch self {
        case .socialDance, .cardioDance, .barre, .flexibility, .coreTraining:
            return true
        default:
            return false
        }
    }
}
