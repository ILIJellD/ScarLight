#!/bin/bash

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}
# 检查多个命令
check_commands() {
    local missing_commands=()
    
    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        echo "以下命令未安装: ${missing_commands[*]}"
        return 1
    else
        echo "所有命令都已安装"
        return 0
    fi
}

# 检查多个命令
check_commands git curl wget make || exit 1