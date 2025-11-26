#!/bin/sh

# C/C++代码格式化脚本
# 使用.clang-format配置文件格式化当前目录下所有的C/C++源文件

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查clang-format是否安装
check_clang_format() {
    if ! command -v clang-format &> /dev/null; then
        print_error "clang-format 未安装！"
        echo "请安装 clang-format："
        echo "  Ubuntu/Debian: sudo apt-get install clang-format"
        echo "  CentOS/RHEL:   sudo yum install clang-format"
        echo "  macOS:         brew install clang-format"
        exit 1
    fi

    local version=$(clang-format --version | head -n1)
    print_info "使用 $version"
}

# 检查.clang-format文件是否存在
check_config_file() {
    if [[ ! -f ".clang-format" ]]; then
        print_warning ".clang-format 配置文件不存在！"
        print_info "将使用默认的LLVM风格格式化代码"

        # 询问是否创建默认配置文件
        read -p "是否创建默认的.clang-format配置文件？(y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            create_default_config
        fi
    else
        print_success "找到 .clang-format 配置文件"
    fi
}

# 创建默认的.clang-format配置文件
create_default_config() {
    cat > .clang-format << 'EOF'
BasedOnStyle: LLVM
ColumnLimit: 120
IndentWidth: 4
TabWidth: 4
UseTab: Never
AccessModifierOffset: -4
MaxEmptyLinesToKeep: 1
KeepEmptyLinesAtTheStartOfBlocks: false
AlignConsecutiveMacros: AcrossEmptyLinesAndComments
AlignTrailingComments: true
SpacesBeforeTrailingComments: 1
AlignEscapedNewlinesLeft: true
AllowAllParametersOfDeclarationOnNextLine: true
BinPackParameters: true
SpaceBeforeParens: ControlStatements
SpaceBeforeAssignmentOperators: true
PointerAlignment: Left
EOF
    print_success "已创建默认的 .clang-format 配置文件"
}

# 查找所有C/C++文件
find_source_files() {
    print_info "正在搜索C/C++源文件..."

    # 支持的文件扩展名
    local extensions=("*.c" "*.cpp" "*.cc" "*.cxx" "*.h" "*.hpp")
    local files=()

    for ext in "${extensions[@]}"; do
        # 使用find命令查找文件，排除一些常见的构建目录
        while IFS= read -r -d $'\0' file; do
            files+=("$file")
        done < <(find . -name "$ext" \
                     -not -path "./build/*" \
                     -not -path "./.git/*" \
                     -not -path "./output/*" \
                     -not -path "./dist/*" \
                     -not -path "./target/*" \
                     -not -path "./cmake-build-*/*" \
                     -print0)
    done

    if [[ ${#files[@]} -eq 0 ]]; then
        print_warning "未找到任何C/C++源文件"
        return 1
    fi

    total_files=${#files[@]}
    print_success "找到 $total_files 个C/C++源文件"

    # 返回文件数组
    source_files=("${files[@]}")
    return 0
}

# 格式化单个文件
format_file() {
    local file="$1"
    local temp_file=$(mktemp)

    # 创建备份
    cp "$file" "$temp_file"

    # 尝试格式化
    if clang-format -i "$file" 2>/dev/null; then
        # 检查文件是否有变化
        if ! cmp -s "$file" "$temp_file"; then
            print_success "已格式化: $file"
            formatted_count=$((formatted_count + 1))
        else
            print_info "无需更改: $file"
        fi
    else
        print_error "格式化失败: $file"
        failed_count=$((failed_count + 1))
        # 恢复原文件
        cp "$temp_file" "$file"
    fi

    # 清理临时文件
    rm -f "$temp_file"
    return 0
}

# 显示帮助信息
show_help() {
    echo "C/C++代码格式化脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help      显示此帮助信息"
    echo "  -v, --verbose   详细输出模式"
    echo "  -d, --dry-run   仅显示将要格式化的文件，不实际格式化"
    echo "  -c, --check     检查代码格式，返回是否有文件需要格式化"
    echo ""
    echo "示例:"
    echo "  $0              # 格式化所有C/C++文件"
    echo "  $0 --dry-run    # 预览将要格式化的文件"
    echo "  $0 --check      # 检查代码格式"
}

# 主函数
main() {
    local verbose=false
    local dry_run=false
    local check_mode=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -c|--check)
                check_mode=true
                shift
                ;;
            *)
                print_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done

    print_info "开始C/C++代码格式化..."

    # 检查环境
    check_clang_format
    check_config_file

    # 查找源文件
    source_files=()
    if ! find_source_files; then
        exit 1
    fi

    # 初始化计数器
    formatted_count=0
    failed_count=0
    local total_files=${#source_files[@]}

    if [[ "$dry_run" == true ]]; then
        print_info "预览模式 - 以下文件将被格式化："
        printf '%s\n' "${source_files[@]}"
        exit 0
    fi

    if [[ "$check_mode" == true ]]; then
        print_info "检查代码格式..."
        local needs_formatting=false

        for file in "${source_files[@]}"; do
            if ! clang-format --dry-run --Werror "$file" &>/dev/null; then
                echo "$file"
                needs_formatting=true
            fi
        done

        if [[ "$needs_formatting" == true ]]; then
            print_warning "存在需要格式化的文件"
            exit 1
        else
            print_success "所有文件格式正确"
            exit 0
        fi
    fi

    # 格式化文件
    print_info "开始格式化文件..."
    local current=0

    for file in "${source_files[@]}"; do
        current=$((current + 1))

        if [[ "$verbose" == true ]]; then
            echo -n "[$current/$total_files] "
        fi

        format_file "$file"
    done

    # 显示结果
    echo ""
    print_success "格式化完成！"
    echo "总文件数: $total_files"
    echo "已格式化: $formatted_count"
    echo "失败文件: $failed_count"

    if [[ $failed_count -gt 0 ]]; then
        print_error "有 $failed_count 个文件格式化失败"
        exit 1
    fi
}

# 运行主函数
main "$@"
