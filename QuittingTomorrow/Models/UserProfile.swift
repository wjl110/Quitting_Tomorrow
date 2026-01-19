//
//  UserProfile.swift
//  QuittingTomorrow
//
//  用户档案数据模型
//

import Foundation

/// 用户勋章枚举
enum Achievement: String, Codable, CaseIterable {
    case workplaceNinja = "职场忍者"        // 连续7天使用
    case pptTerminator = "PPT终结者"       // 单日点击超过500次
    case midnightComrade = "凌晨三点的战友"  // 在凌晨3-4点使用过
    case survivor = "职场幸存者"            // 连续30天使用
    case zenMaster = "禅意大师"            // 连续3天平静状态
    case volcano = "火山爆发"              // 单次连续点击超过1000次
    
    var description: String {
        switch self {
        case .workplaceNinja: return "连续7天记录压力，你是真正的职场忍者！"
        case .pptTerminator: return "单日点击超过500次，PPT已经无法伤害你了！"
        case .midnightComrade: return "凌晨3点的战友，我们懂你的痛！"
        case .survivor: return "连续30天记录，你是真正的职场幸存者！"
        case .zenMaster: return "连续3天保持平静，你已经达到禅意境界！"
        case .volcano: return "单次连续点击超过1000次，火山爆发也不过如此！"
        }
    }
    
    var iconName: String {
        switch self {
        case .workplaceNinja: return "figure.martial.arts"
        case .pptTerminator: return "doc.text.fill"
        case .midnightComrade: return "moon.stars.fill"
        case .survivor: return "shield.fill"
        case .zenMaster: return "leaf.fill"
        case .volcano: return "flame.fill"
        }
    }
}

/// 用户档案模型
struct UserProfile: Codable {
    var achievements: [Achievement]
    var totalDaysUsed: Int
    var totalClicks: Int
    var longestStreak: Int              // 最长连续使用天数
    var currentStreak: Int              // 当前连续使用天数
    var lastActiveDate: Date?
    var resumeBackupDate: Date?         // 简历备份日期
    var hasResumeBackup: Bool
    
    init(achievements: [Achievement] = [],
         totalDaysUsed: Int = 0,
         totalClicks: Int = 0,
         longestStreak: Int = 0,
         currentStreak: Int = 0,
         lastActiveDate: Date? = nil,
         resumeBackupDate: Date? = nil,
         hasResumeBackup: Bool = false) {
        self.achievements = achievements
        self.totalDaysUsed = totalDaysUsed
        self.totalClicks = totalClicks
        self.longestStreak = longestStreak
        self.currentStreak = currentStreak
        self.lastActiveDate = lastActiveDate
        self.resumeBackupDate = resumeBackupDate
        self.hasResumeBackup = hasResumeBackup
    }
    
    /// 解锁新勋章
    mutating func unlockAchievement(_ achievement: Achievement) {
        if !achievements.contains(achievement) {
            achievements.append(achievement)
        }
    }
    
    /// 检查并更新连续使用天数
    mutating func updateStreak() {
        guard let lastDate = lastActiveDate else {
            currentStreak = 1
            lastActiveDate = Date()
            return
        }
        
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        
        if daysSince == 1 {
            // 连续使用
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        } else if daysSince == 0 {
            // 同一天，不更新
            return
        } else {
            // 中断了
            currentStreak = 1
        }
        
        lastActiveDate = Date()
    }
}

