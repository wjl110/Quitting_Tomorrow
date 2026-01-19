# 测试指南

## 快速测试清单

### ✅ 基础功能测试

#### 1. 宣泄中心页面
- [ ] 点击按钮，计数正常增加
- [ ] 按钮颜色随压力等级变化（灰色→蓝色→橙色→红色）
- [ ] 触觉反馈正常工作
- [ ] 按钮动画效果流畅
- [ ] 压力密度计算正确
- [ ] 状态提示文字正确显示

#### 2. 情绪熔断机制
- [ ] 5分钟内点击1000次，触发熔断弹窗
- [ ] 熔断弹窗显示正确
- [ ] 点击"好的，我冷静了"后弹窗消失

#### 3. 日历统计页面
- [ ] 日历网格正确显示
- [ ] 压力色块正确填充
- [ ] 周期选择器正常工作（周/月/季度/年）
- [ ] 折线图正确显示（iOS 16+）
- [ ] 饼图正确显示（iOS 16+）
- [ ] 统计卡片数据正确

#### 4. AI分析页面
- [ ] API Key设置功能正常
- [ ] 未设置API Key时显示提示
- [ ] 分析按钮正常工作
- [ ] 加载状态正确显示
- [ ] AI分析结果正确展示
- [ ] 错误提示正确显示

#### 5. 个人档案页面
- [ ] 用户统计数据正确
- [ ] 勋章正确显示
- [ ] 简历备份功能正常
- [ ] 数据导出功能正常
- [ ] 设置页面正常

### ✅ 数据持久化测试

- [ ] 关闭App后重新打开，数据不丢失
- [ ] 今日点击记录正确保存
- [ ] 压力记录正确保存
- [ ] 用户档案正确保存

### ✅ 后台任务测试

#### 手动测试结算功能
在Xcode控制台或代码中添加：

```swift
// 在任意View的onAppear中添加
Task {
    await SettlementService.shared.manualSettlement()
}
```

测试点：
- [ ] 结算后，今日点击记录清空
- [ ] 结算后，压力记录正确创建
- [ ] 结算后，用户档案正确更新
- [ ] 结算后，勋章正确解锁

### ✅ 边界情况测试

#### 1. 空数据测试
- [ ] 首次打开App，所有页面正常显示
- [ ] 无数据时，图表显示空状态
- [ ] 无数据时，统计卡片显示0

#### 2. 大量数据测试
- [ ] 连续点击10000次，App不崩溃
- [ ] 数据正确保存
- [ ] 性能无明显下降

#### 3. 时间边界测试
- [ ] 跨天时，今日点击记录正确重置
- [ ] 跨月时，月度统计正确
- [ ] 跨年时，年度统计正确

#### 4. 网络异常测试
- [ ] AI分析时断网，错误提示正确
- [ ] 网络恢复后，可以重新分析

## 自动化测试建议

### 单元测试

创建测试文件：`QuittingTomorrowTests/DataManagerTests.swift`

```swift
import XCTest
@testable import QuittingTomorrow

final class DataManagerTests: XCTestCase {
    var dataManager: DataManager!
    
    override func setUp() {
        super.setUp()
        dataManager = DataManager.shared
    }
    
    func testAddClick() {
        let initialCount = dataManager.getTodayClickCount()
        dataManager.addClick()
        XCTAssertEqual(dataManager.getTodayClickCount(), initialCount + 1)
    }
    
    func testPressureLevelCalculation() {
        XCTAssertEqual(
            PressureRecord.calculatePressureLevel(clickCount: 0),
            .calm
        )
        XCTAssertEqual(
            PressureRecord.calculatePressureLevel(clickCount: 25),
            .mild
        )
        XCTAssertEqual(
            PressureRecord.calculatePressureLevel(clickCount: 100),
            .moderate
        )
        XCTAssertEqual(
            PressureRecord.calculatePressureLevel(clickCount: 300),
            .severe
        )
    }
    
    func testStressDensity() {
        // 添加多个点击
        for _ in 0..<10 {
            dataManager.addClick()
        }
        let density = dataManager.calculateStressDensity()
        XCTAssertGreaterThan(density, 0)
    }
}
```

### UI测试

创建测试文件：`QuittingTomorrowUITests/VentingViewUITests.swift`

```swift
import XCTest

final class VentingViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testButtonClick() {
        let button = app.buttons.firstMatch
        XCTAssertTrue(button.exists)
        
        let initialText = button.label
        button.tap()
        
        // 验证计数增加
        XCTAssertNotEqual(button.label, initialText)
    }
    
    func testTabNavigation() {
        // 测试切换到日历页面
        app.tabBars.buttons["日历"].tap()
        XCTAssertTrue(app.navigationBars["辞职日历"].exists)
        
        // 测试切换到AI分析页面
        app.tabBars.buttons["AI分析"].tap()
        XCTAssertTrue(app.navigationBars["AI 分析"].exists)
    }
}
```

## 性能测试

### 内存测试
- 使用Xcode Instruments的Allocations工具
- 连续操作1小时，检查内存泄漏
- 预期：内存使用稳定，无持续增长

### 启动时间测试
- 冷启动时间 < 2秒
- 热启动时间 < 0.5秒

### 数据加载测试
- 1000条记录加载时间 < 1秒
- 图表渲染时间 < 0.5秒

## 兼容性测试

### iOS版本
- [ ] iOS 17.0+（主要支持）
- [ ] iOS 16.0+（图表功能降级）
- [ ] iOS 15.0+（基础功能）

### 设备测试
- [ ] iPhone SE（小屏）
- [ ] iPhone 14 Pro（标准屏）
- [ ] iPhone 14 Pro Max（大屏）
- [ ] iPad（如果支持）

## 测试数据准备

### 创建测试数据脚本

在App启动时添加测试数据（仅Debug模式）：

```swift
#if DEBUG
func createTestData() {
    let dataManager = DataManager.shared
    let calendar = Calendar.current
    
    // 创建过去30天的测试数据
    for day in 0..<30 {
        if let date = calendar.date(byAdding: .day, value: -day, to: Date()) {
            let clickCount = Int.random(in: 0...500)
            let record = PressureRecord(
                date: date,
                clickCount: clickCount,
                pressureLevel: PressureRecord.calculatePressureLevel(clickCount: clickCount),
                stressDensity: Double.random(in: 0...10)
            )
            dataManager.pressureRecords.append(record)
        }
    }
    
    dataManager.savePressureRecords()
}
#endif
```

## 问题排查

### 常见问题

1. **数据不保存**
   - 检查UserDefaults权限
   - 检查数据编码/解码是否正确

2. **AI分析失败**
   - 检查API Key是否正确
   - 检查网络连接
   - 查看控制台错误日志

3. **后台任务不执行**
   - 检查Info.plist中的后台模式配置
   - 检查任务注册是否正确
   - 真机测试（模拟器可能不支持）

4. **图表不显示**
   - 检查iOS版本（需要16+）
   - 检查数据是否为空
   - 检查Chart框架导入

## 测试报告模板

```
测试日期：YYYY-MM-DD
测试人员：XXX
测试环境：iOS X.X / iPhone XX

测试结果：
- 基础功能：✅/❌
- 数据持久化：✅/❌
- 后台任务：✅/❌
- 边界情况：✅/❌
- 性能：✅/❌

发现的问题：
1. [问题描述]
2. [问题描述]

建议：
1. [建议内容]
2. [建议内容]
```

