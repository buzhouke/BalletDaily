//
//  NoteType.swift
//  BalletDaily
//
//  Created on 2026/1/1
//  笔记类型枚举定义
//

import Foundation
import SwiftUI

/// 笔记类型
enum NoteType: String, CaseIterable {
    case general = "general"           // 一般笔记
    case feeling = "feeling"           // 课后感想
    case technique = "technique"       // 技术要点
    case improvement = "improvement"   // 需要改进
    case achievement = "achievement"   // 突破成就
    case music = "music"               // 音乐相关
    
    /// 显示名称（中文）
    var displayName: String {
        switch self {
        case .general:
            return "随笔"
        case .feeling:
            return "课后感想"
        case .technique:
            return "技术要点"
        case .improvement:
            return "需要改进"
        case .achievement:
            return "突破成就"
        case .music:
            return "音乐相关"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .general:
            return "note.text"
        case .feeling:
            return "heart.text.square"
        case .technique:
            return "star.circle"
        case .improvement:
            return "arrow.up.circle"
        case .achievement:
            return "trophy"
        case .music:
            return "music.note"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .general:
            return AppTheme.noteGeneral
        case .feeling:
            return AppTheme.noteFeeling
        case .technique:
            return AppTheme.noteTechnique
        case .improvement:
            return AppTheme.noteImprovement
        case .achievement:
            return AppTheme.noteAchievement
        case .music:
            return AppTheme.noteMusic
        }
    }
}

