# 明天辞职 (Quitting Tomorrow)
<a href="https://www.producthunt.com/products/quittingtomorrow?embed=true&amp;utm_source=badge-featured&amp;utm_medium=badge&amp;utm_campaign=badge-quittingtomorrow" target="_blank" rel="noopener noreferrer"><img alt="QuittingTomorrow - Today's clicks prepare you for resigning tomorrow. | Product Hunt" width="250" height="54" src="https://api.producthunt.com/widgets/embed-image/v1/featured.svg?post_id=1065116&amp;theme=light&amp;t=1768843974535"></a>


一款帮助用户通过情绪宣泄释放职场压力的iOS应用。（用户亦可通过采用跟AI对话的形式，让AI为你录入你的职场状态和心理情绪）

> This is an iOS app called "Quitting Tomorrow." Simply put, the app allows users to release work-related stress daily by expressing their emotions. It features a button with a counter function. The logic is that if a user clicks the button too many times in a day, it indicates a strong desire to quit their job.

## 功能特性

### 🎯 四大核心页面

1. **宣泄中心** - 巨型按钮，点击计数，根据点击次数动态升级压力等级
2. **辞职日历** - 可视化展示每日压力状态，包含折线图、饼图等数据分析
3. **AI 职场导师** - 接入 DeepSeek API，智能分析用户心理状态和辞职倾向
4. **个人档案** - 勋章系统、简历备份、数据统计

### 🧠 核心逻辑

- **压力等级系统**：
  - 平静 (0次)
  - 微烦 (1-50次) - 淡蓝色
  - 忍耐 (51-200次) - 橙色
  - 爆发 (201+次) - 血红色

- **凌晨自动结算**：每天凌晨3-4点自动将前一日数据记录到日历

- **情绪熔断机制**：5分钟内点击超过1000次，触发强制冷静模式

- **AI 智能分析**：
  - 压力类型判断（急性应激/慢性内耗）
  - 辞职倾向指数 (0-100%)
  - 反直觉洞察
  - 致郁因子分析

## 技术栈

- **SwiftUI** - 现代化UI框架
- **Swift Charts** - 数据可视化（iOS 16+）
- **DeepSeek API** - AI分析服务
- **UserDefaults** - 数据持久化
- **Background Tasks** - 后台任务调度
- **UserNotifications** - 推送通知

## 项目结构

```
QuittingTomorrow/
├── QuittingTomorrowApp.swift      # App入口
├── ContentView.swift               # 主界面TabView
├── Models/
│   ├── PressureRecord.swift       # 压力记录模型
│   └── UserProfile.swift          # 用户档案模型
├── Services/
│   ├── DataManager.swift          # 数据管理器（单例）
│   ├── AIService.swift            # AI服务（DeepSeek集成）
│   └── SettlementService.swift    # 凌晨结算服务
└── Views/
    ├── VentingView.swift          # 宣泄中心页面
    ├── CalendarView.swift         # 日历统计页面
    ├── AIAnalystView.swift        # AI分析页面
    └── ProfileView.swift          # 个人档案页面
```

## 安装与运行

### 前置要求

- macOS 13.0+
- Xcode 15.0+
- iOS 17.0+ 设备或模拟器
- DeepSeek API Key（可选，用于AI功能）

### 运行步骤

1. **克隆项目**
   ```bash
   cd QuittingTomorrow
   ```

2. **打开项目**
   ```bash
   open QuittingTomorrow.xcodeproj
   ```

3. **配置API Key（可选）**
   - 运行App后，进入"AI分析"页面
   - 点击"设置 API Key"
   - 输入您的 DeepSeek API Key
   - 获取地址：https://platform.deepseek.com/api_keys

4. **运行项目**
   - 选择目标设备（模拟器或真机）
   - 按 `Cmd + R` 运行

### 测试功能

#### 1. 宣泄中心测试
- 点击按钮，观察计数增加
- 测试不同压力等级的视觉反馈
- 测试触觉反馈
- 测试情绪熔断机制（快速点击1000次）

#### 2. 日历统计测试
- 查看日历视图中的压力色块
- 切换不同时间周期（周/月/季度/年）
- 查看折线图和饼图

