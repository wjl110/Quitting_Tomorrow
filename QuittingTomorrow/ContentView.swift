//
//  ContentView.swift
//  QuittingTomorrow
//
//  主界面 - TabView 容器
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Page 1: 宣泄中心
            VentingView()
                .tabItem {
                    Label("宣泄", systemImage: "hand.tap.fill")
                }
                .tag(0)
            
            // Page 2: 辞职日历与统计
            CalendarView()
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }
                .tag(1)
            
            // Page 3: AI 职场导师
            AIAnalystView()
                .tabItem {
                    Label("AI分析", systemImage: "brain.head.profile")
                }
                .tag(2)
            
            // Page 4: 个人档案
            ProfileView()
                .tabItem {
                    Label("档案", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

