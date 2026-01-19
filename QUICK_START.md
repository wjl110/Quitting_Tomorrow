# 快速开始指南

## 🎯 5分钟快速测试

### 步骤1：打开项目
```bash
# 在macOS上
open QuittingTomorrow/QuittingTomorrow.xcodeproj
```

### 步骤2：选择模拟器
- 在Xcode顶部选择iPhone模拟器（如iPhone 15）
- 确保iOS版本为17.0+

### 步骤3：运行项目
- 按 `Cmd + R` 或点击运行按钮
- 等待App启动

### 步骤4：基础功能测试

#### ✅ 测试1：宣泄中心
1. 打开App，默认进入"宣泄"页面
2. 点击中央的巨型按钮
3. 观察：
   - 数字是否增加
   - 按钮颜色是否变化（灰色→蓝色→橙色→红色）
   - 是否有震动反馈

#### ✅ 测试2：数据持久化
1. 点击按钮10次
2. 关闭App（完全退出）
3. 重新打开App
4. 检查：数字是否还是10

#### ✅ 测试3：日历统计
1. 切换到"日历"标签
2. 观察：
   - 日历网格是否显示
   - 今日是否有色块标记
   - 统计卡片是否有数据

#### ✅ 测试4：AI分析（可选）
1. 切换到"AI分析"标签
2. 点击"设置 API Key"
3. 输入您的DeepSeek API Key
4. 返回宣泄页面，点击几次按钮
5. 回到AI分析页面，点击"开始分析"
6. 等待分析结果

#### ✅ 测试5：个人档案
1. 切换到"档案"标签
2. 查看：
   - 统计数据是否正确
   - 勋章是否显示（如果有）
   - 简历备份功能是否可用

## 🐛 常见问题

### Q: 构建失败，提示找不到文件
**A:** 确保所有Swift文件都在Xcode项目中正确添加：
- 右键点击项目 → Add Files to "QuittingTomorrow"
- 选择所有Swift文件

### Q: 图表不显示
**A:** 
- 确保iOS版本为16.0+（完整功能需要17.0+）
- 检查是否有数据（无数据时图表为空）

### Q: AI分析失败
**A:**
- 检查API Key是否正确
- 检查网络连接
- 查看Xcode控制台的错误信息

### Q: 数据不保存
**A:**
- 检查App是否有写入权限
- 查看UserDefaults是否正常工作

## 📊 测试数据生成

如果想快速生成测试数据，可以在`QuittingTomorrowApp.swift`的`init()`方法中添加：

```swift
#if DEBUG
// 生成30天测试数据
let calendar = Calendar.current
for day in 0..<30 {
    if let date = calendar.date(byAdding: .day, value: -day, to: Date()) {
        let clickCount = Int.random(in: 0...500)
        let record = PressureRecord(
            date: date,
            clickCount: clickCount,
            pressureLevel: PressureRecord.calculatePressureLevel(clickCount: clickCount),
            stressDensity: Double.random(in: 0...10)
        )
        DataManager.shared.pressureRecords.append(record)
    }
}
DataManager.shared.savePressureRecords()
#endif
```

## 🎮 手动测试结算功能

在Xcode控制台输入：

```swift
// 在任意View的onAppear中临时添加
Task {
    await SettlementService.shared.manualSettlement()
}
```

或者创建一个测试按钮：

```swift
Button("手动结算") {
    Task {
        await SettlementService.shared.manualSettlement()
    }
}
```

## 📝 测试检查清单

- [ ] App正常启动
- [ ] 四个Tab页面都能正常切换
- [ ] 宣泄按钮点击正常
- [ ] 数据保存正常
- [ ] 日历显示正常
- [ ] 图表显示正常（iOS 16+）
- [ ] AI分析功能正常（需API Key）
- [ ] 个人档案显示正常
- [ ] 勋章系统正常工作
- [ ] 简历备份功能正常

## 🚀 下一步

完成基础测试后，可以：
1. 阅读 `TEST_GUIDE.md` 进行详细测试
2. 阅读 `README.md` 了解完整功能
3. 根据需要修改和优化代码

