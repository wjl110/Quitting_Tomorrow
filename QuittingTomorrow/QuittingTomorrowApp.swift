//
//  QuittingTomorrowApp.swift
//  QuittingTomorrow
//
//  App 主入口
//

import SwiftUI

@main
struct QuittingTomorrowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // 初始化服务
        setupServices()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupServices() {
        // 注册后台任务
        SettlementService.shared.registerBackgroundTask()
        
        // 安排凌晨结算
        SettlementService.shared.scheduleSettlement()
        
        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("✅ 通知权限已授予")
            } else {
                print("❌ 通知权限被拒绝")
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // App启动时的初始化
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // 进入后台时保存数据
        DataManager.shared.savePressureRecords()
        DataManager.shared.saveUserProfile()
        DataManager.shared.saveTodayClicks()
    }
}

