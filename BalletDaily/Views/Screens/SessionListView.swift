import SwiftUI
internal import CoreData

/// 课程列表视图
struct SessionListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: SessionListViewModel
    @State private var showingAddSession = false
    @State private var selectedSession: BalletSession?
    @State private var showingFilterSheet = false
    
    init(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: SessionListViewModel(context: ctx))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoadingView(message: "加载中...")
                } else if viewModel.filteredSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionListView
                }
            }
            .navigationTitle("课程记录")
            .searchable(text: $viewModel.searchText, prompt: "搜索课程或老师")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // 过滤按钮
                        Button(action: {
                            showingFilterSheet = true
                        }) {
                            Image(systemName: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(viewModel.hasActiveFilters ? .accentColor : .primary)
                        }
                        
                        // 添加按钮
                        Button(action: {
                            showingAddSession = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddSession, onDismiss: {
                // Sheet 关闭后重新加载数据
                viewModel.loadSessions()
            }) {
                SessionEditView(context: viewContext)
            }
            .sheet(item: $selectedSession, onDismiss: {
                // Sheet 关闭后重新加载数据
                viewModel.loadSessions()
            }) { session in
                NavigationStack {
                    SessionDetailView(session: session, context: viewContext)
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                filterSheet
            }
            .onAppear {
                viewModel.loadSessions()
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
        }
    }
    
    // MARK: - Session List View
    
    private var sessionListView: some View {
        List {
            ForEach(viewModel.filteredSessions) { session in
                SessionRowView(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSession = session
                    }
            }
            .onDelete { indexSet in
                viewModel.deleteSessions(at: indexSet)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        EmptyStateView(
            icon: viewModel.hasActiveFilters ? "line.3.horizontal.decrease.circle" : "figure.dance",
            title: viewModel.hasActiveFilters ? "没有找到课程" : "还没有课程记录",
            message: viewModel.hasActiveFilters ? "尝试调整筛选条件" : "点击右上角 + 按钮添加你的第一节课程",
            actionTitle: viewModel.hasActiveFilters ? "清除筛选" : "添加课程",
            action: {
                if viewModel.hasActiveFilters {
                    viewModel.clearFilters()
                } else {
                    showingAddSession = true
                }
            }
        )
    }
    
    // MARK: - Filter Sheet
    
    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section("日期范围") {
                    Picker("时间", selection: $viewModel.dateFilter) {
                        ForEach(SessionListViewModel.DateFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if !viewModel.allInstructors.isEmpty {
                    Section("老师") {
                        Picker("选择老师", selection: $viewModel.selectedInstructor) {
                            Text("全部").tag(nil as String?)
                            ForEach(viewModel.allInstructors, id: \.self) { instructor in
                                Text(instructor).tag(instructor as String?)
                            }
                        }
                    }
                }
                
                if !viewModel.allClassNames.isEmpty {
                    Section("课程名称") {
                        Picker("选择课程", selection: $viewModel.selectedClassName) {
                            Text("全部").tag(nil as String?)
                            ForEach(viewModel.allClassNames, id: \.self) { className in
                                Text(className).tag(className as String?)
                            }
                        }
                    }
                }
                
                if viewModel.hasActiveFilters {
                    Section {
                        Button("清除所有筛选") {
                            viewModel.clearFilters()
                            showingFilterSheet = false
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        showingFilterSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: BalletSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日期和星期
            HStack {
                Text(DateHelper.formatSessionDate(session.sessionDate ?? Date()))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // 数据来源标记
                HStack(spacing: 4) {
                    Image(systemName: session.isManualEntry ? "hand.tap.fill" : "applewatch")
                        .font(.caption)
                        .foregroundColor(session.isManualEntry ? .blue : .green)
                    Text(session.isManualEntry ? "手动" : "同步")
                        .font(.caption2)
                        .foregroundColor(session.isManualEntry ? .blue : .green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((session.isManualEntry ? Color.blue : Color.green).opacity(0.1))
                .cornerRadius(8)
            }
            
            // 课程名称
            Text(session.name ?? "未命名课程")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 老师和时长
            HStack {
                if let instructor = session.instructor {
                    Label(instructor, systemImage: "person")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let instructor = session.instructor {
                    Text("·")
                        .foregroundColor(.secondary)
                }
                
                Label(DateHelper.formatDuration(session.duration), systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // 健康数据（如果有）
            if let metrics = session.healthMetrics {
                HStack(spacing: 12) {
                    if metrics.avgHeartRate > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text("\(Int(metrics.avgHeartRate)) bpm")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if metrics.activeEnergy > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(Int(metrics.activeEnergy)) kcal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview("With Data") {
    let context = PersistenceController.preview.container.viewContext
    
    // 创建测试数据
    let session1 = BalletSession(context: context)
    session1.id = UUID()
    session1.createdAt = Date()
    session1.updatedAt = Date()
    session1.sessionDate = Date()
    session1.duration = 5400 // 1.5小时
    session1.name = "芭蕾基础"
    session1.instructor = "李老师"
    session1.isManualEntry = false
    
    let session2 = BalletSession(context: context)
    session2.id = UUID()
    session2.createdAt = Date().addingTimeInterval(-86400)
    session2.updatedAt = Date().addingTimeInterval(-86400)
    session2.sessionDate = Date().addingTimeInterval(-86400)
    session2.duration = 3600 // 1小时
    session2.name = "现代舞"
    session2.instructor = "王老师"
    session2.isManualEntry = true
    
    let preview = SessionListView(context: context)
    return preview
}

#Preview("Empty State") {
    SessionListView(context: PersistenceController.preview.container.viewContext)
}

