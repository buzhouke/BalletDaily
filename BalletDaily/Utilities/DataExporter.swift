//
//  DataExporter.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  Phase 6: 数据导出工具
//

import Foundation
import UIKit

/// 数据导出工具
class DataExporter {
    
    /// 导出课程数据为 CSV 格式
    /// - Parameter sessions: 课程数组
    /// - Returns: CSV 格式的字符串
    static func exportToCSV(sessions: [BalletSession]) -> String {
        var csv = "日期,课程名称,老师,地点,时长(分钟),数据来源,平均心率,最高心率,最低心率,活动能量(千卡),步数,距离(米)\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for session in sessions {
            let date = dateFormatter.string(from: session.sessionDate ?? Date())
            let name = escapeCSV(session.name ?? "未命名课程")
            let instructor = escapeCSV(session.instructor ?? "")
            let location = escapeCSV(session.location ?? "")
            let duration = Int(session.duration / 60)
            let source = session.isManualEntry ? "手动创建" : "Apple Watch"
            
            // 健康数据
            var avgHR = ""
            var maxHR = ""
            var minHR = ""
            var energy = ""
            var steps = ""
            var distance = ""
            
            if let metrics = session.healthMetrics {
                if metrics.avgHeartRate > 0 {
                    avgHR = String(format: "%.0f", metrics.avgHeartRate)
                }
                if metrics.maxHeartRate > 0 {
                    maxHR = String(format: "%.0f", metrics.maxHeartRate)
                }
                if metrics.minHeartRate > 0 {
                    minHR = String(format: "%.0f", metrics.minHeartRate)
                }
                if metrics.activeEnergy > 0 {
                    energy = String(format: "%.0f", metrics.activeEnergy)
                }
                if metrics.stepCount > 0 {
                    steps = "\(metrics.stepCount)"
                }
                if metrics.distance > 0 {
                    distance = String(format: "%.0f", metrics.distance)
                }
            }
            
            let row = "\(date),\(name),\(instructor),\(location),\(duration),\(source),\(avgHR),\(maxHR),\(minHR),\(energy),\(steps),\(distance)\n"
            csv += row
        }
        
        return csv
    }
    
    /// 转义 CSV 字段（处理逗号和引号）
    private static func escapeCSV(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return field
    }
    
    /// 分享数据
    /// - Parameters:
    ///   - data: 要分享的数据字符串
    ///   - filename: 文件名
    ///   - viewController: 用于呈现分享界面的视图控制器
    static func shareData(_ data: String, filename: String, from viewController: UIViewController) {
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // 创建分享控制器
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // 在 iPad 上需要设置 popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            viewController.present(activityVC, animated: true)
        } catch {
            print("❌ 导出数据失败: \(error.localizedDescription)")
        }
    }
    
    /// 生成统计报告
    /// - Parameters:
    ///   - sessions: 课程数组
    ///   - timeRange: 时间范围描述
    /// - Returns: 文本格式的统计报告
    static func generateStatisticsReport(sessions: [BalletSession], timeRange: String) -> String {
        var report = "BalletDaily 统计报告\n"
        report += "时间范围: \(timeRange)\n"
        report += "生成时间: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n"
        report += "\n"
        report += "=" * 50 + "\n\n"
        
        // 基本统计
        let totalSessions = sessions.count
        let totalDuration = sessions.reduce(0) { $0 + $1.duration }
        let avgDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
        
        report += "📊 基本统计\n"
        report += "总课程数: \(totalSessions) 节\n"
        report += "总时长: \(DateHelper.formatDuration(totalDuration))\n"
        report += "平均时长: \(DateHelper.formatDuration(avgDuration))\n"
        report += "\n"
        
        // 课程分布
        let classCounts = sessions.compactMap { $0.name }
            .reduce(into: [:]) { counts, name in
                counts[name, default: 0] += 1
            }
        
        if !classCounts.isEmpty {
            report += "📚 课程分布\n"
            for (name, count) in classCounts.sorted(by: { $0.value > $1.value }) {
                report += "  \(name): \(count) 节\n"
            }
            report += "\n"
        }
        
        // 老师分布
        let instructorCounts = sessions.compactMap { $0.instructor }
            .reduce(into: [:]) { counts, instructor in
                counts[instructor, default: 0] += 1
            }
        
        if !instructorCounts.isEmpty {
            report += "👨‍🏫 老师分布\n"
            for (instructor, count) in instructorCounts.sorted(by: { $0.value > $1.value }) {
                report += "  \(instructor): \(count) 节\n"
            }
            report += "\n"
        }
        
        // 健康数据统计
        let sessionsWithMetrics = sessions.filter { $0.healthMetrics != nil }
        if !sessionsWithMetrics.isEmpty {
            let avgHeartRates = sessionsWithMetrics.compactMap { $0.healthMetrics?.avgHeartRate }.filter { $0 > 0 }
            let totalEnergy = sessionsWithMetrics.compactMap { $0.healthMetrics?.activeEnergy }.filter { $0 > 0 }.reduce(0, +)
            
            report += "❤️ 健康数据\n"
            if !avgHeartRates.isEmpty {
                let avgHR = avgHeartRates.reduce(0, +) / Double(avgHeartRates.count)
                report += "  平均心率: \(Int(avgHR)) bpm\n"
            }
            if totalEnergy > 0 {
                report += "  总能量消耗: \(Int(totalEnergy)) 千卡\n"
            }
            report += "\n"
        }
        
        report += "=" * 50 + "\n"
        report += "\n由 BalletDaily 生成\n"
        
        return report
    }
}

// MARK: - String Extension

private extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

