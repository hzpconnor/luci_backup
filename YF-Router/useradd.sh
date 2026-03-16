#!/bin/bash



# 你可以在你的 yf.sh 脚本里加上这段：
uci add rpcd login
uci set rpcd.@login[-1].username='user'
uci set rpcd.@login[-1].password='$p$user'  # '$p$user'代表读取系统的/etc/shadow中的user密码，也可以直接写明文(不安全)
uci add_list rpcd.@login[-1].read='user_read'
uci add_list rpcd.@login[-1].write='user_write'
uci commit rpcd



# 同时，记得在底层系统给 user 设置密码（可以通过在 yf.sh 脚本中写入）：
# 添加系统影子用户 (前提是没有此用户)
echo "user:x:1001:1001:user:/var:/bin/false" >> /etc/passwd
echo "user:!:19000:0:99999:7:::" >> /etc/shadow
# 强制将 user 的密码设为 123456
echo -e "123456\n123456" | passwd user