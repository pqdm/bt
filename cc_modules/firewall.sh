#!/bin/bash

#宝塔面板服务器维护工具 - 防火墙配置模块

# 设置基本防火墙规则
setup_basic_firewall() {
    echo -e "${BLUE}【设置基本防火墙规则】${NC}"
    echo "=================================="
    
    # 检查iptables是否可用
    if ! command -v iptables &> /dev/null; then
        echo -e "${RED}❌ iptables未安装${NC}"
        return 1
    fi
    
    # 创建新链
    iptables -N CC_DEFENSE 2>/dev/null || iptables -F CC_DEFENSE
    
    # 添加基本规则
    echo -e "${YELLOW}添加基本防火墙规则...${NC}"
    
    # 允许已建立的连接
    iptables -A CC_DEFENSE -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # 允许本地回环接口
    iptables -A CC_DEFENSE -i lo -j ACCEPT
    
    # 限制单IP的连接数
    iptables -A CC_DEFENSE -p tcp --syn -m connlimit --connlimit-above 50 -j DROP
    
    # 限制单IP在60秒内的新建连接数
    iptables -A CC_DEFENSE -p tcp --syn -m recent --name CC_CONN --update --seconds 60 --hitcount 30 -j DROP
    iptables -A CC_DEFENSE -p tcp --syn -m recent --name CC_CONN --set
    
    # 限制ICMP流量
    iptables -A CC_DEFENSE -p icmp -m limit --limit 1/s --limit-burst 5 -j ACCEPT
    iptables -A CC_DEFENSE -p icmp -j DROP
    
    # 应用CC_DEFENSE链到INPUT链
    iptables -A INPUT -j CC_DEFENSE
    
    # 添加Web服务端口规则
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # 允许SSH端口
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # 允许宝塔面板端口
    iptables -A INPUT -p tcp --dport 8888 -j ACCEPT
    
    # 保存规则
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/sysconfig/iptables 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ 基本防火墙规则已设置${NC}"
    log_message "FIREWALL: Basic firewall rules set up"
    
    return 0
}

# 设置高级防火墙规则
setup_advanced_firewall() {
    echo -e "${BLUE}【设置高级防火墙规则】${NC}"
    echo "=================================="
    
    # 检查iptables是否可用
    if ! command -v iptables &> /dev/null; then
        echo -e "${RED}❌ iptables未安装${NC}"
        return 1
    fi
    
    # 创建新链
    iptables -N CC_ADVANCED 2>/dev/null || iptables -F CC_ADVANCED
    
    # 添加高级规则
    echo -e "${YELLOW}添加高级防火墙规则...${NC}"
    
    # SYN洪水攻击防护
    iptables -A CC_ADVANCED -p tcp --syn -m limit --limit 1/s --limit-burst 5 -j ACCEPT
    iptables -A CC_ADVANCED -p tcp --syn -j DROP
    
    # 端口扫描防护
    iptables -A CC_ADVANCED -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 5 -j ACCEPT
    iptables -A CC_ADVANCED -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j DROP
    
    # XMAS扫描防护
    iptables -A CC_ADVANCED -p tcp --tcp-flags ALL ALL -j DROP
    
    # NULL扫描防护
    iptables -A CC_ADVANCED -p tcp --tcp-flags ALL NONE -j DROP
    
    # 应用CC_ADVANCED链到INPUT链
    iptables -A INPUT -j CC_ADVANCED
    
    # 保存规则
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/sysconfig/iptables 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ 高级防火墙规则已设置${NC}"
    log_message "FIREWALL: Advanced firewall rules set up"
    
    return 0
}

