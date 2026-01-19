//
//  AIService.swift
//  QuittingTomorrow
//
//  DeepSeek API 集成服务
//

import Foundation
import Combine

/// AI服务 - 单例模式
class AIService: ObservableObject {
    static let shared = AIService()
    
    private let apiKey: String
    private let baseURL = "https://api.deepseek.com/v1/chat/completions"
    
    private init() {
        // 从配置或环境变量读取API Key
        // 实际使用时应该从安全的存储中读取
        self.apiKey = UserDefaults.standard.string(forKey: "deepseek_api_key") ?? ""
    }
    
    /// 设置API Key
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "deepseek_api_key")
    }
    
    /// 分析用户压力状态
    func analyzePressureState(record: PressureRecord) async throws -> AIAnalysis {
        guard !apiKey.isEmpty else {
            throw AIError.missingAPIKey
        }
        
        let prompt = buildAnalysisPrompt(record: record)
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": buildSystemPrompt()
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        guard let url = URL(string: baseURL) else {
            throw AIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIError.apiError("API请求失败")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponse
        }
        
        return parseAIResponse(content: content, record: record)
    }
    
    /// 构建系统提示词
    private func buildSystemPrompt() -> String {
        return """
        你是"明天辞职"App的核心智脑。你的角色是一个深度洞察职场心理的导师，语气清醒、幽默且带有适度的同理心。
        
        你的任务是根据用户的点击数据（点击次数、频率、时间）和碎片化的吐槽，生成"辞职倾向报告"。
        
        请用JSON格式返回分析结果，格式如下：
        {
            "pressureType": "急性应激" 或 "慢性内耗",
            "resignationIndex": 0-100的整数,
            "insight": "反直觉洞察（一段话）",
            "quote": "既丧又燃的职场语录",
            "stressFactors": [
                {"name": "因子名称", "percentage": 百分比数字}
            ]
        }
        """
    }
    
    /// 构建分析提示词
    private func buildAnalysisPrompt(record: PressureRecord) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        var prompt = """
        请分析以下用户的压力数据：
        
        - 日期：\(dateFormatter.string(from: record.date))
        - 点击总数：\(record.clickCount)
        - 压力等级：\(record.pressureLevel.displayName)
        - 压力密度：\(String(format: "%.2f", record.stressDensity)) 次/分钟
        """
        
        if let peakTime = record.peakTime {
            prompt += "\n- 点击频率最高峰：\(dateFormatter.string(from: peakTime))"
        }
        
        if let notes = record.userNotes, !notes.isEmpty {
            prompt += "\n- 用户补充：\(notes)"
        }
        
        prompt += """
        
        
        请按照系统提示的要求，分析用户的压力类型、辞职倾向指数、给出反直觉洞察、生成一句职场语录，并分析压力来源（如：老板、加班、通勤、同事等）。
        """
        
        return prompt
    }
    
    /// 解析AI响应
    private func parseAIResponse(content: String, record: PressureRecord) -> AIAnalysis {
        // 尝试解析JSON
        if let jsonData = content.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            
            let pressureType = json["pressureType"] as? String ?? "未知"
            let resignationIndex = json["resignationIndex"] as? Int ?? 0
            let insight = json["insight"] as? String ?? ""
            let quote = json["quote"] as? String ?? ""
            
            var stressFactors: [StressFactor] = []
            if let factors = json["stressFactors"] as? [[String: Any]] {
                stressFactors = factors.compactMap { factor in
                    guard let name = factor["name"] as? String,
                          let percentage = factor["percentage"] as? Double else {
                        return nil
                    }
                    return StressFactor(name: name, percentage: percentage)
                }
            }
            
            return AIAnalysis(
                pressureType: pressureType,
                resignationIndex: resignationIndex,
                insight: insight,
                quote: quote,
                stressFactors: stressFactors
            )
        }
        
        // 如果JSON解析失败，使用默认值
        return AIAnalysis(
            pressureType: "未知",
            resignationIndex: calculateDefaultResignationIndex(record: record),
            insight: "数据正在分析中，请稍后再查看。",
            quote: "职场如战场，但你不必每次都冲锋陷阵。",
            stressFactors: []
        )
    }
    
    /// 计算默认辞职指数（当AI不可用时）
    private func calculateDefaultResignationIndex(record: PressureRecord) -> Int {
        let baseIndex: Int
        
        switch record.pressureLevel {
        case .calm:
            baseIndex = 10
        case .mild:
            baseIndex = 30
        case .moderate:
            baseIndex = 60
        case .severe:
            baseIndex = 85
        }
        
        // 根据压力密度调整
        let densityAdjustment = min(Int(record.stressDensity * 2), 15)
        
        return min(baseIndex + densityAdjustment, 100)
    }
    
    /// 主动归因：当点击数异常波动时触发
    func proactiveAttribution(clickCount: Int, peakTime: Date?) async throws -> String {
        guard !apiKey.isEmpty else {
            return "看起来你今天经历了\(clickCount)次点击，压力不小啊。"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        var prompt = "用户刚才在\(peakTime != nil ? dateFormatter.string(from: peakTime!) : "刚才")经历了\(clickCount)次点击，这是一个异常波动。"
        prompt += "请用一句话主动询问用户原因，语气要轻松、有同理心，不要过于正式。"
        
        let requestBody: [String: Any] = [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": "你是一个幽默、有同理心的职场心理导师。用一句话主动关心用户。"
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ],
            "temperature": 0.8,
            "max_tokens": 100
        ]
        
        guard let url = URL(string: baseURL) else {
            return "看起来你今天经历了\(clickCount)次点击，压力不小啊。"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return "看起来你今天经历了\(clickCount)次点击，压力不小啊。"
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                return "看起来你今天经历了\(clickCount)次点击，压力不小啊。"
            }
            
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return "看起来你今天经历了\(clickCount)次点击，压力不小啊。"
        }
    }
}

/// AI错误类型
enum AIError: Error {
    case missingAPIKey
    case invalidURL
    case apiError(String)
    case invalidResponse
}

