#!/bin/bash



# 你可以在你的 yf.sh 脚本里加上这段：
uci add rpcd login
uci set rpcd.@login[-1].username='user'
# 这里的密码不再使用 '$p$user'（不再关联底层 /etc/shadow），而是直接设置明文或哈希字符串。
# 这样系统就不会去校验系统底层是否存在该 Linux 用户，仅做 rpcd 级访问权限控制。
# uhttpd -m 123456
uci set rpcd.@login[-1].password='123456'
uci add_list rpcd.@login[-1].read='user_read'
uci add_list rpcd.@login[-1].write='user_write'
uci commit rpcd

/etc/init.d/rpcd restart

# 同时，记得在底层系统给 user 设置密码（可以通过在 yf.sh 脚本中写入）：
# 添加系统影子用户 (前提是没有此用户)
if ! grep -q "^user:" /etc/passwd; then
    # 优先尝试 useradd，如果失败则尝试 busybox 的 adduser
    useradd -M -s /bin/false user 2>/dev/null || adduser -h /var -s /bin/false -D user 2>/dev/null
fi
# 强制将 user 的密码设为 123456
echo -e "123456\n123456" | passwd user