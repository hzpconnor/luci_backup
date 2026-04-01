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
    # 不要通过 uci 修改，否则会导致 controller 注册二级菜单路径改变，引起 /admin/system/openmptcprouter 菜单丢失
    # uci set openmptcprouter.settings.menu='YF-Router' 2>/dev/null
    
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
HEADER_UT="/usr/lib/lua/luci/view/themes/openmptcprouter/header.htm"
if [ -f "$HEADER_UT" ]; then
    sed -i 's/alt="OpenMPTCProuter"/alt="YF-Router"/g' "$HEADER_UT"
    sed -i 's/\/> OpenMPTCProuter<\/a>/\/> YF-Router<\/a>/g' "$HEADER_UT"
    sed -i 's/omr-logo\.png/logo\.jpg/g' "$HEADER_UT"
    echo "[✓] Logo 文本已更换为主标题 YF-Router，并且图标变更为 logo.jpg"
else
    echo "[!] 警告: 找不到 ${HEADER_UT}"
fi

# 3. 底部信息由 Powered by ... 更换为 Powered by YF-Router v1.1
FOOTER_UT="/usr/lib/lua/luci/view/themes/openmptcprouter/footer.htm"
if [ -f "$FOOTER_UT" ]; then
    # 替换源码中带超链接或不带超链接的标识文本及目标网址
    sed -i 's|<a href="https://github.com/ysurac/openmptcprouter">Powered by <%= ver.distversion %></a>|<a href="https://yfconf.com">Powered by YF-Router v1.1</a>|g' "$FOOTER_UT"
    sed -i 's/Powered by <%= ver.distversion %>/Powered by YF-Router v1.1/g' "$FOOTER_UT"
    echo "[✓] 底部信息及链接已更改为 Powered by YF-Router v1.1"
else
    echo "[!] 警告: 找不到 ${FOOTER_UT}"
fi

# 4. 登录成功后跳转页改到 /cgi-bin/luci/admin/system/openmptcprouter/status
INDEX_HTML="/www/index.html"
if [ -f "$INDEX_HTML" ]; then
    sed -i 's|URL=cgi-bin/luci/|URL=/cgi-bin/luci/admin/system/openmptcprouter|g' "$INDEX_HTML"
    sed -i 's|href="cgi-bin/luci/"|href="/cgi-bin/luci/admin/system/openmptcprouter"|g' "$INDEX_HTML"
    echo "[✓] 根目录的网页重定向已更新"
else
    echo "[!] 警告: 找不到 ${INDEX_HTML}"
fi

# 另外，要改变LuCI框架内登录(sysauth)成功后的默认跳转逻辑：
# LuCI 通过判断节点 order 权重决定首选页面，由于 system 默认 order 为 20 ，而 status 为 10，dashboard 为 5
# 我们给 admin/dashboard 和 admin/status 增加 order 的值，使得 admin/system 自动成为首选跳转目标
LUCI_BASE_JSON="/usr/share/luci/menu.d/luci-base.json"
LUCI_DASHBOARD_JSON="/usr/share/luci/menu.d/luci-mod-dashboard.json"

if [ -f "$LUCI_BASE_JSON" ]; then
    # 将 admin/status 的 order 10 改为 30, 使得 admin/system (order 20) 成为靠前项
    sed -i '/"admin\/status": {/,/"order":/ s/"order": [0-9]*/"order": 30/' "$LUCI_BASE_JSON"
fi

if [ -f "$LUCI_DASHBOARD_JSON" ]; then
    # 将 dashboard 的 order 5 改为 40
    sed -i 's/"order": 5/"order": 40/g' "$LUCI_DASHBOARD_JSON"
fi

# 清理 LuCI index 缓存，强制重新计算菜单和路由跳转逻辑
rm -f /tmp/luci-indexcache*
echo "[✓] LuCI 后台内部登录重定向(Order权重)已更新"

# 另外修改系统主菜单显示名称为 YF-Router，避免修改 UCI 导致控制器路径漂移
MENU_JSON="/usr/share/luci/menu.d/luci-app-openmptcprouter.json"
if [ -f "$MENU_JSON" ]; then
    sed -i 's/"title": "OpenMPTCProuter"/"title": "YF-Router"/g' "$MENU_JSON"
    echo "[✓] 左侧系统主菜单名称已更改为 YF-Router"
fi

