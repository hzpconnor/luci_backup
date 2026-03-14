#!/bin/bash

# 本脚本用于备份和恢复 YF-Router 修改的系统文件和配置
# 也可以单独由 yf.sh 调用来进行自动备份

BACKUP_DIR="/yf_backup"

# 需要备份的文件列表
FILES_TO_BACKUP=(
    "/www/luci-static/openmptcprouter/images/omr-logo.png"
    "/usr/lib/lua/luci/view/themes/openmptcprouter/header.htm"
    "/usr/lib/lua/luci/view/themes/openmptcprouter/footer.htm"
    "/www/index.html"
    "/usr/share/luci/menu.d/luci-base.json"
)

backup() {
    echo "=== 开始备份系统原始文件 ==="
    mkdir -p "$BACKUP_DIR"
    
    # 备份 UCI 配置
    if command -v uci >/dev/null 2>&1; then
        uci export system > "$BACKUP_DIR/uci_system.bak"
        uci export openmptcprouter > "$BACKUP_DIR/uci_openmptcprouter.bak"
        echo "[✓] UCI 配置已备份到 $BACKUP_DIR"
    fi

    # 备份实体文件
    for file in "${FILES_TO_BACKUP[@]}"; do
        if [ -f "$file" ]; then
            # 保持目录结构备份
            target_dir="$BACKUP_DIR$(dirname "$file")"
            mkdir -p "$target_dir"
            
            # 只有当备份不存在时才备份，防止覆盖掉最初的原始文件
            if [ ! -f "$target_dir/$(basename "$file")" ]; then
                cp -p "$file" "$target_dir/"
                echo "[✓] 已备份文件: $file"
            else
                echo "[-] 备份已存在，跳过: $file"
            fi
        else
            echo "[!] 文件不存在，无法备份: $file"
        fi
    done
    echo "=== 备份完成 ==="
}

restore() {
    echo "=== 开始撤销修改并恢复原始系统 ==="
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "[!] 未找到备份目录 ($BACKUP_DIR)，无法恢复！"
        exit 1
    fi

    # 恢复 UCI 配置
    if command -v uci >/dev/null 2>&1; then
        if [ -f "$BACKUP_DIR/uci_system.bak" ]; then
            uci import system < "$BACKUP_DIR/uci_system.bak"
            echo "[✓] system UCI 配置已还原"
        fi
        if [ -f "$BACKUP_DIR/uci_openmptcprouter.bak" ]; then
            uci import openmptcprouter < "$BACKUP_DIR/uci_openmptcprouter.bak"
            echo "[✓] openmptcprouter UCI 配置已还原"
        fi
        uci commit
    fi

    # 恢复实体文件
    for file in "${FILES_TO_BACKUP[@]}"; do
        backup_file="$BACKUP_DIR$file"
        if [ -f "$backup_file" ]; then
            cp -pf "$backup_file" "$file"
            echo "[✓] 已还原文件: $file"
        else
            echo "[!] 备份中未找到文件: $file"
        fi
    done

    # 清理 LuCI Web 缓存使改动生效
    if [ -d "/tmp/luci-modulecache" ]; then
        rm -rf /tmp/luci-modulecache/* 
    fi
    # /etc/init.d/uhttpd restart 2>/dev/null
    
    echo "=== 恢复完成，系统已还原 ==="
}

case "$1" in
    backup)
        backup
        ;;
    restore|undo)
        restore
        ;;
    *)
        echo "用法: $0 {backup|restore}"
        echo "  backup  - 备份当前的系统核心文件和配置"
        echo "  restore - 撤销所有修改并恢复到备份时的状态"
        exit 1
        ;;
esac
