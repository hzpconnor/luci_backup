#!/bin/bash

# 调用 undo.sh 进行自动备份
# bash "$(dirname "$0")/undo.sh" backup

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
if [ -f "$LOGO_SRC" ]; then
    # OpenMPTCProuter theme specific resources
    mkdir -p /www/luci-static/resources/openmptcprouter/images/
    mkdir -p /www/luci-static/openmptcprouter/images/
    cp -f "$LOGO_SRC" "/www/luci-static/resources/openmptcprouter/images/logo.jpg"
    cp -f "$LOGO_SRC" "/www/luci-static/openmptcprouter/images/logo.jpg"
    echo "[✓] Logo 图片已放入相应目录系统"
else
    echo "[!] 警告: 找不到 ${LOGO_SRC}，跳过Logo图片更换"
fi

# 2. logo文本由 OpenMPTCProuter 更换为 YF-Router，同时修改图标路径
HEADER_HTM="/usr/lib/lua/luci/view/themes/openmptcprouter/header.htm"
if [ -f "$HEADER_HTM" ]; then
    sed -i 's/alt="OpenMPTCProuter"/alt="YF-Router"/g' "$HEADER_HTM"
    sed -i 's/\/> OpenMPTCProuter<\/a>/\/> YF-Router<\/a>/g' "$HEADER_HTM"
    sed -i 's/omr-logo\.png/logo\.jpg/g' "$HEADER_HTM"
    echo "[✓] Logo 文本已更换为主标题 YF-Router，并且图标变更为 logo.jpg"
else
    echo "[!] 警告: 找不到 ${HEADER_HTM}"
fi

# 3. 底部信息由 Powered by ... 更换为 Powered by YF-Router v1.1
FOOTER_HTM="/usr/lib/lua/luci/view/themes/openmptcprouter/footer.htm"
if [ -f "$FOOTER_HTM" ]; then
    # 替换源码中带超链接或不带超链接的标识文本及目标网址
    sed -i 's|<a href="https://github.com/ysurac/openmptcprouter">Powered by <%= ver.distversion %></a>|<a href="https://yf-router.com">Powered by YF-Router v1.1</a>|g' "$FOOTER_HTM"
    sed -i 's/Powered by <%= ver.distversion %>/Powered by YF-Router v1.1/g' "$FOOTER_HTM"
    echo "[✓] 底部信息及链接已更改为 Powered by YF-Router v1.1"
else
    echo "[!] 警告: 找不到 ${FOOTER_HTM}"
fi

# 4. 登录成功后跳转页改到 OpenMPTCProuter 或系统自定页面
INDEX_HTML="/www/index.html"
if [ -f "$INDEX_HTML" ]; then
    sed -i 's|URL=cgi-bin/luci/|URL=/cgi-bin/luci/admin/system/openmptcprouter|g' "$INDEX_HTML"
    sed -i 's|href="cgi-bin/luci/"|href="/cgi-bin/luci/admin/system/openmptcprouter"|g' "$INDEX_HTML"
    echo "[✓] 根目录的网页重定向已更新"
else
    echo "[!] 警告: 找不到 ${INDEX_HTML}"
fi

# 另外，要改变LuCI框架内登录(sysauth)成功后的默认跳转逻辑：
# LuCI 自动路由判定 admin 节点的首选子节点。原逻辑没有指定 preferred 参数，默认进入第一个节点（通常是 status/overview）。
# 我们在 luci-base.json 的 admin 节点下加入 "preferred": "system/openmptcprouter" (或你修改后的菜单名)。
LUCI_BASE_JSON="/usr/share/luci/menu.d/luci-base.json"
if [ -f "$LUCI_BASE_JSON" ]; then
    # 由于是JSON格式，匹配 action 里的 recurse 并在上方插入 preferred 选项。
    sed -i 's/"recurse": true/"preferred": "system\/openmptcprouter",\n\t\t\t"recurse": true/g' "$LUCI_BASE_JSON"
    echo "[✓] LuCI 后台内部登录重定向已更新"
fi

# 5. 任何情况都不弹出新版本 available 的更新提示框
if [ -f "$HEADER_HTM" ]; then
    # 直接在模板逻辑里把 "A < B" 的新旧版本判断条件替换回 false，则始终不进入弹窗渲染循环
    sed -i 's/current_omr_version < latest_omr_version then/false then/g' "$HEADER_HTM"
    echo "[✓] 更新弹窗硬编码限制成功，不再弹出"
fi

# 6. 浏览器标签页(Title)和图标(Favicon)同步更换为 YF-Router 与 logo.jpg
if [ -f "$HEADER_HTM" ]; then
    # 直接将整个 <title> 标签内容强制替换为固定只显示 YF-Router
    sed -i 's|<title>.*</title>|<title>YF-Router</title>|g' "$HEADER_HTM"
    
    # 替换浏览器小图标和苹果桌面书签图标，指向新的 logo.jpg
    sed -i 's/favicon\.png/images\/logo\.jpg/g' "$HEADER_HTM"
    sed -i 's/type="image\/png" href="<%=media%>\/images\/logo\.jpg"/href="<%=media%>\/images\/logo\.jpg"/g' "$HEADER_HTM"
    sed -i 's/omr-logo-apple\.png/images\/logo\.jpg/g' "$HEADER_HTM"
    
    echo "[✓] 浏览器标签页标题及小图标已更新"
fi

# 清理 LuCI Web 缓存使改动生效
if [ -d "/tmp/luci-modulecache" ]; then
    rm -rf /tmp/luci-modulecache/* 
fi
# /etc/init.d/uhttpd restart 2>/dev/null
echo "[✓] 未重启 uhttpd 但已清理了 LuCI 缓存"

echo "所有配置和代码修改项已顺利执行完毕！"
