//
//  PresetTag.swift
//  BalletDaily
//
//  Created on 2026/1/4
//  预设标签模型
//

import Foundation
import Combine

/// 预设标签
struct PresetTag: Identifiable, Codable, Equatable {
    let id: UUID
    var emoji: String
    var name: String
    var type: String // TagType.rawValue
    var order: Int
    var isEnabled: Bool
    var isPlaceholder: Bool // 是否为占位符（用户未使用过的虚拟数据）
    
    init(id: UUID = UUID(), emoji: String, name: String, type: String, order: Int = 0, isEnabled: Bool = true, isPlaceholder: Bool = false) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.type = type
        self.order = order
        self.isEnabled = isEnabled
        self.isPlaceholder = isPlaceholder
    }
}

/// 预设标签管理器
class PresetTagManager: ObservableObject {
    @Published var presetTags: [PresetTag] = []
    
    private let userDefaultsKey = "PresetTags"
    private var tagService: TagService?
    
    init(tagService: TagService? = nil) {
        self.tagService = tagService
        loadPresetTags()
    }
    
    /// 加载预设标签
    func loadPresetTags() {
        // 首先尝试从 UserDefaults 加载已有的预设标签
        var existingTags: [PresetTag] = []
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let tags = try? JSONDecoder().decode([PresetTag].self, from: data) {
            existingTags = tags
        }
        
        // 如果有 tagService，从数据库加载用户真实数据并合并
        if let tagService = tagService {
            presetTags = mergeWithUserData(existingTags: existingTags, tagService: tagService)
        } else if !existingTags.isEmpty {
            // 没有 tagService，但有已保存的标签，直接使用
            presetTags = existingTags.sorted { $0.order < $1.order }
        } else {
            // 都没有，生成初始标签
            presetTags = generateInitialTags()
        }
        
        savePresetTags()
    }
    
