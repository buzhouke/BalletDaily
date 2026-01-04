import SwiftUI
internal import CoreData
import Charts

/// 趋势分析视图
struct TrendView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TrendViewModel
    @State private var showingExportOptions = false
    @State private var showingDatePicker = false
    
    init(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: TrendViewModel(context: ctx))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择器
                    timeRangePicker
                    
                    // 自定义日期范围
                    if viewModel.timeRange == .custom {
                        customDateRangePicker
                    }
                    
                    // 统计卡片
                    if let stats = viewModel.statistics, stats.totalSessions > 0 {
                        statisticsCards(stats: stats)
                        
                        // 图表区域
                        chartsSection
                    } else if !viewModel.isLoading {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("趋势分析")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let stats = viewModel.statistics, stats.totalSessions > 0 {
                        Button {
                            showingExportOptions = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "加载中...")
                }
            }
            .confirmationDialog("导出数据", isPresented: $showingExportOptions) {
                Button("导出为 CSV") {
                    exportCSV()
                }
                Button("生成统计报告") {
                    exportReport()
                }
                Button("取消", role: .cancel) { }
            }
            .onAppear {
                viewModel.loadStatistics()
            }
            .onChange(of: viewModel.timeRange) { _, newValue in
                // 切换到自定义模式时不自动加载，等用户选择日期后再加载
                if newValue != .custom {
                    viewModel.loadStatistics()
                }
            }
        }
    }
    
    // MARK: - Export Functions
    
    private func exportCSV() {
        let sessions = viewModel.sessionService.fetchSessions(from: viewModel.startDate, to: viewModel.endDate)
        let csv = DataExporter.exportToCSV(sessions: sessions)
        
        let filename = "BalletDaily_\(viewModel.timeRange.rawValue)_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)).csv"
        
        shareData(csv, filename: filename)
    }
    
    private func exportReport() {
        let sessions = viewModel.sessionService.fetchSessions(from: viewModel.startDate, to: viewModel.endDate)
        let report = DataExporter.generateStatisticsReport(sessions: sessions, timeRange: viewModel.timeRange.rawValue)
        
        let filename = "BalletDaily_报告_\(viewModel.timeRange.rawValue)_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)).txt"
        
        shareData(report, filename: filename)
    }
    
    private func shareData(_ data: String, filename: String) {
        // 获取当前的 window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootVC = window.rootViewController else {
            return
        }
        
        // 找到最顶层的 view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        DataExporter.shareData(data, filename: filename, from: topVC)
    }
    
    // MARK: - Time Range Picker
    
    private var timeRangePicker: some View {
        VStack(spacing: 12) {
            Picker("时间范围", selection: $viewModel.timeRange) {
                ForEach(TrendViewModel.TimeRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            
            // 显示当前时间范围
            if viewModel.timeRange != .custom {
                Text(dateRangeDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var customDateRangePicker: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("开始日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $viewModel.customStartDate, displayedComponents: .date)
                        .labelsHidden()
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("结束日期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $viewModel.customEndDate, displayedComponents: .date)
                        .labelsHidden()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            Button {
                viewModel.loadStatistics()
            } label: {
                Label("应用日期范围", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    private var dateRangeDescription: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return "\(formatter.string(from: viewModel.startDate)) - \(formatter.string(from: viewModel.endDate))"
    }
    
    // MARK: - Statistics Cards
    
    private func statisticsCards(stats: TrendViewModel.Statistics) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "figure.dance",
                    iconColor: .blue,
                    title: "总课程数",
                    value: "\(stats.totalSessions)",
                    unit: "节"
                )
                
                StatCard(
                    icon: "clock.fill",
                    iconColor: .orange,
                    title: "总时长",
                    value: stats.totalDurationFormatted,
                    unit: ""
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    icon: "timer",
                    iconColor: .green,
                    title: "平均时长",
                    value: stats.averageDurationFormatted,
                    unit: ""
                )
                
                StatCard(
                    icon: "calendar",
                    iconColor: .purple,
                    title: "每周课程",
                    value: stats.sessionsPerWeekFormatted,
                    unit: "节"
                )
            }
            
//            // 最常见的老师和课程
//            if stats.mostFrequentInstructor != nil || stats.mostFrequentClass != nil {
//                VStack(spacing: 8) {
//                    if let instructor = stats.mostFrequentInstructor {
//                        InfoBadge(icon: "person.fill", text: "最常上课: \(instructor)", color: .purple)
//                    }
//                    
//                    if let className = stats.mostFrequentClass {
//                        InfoBadge(icon: "star.fill", text: "最常课程: \(className)", color: .yellow)
//                    }
//                }
//                .padding(.top, 8)
//            }
        }
    }
    
    // MARK: - Charts Section
    
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("数据可视化")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // 课程频率图表
                SessionFrequencyChart(data: viewModel.calculateSessionsPerDay())
                
                // 时长趋势图表
                DurationTrendChart(data: viewModel.calculateDurationTrend())
                
                // 课程分布图表
                let classDistribution = viewModel.calculateClassDistribution()
                if !classDistribution.isEmpty {
                    DistributionChart(
                        title: "课程分布",
                        icon: "figure.dance",
                        color: .green,
                        data: classDistribution
                    )
                }
                
                // 老师分布图表
                let instructorDistribution = viewModel.calculateInstructorDistribution()
                if !instructorDistribution.isEmpty {
                    DistributionChart(
                        title: "老师分布",
                        icon: "person.fill",
                        color: .purple,
                        data: instructorDistribution
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: "chart.xyaxis.line",
            title: "暂无数据",
            message: "在选择的时间范围内没有找到课程记录\n快去添加你的第一节课程吧！",
            actionTitle: nil,
            action: nil
        )
        .padding(.top, 100)
    }
}

// MARK: - Supporting Views

/// 统计卡片
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// 信息徽章
struct InfoBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(20)
    }
}


// MARK: - Previews

#Preview("With Data") {
    let context = PersistenceController.preview.container.viewContext
    
    // 创建测试数据
    for i in 0..<10 {
        let session = BalletSession(context: context)
        session.id = UUID()
        session.createdAt = Date()
        session.updatedAt = Date()
        session.sessionDate = Calendar.current.date(byAdding: .day, value: -i, to: Date())
        session.duration = 3600 + Double(i * 300)
        session.name = ["芭蕾基础", "芭蕾进阶", "现代舞"][i % 3]
        session.instructor = ["张老师", "李老师"][i % 2]
        session.isManualEntry = true
    }
    
    return TrendView(context: context)
}

#Preview("Empty") {
    TrendView(context: PersistenceController.preview.container.viewContext)
}

