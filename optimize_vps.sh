#!/bin/bash

# Script Optimasi Latensi VPS
# Jalankan dengan sudo/root

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}[+] Memulai optimasi latensi VPS...${NC}"

# Cek apakah dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
   echo -e "${RED}[!] Script ini harus dijalankan sebagai root${NC}" 
   exit 1
fi

# Update dan upgrade system
echo -e "${YELLOW}[*] Mengupdate sistem...${NC}"
apt-get update && apt-get upgrade -y

# Install tools yang diperlukan
echo -e "${YELLOW}[*] Menginstall tools yang diperlukan...${NC}"
apt-get install -y ethtool net-tools haveged htop iftop

# Mengaktifkan dan memulai haveged (meningkatkan entropy)
systemctl enable haveged
systemctl start haveged

# Optimasi kernel melalui sysctl
echo -e "${YELLOW}[*] Mengoptimasi parameter kernel...${NC}"
cat > /etc/sysctl.d/99-network-tune.conf << EOF
# Meningkatkan ukuran buffer TCP
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 65536
net.core.somaxconn = 32768

# Meningkatkan buffer TCP per connection
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 65536 131072 262144

# Optimasi TCP
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

# Perbaikan timeout IPv4
net.ipv4.ip_local_port_range = 1024 65535

# Pengaturan swap
vm.swappiness = 10
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2

# Pengurangan lantesi jaringan
net.core.busy_poll = 50
net.core.busy_read = 50
EOF

# Menerapkan perubahan sysctl
sysctl -p /etc/sysctl.d/99-network-tune.conf

# Cek dan aktifkan BBR jika tersedia
echo -e "${YELLOW}[*] Memeriksa dan mengaktifkan BBR congestion control...${NC}"
if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.d/99-network-tune.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-network-tune.conf
    sysctl -p /etc/sysctl.d/99-network-tune.conf
    echo -e "${GREEN}[+] BBR congestion control berhasil diaktifkan${NC}"
else
    echo -e "${RED}[!] BBR tidak tersedia pada kernel ini${NC}"
fi

# Optimasi NIC dengan ethtool
echo -e "${YELLOW}[*] Mengoptimasi network interfaces...${NC}"
for interface in $(ip -o -4 addr show | awk '{print $2}' | grep -v "lo" | cut -d/ -f1); do
    echo -e "${GREEN}[+] Mengoptimasi $interface ${NC}"
    
    # Menonaktifkan power saving mode
    ethtool -s $interface gso off gro off tso off
    ethtool --offload $interface rx off tx off
    
    # Meningkatkan ring buffer jika didukung
    CURRENT_RX=$(ethtool -g $interface 2>/dev/null | grep "RX:" | head -1 | awk '{print $2}')
    CURRENT_TX=$(ethtool -g $interface 2>/dev/null | grep "TX:" | head -1 | awk '{print $2}')
    
    if [ ! -z "$CURRENT_RX" ] && [ ! -z "$CURRENT_TX" ]; then
        ethtool -G $interface rx $CURRENT_RX tx $CURRENT_TX
    fi
done

# Script untuk mengatur prioritas paket
echo -e "${YELLOW}[*] Mengkonfigurasi QoS untuk prioritas paket...${NC}"
cat > /usr/local/sbin/network-tune.sh << 'EOF'
#!/bin/bash

# Reset iptables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# Set default policy
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Memprioritaskan paket ACK dan paket kecil
iptables -t mangle -A PREROUTING -p tcp -m tcp --tcp-flags ACK ACK -j CLASSIFY --set-class 1:1
iptables -t mangle -A PREROUTING -p tcp -m length --length 0:128 -j CLASSIFY --set-class 1:1
iptables -t mangle -A PREROUTING -p udp -m length --length 0:128 -j CLASSIFY --set-class 1:1

# Prioritas untuk ICMP (ping)
iptables -t mangle -A PREROUTING -p icmp -j CLASSIFY --set-class 1:1

INTERFACES=$(ip -o -4 addr show | awk '{print $2}' | grep -v "lo" | cut -d/ -f1)
for IFACE in $INTERFACES; do
    # Membuat qdisc dengan fq_codel (fair queuing dengan controlled delay)
    tc qdisc del dev $IFACE root 2> /dev/null
    tc qdisc add dev $IFACE root handle 1: htb default 10
    tc class add dev $IFACE parent 1: classid 1:1 htb rate 1000mbit ceil 1000mbit prio 1
    tc qdisc add dev $IFACE parent 1:1 fq_codel quantum 300 ecn
done
EOF

chmod +x /usr/local/sbin/network-tune.sh
/usr/local/sbin/network-tune.sh

# Buat systemd service untuk menjalankan script saat startup
echo -e "${YELLOW}[*] Membuat systemd service...${NC}"
cat > /etc/systemd/system/network-tune.service << EOF
[Unit]
Description=Network Optimization for Low Latency
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/network-tune.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable network-tune.service
systemctl start network-tune.service

# Selesai
echo -e "${GREEN}[+] Optimasi latensi VPS selesai!${NC}"
echo -e "${YELLOW}[*] Disarankan untuk melakukan reboot sistem${NC}"
echo -e "${YELLOW}[*] Reboot sekarang? (y/n)${NC}"
read answer
if [ "$answer" == "y" ] || [ "$answer" == "Y" ]; then
    reboot
fi