    /// 合并已有预设标签和用户真实数据
    private func mergeWithUserData(existingTags: [PresetTag], tagService: TagService) -> [PresetTag] {
        var mergedTags: [PresetTag] = []
        var order = 0
        
        // 获取用户数据库中的标签值
        let classNames = Set(tagService.getSuggestions(for: TagType.className.rawValue, limit: 50))
        let instructors = Set(tagService.getSuggestions(for: TagType.instructor.rawValue, limit: 50))
        let locations = Set(tagService.getSuggestions(for: TagType.location.rawValue, limit: 50))
        
        // 处理课程名称标签
        var processedClassNames = Set<String>()
        
        // 保留已有的课程标签（如果在用户数据中存在）
        for tag in existingTags.filter({ $0.type == TagType.className.rawValue }) {
            if classNames.contains(tag.name) {
                var updatedTag = tag
                updatedTag.order = order
                updatedTag.isPlaceholder = false // 标记为非占位符
                mergedTags.append(updatedTag)
                processedClassNames.insert(tag.name)
                order += 1
            }
        }
        
        // 添加新的课程名称（不在已有标签中的）
        for name in classNames.sorted() {
            if !processedClassNames.contains(name) {
                mergedTags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.className.rawValue,
                    order: order,
                    isPlaceholder: false
                ))
                order += 1
            }
        }
        
        // 处理老师标签
        var processedInstructors = Set<String>()
        
        for tag in existingTags.filter({ $0.type == TagType.instructor.rawValue }) {
            if instructors.contains(tag.name) {
                var updatedTag = tag
                updatedTag.order = order
                updatedTag.isPlaceholder = false
                mergedTags.append(updatedTag)
                processedInstructors.insert(tag.name)
                order += 1
            }
        }
        
        for name in instructors.sorted() {
            if !processedInstructors.contains(name) {
                mergedTags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.instructor.rawValue,
                    order: order,
                    isPlaceholder: false
                ))
                order += 1
            }
        }
        
        // 处理地点标签
        var processedLocations = Set<String>()
        
        for tag in existingTags.filter({ $0.type == TagType.location.rawValue }) {
            if locations.contains(tag.name) {
                var updatedTag = tag
                updatedTag.order = order
                updatedTag.isPlaceholder = false
                mergedTags.append(updatedTag)
                processedLocations.insert(tag.name)
                order += 1
            }
        }
        
        for name in locations.sorted() {
            if !processedLocations.contains(name) {
                mergedTags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.location.rawValue,
                    order: order,
                    isPlaceholder: false
                ))
                order += 1
            }
        }
        
        // 如果没有任何真实数据，添加占位符
        if mergedTags.filter({ $0.type == TagType.className.rawValue }).isEmpty {
            let placeholderClasses = ["芭蕾基础", "芭蕾进阶", "芭蕾表演"]
            for name in placeholderClasses {
                mergedTags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.className.rawValue,
                    order: order,
                    isPlaceholder: true
                ))
                order += 1
            }
        }
        
        if mergedTags.filter({ $0.type == TagType.instructor.rawValue }).isEmpty {
            let placeholderInstructors = ["张老师", "李老师"]
            for name in placeholderInstructors {
                mergedTags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.instructor.rawValue,
                    order: order,
                    isPlaceholder: true
                ))
                order += 1
            }
        }
        
        if mergedTags.filter({ $0.type == TagType.location.rawValue }).isEmpty {
            let placeholderLocations = ["舞蹈学院", "舞蹈工作室"]
            for name in placeholderLocations {
                mergedTags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.location.rawValue,
                    order: order,
                    isPlaceholder: true
                ))
                order += 1
            }
        }
        
        return mergedTags
    }
    
    /// 保存预设标签
    func savePresetTags() {
        if let data = try? JSONEncoder().encode(presetTags) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    /// 添加预设标签
    func addPresetTag(_ tag: PresetTag) {
        presetTags.append(tag)
        savePresetTags()
    }
    
    /// 更新预设标签
    func updatePresetTag(_ tag: PresetTag) {
        if let index = presetTags.firstIndex(where: { $0.id == tag.id }) {
            let oldTag = presetTags[index]
            var updatedTag = tag
            
            // 如果是占位符标签被编辑，将其标记为非占位符
            if tag.isPlaceholder {
                updatedTag.isPlaceholder = false
            }
            
            // 如果标签名称发生了变化，执行级联更新
            if oldTag.name != updatedTag.name, let tagService = tagService {
                if let tagType = TagType(rawValue: updatedTag.type) {
                    tagService.updateTagValue(
                        type: tagType,
                        oldValue: oldTag.name,
                        newValue: updatedTag.name
                    )
                    print("🔄 级联更新: \"\(oldTag.name)\" → \"\(updatedTag.name)\"")
                }
            }
            
            presetTags[index] = updatedTag
            savePresetTags()
        }
    }
    
    /// 删除预设标签
    func deletePresetTag(_ tag: PresetTag) {
        presetTags.removeAll { $0.id == tag.id }
        savePresetTags()
    }
    
    /// 获取指定类型的预设标签
    func getPresetTags(for type: String) -> [PresetTag] {
        return presetTags.filter { $0.type == type && $0.isEnabled }
    }
    
    /// 重新排序
    func reorder(_ tags: [PresetTag]) {
        for (index, tag) in tags.enumerated() {
            if let originalIndex = presetTags.firstIndex(where: { $0.id == tag.id }) {
                presetTags[originalIndex].order = index
            }
        }
        presetTags.sort { $0.order < $1.order }
        savePresetTags()
    }
    
    /// 生成初始标签（优先使用用户真实数据，否则使用占位符）
    private func generateInitialTags() -> [PresetTag] {
        var tags: [PresetTag] = []
        var order = 0
        
        // 如果有 tagService，从用户真实数据生成
        if let tagService = tagService {
            // 课程名称 - 获取用户最常用的前10个
            let classNames = tagService.getSuggestions(for: TagType.className.rawValue, limit: 10)
            for name in classNames {
                tags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.className.rawValue,
                    order: order,
                    isPlaceholder: false
                ))
                order += 1
            }
            
            // 老师 - 获取用户最常用的前10个
            let instructors = tagService.getSuggestions(for: TagType.instructor.rawValue, limit: 10)
            for name in instructors {
                tags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.instructor.rawValue,
                    order: order,
                    isPlaceholder: false
                ))
                order += 1
            }
            
            // 地点 - 获取用户最常用的前10个
            let locations = tagService.getSuggestions(for: TagType.location.rawValue, limit: 10)
            for name in locations {
                tags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.location.rawValue,
                    order: order,
                    isPlaceholder: false
                ))
                order += 1
            }
        }
        
        // 如果没有真实数据，添加占位符标签（浅色显示）
        if tags.filter({ $0.type == TagType.className.rawValue }).isEmpty {
            let placeholderClasses = ["芭蕾基础", "芭蕾进阶", "芭蕾表演"]
            for name in placeholderClasses {
                tags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.className.rawValue,
                    order: order,
                    isPlaceholder: true
                ))
                order += 1
            }
        }
        
        if tags.filter({ $0.type == TagType.instructor.rawValue }).isEmpty {
            let placeholderInstructors = ["张老师", "李老师"]
            for name in placeholderInstructors {
                tags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.instructor.rawValue,
                    order: order,
                    isPlaceholder: true
                ))
                order += 1
            }
        }
        
        if tags.filter({ $0.type == TagType.location.rawValue }).isEmpty {
            let placeholderLocations = ["舞蹈学院", "舞蹈工作室"]
            for name in placeholderLocations {
                tags.append(PresetTag(
                    emoji: "",
                    name: name,
                    type: TagType.location.rawValue,
                    order: order,
                    isPlaceholder: true
                ))
                order += 1
            }
        }
        
        return tags
    }
}

