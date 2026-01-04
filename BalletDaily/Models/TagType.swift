//
//  TagType.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  标签类型枚举定义
//

import Foundation

/// 标签类型
enum TagType: String, CaseIterable {
    case className = "className"       // 课程名称
    case instructor = "instructor"     // 老师姓名
    case location = "location"         // 上课地点
    
    /// 显示名称（中文）
    var displayName: String {
        switch self {
        case .className:
            return "课程名称"
        case .instructor:
            return "老师"
        case .location:
            return "地点"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .className:
            return "text.bubble"
        case .instructor:
            return "person"
        case .location:
            return "location"
        }
    }
}

