#!/bin/bash

# 本脚本在openmptcprouter系统根目录下执行
echo "开始执行系统定制修改..."

# 优先通过配置文件修改
if command -v uci >/dev/null 2>&1; then
    # 修改系统主机名为 YF-Router
    uci set system.@system[0].hostname='YF-Router' 2>/dev/null
    
    # 更改 OpenMPTCProuter 在 LuCI 菜单中的显示文本
    # 注意：部分前端可能直接取此项渲染
    uci set openmptcprouter.settings.menu='YF-Router' 2>/dev/null
    
    # 如果有对应的版本显示，可以直接修改最新版本信息防止检测到新版
    # 将目前系统的检查记录给清空或设为极大值，能有效降低弹窗几率
    uci delete openmptcprouter.latest_versions.omr 2>/dev/null
    
    uci commit
    echo "[✓] UCI配置(主机名/系统菜单)已更新"
fi

# 1. logo图标更换为本文件夹下的logo.jpg
LOGO_SRC="$(dirname "$0")/logo.jpg"
LOGO_DEST="/www/luci-static/openmptcprouter/images/omr-logo.png"
if [ -f "$LOGO_SRC" ]; then
    mkdir -p "$(dirname "$LOGO_DEST")"
    cp -f "$LOGO_SRC" "$LOGO_DEST"
    echo "[✓] Logo 图片已替换为 ${LOGO_SRC}"
else
    echo "[!] 警告: 找不到 ${LOGO_SRC}，跳过Logo图片更换"
fi

# 2. logo文本由 OpenMPTCProuter 更换为 YF-Router
HEADER_HTM="/usr/lib/lua/luci/view/themes/openmptcprouter/header.htm"
if [ -f "$HEADER_HTM" ]; then
    sed -i 's/alt="OpenMPTCProuter"/alt="YF-Router"/g' "$HEADER_HTM"
    sed -i 's/\/> OpenMPTCProuter<\/a>/\/> YF-Router<\/a>/g' "$HEADER_HTM"
    echo "[✓] Logo 文本已更换为主标题 YF-Router"
else
    echo "[!] 警告: 找不到 ${HEADER_HTM}"
fi

# 3. 底部信息由 Powered by ... 更换为 Powered by YF-Router v1.1
FOOTER_HTM="/usr/lib/lua/luci/view/themes/openmptcprouter/footer.htm"
if [ -f "$FOOTER_HTM" ]; then
    # 替换源码中带超链接或不带超链接的标识文本
    sed -i 's|<a href="https://github.com/ysurac/openmptcprouter">Powered by <%= ver.distversion %></a>|Powered by YF-Router v1.1|g' "$FOOTER_HTM"
    sed -i 's/Powered by <%= ver.distversion %>/Powered by YF-Router v1.1/g' "$FOOTER_HTM"
    echo "[✓] 底部信息已更改为 Powered by YF-Router v1.1"
else
    echo "[!] 警告: 找不到 ${FOOTER_HTM}"
fi

# 4. 登录成功后跳转页由 /cgi-bin/luci/ 更换为 /cgi-bin/luci/admin/system/openmptcprouter
INDEX_HTML="/www/index.html"
if [ -f "$INDEX_HTML" ]; then
    sed -i 's|URL=cgi-bin/luci/|URL=/cgi-bin/luci/admin/system/openmptcprouter|g' "$INDEX_HTML"
    sed -i 's|href="cgi-bin/luci/"|href="/cgi-bin/luci/admin/system/openmptcprouter"|g' "$INDEX_HTML"
    echo "[✓] 根目录的登录跳转重定向已更新"
else
    echo "[!] 警告: 找不到 ${INDEX_HTML}"
fi

# 5. 任何情况都不弹出新版本 available 的更新提示框
if [ -f "$HEADER_HTM" ]; then
    # 直接在模板逻辑里把 "A < B" 的新旧版本判断条件替换回 false，则始终不进入弹窗渲染循环
    sed -i 's/current_omr_version < latest_omr_version then/false then/g' "$HEADER_HTM"
    echo "[✓] 更新弹窗硬编码限制成功，不再弹出"
fi

# 清理 LuCI Web 缓存使改动生效
if [ -d "/tmp/luci-modulecache" ]; then
    rm -rf /tmp/luci-modulecache/* 
fi
/etc/init.d/uhttpd restart 2>/dev/null
echo "[✓] 已重启 uhttpd 并清理了 LuCI 缓存"

echo "所有配置和代码修改项已顺利执行完毕！"
