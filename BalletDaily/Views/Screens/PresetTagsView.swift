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
    @StateObject private var manager = PresetTagManager()
    @State private var showingAddTag = false
    @State private var selectedType: TagType = .className
    @State private var editingTag: PresetTag?
    
    var body: some View {
        NavigationStack {
            List {
                // 类型选择器
                Section {
                    Picker("标签类型", selection: $selectedType) {
                        Text("课程名称").tag(TagType.className)
                        Text("老师").tag(TagType.instructor)
                        Text("地点").tag(TagType.location)
                    }
                    .pickerStyle(.segmented)
                }
                
                // 标签列表
                Section {
                    let tags = manager.getPresetTags(for: selectedType.rawValue)
                    
                    if tags.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "tag")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("还没有预设标签")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            Spacer()
                        }
                    } else {
                        ForEach(tags) { tag in
                            HStack(spacing: 12) {
                                Text(tag.emoji)
                                    .font(.title2)
                                
                                Text(tag.name)
                                    .font(.body)
                                
                                Spacer()
                                
                                Button {
                                    editingTag = tag
                                } label: {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                manager.deletePresetTag(tags[index])
                            }
                        }
                        .onMove { from, to in
                            var updatedTags = tags
                            updatedTags.move(fromOffsets: from, toOffset: to)
                            manager.reorder(updatedTags)
                        }
                    }
                } header: {
                    Text(selectedType.displayName)
                } footer: {
                    Text("💡 提示：这些标签会在创建或编辑课程时显示，方便快速选择。")
                }
            }
            .navigationTitle("预设标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTag = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
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
    
    @State private var emoji = "🩰"
    @State private var name = ""
    @State private var showingEmojiPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Emoji 选择
                    Button {
                        showingEmojiPicker = true
                    } label: {
                        HStack {
                            Text("图标")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(emoji)
                                .font(.largeTitle)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 名称输入
                    TextField("标签名称", text: $name)
                } header: {
                    Text("标签信息")
                } footer: {
                    Text("为 \(type.displayName) 添加一个预设标签")
                }
            }
            .navigationTitle("添加预设标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }
    
    private func saveTag() {
        let tag = PresetTag(
            emoji: emoji,
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
    
    @State private var emoji: String
    @State private var name: String
    @State private var showingEmojiPicker = false
    
    init(manager: PresetTagManager, tag: PresetTag) {
        self.manager = manager
        self.tag = tag
        _emoji = State(initialValue: tag.emoji)
        _name = State(initialValue: tag.name)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Emoji 选择
                    Button {
                        showingEmojiPicker = true
                    } label: {
                        HStack {
                            Text("图标")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(emoji)
                                .font(.largeTitle)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // 名称输入
                    TextField("标签名称", text: $name)
                } header: {
                    Text("标签信息")
                }
            }
            .navigationTitle("编辑预设标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveTag()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
            }
        }
    }
    
    private func saveTag() {
        var updatedTag = tag
        updatedTag.emoji = emoji
        updatedTag.name = name
        manager.updatePresetTag(updatedTag)
        dismiss()
    }
}

/// Emoji 选择器视图
struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String
    
    // 常用 Emoji 分类
    let emojiCategories: [(String, [String])] = [
        ("舞蹈", ["🩰", "💃", "🕺", "🎭", "🎨", "🌟", "✨", "💫"]),
        ("人物", ["👨‍🏫", "👩‍🏫", "👨‍🎓", "👩‍🎓", "🧑‍🎓", "👤", "👥", "👫"]),
        ("地点", ["🏛️", "🏢", "🏠", "🏫", "🏟️", "🎪", "🏰", "🗼"]),
        ("时间", ["⏰", "⏱️", "⌚", "📅", "📆", "🗓️", "📋", "📝"]),
        ("心情", ["😊", "😃", "🥰", "😍", "🤩", "😎", "🤗", "😌"]),
        ("符号", ["⭐", "🌟", "✨", "💫", "🔥", "💪", "👍", "❤️"]),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24, pinnedViews: [.sectionHeaders]) {
                    ForEach(emojiCategories, id: \.0) { category in
                        Section {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 16) {
                                ForEach(category.1, id: \.self) { emoji in
                                    Button {
                                        selectedEmoji = emoji
                                        dismiss()
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 40))
                                            .frame(width: 50, height: 50)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } header: {
                            Text(category.0)
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.systemGroupedBackground))
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("预设标签列表") {
    PresetTagsView()
}

#Preview("添加标签") {
    AddPresetTagView(manager: PresetTagManager(), type: .className)
}

#Preview("Emoji 选择器") {
    EmojiPickerView(selectedEmoji: .constant("🩰"))
}

