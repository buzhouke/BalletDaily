//
//  TrendViewModel.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  Phase 6: 趋势分析 ViewModel
//

import Foundation
import SwiftUI
internal import CoreData
import Combine

/// 趋势分析 ViewModel
@MainActor
class TrendViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 当前选择的时间范围
    @Published var timeRange: TimeRange = .week
    
    /// 自定义日期范围
    @Published var customStartDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published var customEndDate: Date = Date()
    
    /// 是否使用自定义日期范围
    @Published var useCustomRange: Bool = false
    
    /// 统计数据
    @Published var statistics: Statistics?
    
    /// 是否正在加载
    @Published var isLoading = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let context: NSManagedObjectContext
    let sessionService: SessionService  // 公开以便导出功能使用
    
    // MARK: - Computed Properties
    
    /// 开始日期
    var startDate: Date {
        if useCustomRange {
            return customStartDate
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        switch timeRange {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        case .custom:
            return customStartDate
        }
    }
    
    /// 结束日期
    var endDate: Date {
        if useCustomRange {
            return customEndDate
        }
        
        return timeRange == .custom ? customEndDate : Date()
    }
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext) {
        self.context = context
        self.sessionService = SessionService(context: context)
    }
    
    // MARK: - Data Loading
    
    /// 加载统计数据
    func loadStatistics() {
        isLoading = true
        errorMessage = nil
        
        do {
            // 获取时间范围内的所有课程
            let sessions = sessionService.fetchSessions(from: startDate, to: endDate)
            
            // 计算统计数据
            let stats = calculateStatistics(from: sessions)
            self.statistics = stats
            
            isLoading = false
        } catch {
            errorMessage = "加载数据失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - Statistics Calculation
    
    /// 计算统计数据
    private func calculateStatistics(from sessions: [BalletSession]) -> Statistics {
        guard !sessions.isEmpty else {
            return Statistics(
                totalSessions: 0,
                totalDuration: 0,
                averageDuration: 0,
                sessionsPerWeek: 0,
                mostFrequentInstructor: nil,
                mostFrequentClass: nil
            )
        }
        
        // 总课程数
        let totalSessions = sessions.count
        
        // 总时长
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        
        // 平均时长
        let averageDuration = totalDuration / Double(totalSessions)
        
        // 每周课程数
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let weeks = max(Double(days) / 7.0, 1.0)
        let sessionsPerWeek = Double(totalSessions) / weeks
        
        // 最常见的老师
        let instructorCounts = sessions.compactMap { $0.instructor }
            .reduce(into: [:]) { counts, instructor in
                counts[instructor, default: 0] += 1
            }
        let mostFrequentInstructor = instructorCounts.max(by: { $0.value < $1.value })?.key
        
        // 最常见的课程
        let classCounts = sessions.compactMap { $0.name }
            .reduce(into: [:]) { counts, className in
                counts[className, default: 0] += 1
            }
        let mostFrequentClass = classCounts.max(by: { $0.value < $1.value })?.key
        
        return Statistics(
            totalSessions: totalSessions,
            totalDuration: totalDuration,
            averageDuration: averageDuration,
            sessionsPerWeek: sessionsPerWeek,
            mostFrequentInstructor: mostFrequentInstructor,
            mostFrequentClass: mostFrequentClass
        )
    }
    
    /// 计算每日课程数
    func calculateSessionsPerDay() -> [DateValue] {
        let sessions = sessionService.fetchSessions(from: startDate, to: endDate)
        
        // 按日期分组
        var sessionsByDate: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for session in sessions {
            let date = calendar.startOfDay(for: session.sessionDate ?? Date())
            sessionsByDate[date, default: 0] += 1
        }
        
        // 转换为数组并排序
        return sessionsByDate.map { DateValue(date: $0.key, value: Double($0.value)) }
            .sorted { $0.date < $1.date }
    }
    
    /// 计算时长趋势
    func calculateDurationTrend() -> [DateValue] {
        let sessions = sessionService.fetchSessions(from: startDate, to: endDate)
        
        // 按日期分组并累计时长（转换为小时）
        var durationByDate: [Date: TimeInterval] = [:]
        let calendar = Calendar.current
        
        for session in sessions {
            let date = calendar.startOfDay(for: session.sessionDate ?? Date())
            durationByDate[date, default: 0] += session.duration
        }
        
        // 转换为数组并排序（时长转为小时）
        return durationByDate.map { DateValue(date: $0.key, value: $0.value / 3600.0) }
            .sorted { $0.date < $1.date }
    }
    
    /// 计算老师分布
    func calculateInstructorDistribution() -> [NameValue] {
        let sessions = sessionService.fetchSessions(from: startDate, to: endDate)
        
        let instructorCounts = sessions.compactMap { $0.instructor }
            .reduce(into: [:]) { counts, instructor in
                counts[instructor, default: 0] += 1
            }
        
        return instructorCounts.map { NameValue(name: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }
    
    /// 计算课程分布
    func calculateClassDistribution() -> [NameValue] {
        let sessions = sessionService.fetchSessions(from: startDate, to: endDate)
        
        let classCounts = sessions.compactMap { $0.name }
            .reduce(into: [:]) { counts, className in
                counts[className, default: 0] += 1
            }
        
        return classCounts.map { NameValue(name: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }
    }
}

// MARK: - Models

extension TrendViewModel {
    /// 时间范围
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "本周"
        case month = "本月"
        case year = "本年"
        case custom = "自定义"
        
        var id: String { rawValue }
    }
    
    /// 统计数据
    struct Statistics {
        let totalSessions: Int
        let totalDuration: TimeInterval
        let averageDuration: TimeInterval
        let sessionsPerWeek: Double
        let mostFrequentInstructor: String?
        let mostFrequentClass: String?
        
        /// 格式化总时长
        var totalDurationFormatted: String {
            DateHelper.formatDuration(totalDuration)
        }
        
        /// 格式化平均时长
        var averageDurationFormatted: String {
            DateHelper.formatDuration(averageDuration)
        }
        
        /// 格式化每周课程数
        var sessionsPerWeekFormatted: String {
            String(format: "%.1f", sessionsPerWeek)
        }
    }
}

// MARK: - Chart Data Models

/// 日期-数值对（用于时间序列图表）
struct DateValue: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

/// 名称-数值对（用于分布图表）
struct NameValue: Identifiable {
    let id = UUID()
    let name: String
    let value: Int
}

