import Foundation

/// 日期处理工具类
/// 封装常用的日期格式化和计算功能
struct DateHelper {
    
    // MARK: - 日期格式化
    
    /// 格式化课程日期
    /// 示例: "12月25日 周一"
    static func formatSessionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
    
    /// 格式化简短日期
    /// 示例: "12月25日"
    static func formatShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    /// 格式化完整日期
    /// 示例: "2024年12月25日"
    static func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
    
    /// 格式化时间
    /// 示例: "14:30"
    static func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    /// 格式化日期和时间
    /// 示例: "12月25日 14:30"
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: date)
    }
    
    /// 格式化时长
    /// 示例: "1小时30分钟", "45分钟", "2小时"
    static func formatDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else if hours > 0 {
            return "\(hours)小时"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 格式化时长（简短版本）
    /// 示例: "1h 30m", "45m", "2h"
    static func formatDurationShort(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    /// 格式化时间范围
    /// 示例: "14:30 - 16:00"
    static func formatTimeRange(start: Date, end: Date) -> String {
        let startTime = formatTime(start)
        let endTime = formatTime(end)
        return "\(startTime) - \(endTime)"
    }
    
    // MARK: - 相对时间
    
    /// 获取相对时间字符串
    /// 示例: "今天", "昨天", "3天前", "1周前"
    static func relativeString(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        // 今天
        if calendar.isDateInToday(date) {
            return "今天"
        }
        
        // 昨天
        if calendar.isDateInYesterday(date) {
            return "昨天"
        }
        
        // 明天
        if calendar.isDateInTomorrow(date) {
            return "明天"
        }
        
        // 计算天数差
        let components = calendar.dateComponents([.day], from: date, to: now)
        
        if let days = components.day {
            if days > 0 {
                // 过去
                if days < 7 {
                    return "\(days)天前"
                } else if days < 30 {
                    let weeks = days / 7
                    return "\(weeks)周前"
                } else if days < 365 {
                    let months = days / 30
                    return "\(months)个月前"
                } else {
                    let years = days / 365
                    return "\(years)年前"
                }
            } else if days < 0 {
                // 未来
                let futureDays = abs(days)
                if futureDays < 7 {
                    return "\(futureDays)天后"
                } else if futureDays < 30 {
                    let weeks = futureDays / 7
                    return "\(weeks)周后"
                } else {
                    let months = futureDays / 30
                    return "\(months)个月后"
                }
            }
        }
        
        return formatShortDate(date)
    }
    
    // MARK: - 日期计算
    
    /// 获取指定日期所在周的开始日期（周一）
    static func startOfWeek(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        components.weekday = 2 // 周一
        return calendar.date(from: components) ?? date
    }
    
    /// 获取指定日期所在月的开始日期
    static func startOfMonth(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    /// 获取指定日期所在年的开始日期
    static func startOfYear(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: date)
        return calendar.date(from: components) ?? date
    }
    
    /// 获取指定日期所在周的结束日期（周日）
    static func endOfWeek(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startDate = startOfWeek(for: date)
        return calendar.date(byAdding: .day, value: 6, to: startDate) ?? date
    }
    
    /// 获取指定日期所在月的结束日期
    static func endOfMonth(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startDate = startOfMonth(for: date)
        
        var components = DateComponents()
        components.month = 1
        components.day = -1
        
        return calendar.date(byAdding: components, to: startDate) ?? date
    }
    
    /// 获取指定日期所在年的结束日期
    static func endOfYear(for date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let startDate = startOfYear(for: date)
        
        var components = DateComponents()
        components.year = 1
        components.day = -1
        
        return calendar.date(byAdding: components, to: startDate) ?? date
    }
    
    // MARK: - 日期比较
    
    /// 判断两个日期是否在同一天
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    /// 判断两个日期是否在同一周
    static func isSameWeek(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date1)
        let components2 = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date2)
        return components1.yearForWeekOfYear == components2.yearForWeekOfYear &&
               components1.weekOfYear == components2.weekOfYear
    }
    
    /// 判断两个日期是否在同一月
    static func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month], from: date1)
        let components2 = calendar.dateComponents([.year, .month], from: date2)
        return components1.year == components2.year &&
               components1.month == components2.month
    }
    
    /// 判断两个日期是否在同一年
    static func isSameYear(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year], from: date1)
        let components2 = calendar.dateComponents([.year], from: date2)
        return components1.year == components2.year
    }
    
    // MARK: - 日期范围生成
    
    /// 生成日期范围内的所有日期
    static func dates(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        var currentDate = startDate
        let calendar = Calendar.current
        
        while currentDate <= endDate {
            dates.append(currentDate)
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDate
        }
        
        return dates
    }
}

// MARK: - Date 扩展

extension Date {
    /// 本周开始日期
    var startOfWeek: Date {
        DateHelper.startOfWeek(for: self)
    }
    
    /// 本月开始日期
    var startOfMonth: Date {
        DateHelper.startOfMonth(for: self)
    }
    
    /// 本年开始日期
    var startOfYear: Date {
        DateHelper.startOfYear(for: self)
    }
    
    /// 本周结束日期
    var endOfWeek: Date {
        DateHelper.endOfWeek(for: self)
    }
    
    /// 本月结束日期
    var endOfMonth: Date {
        DateHelper.endOfMonth(for: self)
    }
    
    /// 本年结束日期
    var endOfYear: Date {
        DateHelper.endOfYear(for: self)
    }
    
    /// 相对时间字符串
    var relativeString: String {
        DateHelper.relativeString(from: self)
    }
}

