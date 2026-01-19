//
//  SettlementService.swift
//  QuittingTomorrow
//
//  凌晨结算服务 - 负责在凌晨3-4点自动结算数据
//

import Foundation
import UserNotifications
import BackgroundTasks

/// 结算服务 - 单例模式
class SettlementService {
    static let shared = SettlementService()
    
    private let settlementTaskIdentifier = "com.quittingtomorrow.settlement"
    
    private init() {}
    
    /// 注册后台任务
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: settlementTaskIdentifier, using: nil) { task in
            self.handleSettlementTask(task: task as! BGProcessingTask)
        }
    }
    
    /// 安排凌晨结算任务（3:00-4:00之间）
    func scheduleSettlement() {
        let request = BGProcessingTaskRequest(identifier: settlementTaskIdentifier)
        
        // 计算下次凌晨3点的时间
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 3
        components.minute = 0
        
        var nextSettlementDate = calendar.date(from: components) ?? Date()
        
        // 如果今天已经过了3点，设置为明天
        if nextSettlementDate <= Date() {
            nextSettlementDate = calendar.date(byAdding: .day, value: 1, to: nextSettlementDate) ?? Date()
        }
        
        // 设置最早执行时间为凌晨3点，最晚为凌晨4点
        request.earliestBeginDate = nextSettlementDate
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ 已安排凌晨结算任务：\(nextSettlementDate)")
        } catch {
            print("❌ 安排结算任务失败：\(error)")
        }
    }
    
    /// 处理结算任务
    private func handleSettlementTask(task: BGProcessingTask) {
        // 设置任务过期处理
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // 执行结算
        Task {
            await performSettlement()
            
            // 安排下一次结算
            scheduleSettlement()
            
            task.setTaskCompleted(success: true)
        }
    }
    
    /// 执行结算逻辑
    @MainActor
    private func performSettlement() async {
        let dataManager = DataManager.shared
        
        // 结算昨日记录
        dataManager.settleDailyRecord()
        
        // 如果有AI分析需求，可以在这里触发
        if let yesterdayRecord = getYesterdayRecord() {
            // 异步分析，不阻塞结算流程
            Task {
                do {
                    let analysis = try await AIService.shared.analyzePressureState(record: yesterdayRecord)
                    
                    // 更新记录
                    if let index = dataManager.pressureRecords.firstIndex(where: { $0.id == yesterdayRecord.id }) {
                        dataManager.pressureRecords[index].aiAnalysis = analysis
                        dataManager.savePressureRecords()
                    }
                } catch {
                    print("AI分析失败：\(error)")
                }
            }
        }
        
        print("✅ 凌晨结算完成")
    }
    
    /// 获取昨日记录
    private func getYesterdayRecord() -> PressureRecord? {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        return DataManager.shared.pressureRecords.first { record in
            calendar.isDate(record.date, inSameDayAs: yesterday)
        }
    }
    
    /// 手动触发结算（用于测试或用户主动触发）
    @MainActor
    func manualSettlement() async {
        await performSettlement()
    }
}