# 设置CC攻击防护规则
setup_cc_protection() {
    echo -e "${BLUE}【设置CC攻击防护规则】${NC}"
    echo "=================================="
    
    # 检查iptables是否可用
    if ! command -v iptables &> /dev/null; then
        echo -e "${RED}❌ iptables未安装${NC}"
        return 1
    fi
    
    # 创建新链
    iptables -N CC_PROTECT 2>/dev/null || iptables -F CC_PROTECT
    
    # 添加CC防护规则
    echo -e "${YELLOW}添加CC攻击防护规则...${NC}"
    
    # 限制单IP对80端口的并发连接数
    iptables -A CC_PROTECT -p tcp --dport 80 -m connlimit --connlimit-above 30 --connlimit-mask 32 -j DROP
    
    # 限制单IP对443端口的并发连接数
    iptables -A CC_PROTECT -p tcp --dport 443 -m connlimit --connlimit-above 30 --connlimit-mask 32 -j DROP
    
    # 限制单IP在60秒内对Web端口的新建连接数
    iptables -A CC_PROTECT -p tcp --dport 80 -m recent --name CC_HTTP --update --seconds 60 --hitcount 60 -j DROP
    iptables -A CC_PROTECT -p tcp --dport 80 -m recent --name CC_HTTP --set
    
    iptables -A CC_PROTECT -p tcp --dport 443 -m recent --name CC_HTTPS --update --seconds 60 --hitcount 60 -j DROP
    iptables -A CC_PROTECT -p tcp --dport 443 -m recent --name CC_HTTPS --set
    
    # 应用CC_PROTECT链到INPUT链
    iptables -A INPUT -j CC_PROTECT
    
    # 保存规则
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/sysconfig/iptables 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ CC攻击防护规则已设置${NC}"
    log_message "FIREWALL: CC protection rules set up"
    
    return 0
}

# 应用黑名单到防火墙
apply_blacklist_to_firewall() {
    echo -e "${BLUE}【应用黑名单到防火墙】${NC}"
    echo "=================================="
    
    # 检查iptables是否可用
    if ! command -v iptables &> /dev/null; then
        echo -e "${RED}❌ iptables未安装${NC}"
        return 1
    fi
    
    # 检查黑名单文件
    if [ ! -f "$BLACKLIST_FILE" ]; then
        echo -e "${YELLOW}⚠️ 黑名单文件不存在${NC}"
        return 1
    fi
    
    # 创建新链
    iptables -N CC_BLACKLIST 2>/dev/null || iptables -F CC_BLACKLIST
    
    # 应用黑名单
    echo -e "${YELLOW}应用黑名单到防火墙...${NC}"
    
    local count=0
    while IFS="|" read -r ip timestamp expiry reason; do
        iptables -A CC_BLACKLIST -s "$ip" -j DROP
        count=$((count + 1))
    done < "$BLACKLIST_FILE"
    
    # 应用CC_BLACKLIST链到INPUT链
    iptables -A INPUT -j CC_BLACKLIST
    
    # 保存规则
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/sysconfig/iptables 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ 已将 $count 个黑名单IP应用到防火墙${NC}"
    log_message "FIREWALL: Applied $count blacklisted IPs to firewall"
    
    return 0
}

# 清理防火墙规则
clean_firewall_rules() {
    echo -e "${BLUE}【清理防火墙规则】${NC}"
    echo "=================================="
    
    # 检查iptables是否可用
    if ! command -v iptables &> /dev/null; then
        echo -e "${RED}❌ iptables未安装${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}清理防火墙规则...${NC}"
    
    # 删除自定义链引用
    iptables -D INPUT -j CC_DEFENSE 2>/dev/null
    iptables -D INPUT -j CC_ADVANCED 2>/dev/null
    iptables -D INPUT -j CC_PROTECT 2>/dev/null
    iptables -D INPUT -j CC_BLACKLIST 2>/dev/null
    
    # 清空并删除自定义链
    iptables -F CC_DEFENSE 2>/dev/null
    iptables -X CC_DEFENSE 2>/dev/null
    
    iptables -F CC_ADVANCED 2>/dev/null
    iptables -X CC_ADVANCED 2>/dev/null
    
    iptables -F CC_PROTECT 2>/dev/null
    iptables -X CC_PROTECT 2>/dev/null
    
    iptables -F CC_BLACKLIST 2>/dev/null
    iptables -X CC_BLACKLIST 2>/dev/null
    
    # 保存规则
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/sysconfig/iptables 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ 防火墙规则已清理${NC}"
    log_message "FIREWALL: Firewall rules cleaned"
    
    return 0
}

