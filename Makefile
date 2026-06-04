.PHONY: help open test lint regen-project

help:
	@echo "微醺之度 / 53° 雲 —— 常用命令"
	@echo "  make open          打开 Xcode 工程"
	@echo "  make test          用 SPM 跑所有包的单元测试（需完整 Xcode 工具链）"
	@echo "  make lint          运行 SwiftLint（需 brew install swiftlint）"
	@echo "  make regen-project 用 XcodeGen 重新生成 YunApp.xcodeproj（需 brew install xcodegen）"

open:
	open YunApp/YunApp.xcodeproj

# 逐个包跑测试（XCTest 需要完整 Xcode；纯命令行工具链下会因缺少 XCTest 而失败）。
test:
	@for pkg in Engine DesignSystem Mixing Recipes ShareCard DeepLink Health Cellar Authenticity AICompanion; do \
		echo "== test $$pkg =="; (cd Packages/$$pkg && swift test) || exit 1; \
	done

lint:
	swiftlint

regen-project:
	cd YunApp && xcodegen generate
