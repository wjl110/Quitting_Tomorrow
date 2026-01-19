//
//  VentingView.swift
//  QuittingTomorrow
//
//  Page 1: 宣泄中心页面
//

import SwiftUI
import UIKit

struct VentingView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var clickCount: Int = 0
    @State private var buttonScale: CGFloat = 1.0
    @State private var buttonRotation: Double = 0
    @State private var showCircuitBreaker = false
    @State private var lastClickTime: Date?
    @State private var rapidClickCount: Int = 0
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: backgroundColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 标题
                Text("宣泄中心")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 60)
                
                Spacer()
                
                // 巨型按钮
                Button(action: handleButtonClick) {
                    ZStack {
                        Circle()
                            .fill(buttonColor)
                            .frame(width: 200, height: 200)
                            .shadow(color: buttonColor.opacity(0.6), radius: 20, x: 0, y: 10)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                            )
                        
                        VStack(spacing: 8) {
                            Text("\(clickCount)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(pressureLevel.displayName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(buttonScale)
                .rotationEffect(.degrees(buttonRotation))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: buttonRotation)
                
                // 状态提示
                VStack(spacing: 12) {
                    Text(statusMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if pressureLevel == .severe {
                        HStack(spacing: 8) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.red)
                            Text("辞职顶点状态")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
                
                // 今日统计
                HStack(spacing: 30) {
                    StatCard(title: "今日点击", value: "\(clickCount)")
                    StatCard(title: "压力密度", value: String(format: "%.1f", stressDensity))
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showCircuitBreaker) {
            CircuitBreakerView()
        }
        .onAppear {
            loadTodayData()
            setupNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: .emotionalCircuitBreaker)) { _ in
            showCircuitBreaker = true
        }
    }
    
    // MARK: - 计算属性
    
    private var pressureLevel: PressureLevel {
        PressureRecord.calculatePressureLevel(clickCount: clickCount)
    }
    
    private var buttonColor: Color {
        switch pressureLevel {
        case .calm:
            return Color(hex: "#E8E8E8")
        case .mild:
            return Color(hex: "#4A90E2")
        case .moderate:
            return Color(hex: "#F5A623")
        case .severe:
            return Color(hex: "#D0021B")
        }
    }
    
    private var backgroundColors: [Color] {
        switch pressureLevel {
        case .calm:
            return [Color(hex: "#F5F5F5"), Color(hex: "#E8E8E8")]
        case .mild:
            return [Color(hex: "#E3F2FD"), Color(hex: "#BBDEFB")]
        case .moderate:
            return [Color(hex: "#FFF3E0"), Color(hex: "#FFE0B2")]
        case .severe:
            return [Color(hex: "#FFEBEE"), Color(hex: "#FFCDD2")]
        }
    }
    
    private var statusMessage: String {
        switch pressureLevel {
        case .calm:
            return "保持平静，职场如战场，但你不必每次都冲锋陷阵"
        case .mild:
            return "微烦状态，小压力而已，深呼吸"
        case .moderate:
            return "忍耐状态，压力在积累，注意调节"
        case .severe:
            return "爆发状态！你的辞职能量已充满，是时候考虑下一步了"
        }
    }
    
    private var stressDensity: Double {
        dataManager.calculateStressDensity()
    }
    
    // MARK: - 方法
    
    private func handleButtonClick() {
        // 添加点击
        dataManager.addClick()
        clickCount = dataManager.getTodayClickCount()
        
        // 触觉反馈
        let impactFeedback = UIImpactFeedbackGenerator(style: pressureLevel == .severe ? .heavy : .medium)
        impactFeedback.impactOccurred()
        
        // 按钮动画
        withAnimation {
            buttonScale = 0.9
            buttonRotation = Double.random(in: -5...5)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                buttonScale = 1.0
                buttonRotation = 0
            }
        }
        
        // 检查快速点击
        checkRapidClicking()
        
        // 检查是否需要AI主动归因
        checkAIProactiveAttribution()
    }
    
    private func checkRapidClicking() {
        let now = Date()
        if let lastTime = lastClickTime {
            let interval = now.timeIntervalSince(lastTime)
            if interval < 1.0 {
                rapidClickCount += 1
            } else {
                rapidClickCount = 1
            }
        } else {
            rapidClickCount = 1
        }
        lastClickTime = now
    }
    
    private func checkAIProactiveAttribution() {
        // 如果10秒内点击超过100次，触发AI主动归因
        if rapidClickCount >= 100 {
            Task {
                let message = try? await AIService.shared.proactiveAttribution(
                    clickCount: clickCount,
                    peakTime: Date()
                )
                // 可以显示一个提示
            }
            rapidClickCount = 0
        }
    }
    
    private func loadTodayData() {
        clickCount = dataManager.getTodayClickCount()
    }
    
    private func setupNotifications() {
        // 监听情绪熔断通知
    }
}

// MARK: - 辅助视图

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(width: 120, height: 80)
        .background(Color.white.opacity(0.2))
        .cornerRadius(16)
    }
}

struct CircuitBreakerView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("情绪熔断机制")
                .font(.system(size: 24, weight: .bold))
            
            Text("别把手机点坏了，老板不值得你赔屏。\n深呼吸，冷静一下。")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            Button("好的，我冷静了") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .padding(40)
    }
}

// MARK: - Color Extension

extension Color {
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

