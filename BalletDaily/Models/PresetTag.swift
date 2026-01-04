//
//  PresetTag.swift
//  BalletDaily
//
//  Created on 2026/1/4
//  预设标签模型
//

import Foundation

/// 预设标签
struct PresetTag: Identifiable, Codable, Equatable {
    let id: UUID
    var emoji: String
    var name: String
    var type: String // TagType.rawValue
    var order: Int
    var isEnabled: Bool
    
    init(id: UUID = UUID(), emoji: String, name: String, type: String, order: Int = 0, isEnabled: Bool = true) {
        self.id = id
        self.emoji = emoji
        self.name = name
        self.type = type
        self.order = order
        self.isEnabled = isEnabled
    }
}

/// 预设标签管理器
class PresetTagManager: ObservableObject {
    @Published var presetTags: [PresetTag] = []
    
    private let userDefaultsKey = "PresetTags"
    
    init() {
        loadPresetTags()
    }
    
    /// 加载预设标签
    func loadPresetTags() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let tags = try? JSONDecoder().decode([PresetTag].self, from: data) {
            presetTags = tags.sorted { $0.order < $1.order }
        } else {
            // 初始化默认标签
            presetTags = defaultPresetTags()
            savePresetTags()
        }
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
            presetTags[index] = tag
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
    
    /// 默认预设标签
    private func defaultPresetTags() -> [PresetTag] {
        return [
            // 课程名称
            PresetTag(emoji: "🩰", name: "芭蕾基础", type: TagType.className.rawValue, order: 0),
            PresetTag(emoji: "💃", name: "芭蕾进阶", type: TagType.className.rawValue, order: 1),
            PresetTag(emoji: "🎭", name: "芭蕾表演", type: TagType.className.rawValue, order: 2),
            PresetTag(emoji: "🎨", name: "芭蕾编舞", type: TagType.className.rawValue, order: 3),
            PresetTag(emoji: "🌟", name: "芭蕾大师课", type: TagType.className.rawValue, order: 4),
            
            // 老师
            PresetTag(emoji: "👨‍🏫", name: "张老师", type: TagType.instructor.rawValue, order: 5),
            PresetTag(emoji: "👩‍🏫", name: "李老师", type: TagType.instructor.rawValue, order: 6),
            
            // 地点
            PresetTag(emoji: "🏛️", name: "北京舞蹈学院", type: TagType.location.rawValue, order: 7),
            PresetTag(emoji: "🏢", name: "舞蹈工作室", type: TagType.location.rawValue, order: 8),
            PresetTag(emoji: "🏠", name: "家", type: TagType.location.rawValue, order: 9),
        ]
    }
}

