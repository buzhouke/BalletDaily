import SwiftUI

/// 应用主题配色系统
/// 符合"安静不打扰"的设计原则，使用柔和的色调
struct AppTheme {
    
    // MARK: - 主色调
    
    /// 主色调 - 优雅的芭蕾粉
    /// 用于主要按钮、强调元素
    static let primary = Color("PrimaryColor")
    
    /// 次要色 - 柔和的灰蓝
    /// 用于次要信息、辅助元素
    static let secondary = Color("SecondaryColor")
    
    // MARK: - 背景色
    
    /// 主背景色
    static let background = Color("BackgroundColor")
    
    /// 卡片背景色
    static let cardBackground = Color("CardBackgroundColor")
    
    /// 分组背景色（用于 Form）
    static let groupedBackground = Color("GroupedBackgroundColor")
    
    // MARK: - 文字颜色
    
    /// 主要文字颜色
    static let textPrimary = Color.primary
    
    /// 次要文字颜色
    static let textSecondary = Color.secondary
    
    /// 提示文字颜色
    static let textTertiary = Color("TextTertiaryColor")
    
    // MARK: - 功能色（降低饱和度，柔和处理）
    
    /// 成功/正向色
    static let success = Color("SuccessColor")
    
    /// 警告色
    static let warning = Color("WarningColor")
    
    /// 错误/危险色
    static let error = Color("ErrorColor")
    
    /// 信息提示色
    static let info = Color("InfoColor")
    
    // MARK: - 笔记类型颜色
    
    /// 一般笔记
    static let noteGeneral = Color.gray
    
    /// 课后感想
    static let noteFeeling = Color("FeelingColor")
    
    /// 技术要点
    static let noteTechnique = Color("TechniqueColor")
    
    /// 需要改进
    static let noteImprovement = Color("ImprovementColor")
    
    /// 突破成就
    static let noteAchievement = Color("AchievementColor")
    
    /// 音乐相关
    static let noteMusic = Color("MusicColor")
    
    // MARK: - 图表颜色
    
    /// 图表主色
    static let chartPrimary = primary
    
    /// 图表次要色
    static let chartSecondary = secondary
    
    /// 图表渐变起始色
    static let chartGradientStart = primary.opacity(0.8)
    
    /// 图表渐变结束色
    static let chartGradientEnd = primary.opacity(0.2)
}

// MARK: - 预设颜色值（用于在 Assets.xcassets 中配置）

/*
 颜色配置参考（浅色模式 / 深色模式）：
 
 PrimaryColor: #C4969E / #D4A6AE
 SecondaryColor: #8B9EB7 / #9BAEC7
 
 BackgroundColor: #F8F9FA / #1C1C1E
 CardBackgroundColor: #FFFFFF / #2C2C2E
 GroupedBackgroundColor: #F2F2F7 / #000000
 
 TextTertiaryColor: #8E8E93 / #8E8E93
 
 SuccessColor: #A8C5A8 / #B8D5B8
 WarningColor: #E8C4A0 / #F8D4B0
 ErrorColor: #D8A0A0 / #E8B0B0
 InfoColor: #A8B8D8 / #B8C8E8
 
 笔记类型颜色：
 FeelingColor: #E8B4C4 / #F8C4D4（温暖的粉色）
 TechniqueColor: #A4B8D8 / #B4C8E8（专业的蓝色）
 ImprovementColor: #E8C8A8 / #F8D8B8（积极的橙色）
 AchievementColor: #E8D8A8 / #F8E8B8（喜悦的金色）
 MusicColor: #C8B8D8 / #D8C8E8（优雅的紫色）
 */

// MARK: - 颜色扩展工具

extension Color {
    /// 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - 主题预览

#Preview("主题色板") {
    ScrollView {
        VStack(spacing: 20) {
            // 主色调
            VStack(alignment: .leading, spacing: 8) {
                Text("主色调")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ColorSwatch(color: AppTheme.primary, name: "Primary")
                    ColorSwatch(color: AppTheme.secondary, name: "Secondary")
                }
            }
            
            // 背景色
            VStack(alignment: .leading, spacing: 8) {
                Text("背景色")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ColorSwatch(color: AppTheme.background, name: "Background")
                    ColorSwatch(color: AppTheme.cardBackground, name: "Card")
                    ColorSwatch(color: AppTheme.groupedBackground, name: "Grouped")
                }
            }
            
            // 功能色
            VStack(alignment: .leading, spacing: 8) {
                Text("功能色")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    ColorSwatch(color: AppTheme.success, name: "Success")
                    ColorSwatch(color: AppTheme.warning, name: "Warning")
                }
                HStack(spacing: 12) {
                    ColorSwatch(color: AppTheme.error, name: "Error")
                    ColorSwatch(color: AppTheme.info, name: "Info")
                }
            }
            
            // 笔记类型颜色
            VStack(alignment: .leading, spacing: 8) {
                Text("笔记类型")
                    .font(.headline)
                
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        ColorSwatch(color: AppTheme.noteFeeling, name: "感想")
                        ColorSwatch(color: AppTheme.noteTechnique, name: "技术")
                    }
                    HStack(spacing: 12) {
                        ColorSwatch(color: AppTheme.noteImprovement, name: "改进")
                        ColorSwatch(color: AppTheme.noteAchievement, name: "成就")
                    }
                    HStack(spacing: 12) {
                        ColorSwatch(color: AppTheme.noteMusic, name: "音乐")
                        ColorSwatch(color: AppTheme.noteGeneral, name: "一般")
                    }
                }
            }
        }
        .padding()
    }
}

// 颜色样本视图（用于预览）
private struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 60)
            
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