# 将 OpenMPTCProuter 控制器子菜单中 status 调整为第一项，wizard 降为第二项
OMPR_CTRL="/usr/lib/lua/luci/controller/openmptcprouter.lua"
if [ -f "$OMPR_CTRL" ]; then
    # 根节点默认跳转目标由 wizard 改为 status
    sed -i 's/alias("admin", "system", menuentry:lower(), "wizard")/alias("admin", "system", menuentry:lower(), "status")/' "$OMPR_CTRL"
    # # status order 2 → 1
    # sed -i 's/template("openmptcprouter\/wanstatus"), _("Status"), 2/template("openmptcprouter\/wanstatus"), _("Status"), 1/' "$OMPR_CTRL"
    # # wizard order 1 → 2
    # sed -i 's/template("openmptcprouter\/wizard"), _("Settings Wizard"), 1/template("openmptcprouter\/wizard"), _("Settings Wizard"), 2/' "$OMPR_CTRL"
    echo "[✓] OpenMPTCProuter 子菜单 Status 已调整为首位"
else
    echo "[!] 警告: 找不到 ${OMPR_CTRL}，跳过子菜单排序调整"
fi

# 5. 任何情况都不弹出新版本 available 的更新提示框
if [ -f "$HEADER_UT" ]; then
    # 直接在模板逻辑里把 "A < B" 的新旧版本判断条件替换回 false，则始终不进入弹窗渲染循环
    sed -i 's/current_omr_version < latest_omr_version/false/g' "$HEADER_UT"
    echo "[✓] 更新弹窗硬编码限制成功，不再弹出"
fi

# 6. 浏览器标签页(Title)和图标(Favicon)同步更换为 YF-Router 与 logo.jpg
if [ -f "$HEADER_UT" ]; then
    # 直接将整个 <title> 标签内容强制替换为固定只显示 YF-Router
    sed -i 's|<title>.*</title>|<title>YF-Router</title>|g' "$HEADER_UT"
    
    # 替换浏览器小图标和苹果桌面书签图标，指向新的 logo.jpg
    sed -i 's/favicon\.png/images\/logo\.jpg/g' "$HEADER_UT"
    sed -i 's/href="{{ media }}\/images\/logo\.jpg"/href="{{ media }}\/images\/logo\.jpg"/g' "$HEADER_UT"
    sed -i 's/omr-logo-apple\.png/images\/logo\.jpg/g' "$HEADER_UT"
    
    echo "[✓] 浏览器标签页标题及小图标已更新"
fi

# 7. 添加登录页面背景
LOGIN_BG_SRC="$(dirname "$0")/login_bg.png"
if [ -f "$LOGIN_BG_SRC" ]; then
    mkdir -p /www/luci-static/resources/openmptcprouter/images/
    mkdir -p /www/luci-static/openmptcprouter/images/
    
    cp -f "$LOGIN_BG_SRC" "/www/luci-static/resources/openmptcprouter/images/login_bg.png"
    cp -f "$LOGIN_BG_SRC" "/www/luci-static/openmptcprouter/images/login_bg.png"
    
    SYSAUTH_UT="/usr/share/ucode/luci/template/sysauth.ut"
    if [ -f "$SYSAUTH_UT" ]; then
        if ! grep -q "login_bg\.png" "$SYSAUTH_UT"; then
            sed -i '/{% include('\''header'\'') %}/a\\n<style>body { background: url("{{ media }}/images/login_bg.png") no-repeat center center fixed !important; background-size: cover !important; }<\/style>' "$SYSAUTH_UT"
        fi
    fi
    
    CASCADE_CSS="/www/luci-static/openmptcprouter/cascade.css"
    if [ -f "$CASCADE_CSS" ]; then
        if ! grep -q "login_bg\.png" "$CASCADE_CSS"; then
            echo "" >> "$CASCADE_CSS"
            echo "/* 添加登录页背景 */" >> "$CASCADE_CSS"
            echo "body.sysauth, body[data-page=\"sysauth\"] { background: url('images/login_bg.png') no-repeat center center fixed !important; background-size: cover !important; }" >> "$CASCADE_CSS"
        fi
    fi
    
    echo "[✓] 登录页面背景已设置为 login_bg.png"
else
    echo "[!] 警告: 找不到 ${LOGIN_BG_SRC}，跳过登录页面背景设置"
fi

# 清理 LuCI Web 缓存使改动生效
if [ -d "/tmp/luci-modulecache" ]; then
    rm -rf /tmp/luci-modulecache/* 
fi
# /etc/init.d/uhttpd restart 2>/dev/null
echo "[✓] 未重启 uhttpd 但已清理了 LuCI 缓存"

echo "所有配置和代码修改项已顺利执行完毕！"
