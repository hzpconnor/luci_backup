




ssh-keygen -R 192.168.100.1; scp -O -o StrictHostKeyChecking=no -r d:\test\test7\YF-Router\ root@192.168.100.1:/YF-Router/; ssh -o StrictHostKeyChecking=no root@192.168.100.1 "sh /YF-Router/yf.sh"
