//
//  PresetTagsView.swift
//  BalletDaily
//
//  Created on 2026/1/4
//  预设标签管理视图
//

import SwiftUI

/// 预设标签管理视图
struct PresetTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager: PresetTagManager
    @State private var showingAddTag = false
    @State private var selectedType: TagType = .className
    @State private var editingTag: PresetTag?
    
    init() {
        // 初始化时传入 TagService 以加载用户真实数据
        let tagService = TagService()
        _manager = StateObject(wrappedValue: PresetTagManager(tagService: tagService))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 背景色
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        // 类型选择器卡片
                        VStack(spacing: 0) {
                            Picker("标签类型", selection: $selectedType) {
                                Text("课程名称").tag(TagType.className)
                                Text("老师").tag(TagType.instructor)
                                Text("地点").tag(TagType.location)
                            }
                            .pickerStyle(.segmented)
                            .padding(16)
                        }
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        
                        // 标签列表卡片
                        let tags = manager.getPresetTags(for: selectedType.rawValue)
                        
                        VStack(spacing: 0) {
                            // 标题栏
                            HStack {
                                Text(selectedType.displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppTheme.cardBackground)
                            
                            Divider()
                            
                            if tags.isEmpty {
                                // 空状态
                                VStack(spacing: 16) {
                                    Image(systemName: "tag")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppTheme.textTertiary)
                                    
                                    Text("还没有预设标签")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Text("点击右上角 + 添加标签")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textTertiary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 60)
                                .background(AppTheme.cardBackground)
                            } else {
                                // 标签列表
                                VStack(spacing: 0) {
                                    ForEach(Array(tags.enumerated()), id: \.element.id) { index, tag in
                                        VStack(spacing: 0) {
                                            HStack(spacing: 16) {
                                                // 标签名称
                                                Text(tag.name)
                                                    .font(.system(size: 17))
                                                    .foregroundColor(tag.isPlaceholder ? AppTheme.textTertiary : AppTheme.textPrimary)
                                                
                                                Spacer()
                                                
                                                // 编辑按钮
                                                Button {
                                                    editingTag = tag
                                                } label: {
                                                    Image(systemName: "pencil.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.blue)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 14)
                                            .background(AppTheme.cardBackground)
                                            .contentShape(Rectangle())
                                            
                                            // 分隔线（最后一项不显示）
                                            if index < tags.count - 1 {
                                                Divider()
                                                    .padding(.leading, 16)
                                            }
                                        }
                                    }
                                    .onDelete { indexSet in
                                        for index in indexSet {
                                            manager.deletePresetTag(tags[index])
                                        }
                                    }
                                }
                            }
                        }
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                        .padding(.horizontal, 16)
                        
                        // 底部提示
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.info)
                            
                            Text("这些标签会在创建或编辑课程时显示，方便快速选择")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(AppTheme.info.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("预设标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTag = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddTag) {
                AddPresetTagView(manager: manager, type: selectedType)
            }
            .sheet(item: $editingTag) { tag in
                EditPresetTagView(manager: manager, tag: tag)
            }
        }
    }
}

/// 添加预设标签视图
struct AddPresetTagView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: PresetTagManager
    let type: TagType
    
    @State private var name = ""
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 标题说明
                    VStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("添加\(type.displayName)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("为\(type.displayName)添加一个预设标签")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 32)
                    
                    // 输入卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("标签名称")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                        
                        TextField("请输入名称", text: $name)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(AppTheme.background)
                            .cornerRadius(8)
                            .focused($isNameFocused)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // 保存按钮
                    Button(action: saveTag) {
                        Text("保存")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                name.isEmpty ? AppTheme.textTertiary : Color.blue
                            )
                            .cornerRadius(12)
                    }
                    .disabled(name.isEmpty)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("添加预设标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear {
                isNameFocused = true
            }
        }
    }
    
    private func saveTag() {
        guard !name.isEmpty else { return }
        let tag = PresetTag(
            emoji: "",
            name: name,
            type: type.rawValue,
            order: manager.presetTags.count
        )
        manager.addPresetTag(tag)
        dismiss()
    }
}

/// 编辑预设标签视图
struct EditPresetTagView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: PresetTagManager
    let tag: PresetTag
    
    @State private var name: String
    @State private var showingSaveConfirmation = false
    @FocusState private var isNameFocused: Bool
    
    init(manager: PresetTagManager, tag: PresetTag) {
        self.manager = manager
        self.tag = tag
        _name = State(initialValue: tag.name)
    }
    
    private var hasNameChanged: Bool {
        return name != tag.name && !name.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.groupedBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 标题说明
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Text("编辑标签")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Text("修改标签的名称")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 32)
                    
                    // 输入卡片
                    VStack(alignment: .leading, spacing: 12) {
                        Text("标签名称")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                        
                        TextField("请输入名称", text: $name)
                            .font(.system(size: 17))
                            .padding(16)
                            .background(AppTheme.background)
                            .cornerRadius(8)
                            .focused($isNameFocused)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // 按钮组
                    VStack(spacing: 12) {
                        // 保存按钮
                        Button(action: {
                            if hasNameChanged {
                                showingSaveConfirmation = true
                            } else {
                                saveTag()
                            }
                        }) {
                            Text("保存")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    name.isEmpty ? AppTheme.textTertiary : Color.blue
                                )
                                .cornerRadius(12)
                        }
                        .disabled(name.isEmpty)
                        
                        // 删除按钮
                        Button(action: deleteTag) {
                            Text("删除标签")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppTheme.error)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppTheme.error.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("编辑预设标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .onAppear {
                isNameFocused = true
            }
            .alert("确认修改", isPresented: $showingSaveConfirmation) {
                Button("取消", role: .cancel) { }
                Button("确认") {
                    saveTag()
                }
            } message: {
                if let tagType = TagType(rawValue: tag.type) {
                    Text("修改标签名称后，所有使用「\(tag.name)」的课程都会自动更新为「\(name)」")
                }
            }
        }
    }
    
    private func saveTag() {
        guard !name.isEmpty else { return }
        var updatedTag = tag
        updatedTag.name = name
        manager.updatePresetTag(updatedTag)
        dismiss()
    }
    
    private func deleteTag() {
        manager.deletePresetTag(tag)
        dismiss()
    }
}

// MARK: - Preview

#Preview("预设标签列表") {
    PresetTagsView()
}

#Preview("添加标签") {
    AddPresetTagView(manager: PresetTagManager(), type: .className)
}

