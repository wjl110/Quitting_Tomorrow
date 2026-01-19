//
//  AIAnalystView.swift
//  QuittingTomorrow
//
//  Page 3: AI 职场导师页面
//

import SwiftUI

struct AIAnalystView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var isLoading = false
    @State private var analysisResult: AIAnalysis?
    @State private var errorMessage: String?
    @State private var showAPIKeyInput = false
    @State private var apiKey: String = ""
    @State private var userInput: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // API Key 设置
                    if AIService.shared.apiKey.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("需要设置 DeepSeek API Key")
                                .font(.system(size: 18, weight: .medium))
                            
                            Button("设置 API Key") {
                                showAPIKeyInput = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                    } else {
                        // 分析区域
                        VStack(alignment: .leading, spacing: 20) {
                            Text("AI 职场导师")
                                .font(.system(size: 24, weight: .bold))
                            
                            // 用户输入框
                            VStack(alignment: .leading, spacing: 8) {
                                Text("补充说明（可选）")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                TextEditor(text: $userInput)
                                    .frame(height: 100)
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(8)
                            }
                            
                            // 分析按钮
                            Button(action: performAnalysis) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "brain.head.profile")
                                        Text("开始分析")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isLoading ? Color.gray : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading)
                            
                            // 错误提示
                            if let error = errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        
                        // 分析结果
                        if let analysis = analysisResult {
                            AnalysisResultView(analysis: analysis)
                        }
                        
                        // 今日数据预览
                        if let todayRecord = dataManager.getTodayRecord() {
                            TodayDataPreview(record: todayRecord)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI 分析")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAPIKeyInput) {
                APIKeyInputView(apiKey: $apiKey) { key in
                    AIService.shared.setAPIKey(key)
                    showAPIKeyInput = false
                }
            }
        }
    }
    
    private func performAnalysis() {
        guard let todayRecord = dataManager.getTodayRecord() else {
            errorMessage = "暂无今日数据，请先在宣泄中心点击按钮"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // 更新用户补充文本
        var record = todayRecord
        record.userNotes = userInput.isEmpty ? nil : userInput
        
        Task {
            do {
                let analysis = try await AIService.shared.analyzePressureState(record: record)
                
                await MainActor.run {
                    analysisResult = analysis
                    isLoading = false
                    
                    // 保存分析结果
                    if let index = dataManager.pressureRecords.firstIndex(where: { $0.id == record.id }) {
                        dataManager.pressureRecords[index].aiAnalysis = analysis
                        dataManager.pressureRecords[index].userNotes = record.userNotes
                        dataManager.savePressureRecords()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "分析失败：\(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - 分析结果视图

struct AnalysisResultView: View {
    let analysis: AIAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("分析结果")
                .font(.system(size: 20, weight: .bold))
            
            // 压力类型
            VStack(alignment: .leading, spacing: 8) {
                Text("压力类型")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(analysis.pressureType)
                    .font(.system(size: 18, weight: .semibold))
            }
            
            // 辞职倾向指数
            VStack(alignment: .leading, spacing: 12) {
                Text("辞职倾向指数")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(analysis.resignationIndex)%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(indexColor)
                    
                    Spacer()
                    
                    ProgressView(value: Double(analysis.resignationIndex), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: indexColor))
                        .frame(width: 150)
                }
                
                Text(indexDescription)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            // 反直觉洞察
            VStack(alignment: .leading, spacing: 8) {
                Text("反直觉洞察")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(analysis.insight)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
            }
            
            // 本周金句
            VStack(alignment: .leading, spacing: 8) {
                Text("本周金句")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text("\"\(analysis.quote)\"")
                    .font(.system(size: 18).italic())
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            
            // 致郁因子
            if !analysis.stressFactors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("致郁因子分析")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    ForEach(analysis.stressFactors) { factor in
                        HStack {
                            Text(factor.name)
                            Spacer()
                            Text("\(Int(factor.percentage))%")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.vertical, 4)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color(.secondarySystemBackground))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color.orange)
                                    .frame(width: geometry.size.width * CGFloat(factor.percentage / 100), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var indexColor: Color {
        switch analysis.resignationIndex {
        case 0..<30:
            return .green
        case 30..<60:
            return .orange
        case 60..<90:
            return .red
        default:
            return .purple
        }
    }
    
    private var indexDescription: String {
        switch analysis.resignationIndex {
        case 0..<30:
            return "状态良好，继续保持"
        case 30..<60:
            return "压力在积累，注意调节"
        case 60..<90:
            return "辞职倾向较高，建议认真考虑"
        default:
            return "辞职顶点！是时候行动了"
        }
    }
}

// MARK: - 今日数据预览

struct TodayDataPreview: View {
    let record: PressureRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("今日数据预览")
                .font(.system(size: 18, weight: .bold))
            
            HStack {
                DataItem(title: "点击数", value: "\(record.clickCount)")
                DataItem(title: "压力等级", value: record.pressureLevel.displayName)
                DataItem(title: "压力密度", value: String(format: "%.1f", record.stressDensity))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct DataItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - API Key 输入视图

struct APIKeyInputView: View {
    @Binding var apiKey: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("请输入您的 DeepSeek API Key")
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Link("获取 API Key", destination: URL(string: "https://platform.deepseek.com/api_keys")!)
                    .font(.system(size: 14))
                
                Button("保存") {
                    onSave(apiKey)
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKey.isEmpty)
            }
            .padding()
            .navigationTitle("设置 API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

