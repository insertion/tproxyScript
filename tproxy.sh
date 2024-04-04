#策略路由
ip route add local default dev lo table 100
ip rule add fwmark 1 table 100


# 127.0.0.0/8, 10.0.0.0/8, 192.168.0.0/16, 100.64.0.0/10, 169.254.0.0/16, 172.16.0.0/12, 224.0.0.0/4, 240.0.0.0/4, 255.255.255.255/32
iptables -t mangle -N SING_BOX_LAN
iptables -t mangle -A SING_BOX_LAN -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 192.0.0.0/24 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 255.255.255.255/32 -j RETURN

#局域网如何将本机作为dns服务器,会劫持到代理软件中
iptables -t mangle -A SING_BOX_LAN -d 192.168.0.0/16 -p tcp ! --dport 53 -j RETURN
iptables -t mangle -A SING_BOX_LAN -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN

# mark设置为1,会routing到本地回环网卡
iptables -t mangle -A SING_BOX_LAN -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A SING_BOX_LAN -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A PREROUTING -j SING_BOX_LAN


#本机浏览在出口处进行劫持,由于出口不支持TPROXY,我们需要将mark设为1,让其routing到本地回环入口
iptables -t mangle -N SING_BOX_LOCAL
iptables -t mangle -A SING_BOX_LOCAL -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 192.0.0.0/24 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 255.255.255.255/32 -j RETURN
# 经过代理软件处理的包会加上mark 1234，不会被劫持直接从网卡送出
iptables -t mangle -A SING_BOX_LOCAL  -j RETURN -m mark --mark 1234

#本机访问局域网dns也会被劫持
iptables -t mangle -A SING_BOX_LOCAL -d 192.168.0.0/16 -p tcp ! --dport 53 -j RETURN
iptables -t mangle -A SING_BOX_LOCAL -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN

# mark设置为1,会routing到本地回环网卡
iptables -t mangle -A SING_BOX_LOCAL -p tcp -j MARK --set-mark 1
iptables -t mangle -A SING_BOX_LOCAL -p udp -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -j SING_BOX_LOCAL