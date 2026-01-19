//
//  CalendarView.swift
//  QuittingTomorrow
//
//  Page 2: 辞职日历与统计页面
//

import SwiftUI
import Charts

struct CalendarView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var selectedPeriod: Period = .month
    @State private var selectedDate = Date()
    
    enum Period: String, CaseIterable {
        case week = "本周"
        case month = "本月"
        case quarter = "本季度"
        case year = "本年度"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // 周期选择器
                    Picker("周期", selection: $selectedPeriod) {
                        ForEach(Period.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 日历视图
                    CalendarGridView(records: filteredRecords)
                        .padding(.horizontal)
                    
                    // 折线图 - 压力脉冲
                    PressureLineChart(records: filteredRecords)
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    // 饼图 - 致郁因子
                    if let analysis = latestAIAnalysis {
                        StressFactorPieChart(analysis: analysis)
                            .frame(height: 300)
                            .padding(.horizontal)
                    }
                    
                    // 统计卡片
                    StatisticsCards(records: filteredRecords)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("辞职日历")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var filteredRecords: [PressureRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .week:
            return dataManager.getRecentRecords(days: 7)
        case .month:
            let components = calendar.dateComponents([.year, .month], from: now)
            return dataManager.getMonthlyRecords(
                month: components.month ?? 1,
                year: components.year ?? 2024
            )
        case .quarter:
            let quarter = (calendar.component(.month, from: now) - 1) / 3 + 1
            let year = calendar.component(.year, from: now)
            return dataManager.getQuarterlyRecords(quarter: quarter, year: year)
        case .year:
            let year = calendar.component(.year, from: now)
            return dataManager.getYearlyRecords(year: year)
        }
    }
    
    private var latestAIAnalysis: AIAnalysis? {
        filteredRecords.compactMap { $0.aiAnalysis }.last
    }
}

// MARK: - 日历网格视图

struct CalendarGridView: View {
    let records: [PressureRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("压力日历")
                .font(.system(size: 20, weight: .bold))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                // 星期标题
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                
                // 日期单元格
                ForEach(generateCalendarDays(), id: \.self) { date in
                    CalendarDayCell(date: date, record: getRecord(for: date))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func generateCalendarDays() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        
        var days: [Date] = []
        
        // 填充上个月的日期
        let daysToSubtract = (firstWeekday - 1) % 7
        for i in (1...daysToSubtract).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // 填充本月的日期
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                days.append(date)
            }
        }
        
        // 填充下个月的日期（补齐6行）
        let remaining = 42 - days.count
        for day in 1...remaining {
            if let date = calendar.date(byAdding: .day, value: day, to: startOfMonth) {
                if let lastDay = calendar.date(byAdding: .day, value: daysInMonth - 1, to: startOfMonth) {
                    if let nextDate = calendar.date(byAdding: .day, value: day, to: lastDay) {
                        days.append(nextDate)
                    }
                }
            }
        }
        
        return days.prefix(42).map { $0 }
    }
    
    private func getRecord(for date: Date) -> PressureRecord? {
        return records.first { record in
            Calendar.current.isDate(record.date, inSameDayAs: date)
        }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let record: PressureRecord?
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isToday ? .white : .primary)
            
            if let record = record {
                Circle()
                    .fill(Color(hex: record.pressureLevel.colorHex))
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 40, height: 50)
        .background(isToday ? Color.blue : Color.clear)
        .cornerRadius(8)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - 折线图

struct PressureLineChart: View {
    let records: [PressureRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("压力脉冲趋势")
                .font(.system(size: 20, weight: .bold))
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(records.sorted(by: { $0.date < $1.date })) { record in
                        LineMark(
                            x: .value("日期", record.date, unit: .day),
                            y: .value("点击数", record.clickCount)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("日期", record.date, unit: .day),
                            y: .value("点击数", record.clickCount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 250)
            } else {
                // iOS 15 及以下使用简单视图
                Text("需要 iOS 16+ 支持图表")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - 饼图

struct StressFactorPieChart: View {
    let analysis: AIAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("致郁因子分析")
                .font(.system(size: 20, weight: .bold))
            
            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(analysis.stressFactors) { factor in
                        SectorMark(
                            angle: .value("百分比", factor.percentage),
                            innerRadius: .ratio(0.5),
                            angularInset: 2
                        )
                        .foregroundStyle(by: .value("因子", factor.name))
                        .annotation(position: .overlay) {
                            if factor.percentage > 10 {
                                Text("\(Int(factor.percentage))%")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .frame(height: 250)
                .chartLegend(position: .bottom, alignment: .center)
            } else {
                // iOS 15 及以下使用列表显示
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(analysis.stressFactors) { factor in
                        HStack {
                            Text(factor.name)
                            Spacer()
                            Text("\(Int(factor.percentage))%")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .frame(height: 250)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

// MARK: - 统计卡片

struct StatisticsCards: View {
    let records: [PressureRecord]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("统计概览")
                .font(.system(size: 20, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCardView(
                    title: "总点击数",
                    value: "\(records.reduce(0) { $0 + $1.clickCount })",
                    icon: "hand.tap.fill"
                )
                
                StatCardView(
                    title: "平均压力",
                    value: String(format: "%.1f", averagePressure),
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                StatCardView(
                    title: "最高峰值",
                    value: "\(records.map { $0.clickCount }.max() ?? 0)",
                    icon: "arrow.up.circle.fill"
                )
                
                StatCardView(
                    title: "记录天数",
                    value: "\(records.count)",
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private var averagePressure: Double {
        guard !records.isEmpty else { return 0.0 }
        let total = records.reduce(0.0) { $0 + Double($1.clickCount) }
        return total / Double(records.count)
    }
}

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
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

