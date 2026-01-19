//
//  PressureRecord.swift
//  QuittingTomorrow
//
//  压力记录数据模型
//

import Foundation

/// 压力等级枚举
enum PressureLevel: Int, Codable, CaseIterable {
    case calm = 0        // 平静
    case mild = 1        // 微烦 (1-50次)
    case moderate = 2    // 忍耐 (51-200次)
    case severe = 3      // 爆发 (201+次)
    
    var displayName: String {
        switch self {
        case .calm: return "平静"
        case .mild: return "微烦"
        case .moderate: return "忍耐"
        case .severe: return "爆发"
        }
    }
    
    var colorHex: String {
        switch self {
        case .calm: return "#E8E8E8"      // 灰色
        case .mild: return "#4A90E2"      // 淡蓝色
        case .moderate: return "#F5A623"  // 橙色
        case .severe: return "#D0021B"    // 血红色
        }
    }
}

/// 压力记录模型
struct PressureRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    var clickCount: Int
    var pressureLevel: PressureLevel
    var peakTime: Date?              // 点击频率最高峰时间
    var stressDensity: Double        // 压力密度（点击数/时间）
    var aiAnalysis: AIAnalysis?      // AI分析结果
    var userNotes: String?           // 用户补充文本
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         clickCount: Int = 0, 
         pressureLevel: PressureLevel = .calm,
         peakTime: Date? = nil,
         stressDensity: Double = 0.0,
         aiAnalysis: AIAnalysis? = nil,
         userNotes: String? = nil) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.clickCount = clickCount
        self.pressureLevel = pressureLevel
        self.peakTime = peakTime
        self.stressDensity = stressDensity
        self.aiAnalysis = aiAnalysis
        self.userNotes = userNotes
    }
    
    /// 根据点击数计算压力等级
    static func calculatePressureLevel(clickCount: Int) -> PressureLevel {
        switch clickCount {
        case 0: return .calm
        case 1...50: return .mild
        case 51...200: return .moderate
        default: return .severe
        }
    }
}

/// AI分析结果模型
struct AIAnalysis: Codable {
    let timestamp: Date
    let pressureType: String          // "急性应激" 或 "慢性内耗"
    let resignationIndex: Int         // 辞职倾向指数 (0-100)
    let insight: String               // 反直觉洞察
    let quote: String                 // 本周金句
    let stressFactors: [StressFactor] // 致郁因子分析
    
    init(timestamp: Date = Date(),
         pressureType: String = "",
         resignationIndex: Int = 0,
         insight: String = "",
         quote: String = "",
         stressFactors: [StressFactor] = []) {
        self.timestamp = timestamp
        self.pressureType = pressureType
        self.resignationIndex = resignationIndex
        self.insight = insight
        self.quote = quote
        self.stressFactors = stressFactors
    }
}

/// 压力因子模型
struct StressFactor: Codable, Identifiable {
    let id: UUID
    let name: String      // 如："老板"、"加班"、"通勤"
    let percentage: Double
    
    init(id: UUID = UUID(), name: String, percentage: Double) {
        self.id = id
        self.name = name
        self.percentage = percentage
    }
}

/// 点击事件模型（用于实时追踪）
struct ClickEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    
    init(id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.timestamp = timestamp
    }
}

