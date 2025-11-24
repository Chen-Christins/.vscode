# 本项目致力于在 vscode 获得更加便利的 C/C++ Workspace

这里有一个专门用来格式化 C/C++ 文件的脚本 format_code.sh
## 脚本特性

### 核心功能：
- 自动查找并格式化所有C/C++源文件（.c, .cpp, .cc, .cxx, .h, .hpp）
- 使用现有的 .clang-format 配置文件
- 智能排除构建目录（build/, .git/, output/, dist/等）
- 完整的错误处理和进度反馈

### 多种运行模式：
- 标准格式化
```shell
./format_code.sh
```

- 预览模式 - 查看将要格式化的文件
```shell
./format_code.sh --dry-run
```

- 检查模式 - 仅检查格式，不修改文件
```shell
./format_code.sh --check
```

-  详细模式
```shell
./format_code.sh --verbose
```

-  显示帮助
```shell
./format_code.sh --help
```

### 安全特性：
  - 格式化前自动创建备份
  - 格式化失败时自动恢复原文件
  - 详细的进度和结果统计
  - 优雅的错误处理
