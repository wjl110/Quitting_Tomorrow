#!/bin/bash
# iOS项目测试运行脚本
# 注意：此脚本需要在macOS上运行，且需要安装Xcode

echo "🚀 开始测试明天辞职App..."

# 检查是否在macOS上
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ 错误：此脚本只能在macOS上运行"
    echo "   请在macOS上使用Xcode打开项目进行测试"
    exit 1
fi

# 检查Xcode是否安装
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ 错误：未找到Xcode，请先安装Xcode"
    exit 1
fi

# 进入项目目录
cd QuittingTomorrow || exit 1

# 清理构建
echo "🧹 清理构建..."
xcodebuild clean -project QuittingTomorrow.xcodeproj -scheme QuittingTomorrow

# 构建项目
echo "🔨 构建项目..."
xcodebuild build -project QuittingTomorrow.xcodeproj -scheme QuittingTomorrow -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo ""
    echo "📱 下一步："
    echo "   1. 在Xcode中打开 QuittingTomorrow.xcodeproj"
    echo "   2. 选择目标设备（模拟器或真机）"
    echo "   3. 按 Cmd+R 运行项目"
    echo ""
    echo "🧪 测试建议："
    echo "   - 查看 TEST_GUIDE.md 获取详细测试指南"
    echo "   - 测试宣泄中心按钮点击功能"
    echo "   - 测试数据持久化"
    echo "   - 测试AI分析功能（需要设置API Key）"
else
    echo "❌ 构建失败，请检查错误信息"
    exit 1
fi

