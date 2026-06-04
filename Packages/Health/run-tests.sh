#!/usr/bin/env bash
# 运行 Health 包单元测试（swift-testing）。
#
# 完整 Xcode 环境下可直接 `swift test` 或在 Xcode 中 ⌘U。
# 本脚本面向「仅安装 CommandLineTools」的环境：手动指向 swift-testing 的
# 框架与运行时（Testing.framework / lib_TestingInterop.dylib）。
set -euo pipefail
cd "$(dirname "$0")"

# 优先尝试标准方式（完整 Xcode）。
if xcode-select -p 2>/dev/null | grep -q "Xcode.app"; then
  exec swift test
fi

FW=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
LIB=/Library/Developer/CommandLineTools/Library/Developer/usr/lib

if [[ ! -d "$FW/Testing.framework" ]]; then
  echo "未找到 Testing.framework，请安装完整 Xcode 后运行 swift test。" >&2
  exit 1
fi

DYLD_LIBRARY_PATH="$LIB" swift test \
  -Xswiftc -F -Xswiftc "$FW" \
  -Xlinker -F -Xlinker "$FW" \
  -Xlinker -rpath -Xlinker "$FW" \
  -Xlinker -rpath -Xlinker "$LIB"