#### 3. AI分析测试
- 设置API Key
- 在宣泄中心点击后，进入AI分析页面
- 输入补充说明（可选）
- 点击"开始分析"，查看AI分析结果

#### 4. 个人档案测试
- 查看用户统计数据
- 测试勋章解锁逻辑
- 测试简历备份功能

#### 5. 凌晨结算测试
- 手动触发结算：在代码中调用 `SettlementService.shared.manualSettlement()`
- 或等待凌晨3-4点自动结算

## 核心算法

### 辞职倾向指数 (RPI) 计算公式

```
RPI = BaseIndex + DensityAdjustment + VelocityBonus

其中：
- BaseIndex: 根据压力等级的基础指数
  - 平静: 10
  - 微烦: 30
  - 忍耐: 60
  - 爆发: 85

- DensityAdjustment: 压力密度调整（最高+15）
  - 密度 = 点击数 / 时间（分钟）

- VelocityBonus: 速度奖励（AI分析时考虑）
  - 10秒内连续点击100次 > 10分钟点击100次
```

### 压力密度计算

```swift
压力密度 = 总点击数 / 时间跨度（分钟）
```

## 数据持久化

所有数据使用 `UserDefaults` 存储：
- `pressure_records` - 压力记录数组
- `user_profile` - 用户档案
- `today_clicks` - 今日点击记录
- `deepseek_api_key` - API密钥（建议使用Keychain）

## 后台任务

App支持后台任务调度：
- 注册标识符：`com.quittingtomorrow.settlement`
- 执行时间：每天凌晨3:00-4:00
- 功能：自动结算前一日数据

## 注意事项

1. **API Key安全**：当前API Key存储在UserDefaults，生产环境建议使用Keychain
2. **数据备份**：建议定期导出数据，避免丢失
3. **隐私保护**：所有数据仅存储在本地，不上传服务器
4. **iOS版本**：图表功能需要iOS 16+，低版本会显示替代视图

## 待优化功能

- [ ] 使用Core Data替代UserDefaults（大数据量场景）
- [ ] 添加iCloud同步功能
- [ ] 优化AI提示词，提高分析准确性
- [ ] 添加更多勋章类型
- [ ] 支持数据导出为CSV/PDF
- [ ] 添加分享功能（匿名分享压力数据）

## 许可证

MIT License

## 联系方式

如有问题或建议，欢迎提交Issue。

<div style="font-family: -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, Roboto, &quot;Helvetica Neue&quot;, Arial, sans-serif; border: 1px solid rgb(224, 224, 224); border-radius: 12px; padding: 20px; max-width: 500px; background: rgb(255, 255, 255); box-shadow: rgba(0, 0, 0, 0.05) 0px 2px 8px;"><div style="display: flex; align-items: center; gap: 12px; margin-bottom: 12px;"><img alt="QuittingTomorrow" src="https://ph-files.imgix.net/ff935a72-26ca-45ac-bc11-9b61dfefa1f2.png?auto=format&amp;fit=crop&amp;w=80&amp;h=80" style="width: 64px; height: 64px; border-radius: 8px; object-fit: cover; flex-shrink: 0;"><div style="flex: 1 1 0%; min-width: 0px;"><h3 style="margin: 0px; font-size: 18px; font-weight: 600; color: rgb(26, 26, 26); line-height: 1.3; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;">QuittingTomorrow</h3><p style="margin: 4px 0px 0px; font-size: 14px; color: rgb(102, 102, 102); line-height: 1.4; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;">Today's clicks prepare you for resigning tomorrow.</p></div></div><a href="https://www.producthunt.com/products/quittingtomorrow?embed=true&amp;utm_source=embed&amp;utm_medium=post_embed" target="_blank" rel="noopener" style="display: inline-flex; align-items: center; gap: 4px; margin-top: 12px; padding: 8px 16px; background: rgb(255, 97, 84); color: rgb(255, 255, 255); text-decoration: none; border-radius: 8px; font-size: 14px; font-weight: 600;">Check it out on Product Hunt →</a></div>
