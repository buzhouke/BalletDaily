import SwiftUI
internal import CoreData
import Charts

/// 课程详情视图
struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: SessionDetailViewModel
    @State private var showingEditView = false
    @State private var showingNotesView = false
    @State private var showingQuickNoteEdit = false
    @State private var quickNoteType: NoteType = .general
    
    init(session: BalletSession, context: NSManagedObjectContext? = nil) {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: SessionDetailViewModel(session: session, context: ctx))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本信息
                basicInfoSection
                
                // 健康数据
                if viewModel.hasHealthMetrics {
                    healthMetricsSection
                }
                
                // 笔记预览
                notesPreviewSection
                
                // 删除按钮
                deleteButton
            }
            .padding()
        }
        .navigationTitle(viewModel.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("编辑") {
                    showingEditView = true
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            SessionEditView(session: viewModel.session, context: viewContext)
        }
        .sheet(isPresented: $showingNotesView) {
            NoteListView(session: viewModel.session, context: viewContext)
        }
        .sheet(isPresented: $showingQuickNoteEdit) {
            NoteEditView(
                session: viewModel.session,
                note: nil,
                initialType: quickNoteType,
                context: viewContext
            )
        }
        .onChange(of: showingEditView) { _, newValue in
            if !newValue {
                // 编辑视图关闭后重新加载数据
                viewModel.loadData()
            }
        }
        .onChange(of: showingNotesView) { _, newValue in
            if !newValue {
                // 笔记视图关闭后重新加载数据
                viewModel.loadData()
            }
        }
        .onChange(of: showingQuickNoteEdit) { _, newValue in
            if !newValue {
                // 快速笔记关闭后重新加载数据
                viewModel.loadData()
            }
        }
        .alert("删除课程", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task {
                    if await viewModel.deleteSession() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("确定要删除这节课程吗？此操作无法撤销。")
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "处理中...")
            }
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(spacing: 16) {
            // 日期和时间
            InfoRow(
                icon: "calendar",
                iconColor: .blue,
                title: "日期",
                value: viewModel.dateDisplay
            )
            
            if let timeRange = viewModel.timeRangeDisplay {
                InfoRow(
                    icon: "clock",
                    iconColor: .green,
                    title: "时间",
                    value: timeRange
                )
            }
            
            InfoRow(
                icon: "timer",
                iconColor: .orange,
                title: "时长",
                value: viewModel.durationDisplay
            )
            
            Divider()
            
            // 课程信息（可点击编辑）
            EditableInfoRow(
                icon: "person.fill",
                iconColor: .purple,
                title: "老师",
                value: viewModel.instructorDisplay,
                onTap: {
                    showingEditView = true
                }
            )
            
            EditableInfoRow(
                icon: "location.fill",
                iconColor: .red,
                title: "地点",
                value: viewModel.locationDisplay,
                onTap: {
                    showingEditView = true
                }
            )
            
            // 数据来源
            HStack {
                Image(systemName: viewModel.session.isManualEntry ? "hand.draw" : "applewatch")
                    .foregroundColor(.secondary)
                Text(viewModel.session.isManualEntry ? "手动创建" : "从 Apple Watch 导入")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Health Metrics Section
    
    private var healthMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("健康数据")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // 心率卡片
                if let metrics = viewModel.healthMetrics, metrics.avgHeartRate > 0 {
                    heartRateCard(metrics: metrics)
                }
                
                // 活动数据卡片
                if let metrics = viewModel.healthMetrics {
                    activityDataCard(metrics: metrics)
                }
            }
        }
    }
    
    private func heartRateCard(metrics: HealthMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("心率")
                    .font(.headline)
                Spacer()
            }
            
            // 统计数据
            HStack(spacing: 20) {
                StatItem(title: "平均", value: "\(Int(metrics.avgHeartRate))", unit: "bpm")
                StatItem(title: "最高", value: "\(Int(metrics.maxHeartRate))", unit: "bpm")
                StatItem(title: "最低", value: "\(Int(metrics.minHeartRate))", unit: "bpm")
            }
            
            // 心率曲线图
            if !viewModel.heartRateData.isEmpty {
                heartRateChart
                    .frame(height: 200)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private var heartRateChart: some View {
        Chart(viewModel.heartRateData) { dataPoint in
            LineMark(
                x: .value("时间", dataPoint.time / 60), // 转换为分钟
                y: .value("心率", dataPoint.heartRate)
            )
            .foregroundStyle(Color.red)
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            
            AreaMark(
                x: .value("时间", dataPoint.time / 60),
                y: .value("心率", dataPoint.heartRate)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.red.opacity(0.3), Color.red.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
                AxisGridLine()
            }
        }
        .chartXAxisLabel("时间 (分钟)")
        .chartYAxisLabel("心率 (bpm)")
        .chartPlotStyle { plotArea in
            plotArea
                .background(Color(.systemBackground))
        }
    }
    
    private func activityDataCard(metrics: HealthMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("活动数据")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                if metrics.activeEnergy > 0 {
                    ActivityRow(
                        icon: "flame.fill",
                        iconColor: .orange,
                        title: "活动能量",
                        value: "\(Int(metrics.activeEnergy))",
                        unit: "千卡"
                    )
                }
                
                if metrics.stepCount > 0 {
                    ActivityRow(
                        icon: "figure.walk",
                        iconColor: .green,
                        title: "步数",
                        value: "\(metrics.stepCount)",
                        unit: "步"
                    )
                }
                
                if metrics.distance > 0 {
                    ActivityRow(
                        icon: "location.fill",
                        iconColor: .blue,
                        title: "距离",
                        value: String(format: "%.2f", metrics.distance / 1000),
                        unit: "公里"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Notes Preview Section
    
    private var notesPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("笔记")
                    .font(.headline)
                
                if viewModel.notesCount > 0 {
                    Text("(\(viewModel.notesCount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if viewModel.notesCount > 0 {
                    Button("查看全部") {
                        showingNotesView = true
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            // 快速添加按钮
            quickAddButtons
            
            if viewModel.notesCount == 0 {
                Text("还没有添加笔记")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentNotes) { note in
                        NotePreviewRow(note: note)
                            .onTapGesture {
                                showingNotesView = true
                            }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Quick Add Buttons
    
    private var quickAddButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(NoteType.allCases, id: \.self) { type in
                    quickAddButton(for: type)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private func quickAddButton(for type: NoteType) -> some View {
        Button {
            quickNoteType = type
            showingQuickNoteEdit = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.caption)
                Image(systemName: type.icon)
                    .font(.caption)
                Text(type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(type.color.opacity(0.15))
            .foregroundColor(type.color)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(type.color.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: type.color.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.showingDeleteConfirmation = true
        } label: {
            Label("删除课程", systemImage: "trash")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
        }
    }
}

// MARK: - Supporting Views

struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct EditableInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(value)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActivityRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .fontWeight(.semibold)
                Text(unit)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NotePreviewRow: View {
    let note: BalletSessionNote
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: NoteType(rawValue: note.noteType ?? "general")?.icon ?? "note.text")
                .foregroundColor(.gray)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(NoteType(rawValue: note.noteType ?? "general")?.displayName ?? "笔记")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(note.content ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Previews

private extension SessionDetailView {
    static var previewContext: NSManagedObjectContext {
        PersistenceController.preview.container.viewContext
    }

    static var healthDataPreview: some View {
        let session = makeSessionWithHealthMetrics(in: previewContext)
        return NavigationStack {
            SessionDetailView(session: session, context: previewContext)
        }
    }

    static var manualEntryPreview: some View {
        let session = makeManualEntrySession(in: previewContext)
        return NavigationStack {
            SessionDetailView(session: session, context: previewContext)
        }
    }

    static func makeSessionWithHealthMetrics(in context: NSManagedObjectContext) -> BalletSession {
        let session = BalletSession(context: context)
        session.id = UUID()
        session.createdAt = Date()
        session.updatedAt = Date()
        session.sessionDate = Date().addingTimeInterval(-3600)
        session.duration = 5400
        session.name = "芭蕾基础"
        session.instructor = "李老师"
        session.location = "北京舞蹈学院"
        session.isManualEntry = false

        let metrics = HealthMetrics(context: context)
        metrics.id = UUID()
        metrics.avgHeartRate = 135
        metrics.maxHeartRate = 165
        metrics.minHeartRate = 95
        metrics.activeEnergy = 380
        metrics.stepCount = 4500
        metrics.distance = 2500
        metrics.syncedAt = Date()
        session.healthMetrics = metrics

        return session
    }

    static func makeManualEntrySession(in context: NSManagedObjectContext) -> BalletSession {
        let session = BalletSession(context: context)
        session.id = UUID()
        session.createdAt = Date()
        session.updatedAt = Date()
        session.sessionDate = Date()
        session.duration = 3600
        session.name = "现代舞"
        session.instructor = "王老师"
        session.location = "舞蹈室 B"
        session.isManualEntry = true
        return session
    }
}

#Preview("With Health Data") {
    SessionDetailView.healthDataPreview
}

#Preview("Manual Entry") {
    SessionDetailView.manualEntryPreview
}

