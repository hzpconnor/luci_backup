#!/bin/bash



# 你可以在你的 yf.sh 脚本里加上这段：
uci add rpcd login
uci set rpcd.@login[-1].username='user'
# 这里的密码必须使用 '$p$user' 或 Hash（uhttpd -m 123456) 后的密码串。
# 我们在这里通过 uhttpd 动态生成 123456 的 Hash 字符串
HASH_PASS=$(uhttpd -m 123456)
uci set rpcd.@login[-1].password="$HASH_PASS"
uci add_list rpcd.@login[-1].read='user_read'
uci add_list rpcd.@login[-1].write='user_write'
uci commit rpcd

/etc/init.d/rpcd restart

# # 同时，记得在底层系统给 user 设置密码（可以通过在 yf.sh 脚本中写入）：
# # 添加系统影子用户 (前提是没有此用户)
# if ! grep -q "^user:" /etc/passwd; then
#     # 优先尝试 useradd，如果失败则尝试 busybox 的 adduser
#     useradd -M -s /bin/false user 2>/dev/null || adduser -h /var -s /bin/false -D user 2>/dev/null
# fi
# # 强制将 user 的密码设为 123456
# echo -e "123456\n123456" | passwd user