//
//  DataManager.swift
//  QuittingTomorrow
//
//  数据持久化管理器
//

import Foundation
import Combine

/// 数据管理器 - 单例模式
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var pressureRecords: [PressureRecord] = []
    @Published var userProfile: UserProfile = UserProfile()
    @Published var todayClicks: [ClickEvent] = []
    
    private let recordsKey = "pressure_records"
    private let profileKey = "user_profile"
    private let todayClicksKey = "today_clicks"
    
    private init() {
        loadData()
    }
    
    // MARK: - 数据加载
    
    /// 加载所有数据
    func loadData() {
        loadPressureRecords()
        loadUserProfile()
        loadTodayClicks()
    }
    
    /// 加载压力记录
    private func loadPressureRecords() {
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let records = try? JSONDecoder().decode([PressureRecord].self, from: data) {
            pressureRecords = records
        }
    }
    
    /// 加载用户档案
    private func loadUserProfile() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
    }
    
    /// 加载今日点击记录
    private func loadTodayClicks() {
        let today = Calendar.current.startOfDay(for: Date())
        if let data = UserDefaults.standard.data(forKey: todayClicksKey),
           let clicks = try? JSONDecoder().decode([ClickEvent].self, from: data) {
            // 过滤掉非今日的点击
            todayClicks = clicks.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: today) }
        }
    }
    
    // MARK: - 数据保存
    
    /// 保存压力记录
    func savePressureRecords() {
        if let data = try? JSONEncoder().encode(pressureRecords) {
            UserDefaults.standard.set(data, forKey: recordsKey)
        }
    }
    
    /// 保存用户档案
    func saveUserProfile() {
        if let data = try? JSONEncoder().encode(userProfile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
    }
    
    /// 保存今日点击记录
    func saveTodayClicks() {
        if let data = try? JSONEncoder().encode(todayClicks) {
            UserDefaults.standard.set(data, forKey: todayClicksKey)
        }
    }
    
    // MARK: - 业务逻辑
    
    /// 添加一次点击
    func addClick() {
        let clickEvent = ClickEvent()
        todayClicks.append(clickEvent)
        saveTodayClicks()
        
        // 更新用户档案
        userProfile.totalClicks += 1
        saveUserProfile()
        
        // 检查情绪熔断机制
        checkEmotionalCircuitBreaker()
    }
    
    /// 获取今日点击数
    func getTodayClickCount() -> Int {
        return todayClicks.count
    }
    
    /// 获取今日压力等级
    func getTodayPressureLevel() -> PressureLevel {
        let count = getTodayClickCount()
        return PressureRecord.calculatePressureLevel(clickCount: count)
    }
    
    /// 计算压力密度（点击数/时间，单位：次/分钟）
    func calculateStressDensity() -> Double {
        guard todayClicks.count > 1 else { return 0.0 }
        
        let sortedClicks = todayClicks.sorted { $0.timestamp < $1.timestamp }
        guard let firstClick = sortedClicks.first,
              let lastClick = sortedClicks.last else { return 0.0 }
        
        let timeInterval = lastClick.timestamp.timeIntervalSince(firstClick.timestamp)
        let minutes = timeInterval / 60.0
        
        return minutes > 0 ? Double(todayClicks.count) / minutes : 0.0
    }
    
    /// 获取点击频率最高峰时间
    func getPeakTime() -> Date? {
        guard !todayClicks.isEmpty else { return nil }
        
        // 将时间分成10分钟窗口，找出点击最密集的窗口
        var windowCounts: [Date: Int] = [:]
        
        for click in todayClicks {
            let windowStart = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: click.timestamp),
                                                    minute: (Calendar.current.component(.minute, from: click.timestamp) / 10) * 10,
                                                    second: 0,
                                                    of: click.timestamp) ?? click.timestamp
            
            windowCounts[windowStart, default: 0] += 1
        }
        
        return windowCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /// 情绪熔断机制：如果5分钟内点击过千，触发熔断
    func checkEmotionalCircuitBreaker() {
        guard todayClicks.count >= 1000 else { return }
        
        let recentClicks = todayClicks.suffix(1000)
        guard let firstRecent = recentClicks.first else { return }
        
        let timeInterval = Date().timeIntervalSince(firstRecent.timestamp)
        let minutes = timeInterval / 60.0
        
        if minutes <= 5.0 {
            // 触发熔断
            NotificationCenter.default.post(name: .emotionalCircuitBreaker, object: nil)
        }
    }
    
    /// 凌晨结算：将今日数据转化为压力记录
    func settleDailyRecord() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // 检查是否已经结算过
        if let existingRecord = pressureRecords.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // 更新现有记录
            if let index = pressureRecords.firstIndex(where: { $0.id == existingRecord.id }) {
                pressureRecords[index].clickCount = todayClicks.count
                pressureRecords[index].pressureLevel = getTodayPressureLevel()
                pressureRecords[index].stressDensity = calculateStressDensity()
                pressureRecords[index].peakTime = getPeakTime()
            }
        } else {
            // 创建新记录
            let record = PressureRecord(
                date: today,
                clickCount: todayClicks.count,
                pressureLevel: getTodayPressureLevel(),
                peakTime: getPeakTime(),
                stressDensity: calculateStressDensity()
            )
            pressureRecords.append(record)
        }
        
        savePressureRecords()
        
        // 清空今日点击记录（准备新的一天）
        todayClicks.removeAll()
        saveTodayClicks()
        
        // 更新用户档案
        userProfile.updateStreak()
        userProfile.totalDaysUsed += 1
        checkAchievements()
        saveUserProfile()
    }
    
    /// 检查并解锁勋章
    func checkAchievements() {
        // 检查连续使用天数
        if userProfile.currentStreak >= 7 {
            userProfile.unlockAchievement(.workplaceNinja)
        }
        if userProfile.currentStreak >= 30 {
            userProfile.unlockAchievement(.survivor)
        }
        
        // 检查单日点击数
        if let todayRecord = getTodayRecord(), todayRecord.clickCount >= 500 {
            userProfile.unlockAchievement(.pptTerminator)
        }
        
        // 检查连续平静天数
        let recentRecords = getRecentRecords(days: 3)
        if recentRecords.count == 3 && recentRecords.allSatisfy({ $0.pressureLevel == .calm }) {
            userProfile.unlockAchievement(.zenMaster)
        }
        
        // 检查单次连续点击（在checkEmotionalCircuitBreaker中处理）
        if todayClicks.count >= 1000 {
            userProfile.unlockAchievement(.volcano)
        }
        
        saveUserProfile()
    }
    
    /// 获取今日记录
    func getTodayRecord() -> PressureRecord? {
        let today = Calendar.current.startOfDay(for: Date())
        return pressureRecords.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }
    
    /// 获取最近N天的记录
    func getRecentRecords(days: Int) -> [PressureRecord] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        return pressureRecords.filter { record in
            record.date >= startDate && record.date <= endDate
        }.sorted { $0.date > $1.date }
    }
    
    /// 获取月度记录
    func getMonthlyRecords(month: Int, year: Int) -> [PressureRecord] {
        return pressureRecords.filter { record in
            let components = Calendar.current.dateComponents([.year, .month], from: record.date)
            return components.year == year && components.month == month
        }.sorted { $0.date < $1.date }
    }
    
    /// 获取季度记录
    func getQuarterlyRecords(quarter: Int, year: Int) -> [PressureRecord] {
        let startMonth = (quarter - 1) * 3 + 1
        let endMonth = quarter * 3
        
        return pressureRecords.filter { record in
            let components = Calendar.current.dateComponents([.year, .month], from: record.date)
            guard let recordYear = components.year, let month = components.month else { return false }
            return recordYear == year && month >= startMonth && month <= endMonth
        }.sorted { $0.date < $1.date }
    }
    
    /// 获取年度记录
    func getYearlyRecords(year: Int) -> [PressureRecord] {
        return pressureRecords.filter { record in
            Calendar.current.component(.year, from: record.date) == year
        }.sorted { $0.date < $1.date }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let emotionalCircuitBreaker = Notification.Name("emotionalCircuitBreaker")
}