# 显示防火墙规则
show_firewall_rules() {
    echo -e "${BLUE}【当前防火墙规则】${NC}"
    echo "=================================="
    
    # 检查iptables是否可用
    if ! command -v iptables &> /dev/null; then
        echo -e "${RED}❌ iptables未安装${NC}"
        return 1
    fi
    
    echo -e "${CYAN}INPUT链规则:${NC}"
    iptables -L INPUT -n --line-numbers
    
    echo -e "${CYAN}CC_DEFENSE链规则:${NC}"
    iptables -L CC_DEFENSE -n --line-numbers 2>/dev/null || echo "链不存在"
    
    echo -e "${CYAN}CC_ADVANCED链规则:${NC}"
    iptables -L CC_ADVANCED -n --line-numbers 2>/dev/null || echo "链不存在"
    
    echo -e "${CYAN}CC_PROTECT链规则:${NC}"
    iptables -L CC_PROTECT -n --line-numbers 2>/dev/null || echo "链不存在"
    
    echo -e "${CYAN}CC_BLACKLIST链规则:${NC}"
    iptables -L CC_BLACKLIST -n --line-numbers 2>/dev/null || echo "链不存在"
    
    return 0
}

# 配置防火墙自启动
setup_firewall_autostart() {
    echo -e "${BLUE}【配置防火墙自启动】${NC}"
    echo "=================================="
    
    # 检查系统类型
    local is_systemd=false
    if command -v systemctl &> /dev/null; then
        is_systemd=true
    fi
    
    if [ "$is_systemd" = true ]; then
        # 对于systemd系统
        if [ -f "/etc/systemd/system/cc-firewall.service" ]; then
            echo -e "${YELLOW}⚠️ 防火墙自启动服务已存在${NC}"
        else
            cat > "/etc/systemd/system/cc-firewall.service" << EOF
[Unit]
Description=CC Defense Firewall Rules
After=network.target

[Service]
Type=oneshot
ExecStart=/root/cc_defense.sh --firewall
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
            
            systemctl daemon-reload
            systemctl enable cc-firewall.service
            
            echo -e "${GREEN}✅ 防火墙自启动服务已配置${NC}"
        fi
    else
        # 对于init.d系统
        if [ -f "/etc/init.d/cc-firewall" ]; then
            echo -e "${YELLOW}⚠️ 防火墙自启动脚本已存在${NC}"
        else
            cat > "/etc/init.d/cc-firewall" << EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides:          cc-firewall
# Required-Start:    \$network
# Required-Stop:     \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: CC Defense Firewall Rules
# Description:       Start CC Defense Firewall Rules
### END INIT INFO

case "\$1" in
    start)
        echo "Starting CC Defense Firewall Rules"
        /root/cc_defense.sh --firewall
        ;;
    stop)
        echo "Stopping CC Defense Firewall Rules"
        /root/cc_defense.sh --clean-firewall
        ;;
    restart)
        echo "Restarting CC Defense Firewall Rules"
        /root/cc_defense.sh --clean-firewall
        /root/cc_defense.sh --firewall
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart}"
        exit 1
        ;;
esac
exit 0
EOF
            
            chmod +x /etc/init.d/cc-firewall
            
            if command -v chkconfig &> /dev/null; then
                chkconfig --add cc-firewall
                chkconfig cc-firewall on
            elif command -v update-rc.d &> /dev/null; then
                update-rc.d cc-firewall defaults
            fi
            
            echo -e "${GREEN}✅ 防火墙自启动脚本已配置${NC}"
        fi
    fi
    
    log_message "FIREWALL: Firewall autostart configured"
    
    return 0
}
