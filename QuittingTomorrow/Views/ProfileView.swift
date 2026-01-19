//
//  ProfileView.swift
//  QuittingTomorrow
//
//  Page 4: 个人档案页面
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showResumeBackup = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 用户统计概览
                    UserStatsCard(profile: dataManager.userProfile)
                    
                    // 勋章系统
                    AchievementsSection(achievements: dataManager.userProfile.achievements)
                    
                    // 简历备份入口
                    ResumeBackupCard(
                        hasBackup: dataManager.userProfile.hasResumeBackup,
                        backupDate: dataManager.userProfile.resumeBackupDate
                    ) {
                        showResumeBackup = true
                    }
                    
                    // 数据导出
                    DataExportSection()
                    
                    // 设置
                    SettingsSection()
                }
                .padding()
            }
            .navigationTitle("个人档案")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showResumeBackup) {
                ResumeBackupView()
            }
        }
    }
}

// MARK: - 用户统计卡片

struct UserStatsCard: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            Text("职场幸存者档案")
                .font(.system(size: 24, weight: .bold))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                StatItemView(
                    icon: "calendar",
                    title: "使用天数",
                    value: "\(profile.totalDaysUsed)"
                )
                
                StatItemView(
                    icon: "hand.tap.fill",
                    title: "总点击数",
                    value: "\(profile.totalClicks)"
                )
                
                StatItemView(
                    icon: "flame.fill",
                    title: "最长连续",
                    value: "\(profile.longestStreak)天"
                )
                
                StatItemView(
                    icon: "arrow.right.circle.fill",
                    title: "当前连续",
                    value: "\(profile.currentStreak)天"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct StatItemView: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - 勋章系统

struct AchievementsSection: View {
    let achievements: [Achievement]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("已解锁勋章")
                .font(.system(size: 20, weight: .bold))
            
            if achievements.isEmpty {
                Text("还没有解锁任何勋章，继续使用App来解锁吧！")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(achievements, id: \.self) { achievement in
                        AchievementCard(achievement: achievement)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(achievement.rawValue)
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - 简历备份卡片

struct ResumeBackupCard: View {
    let hasBackup: Bool
    let backupDate: Date?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: hasBackup ? "doc.fill.checkmark" : "doc.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hasBackup ? "简历已备份" : "简历备份")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let date = backupDate {
                        Text("备份时间：\(formatDate(date))")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    } else {
                        Text("当AI判定辞职指数达90%时，建议更新简历")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - 简历备份视图

struct ResumeBackupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataManager = DataManager.shared
    @State private var resumeText: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("简历备份")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.top)
                
                TextEditor(text: $resumeText)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .frame(minHeight: 300)
                
                Text("提示：当AI判定您的辞职指数达到90%时，建议更新并备份简历。")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button("保存备份") {
                    saveResume()
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .padding()
            .navigationTitle("简历备份")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveResume() {
        // 保存简历文本到UserDefaults
        UserDefaults.standard.set(resumeText, forKey: "resume_backup_text")
        
        // 更新用户档案
        dataManager.userProfile.hasResumeBackup = true
        dataManager.userProfile.resumeBackupDate = Date()
        dataManager.saveUserProfile()
        
        alertMessage = "简历备份成功！"
        showAlert = true
    }
}

// MARK: - 数据导出

struct DataExportSection: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("数据管理")
                .font(.system(size: 20, weight: .bold))
            
            Button(action: exportData) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("导出数据")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: clearAllData) {
                HStack {
                    Image(systemName: "trash")
                    Text("清空所有数据")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func exportData() {
        // 导出数据为JSON
        let exportData: [String: Any] = [
            "records": dataManager.pressureRecords.map { record in
                [
                    "date": ISO8601DateFormatter().string(from: record.date),
                    "clickCount": record.clickCount,
                    "pressureLevel": record.pressureLevel.rawValue
                ]
            },
            "profile": [
                "totalDaysUsed": dataManager.userProfile.totalDaysUsed,
                "totalClicks": dataManager.userProfile.totalClicks,
                "longestStreak": dataManager.userProfile.longestStreak
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // 这里可以分享或保存文件
            print("导出数据：\n\(jsonString)")
        }
    }
    
    private func clearAllData() {
        // 清空所有数据（需要确认）
        dataManager.pressureRecords.removeAll()
        dataManager.userProfile = UserProfile()
        dataManager.todayClicks.removeAll()
        dataManager.savePressureRecords()
        dataManager.saveUserProfile()
        dataManager.saveTodayClicks()
    }
}

// MARK: - 设置

struct SettingsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("设置")
                .font(.system(size: 20, weight: .bold))
            
            NavigationLink(destination: SettingsView()) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("应用设置")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct SettingsView: View {
    var body: some View {
        List {
            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("功能") {
                Toggle("推送通知", isOn: .constant(true))
                Toggle("自动结算", isOn: .constant(true))
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
    }
}

