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

# 创建输出目录
if [ ! -d "./out/" ]; then
    mkdir -p out out/boot out/kernel out/lib out/lib/kernel out/lib/user
fi

# 创建系统镜像文件（如果不存在）
if [ ! -e "./sys.img" ]; then
    if command_exists bximage; then
        bximage -func=create -hd=60M -imgmode=flat -sectsize=512 -q sys.img
    else
        echo "PANIC: build.sh need 'bximage' to create an image file"
        echo "FATAL ERROR, aborted build."
        exit 1
    fi
fi

# 检查必要的工具
if ! check_commands gcc nasm ld dd bochs; then
    echo "WARNING: Required tools not exist. I'm going to try installing them."
    echo "ATTENTION: MAY FAIL"

    if command_exists "apt"; then
        echo "Installing with apt"
        sudo apt install -y gcc nasm binutils dd bochs

    elif command_exists "pacman"; then
        echo "Installing with pacman"
        sudo pacman -S --noconfirm gcc nasm binutils coreutils bochs

    elif command_exists "yum"; then
        echo "Installing with yum"
        sudo yum install -y gcc nasm binutils dd bochs

    elif command_exists "dnf"; then
        echo "Installing with dnf"
        sudo dnf install -y gcc nasm binutils coreutils bochs

    else
        echo "PANIC: No known package manager on your computer. Could not install the missing tools."
        echo "FATAL ERROR, aborted build."
        exit 1
    fi
    
    # 重新检查安装后的工具
    if ! check_commands gcc nasm ld dd bochs; then
        echo "PANIC: Still missing required tools after installation attempt."
        echo "FATAL ERROR, aborted build."
        exit 1
    fi
fi

# 编译库文件
cd lib/kernel
nasm -f elf -o ../../out/lib/kernel/print.o ./print.asm
cd ../..

# 编译内核
gcc -m32 -c -o ./out/kernel/main.o ./kernel/main.c -nostdlib -nostdinc -nodefaultlibs -I"./lib/" -I"./lib/kernel/" -I"./lib/user/" -I"./lib/kernel/config/"
ld -m elf_i386 -Ttext 0xc0001500 -e main -o ./out/kernel/kernel.bin ./out/kernel/main.o ./out/lib/kernel/print.o 

# 编译引导程序
cd boot || exit 1
nasm -o ../out/boot/mbr.bin ./mbr.asm
nasm -o ../out/boot/loader.bin ./loader.asm
cd .. || exit 1

# 写入镜像文件
dd if=./out/boot/mbr.bin of=./sys.img count=1 conv=notrunc bs=512
dd if=./out/boot/loader.bin of=./sys.img count=4 seek=2 conv=notrunc bs=512
dd if=./out/kernel/kernel.bin of=./sys.img count=200 seek=9 conv=notrunc bs=512

# 检查是否传入"run"参数
for arg in "$@"; do
    if [ "$arg" = "run" ]; then
        echo "Starting bochs..."
        bochs -debugger
        break
    fi
done

# 清理临时文件
rm -rf ./out

echo "Build completed successfully!"