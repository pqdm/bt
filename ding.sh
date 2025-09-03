#!/bin/bash

# 宝塔面板服务器安全监控脚本 - 完整增强版
# 功能：检查挖矿程序、CC攻击、CPU占用问题，并提供自动修复
# 作者：咸鱼神秘人
# 联系方式：微信dingyanan2008 QQ314450957

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志文件
LOG_FILE="/tmp/bt_monitor_$(date +%Y%m%d_%H%M%S).log"

# 记录日志函数
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 显示标题
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                宝塔面板服务器安全监控系统                    ║${NC}"
    echo -e "${CYAN}║              BT Panel Security Monitor                      ║${NC}"
    echo -e "${CYAN}║                    完整增强版 - 专业版                       ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  作者: 咸鱼神秘人 | 微信: dingyanan2008 | QQ: 314450957      ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 实时监控模式
real_time_monitor() {
    echo -e "${GREEN}启动实时监控模式...${NC}"
    echo -e "${YELLOW}按 Ctrl+C 退出监控${NC}"
    echo ""
    
    while true; do
        clear
        show_header
        echo -e "${CYAN}实时监控中... $(date)${NC}"
        echo "=================================="
        
        # 实时显示关键指标
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
        CONN_COUNT=$(netstat -an | wc -l)
        TIME_WAIT=$(netstat -an | grep TIME_WAIT | wc -l)
        PHP_PROCESSES=$(ps aux | grep php-fpm | grep -v grep | wc -l)
        
        echo -e "CPU: ${YELLOW}${CPU_USAGE}%${NC} | 内存: ${YELLOW}${MEM_USAGE}%${NC} | 连接: ${YELLOW}$CONN_COUNT${NC} | TIME_WAIT: ${YELLOW}$TIME_WAIT${NC} | PHP进程: ${YELLOW}$PHP_PROCESSES${NC}"
        
        # 显示警告
        if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
            echo -e "${RED}⚠️  CPU使用率过高！${NC}"
        fi
        if [ $TIME_WAIT -gt 1000 ]; then
            echo -e "${RED}⚠️  可能存在CC攻击！${NC}"
        fi
        if [ $PHP_PROCESSES -gt 50 ]; then
            echo -e "${RED}⚠️  PHP进程数过多！${NC}"
        fi
        
        # 显示占用CPU最高的进程
        echo -e "${CYAN}CPU占用最高的进程:${NC}"
        ps aux --sort=-%cpu | head -4 | tail -3 | while read user pid cpu mem vsz rss tty stat start time command; do
            if [ "$user" != "USER" ] && [ ! -z "$pid" ]; then
                echo -e "  ${YELLOW}PID: $pid${NC} | ${RED}CPU: $cpu%${NC} | ${GREEN}用户: $user${NC} | ${CYAN}命令: $command${NC}"
            fi
        done
        
        sleep 3
    done
}

# 邮件告警配置
EMAIL_CONFIG() {
    echo -e "${BLUE}【邮件告警配置】${NC}"
    echo "=================================="
    
    echo -e "${YELLOW}请输入邮箱地址:${NC} "
    read -r email_address
    
    echo -e "${YELLOW}请输入SMTP服务器 (如: smtp.qq.com):${NC} "
    read -r smtp_server
    
    echo -e "${YELLOW}请输入邮箱密码:${NC} "
    read -s email_password
    
    # 保存配置
    cat > /root/.monitor_email.conf << EOF
EMAIL_ADDRESS="$email_address"
SMTP_SERVER="$smtp_server"
EMAIL_PASSWORD="$email_password"
EOF
    
    echo -e "${GREEN}✅ 邮件配置已保存${NC}"
    log_message "CONFIG: Email alert configured"
}

# 发送邮件告警
send_alert_email() {
    local subject="$1"
    local message="$2"
    
    if [ -f "/root/.monitor_email.conf" ]; then
        source /root/.monitor_email.conf
        
        echo "$message" | mail -s "$subject" \
            -S smtp="$SMTP_SERVER" \
            -S smtp-use-starttls \
            -S smtp-auth=login \
            -S smtp-auth-user="$EMAIL_ADDRESS" \
            -S smtp-auth-password="$EMAIL_PASSWORD" \
            "$EMAIL_ADDRESS" 2>/dev/null
        
        log_message "ALERT: Email sent - $subject"
    fi
}

# 微信/钉钉告警
send_webhook_alert() {
    local message="$1"
    local webhook_url="$2"
    
    if [ ! -z "$webhook_url" ]; then
        curl -H "Content-Type: application/json" \
             -X POST \
             -d "{\"text\":\"$message\"}" \
             "$webhook_url" 2>/dev/null
        
        log_message "ALERT: Webhook sent - $message"
    fi
}

# 自动备份重要配置
auto_backup() {
    echo -e "${BLUE}【自动备份重要配置】${NC}"
    echo "=================================="
    
    BACKUP_DIR="/root/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 备份PHP配置
    find /www/server/php -name "php-fpm.conf" -exec cp {} "$BACKUP_DIR/" \;
    
    # 备份Nginx配置
    if [ -d "/www/server/nginx/conf" ]; then
        cp -r /www/server/nginx/conf "$BACKUP_DIR/"
    fi
    
    # 备份防火墙规则
    if command -v iptables &> /dev/null; then
        iptables-save > "$BACKUP_DIR/iptables.rules"
    fi
    
    # 备份系统配置
    cp /etc/sysctl.conf "$BACKUP_DIR/"
    cp /etc/security/limits.conf "$BACKUP_DIR/"
    
    # 压缩备份
    tar -czf "${BACKUP_DIR}.tar.gz" -C "$BACKUP_DIR" .
    rm -rf "$BACKUP_DIR"
    
    echo -e "${GREEN}✅ 配置备份完成: ${BACKUP_DIR}.tar.gz${NC}"
    log_message "AUTO_BACKUP: Configuration backup completed"
}

# 性能优化建议
performance_advice() {
    echo -e "${BLUE}【性能优化建议】${NC}"
    echo "=================================="
    
    # CPU优化建议
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$CPU_USAGE > 70" | bc -l) )); then
        echo -e "${YELLOW}CPU优化建议:${NC}"
        echo "  - 检查PHP-FPM进程数配置"
        echo "  - 优化数据库查询"
        echo "  - 启用Redis缓存"
        echo "  - 检查是否有异常进程"
        echo "  - 考虑升级服务器配置"
    fi
    
    # 内存优化建议
    MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    if (( $(echo "$MEM_USAGE > 80" | bc -l) )); then
        echo -e "${YELLOW}内存优化建议:${NC}"
        echo "  - 增加swap空间"
        echo "  - 优化MySQL内存配置"
        echo "  - 清理系统缓存"
        echo "  - 检查内存泄漏"
        echo "  - 考虑增加物理内存"
    fi
    
    # 网络优化建议
    TIME_WAIT=$(netstat -an | grep TIME_WAIT | wc -l)
    if [ $TIME_WAIT -gt 500 ]; then
        echo -e "${YELLOW}网络优化建议:${NC}"
        echo "  - 调整TCP参数"
        echo "  - 启用连接复用"
        echo "  - 配置负载均衡"
        echo "  - 检查CC攻击"
        echo "  - 使用CDN加速"
    fi
    
    # 磁盘优化建议
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ $DISK_USAGE -gt 80 ]; then
        echo -e "${YELLOW}磁盘优化建议:${NC}"
        echo "  - 清理日志文件"
        echo "  - 清理临时文件"
        echo "  - 清理备份文件"
        echo "  - 考虑扩容磁盘"
        echo "  - 使用日志轮转"
    fi
    
    echo ""
}

# 定时任务管理
cron_management() {
    echo -e "${BLUE}【定时任务管理】${NC}"
    echo "=================================="
    
    echo -e "${CYAN}当前定时任务:${NC}"
    crontab -l 2>/dev/null || echo "暂无定时任务"
    
    echo ""
    echo -e "${YELLOW}请选择操作:${NC}"
    echo "1. 添加监控定时任务"
    echo "2. 添加备份定时任务"
    echo "3. 添加清理定时任务"
    echo "4. 删除所有定时任务"
    echo "5. 返回主菜单"
    echo ""
    echo -e "${YELLOW}请输入选项 (1-5):${NC} "
    read -r cron_choice
    
    case $cron_choice in
        1)
            # 添加每5分钟检查一次的任务
            (crontab -l 2>/dev/null; echo "*/5 * * * * /root/bt_monitor.sh --cron-check") | crontab -
            echo -e "${GREEN}✅ 已添加监控定时任务${NC}"
            log_message "CRON: Added monitoring cron job"
            ;;
        2)
            # 添加每天凌晨2点备份的任务
            (crontab -l 2>/dev/null; echo "0 2 * * * /root/bt_monitor.sh --auto-backup") | crontab -
            echo -e "${GREEN}✅ 已添加备份定时任务${NC}"
            log_message "CRON: Added backup cron job"
            ;;
        3)
            # 添加每周清理日志的任务
            (crontab -l 2>/dev/null; echo "0 3 * * 0 /root/bt_monitor.sh --clean-logs") | crontab -
            echo -e "${GREEN}✅ 已添加清理定时任务${NC}"
            log_message "CRON: Added cleanup cron job"
            ;;
        4)
            crontab -r
            echo -e "${GREEN}✅ 已删除所有定时任务${NC}"
            log_message "CRON: Removed all cron jobs"
            ;;
        5)
            return
            ;;
        *)
            echo -e "${RED}无效选项${NC}"
            ;;
    esac
}

# 系统资源限制
set_resource_limits() {
    echo -e "${BLUE}【系统资源限制】${NC}"
    echo "=================================="
    
    # 限制单个用户的最大进程数
    echo "* soft nproc 1024" >> /etc/security/limits.conf
    echo "* hard nproc 2048" >> /etc/security/limits.conf
    
    # 限制单个用户的最大文件数
    echo "* soft nofile 65536" >> /etc/security/limits.conf
    echo "* hard nofile 65536" >> /etc/security/limits.conf
    
    # 优化TCP参数
    cat >> /etc/sysctl.conf << EOF
# 优化TCP连接
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_max_syn_backlog = 8192
net.core.somaxconn = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_syncookies = 1
EOF
    
    sysctl -p
    
    echo -e "${GREEN}✅ 系统资源限制已设置${NC}"
    log_message "SYSTEM: Resource limits configured"
}

# 一键安全加固
security_hardening() {
    echo -e "${BLUE}【一键安全加固】${NC}"
    echo "=================================="
    
    echo -e "${RED}警告：此操作将修改系统安全设置！${NC}"
    echo -e "${YELLOW}是否继续？(y/n):${NC} "
    read -r confirm
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return
    fi
    
    # 禁用不必要的服务
    systemctl disable rpcbind 2>/dev/null
    systemctl disable rpcbind.socket 2>/dev/null
    systemctl disable telnet 2>/dev/null
    
    # 设置SSH安全
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
    sed -i 's/#Port 22/Port 22222/g' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
    
    # 设置防火墙规则
    if command -v firewalld &> /dev/null; then
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --permanent --add-port=8888/tcp
        firewall-cmd --permanent --add-port=22222/tcp
        firewall-cmd --reload
    fi
    
    # 设置文件权限
    chmod 600 /etc/passwd
    chmod 600 /etc/shadow
    chmod 600 /etc/group
    chmod 600 /etc/gshadow
    
    # 禁用不必要的模块
    echo "install dccp /bin/true" >> /etc/modprobe.d/security.conf
    echo "install sctp /bin/true" >> /etc/modprobe.d/security.conf
    echo "install rds /bin/true" >> /etc/modprobe.d/security.conf
    echo "install tipc /bin/true" >> /etc/modprobe.d/security.conf
    
    echo -e "${GREEN}✅ 安全加固完成${NC}"
    echo -e "${YELLOW}注意：SSH端口已改为22222，请使用新端口连接！${NC}"
    log_message "SECURITY: System hardening completed"
}

# 日志分析
log_analysis() {
    echo -e "${BLUE}【日志分析】${NC}"
    echo "=================================="
    
    # 分析访问日志
    if [ -f "/var/log/nginx/access.log" ]; then
        echo -e "${CYAN}访问量最高的IP:${NC}"
        tail -1000 /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
        
        echo -e "${CYAN}访问量最高的页面:${NC}"
        tail -1000 /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c | sort -nr | head -10
        
        echo -e "${CYAN}错误状态码:${NC}"
        tail -1000 /var/log/nginx/access.log | awk '{print $9}' | sort | uniq -c | sort -nr | grep -E "(404|500|502|503)"
        
        echo -e "${CYAN}最近的异常访问:${NC}"
        tail -100 /var/log/nginx/access.log | grep -E "(404|500|502|503)" | head -10
    else
        echo -e "${YELLOW}未找到Nginx访问日志${NC}"
    fi
    
    # 分析错误日志
    if [ -f "/var/log/nginx/error.log" ]; then
        echo -e "${CYAN}最近的错误日志:${NC}"
        tail -20 /var/log/nginx/error.log
    fi
    
    # 分析PHP错误日志
    if [ -f "/var/log/php-fpm/error.log" ]; then
        echo -e "${CYAN}PHP错误日志:${NC}"
        tail -20 /var/log/php-fpm/error.log
    fi
    
    echo ""
}

# 系统恢复
system_recovery() {
    echo -e "${BLUE}【系统恢复】${NC}"
    echo "=================================="
    
    echo -e "${RED}警告：此操作将重启所有服务！${NC}"
    echo -e "${YELLOW}是否继续？(y/n):${NC} "
    read -r confirm
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        # 重启所有服务
        systemctl restart nginx
        systemctl restart php-fpm-56 2>/dev/null
        systemctl restart php-fpm-71 2>/dev/null
        systemctl restart php-fpm-74 2>/dev/null
        systemctl restart php-fpm-80 2>/dev/null
        systemctl restart php-fpm-81 2>/dev/null
        systemctl restart mysql 2>/dev/null
        systemctl restart redis 2>/dev/null
        
        # 清理连接
        echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
        echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
        
        # 清理缓存
        sync
        echo 3 > /proc/sys/vm/drop_caches
        
        echo -e "${GREEN}✅ 系统恢复完成${NC}"
        log_message "RECOVERY: System recovery completed"
    fi
}

# 自动修复CC攻击
fix_cc_attack() {
    echo -e "${RED}【检测到CC攻击，开始自动修复】${NC}"
    echo "=================================="
    
    log_message "AUTO_FIX: Starting CC attack fix"
    
    # 1. 重启Nginx清理连接
    echo -e "${YELLOW}1. 重启Nginx清理连接...${NC}"
    systemctl restart nginx
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Nginx重启成功${NC}"
        log_message "AUTO_FIX: Nginx restarted successfully"
    else
        echo -e "${RED}❌ Nginx重启失败${NC}"
        log_message "AUTO_FIX: Nginx restart failed"
    fi
    
    # 2. 重启PHP-FPM
    echo -e "${YELLOW}2. 重启PHP-FPM...${NC}"
    systemctl restart php-fpm-56 2>/dev/null
    systemctl restart php-fpm-71 2>/dev/null
    systemctl restart php-fpm-74 2>/dev/null
    systemctl restart php-fpm-80 2>/dev/null
    systemctl restart php-fpm-81 2>/dev/null
    echo -e "${GREEN}✅ PHP-FPM重启完成${NC}"
    log_message "AUTO_FIX: PHP-FPM restarted"
    
    # 3. 清理TIME_WAIT连接
    echo -e "${YELLOW}3. 清理TIME_WAIT连接...${NC}"
    echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
    echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
    echo -e "${GREEN}✅ TIME_WAIT连接清理完成${NC}"
    log_message "AUTO_FIX: TIME_WAIT connections cleared"
    
    # 4. 添加防火墙规则
    echo -e "${YELLOW}4. 添加防火墙防护规则...${NC}"
    if command -v iptables &> /dev/null; then
        # 限制单个IP的连接数
        iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 50 -j DROP
        iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 50 -j DROP
        echo -e "${GREEN}✅ 防火墙规则添加完成${NC}"
        log_message "AUTO_FIX: Firewall rules added"
    fi
    
    # 5. 检查修复效果
    sleep 5
    echo -e "${YELLOW}5. 检查修复效果...${NC}"
    NEW_CONN=$(netstat -an | wc -l)
    NEW_TIME_WAIT=$(netstat -an | grep TIME_WAIT | wc -l)
    echo -e "当前连接数: ${YELLOW}$NEW_CONN${NC}"
    echo -e "TIME_WAIT连接数: ${YELLOW}$NEW_TIME_WAIT${NC}"
    
    if [ $NEW_TIME_WAIT -lt 500 ]; then
        echo -e "${GREEN}✅ CC攻击修复成功！${NC}"
        log_message "AUTO_FIX: CC attack fixed successfully"
    else
        echo -e "${YELLOW}⚠️  CC攻击可能仍在持续，建议手动检查${NC}"
        log_message "AUTO_FIX: CC attack may still be ongoing"
    fi
    
    echo ""
}

# 自动修复可疑进程
fix_suspicious_processes() {
    echo -e "${RED}【检测到可疑进程，开始自动清理】${NC}"
    echo "=================================="
    
    log_message "AUTO_FIX: Starting suspicious process cleanup"
    
    # 定义可疑进程关键词
    SUSPICIOUS_PROCESSES=("miner" "xmr" "monero" "coinhive" "cryptonight" "xmrig" "ccminer" "ethminer" "bitcoin" "litecoin" "stratum" "pool" "hashrate")
    
    KILLED_COUNT=0
    
    for process in "${SUSPICIOUS_PROCESSES[@]}"; do
        PIDS=$(pgrep -f "$process" 2>/dev/null)
        if [ ! -z "$PIDS" ]; then
            echo -e "${YELLOW}发现可疑进程: $process${NC}"
            echo -e "进程ID: $PIDS"
            
            # 杀死进程
            for pid in $PIDS; do
                kill -9 $pid 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo -e "${GREEN}✅ 已杀死进程: $pid${NC}"
                    log_message "AUTO_FIX: Killed suspicious process $pid ($process)"
                    KILLED_COUNT=$((KILLED_COUNT + 1))
                else
                    echo -e "${RED}❌ 杀死进程失败: $pid${NC}"
                    log_message "AUTO_FIX: Failed to kill process $pid"
                fi
            done
        fi
    done
    
    if [ $KILLED_COUNT -gt 0 ]; then
        echo -e "${GREEN}✅ 共清理了 $KILLED_COUNT 个可疑进程${NC}"
        log_message "AUTO_FIX: Cleaned $KILLED_COUNT suspicious processes"
    else
        echo -e "${GREEN}✅ 未发现需要清理的可疑进程${NC}"
        log_message "AUTO_FIX: No suspicious processes found to clean"
    fi
    
    echo ""
}

# 自动修复CPU占用过高
fix_high_cpu() {
    echo -e "${RED}【检测到CPU占用过高，开始自动优化】${NC}"
    echo "=================================="
    
    log_message "AUTO_FIX: Starting high CPU usage fix"
    
    # 1. 查找CPU占用最高的进程
    echo -e "${YELLOW}1. 分析CPU占用最高的进程...${NC}"
    HIGH_CPU_PROCESSES=$(ps aux --sort=-%cpu | head -6 | tail -5 | awk '{print $2, $3, $11}')
    
    echo -e "${CYAN}CPU占用最高的进程:${NC}"
    echo "$HIGH_CPU_PROCESSES" | while read pid cpu command; do
        if [ ! -z "$pid" ] && [ "$pid" != "PID" ]; then
            echo -e "  PID: ${YELLOW}$pid${NC} | CPU: ${RED}${cpu}%${NC} | 命令: ${CYAN}$command${NC}"
        fi
    done
    
    # 2. 检查是否为正常进程
    echo -e "${YELLOW}2. 检查进程类型...${NC}"
    echo "$HIGH_CPU_PROCESSES" | while read pid cpu command; do
        if [ ! -z "$pid" ] && [ "$pid" != "PID" ]; then
            # 检查是否为系统关键进程
            if [[ "$command" == *"systemd"* ]] || [[ "$command" == *"kworker"* ]] || [[ "$command" == *"BT-Panel"* ]]; then
                echo -e "${YELLOW}⚠️  进程 $pid 为系统关键进程，跳过处理${NC}"
                log_message "AUTO_FIX: Skipped system critical process $pid"
            elif (( $(echo "$cpu > 50" | bc -l) )); then
                echo -e "${RED}⚠️  进程 $pid CPU占用过高 (${cpu}%)，建议手动检查${NC}"
                log_message "AUTO_FIX: High CPU process detected $pid ($cpu%)"
            fi
        fi
    done
    
    # 3. 优化PHP-FPM配置
    echo -e "${YELLOW}3. 优化PHP-FPM配置...${NC}"
    PHP_CONFIGS=$(find /www/server/php -name "php-fpm.conf" 2>/dev/null)
    
    for config in $PHP_CONFIGS; do
        if [ -f "$config" ]; then
            # 备份原配置
            cp "$config" "${config}.backup.$(date +%Y%m%d_%H%M%S)"
            
            # 修改配置
            sed -i 's/pm.max_children = [0-9]*/pm.max_children = 10/g' "$config"
            sed -i 's/pm.start_servers = [0-9]*/pm.start_servers = 2/g' "$config"
            sed -i 's/pm.min_spare_servers = [0-9]*/pm.min_spare_servers = 1/g' "$config"
            sed -i 's/pm.max_spare_servers = [0-9]*/pm.max_spare_servers = 3/g' "$config"
            
            echo -e "${GREEN}✅ 已优化配置: $config${NC}"
            log_message "AUTO_FIX: Optimized PHP-FPM config: $config"
        fi
    done
    
    # 4. 重启PHP-FPM
    echo -e "${YELLOW}4. 重启PHP-FPM服务...${NC}"
    systemctl restart php-fpm-56 2>/dev/null
    systemctl restart php-fpm-71 2>/dev/null
    systemctl restart php-fpm-74 2>/dev/null
    systemctl restart php-fpm-80 2>/dev/null
    systemctl restart php-fpm-81 2>/dev/null
    echo -e "${GREEN}✅ PHP-FPM重启完成${NC}"
    
    # 5. 检查修复效果
    sleep 3
    echo -e "${YELLOW}5. 检查修复效果...${NC}"
    NEW_CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "当前CPU使用率: ${YELLOW}${NEW_CPU_USAGE}%${NC}"
    
    if (( $(echo "$NEW_CPU_USAGE < 50" | bc -l) )); then
        echo -e "${GREEN}✅ CPU占用优化成功！${NC}"
        log_message "AUTO_FIX: CPU usage optimized successfully"
    else
        echo -e "${YELLOW}⚠️  CPU占用仍然较高，建议进一步检查${NC}"
        log_message "AUTO_FIX: CPU usage still high after optimization"
    fi
    
    echo ""
}

# 自动修复内存占用过高
fix_high_memory() {
    echo -e "${RED}【检测到内存占用过高，开始自动优化】${NC}"
    echo "=================================="
    
    log_message "AUTO_FIX: Starting high memory usage fix"
    
    # 1. 清理缓存
    echo -e "${YELLOW}1. 清理系统缓存...${NC}"
    sync
    echo 3 > /proc/sys/vm/drop_caches
    echo -e "${GREEN}✅ 系统缓存清理完成${NC}"
    log_message "AUTO_FIX: System cache cleared"
    
    # 2. 查找内存占用最高的进程
    echo -e "${YELLOW}2. 分析内存占用最高的进程...${NC}"
    HIGH_MEM_PROCESSES=$(ps aux --sort=-%mem | head -6 | tail -5 | awk '{print $2, $4, $11}')
    
    echo -e "${CYAN}内存占用最高的进程:${NC}"
    echo "$HIGH_MEM_PROCESSES" | while read pid mem command; do
        if [ ! -z "$pid" ] && [ "$pid" != "PID" ]; then
            echo -e "  PID: ${YELLOW}$pid${NC} | 内存: ${RED}${mem}%${NC} | 命令: ${CYAN}$command${NC}"
        fi
    done
    
    # 3. 重启内存占用高的服务
    echo -e "${YELLOW}3. 重启高内存占用服务...${NC}"
    
    # 检查并重启MySQL
    MYSQL_MEM=$(ps aux | grep mysql | grep -v grep | awk '{sum+=$4} END {print sum}')
    if (( $(echo "$MYSQL_MEM > 20" | bc -l) )); then
        echo -e "${YELLOW}MySQL内存占用较高，重启MySQL...${NC}"
        systemctl restart mysql 2>/dev/null
        echo -e "${GREEN}✅ MySQL重启完成${NC}"
        log_message "AUTO_FIX: MySQL restarted due to high memory usage"
    fi
    
    # 检查并重启Redis
    REDIS_MEM=$(ps aux | grep redis | grep -v grep | awk '{sum+=$4} END {print sum}')
    if (( $(echo "$REDIS_MEM > 10" | bc -l) )); then
        echo -e "${YELLOW}Redis内存占用较高，重启Redis...${NC}"
        systemctl restart redis 2>/dev/null
        echo -e "${GREEN}✅ Redis重启完成${NC}"
        log_message "AUTO_FIX: Redis restarted due to high memory usage"
    fi
    
    # 4. 检查修复效果
    sleep 3
    echo -e "${YELLOW}4. 检查修复效果...${NC}"
    NEW_MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    echo -e "当前内存使用率: ${YELLOW}${NEW_MEM_USAGE}%${NC}"
    
    if (( $(echo "$NEW_MEM_USAGE < 70" | bc -l) )); then
        echo -e "${GREEN}✅ 内存占用优化成功！${NC}"
        log_message "AUTO_FIX: Memory usage optimized successfully"
    else
        echo -e "${YELLOW}⚠️  内存占用仍然较高，建议进一步检查${NC}"
        log_message "AUTO_FIX: Memory usage still high after optimization"
    fi
    
    echo ""
}

# 检查CPU使用率
check_cpu() {
    echo -e "${BLUE}【CPU使用率检查】${NC}"
    echo "=================================="
    
    # 获取CPU使用率
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    CPU_CORES=$(nproc)
    LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    echo -e "CPU核心数: ${YELLOW}$CPU_CORES${NC}"
    echo -e "CPU使用率: ${YELLOW}${CPU_USAGE}%${NC}"
    echo -e "系统负载: ${YELLOW}$LOAD_AVG${NC}"
    
    # 判断CPU状态
    if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
        echo -e "${RED}⚠️  CPU使用率过高！可能存在异常进程${NC}"
        log_message "WARNING: CPU usage is high: ${CPU_USAGE}%"
        
        # 询问是否自动修复
        echo -e "${YELLOW}是否自动修复CPU占用过高问题？(y/n):${NC} "
        read -r auto_fix
        if [ "$auto_fix" = "y" ] || [ "$auto_fix" = "Y" ]; then
            fix_high_cpu
        fi
    elif (( $(echo "$CPU_USAGE > 50" | bc -l) )); then
        echo -e "${YELLOW}⚠️  CPU使用率偏高，建议检查${NC}"
        log_message "WARNING: CPU usage is moderate: ${CPU_USAGE}%"
    else
        echo -e "${GREEN}✅ CPU使用率正常${NC}"
        log_message "INFO: CPU usage is normal: ${CPU_USAGE}%"
    fi
    
    echo ""
}

# 检查内存使用率
check_memory() {
    echo -e "${BLUE}【内存使用率检查】${NC}"
    echo "=================================="
    
    # 获取内存信息
    MEMORY_INFO=$(free -h | grep "Mem:")
    TOTAL_MEM=$(echo $MEMORY_INFO | awk '{print $2}')
    USED_MEM=$(echo $MEMORY_INFO | awk '{print $3}')
    FREE_MEM=$(echo $MEMORY_INFO | awk '{print $4}')
    
    echo -e "总内存: ${YELLOW}$TOTAL_MEM${NC}"
    echo -e "已使用: ${YELLOW}$USED_MEM${NC}"
    echo -e "可用内存: ${YELLOW}$FREE_MEM${NC}"
    
    # 计算内存使用率
    MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    echo -e "内存使用率: ${YELLOW}${MEM_USAGE}%${NC}"
    
    if (( $(echo "$MEM_USAGE > 90" | bc -l) )); then
        echo -e "${RED}⚠️  内存使用率过高！${NC}"
        log_message "WARNING: Memory usage is high: ${MEM_USAGE}%"
        
        # 询问是否自动修复
        echo -e "${YELLOW}是否自动修复内存占用过高问题？(y/n):${NC} "
        read -r auto_fix
        if [ "$auto_fix" = "y" ] || [ "$auto_fix" = "Y" ]; then
            fix_high_memory
        fi
    elif (( $(echo "$MEM_USAGE > 70" | bc -l) )); then
        echo -e "${YELLOW}⚠️  内存使用率偏高${NC}"
        log_message "WARNING: Memory usage is moderate: ${MEM_USAGE}%"
    else
        echo -e "${GREEN}✅ 内存使用率正常${NC}"
        log_message "INFO: Memory usage is normal: ${MEM_USAGE}%"
    fi
    
    echo ""
}

# 检查网络连接
check_network() {
    echo -e "${BLUE}【网络连接检查】${NC}"
    echo "=================================="
    
    # 获取网络连接信息
    TOTAL_CONN=$(netstat -an | wc -l)
    ESTABLISHED_CONN=$(netstat -an | grep ESTABLISHED | wc -l)
    TIME_WAIT_CONN=$(netstat -an | grep TIME_WAIT | wc -l)
    SYN_RECV_CONN=$(netstat -an | grep SYN_RECV | wc -l)
    
    echo -e "总连接数: ${YELLOW}$TOTAL_CONN${NC}"
    echo -e "已建立连接: ${YELLOW}$ESTABLISHED_CONN${NC}"
    echo -e "TIME_WAIT连接: ${YELLOW}$TIME_WAIT_CONN${NC}"
    echo -e "SYN_RECV连接: ${YELLOW}$SYN_RECV_CONN${NC}"
    
    # 检查是否有异常连接
    if [ $TIME_WAIT_CONN -gt 1000 ]; then
        echo -e "${RED}⚠️  TIME_WAIT连接过多，可能存在CC攻击！${NC}"
        log_message "WARNING: Too many TIME_WAIT connections: $TIME_WAIT_CONN"
        
        # 询问是否自动修复
        echo -e "${YELLOW}是否自动修复CC攻击问题？(y/n):${NC} "
        read -r auto_fix
        if [ "$auto_fix" = "y" ] || [ "$auto_fix" = "Y" ]; then
            fix_cc_attack
        fi
    fi
    
    if [ $SYN_RECV_CONN -gt 100 ]; then
        echo -e "${RED}⚠️  SYN_RECV连接过多，可能存在SYN攻击！${NC}"
        log_message "WARNING: Too many SYN_RECV connections: $SYN_RECV_CONN"
    fi
    
    # 显示连接数最多的IP
    echo -e "${CYAN}连接数最多的IP地址:${NC}"
    netstat -an | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -5 | while read count ip; do
        if [ "$ip" != "127.0.0.1" ] && [ "$ip" != "0.0.0.0" ] && [ "$ip" != "" ]; then
            echo -e "  ${YELLOW}$ip${NC}: ${RED}$count${NC} 个连接"
        fi
    done
    
    echo ""
}

# 检查可疑进程
check_suspicious_processes() {
    echo -e "${BLUE}【可疑进程检查】${NC}"
    echo "=================================="
    
    # 检查CPU占用最高的进程
    echo -e "${CYAN}CPU占用最高的进程:${NC}"
    ps aux --sort=-%cpu | head -6 | while read user pid cpu mem vsz rss tty stat start time command; do
        if [ "$user" != "USER" ]; then
            echo -e "  ${YELLOW}PID: $pid${NC} | ${RED}CPU: $cpu%${NC} | ${GREEN}用户: $user${NC} | ${CYAN}命令: $command${NC}"
        fi
    done
    
    echo ""
    
    # 检查内存占用最高的进程
    echo -e "${CYAN}内存占用最高的进程:${NC}"
    ps aux --sort=-%mem | head -6 | while read user pid cpu mem vsz rss tty stat start time command; do
        if [ "$user" != "USER" ]; then
            echo -e "  ${YELLOW}PID: $pid${NC} | ${RED}内存: $mem%${NC} | ${GREEN}用户: $user${NC} | ${CYAN}命令: $command${NC}"
        fi
    done
    
    echo ""
    
    # 检查可疑的进程名
    SUSPICIOUS_PROCESSES=("miner" "xmr" "monero" "coinhive" "cryptonight" "xmrig" "ccminer" "ethminer" "bitcoin" "litecoin" "stratum" "pool" "hashrate")
    
    echo -e "${CYAN}检查挖矿相关进程:${NC}"
    FOUND_SUSPICIOUS=false
    
    for process in "${SUSPICIOUS_PROCESSES[@]}"; do
        if pgrep -f "$process" > /dev/null; then
            echo -e "${RED}⚠️  发现可疑进程: $process${NC}"
            ps aux | grep "$process" | grep -v grep
            FOUND_SUSPICIOUS=true
            log_message "WARNING: Suspicious process found: $process"
        fi
    done
    
    if [ "$FOUND_SUSPICIOUS" = true ]; then
        # 询问是否自动清理
        echo -e "${YELLOW}是否自动清理可疑进程？(y/n):${NC} "
        read -r auto_fix
        if [ "$auto_fix" = "y" ] || [ "$auto_fix" = "Y" ]; then
            fix_suspicious_processes
        fi
    else
        echo -e "${GREEN}✅ 未发现明显的挖矿进程${NC}"
        log_message "INFO: No obvious mining processes found"
    fi
    
    echo ""
}

# 检查宝塔面板服务
check_bt_services() {
    echo -e "${BLUE}【宝塔面板服务检查】${NC}"
    echo "=================================="
    
    # 检查宝塔面板进程
    BT_PROCESSES=$(ps aux | grep -E "(BT-Panel|bt)" | grep -v grep | wc -l)
    echo -e "宝塔面板进程数: ${YELLOW}$BT_PROCESSES${NC}"
    
    if [ $BT_PROCESSES -gt 5 ]; then
        echo -e "${YELLOW}⚠️  宝塔面板进程数较多${NC}"
        log_message "WARNING: Many BT Panel processes: $BT_PROCESSES"
    else
        echo -e "${GREEN}✅ 宝塔面板进程数正常${NC}"
        log_message "INFO: BT Panel processes count is normal: $BT_PROCESSES"
    fi

        # 检查宝塔面板端口
    BT_PORT=$(netstat -tlnp | grep :8888 | wc -l)
    if [ $BT_PORT -gt 0 ]; then
        echo -e "${GREEN}✅ 宝塔面板端口8888正常监听${NC}"
    else
        echo -e "${RED}⚠️  宝塔面板端口8888未监听${NC}"
        log_message "WARNING: BT Panel port 8888 not listening"
    fi
    
    echo ""
}

# 检查PHP-FPM进程
check_php_fpm() {
    echo -e "${BLUE}【PHP-FPM进程检查】${NC}"
    echo "=================================="
    
    # 检查所有PHP版本
    PHP_VERSIONS=$(ls /www/server/php/ 2>/dev/null)
    
    if [ -z "$PHP_VERSIONS" ]; then
        echo -e "${YELLOW}⚠️  未找到PHP安装目录${NC}"
        return
    fi
    
    for version in $PHP_VERSIONS; do
        if [ -d "/www/server/php/$version" ]; then
            PHP_PROCESSES=$(ps aux | grep "php-fpm.*$version" | grep -v grep | wc -l)
            echo -e "PHP $version 进程数: ${YELLOW}$PHP_PROCESSES${NC}"
            
            if [ $PHP_PROCESSES -gt 50 ]; then
                echo -e "${RED}⚠️  PHP $version 进程数过多，可能存在CC攻击！${NC}"
                log_message "WARNING: Too many PHP $version processes: $PHP_PROCESSES"
            elif [ $PHP_PROCESSES -gt 20 ]; then
                echo -e "${YELLOW}⚠️  PHP $version 进程数偏高${NC}"
                log_message "WARNING: High number of PHP $version processes: $PHP_PROCESSES"
            else
                echo -e "${GREEN}✅ PHP $version 进程数正常${NC}"
                log_message "INFO: PHP $version processes count is normal: $PHP_PROCESSES"
            fi
        fi
    done
    
    echo ""
}

# 检查Web服务器
check_web_server() {
    echo -e "${BLUE}【Web服务器检查】${NC}"
    echo "=================================="
    
    # 检查Nginx
    NGINX_PROCESSES=$(ps aux | grep nginx | grep -v grep | wc -l)
    if [ $NGINX_PROCESSES -gt 0 ]; then
        echo -e "${GREEN}✅ Nginx 运行中 (${NGINX_PROCESSES}个进程)${NC}"
        
        # 检查Nginx端口
        NGINX_PORT_80=$(netstat -tlnp | grep :80 | wc -l)
        NGINX_PORT_443=$(netstat -tlnp | grep :443 | wc -l)
        
        if [ $NGINX_PORT_80 -gt 0 ]; then
            echo -e "${GREEN}✅ Nginx 80端口正常监听${NC}"
        fi
        if [ $NGINX_PORT_443 -gt 0 ]; then
            echo -e "${GREEN}✅ Nginx 443端口正常监听${NC}"
        fi
    else
        echo -e "${RED}⚠️  Nginx 未运行${NC}"
        log_message "WARNING: Nginx is not running"
    fi
    
    # 检查Apache
    APACHE_PROCESSES=$(ps aux | grep httpd | grep -v grep | wc -l)
    if [ $APACHE_PROCESSES -gt 0 ]; then
        echo -e "${GREEN}✅ Apache 运行中 (${APACHE_PROCESSES}个进程)${NC}"
    fi
    
    echo ""
}

# 检查数据库
check_database() {
    echo -e "${BLUE}【数据库检查】${NC}"
    echo "=================================="
    
    # 检查MySQL
    MYSQL_PROCESSES=$(ps aux | grep mysql | grep -v grep | wc -l)
    if [ $MYSQL_PROCESSES -gt 0 ]; then
        echo -e "${GREEN}✅ MySQL 运行中 (${MYSQL_PROCESSES}个进程)${NC}"
        
        # 检查MySQL端口
        MYSQL_PORT=$(netstat -tlnp | grep :3306 | wc -l)
        if [ $MYSQL_PORT -gt 0 ]; then
            echo -e "${GREEN}✅ MySQL 3306端口正常监听${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  MySQL 未运行${NC}"
    fi
    
    # 检查Redis
    REDIS_PROCESSES=$(ps aux | grep redis | grep -v grep | wc -l)
    if [ $REDIS_PROCESSES -gt 0 ]; then
        echo -e "${GREEN}✅ Redis 运行中 (${REDIS_PROCESSES}个进程)${NC}"
        
        # 检查Redis端口
        REDIS_PORT=$(netstat -tlnp | grep :6379 | wc -l)
        if [ $REDIS_PORT -gt 0 ]; then
            echo -e "${GREEN}✅ Redis 6379端口正常监听${NC}"
        fi
    fi
    
    echo ""
}

# 检查系统负载
check_system_load() {
    echo -e "${BLUE}【系统负载检查】${NC}"
    echo "=================================="
    
    LOAD_1=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    LOAD_5=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $2}' | sed 's/,//')
    LOAD_15=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $3}')
    
    CPU_CORES=$(nproc)
    LOAD_THRESHOLD=$(echo "$CPU_CORES * 0.7" | bc -l)
    
    echo -e "1分钟负载: ${YELLOW}$LOAD_1${NC}"
    echo -e "5分钟负载: ${YELLOW}$LOAD_5${NC}"
    echo -e "15分钟负载: ${YELLOW}$LOAD_15${NC}"
    echo -e "CPU核心数: ${YELLOW}$CPU_CORES${NC}"
    echo -e "负载阈值: ${YELLOW}$LOAD_THRESHOLD${NC}"
    
    if (( $(echo "$LOAD_1 > $LOAD_THRESHOLD" | bc -l) )); then
        echo -e "${RED}⚠️  系统负载过高！${NC}"
        log_message "WARNING: System load is high: $LOAD_1"
    else
        echo -e "${GREEN}✅ 系统负载正常${NC}"
        log_message "INFO: System load is normal: $LOAD_1"
    fi
    
    echo ""
}

# 检查磁盘使用率
check_disk() {
    echo -e "${BLUE}【磁盘使用率检查】${NC}"
    echo "=================================="
    
    df -h | grep -E "^/dev/" | while read device size used avail use_percent mount; do
        use_percent_num=$(echo $use_percent | sed 's/%//')
        echo -e "挂载点: ${YELLOW}$mount${NC}"
        echo -e "  设备: ${CYAN}$device${NC}"
        echo -e "  总大小: ${GREEN}$size${NC}"
        echo -e "  已使用: ${YELLOW}$used${NC}"
        echo -e "  可用: ${GREEN}$avail${NC}"
        echo -e "  使用率: ${YELLOW}$use_percent${NC}"
        
        if [ $use_percent_num -gt 90 ]; then
            echo -e "  ${RED}⚠️  磁盘使用率过高！${NC}"
            log_message "WARNING: Disk usage is high on $mount: $use_percent"
        elif [ $use_percent_num -gt 80 ]; then
            echo -e "  ${YELLOW}⚠️  磁盘使用率偏高${NC}"
            log_message "WARNING: Disk usage is moderate on $mount: $use_percent"
        else
            echo -e "  ${GREEN}✅ 磁盘使用率正常${NC}"
        fi
        echo ""
    done
}

# 检查防火墙状态
check_firewall() {
    echo -e "${BLUE}【防火墙状态检查】${NC}"
    echo "=================================="
    
    if command -v firewalld &> /dev/null; then
        if systemctl is-active --quiet firewalld; then
            echo -e "${GREEN}✅ firewalld 防火墙已启用${NC}"
            log_message "INFO: firewalld firewall is active"
        else
            echo -e "${RED}⚠️  firewalld 防火墙未启用${NC}"
            log_message "WARNING: firewalld firewall is not active"
        fi
    fi
    
    if command -v iptables &> /dev/null; then
        RULES_COUNT=$(iptables -L | wc -l)
        if [ $RULES_COUNT -gt 10 ]; then
            echo -e "${GREEN}✅ iptables 规则已配置 (${RULES_COUNT}条规则)${NC}"
            log_message "INFO: iptables rules configured: $RULES_COUNT rules"
        else
            echo -e "${YELLOW}⚠️  iptables 规则较少${NC}"
            log_message "WARNING: Few iptables rules: $RULES_COUNT rules"
        fi
    fi
    
    echo ""
}

# 生成安全报告
generate_report() {
    echo -e "${BLUE}【安全报告生成】${NC}"
    echo "=================================="
    
    REPORT_FILE="/tmp/bt_security_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "宝塔面板服务器安全监控报告"
        echo "生成时间: $(date)"
        echo "=================================="
        echo ""
        echo "系统信息:"
        echo "  主机名: $(hostname)"
        echo "  操作系统: $(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
        echo "  内核版本: $(uname -r)"
        echo "  CPU核心数: $(nproc)"
        echo "  总内存: $(free -h | grep Mem | awk '{print $2}')"
        echo ""
        echo "性能指标:"
        echo "  CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
        echo "  内存使用率: $(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')%"
        echo "  系统负载: $(uptime | awk -F'load average:' '{print $2}')"
        echo "  网络连接数: $(netstat -an | wc -l)"
        echo "  PHP-FPM进程数: $(ps aux | grep php-fpm | grep -v grep | wc -l)"
        echo ""
        echo "宝塔服务状态:"
        echo "  宝塔面板进程: $(ps aux | grep -E "(BT-Panel|bt)" | grep -v grep | wc -l)"
        echo "  Nginx进程: $(ps aux | grep nginx | grep -v grep | wc -l)"
        echo "  MySQL进程: $(ps aux | grep mysql | grep -v grep | wc -l)"
        echo "  Redis进程: $(ps aux | grep redis | grep -v grep | wc -l)"
        echo ""
        echo "安全状态:"
        echo "  防火墙状态: $(systemctl is-active firewalld 2>/dev/null || echo 'Unknown')"
        echo "  可疑进程: $(ps aux | grep -E '(miner|xmr|monero|cryptonight)' | grep -v grep | wc -l) 个"
        echo ""
        echo "建议措施:"
        if (( $(echo "$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1) > 80" | bc -l) )); then
            echo "  - CPU使用率过高，建议检查异常进程"
        fi
        if [ $(ps aux | grep php-fpm | grep -v grep | wc -l) -gt 50 ]; then
            echo "  - PHP-FPM进程数过多，可能存在CC攻击"
        fi
        if [ $(netstat -an | grep TIME_WAIT | wc -l) -gt 1000 ]; then
            echo "  - TIME_WAIT连接过多，建议重启Nginx"
        fi
        echo ""
        echo "日志文件: $LOG_FILE"
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}✅ 安全报告已生成: $REPORT_FILE${NC}"
    log_message "INFO: Security report generated: $REPORT_FILE"
    
    # 显示报告内容
    echo -e "${CYAN}报告内容预览:${NC}"
    cat "$REPORT_FILE"
    echo ""
}

# 清理日志文件
clean_logs() {
    echo -e "${BLUE}【清理日志文件】${NC}"
    echo "=================================="
    
    # 清理临时文件
    rm -f /tmp/bt_monitor_*.log 2>/dev/null
    rm -f /tmp/bt_security_report_*.txt 2>/dev/null
    
    # 清理旧的Nginx日志
    find /www/wwwlogs/ -name "*.log" -type f -mtime +30 -delete 2>/dev/null
    
    # 清理PHP错误日志
    find /var/log/php-fpm/ -name "*.log" -type f -mtime +15 -delete 2>/dev/null
    
    # 清理MySQL日志
    find /var/log/mysql/ -name "*.log" -type f -mtime +15 -delete 2>/dev/null
    
    echo -e "${GREEN}✅ 日志文件清理完成${NC}"
    log_message "CLEANUP: Log files cleaned up"
}

# 自动修复所有问题
auto_fix_all() {
    show_header
    echo -e "${GREEN}开始自动修复所有问题...${NC}"
    echo ""
    
    # 检查并修复CPU问题
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
        echo -e "${YELLOW}检测到CPU占用过高，开始修复...${NC}"
        fix_high_cpu
    fi
    
    # 检查并修复内存问题
    MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    if (( $(echo "$MEM_USAGE > 90" | bc -l) )); then
        echo -e "${YELLOW}检测到内存占用过高，开始修复...${NC}"
        fix_high_memory
    fi
    
    # 检查并修复CC攻击
    TIME_WAIT_CONN=$(netstat -an | grep TIME_WAIT | wc -l)
    if [ $TIME_WAIT_CONN -gt 1000 ]; then
        echo -e "${YELLOW}检测到CC攻击，开始修复...${NC}"
        fix_cc_attack
    fi
    
    # 检查并修复可疑进程
    SUSPICIOUS_COUNT=$(ps aux | grep -E "(miner|xmr|monero|cryptonight)" | grep -v grep | wc -l)
    if [ $SUSPICIOUS_COUNT -gt 0 ]; then
        echo -e "${YELLOW}检测到可疑进程，开始清理...${NC}"
        fix_suspicious_processes
    fi
    
    echo -e "${GREEN}自动修复完成！${NC}"
    echo ""
}

# 主菜单
show_menu() {
    echo -e "${CYAN}请选择要执行的操作:${NC}"
    echo "1. 快速安全检查 (推荐)"
    echo "2. 详细安全检查"
    echo "3. 实时监控模式"
    echo "4. 自动修复所有问题"
    echo "5. 性能优化建议"
    echo "6. 一键安全加固"
    echo "7. 系统资源限制"
    echo "8. 定时任务管理"
    echo "9. 邮件告警配置"
    echo "10. 日志分析"
    echo "11. 自动备份配置"
    echo "12. 系统恢复"
    echo "13. 生成安全报告"
    echo "14. 查看监控日志"
    echo "15. 清理日志文件"
    echo "16. 退出"
    echo ""
    echo -e "${YELLOW}请输入选项 (1-16):${NC} "
}

# 快速安全检查
quick_check() {
    show_header
    echo -e "${GREEN}开始快速安全检查...${NC}"
    echo ""
    
    check_cpu
    check_memory
    check_network
    check_suspicious_processes
    check_bt_services
    check_php_fpm
    
    echo -e "${GREEN}快速安全检查完成！${NC}"
    echo ""
}

# 详细安全检查
detailed_check() {
    show_header
    echo -e "${GREEN}开始详细安全检查...${NC}"
    echo ""
    
    check_cpu
    check_memory
    check_network
    check_suspicious_processes
    check_bt_services
    check_php_fpm
    check_web_server
    check_database
    check_system_load
    check_disk
    check_firewall
    
    echo -e "${GREEN}详细安全检查完成！${NC}"
    echo ""
}

# 处理命令行参数
handle_args() {
    case "$1" in
        --cron-check)
            # 静默模式检查，发现问题发送告警
            CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
            MEM_USAGE=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
            TIME_WAIT_CONN=$(netstat -an | grep TIME_WAIT | wc -l)
            
            ALERT_MSG=""
            
            if (( $(echo "$CPU_USAGE > 90" | bc -l) )); then
                ALERT_MSG="${ALERT_MSG}[警告] CPU使用率过高: ${CPU_USAGE}%\n"
            fi
            
            if (( $(echo "$MEM_USAGE > 90" | bc -l) )); then
                ALERT_MSG="${ALERT_MSG}[警告] 内存使用率过高: ${MEM_USAGE}%\n"
            fi
            
            if [ $TIME_WAIT_CONN -gt 1000 ]; then
                ALERT_MSG="${ALERT_MSG}[警告] TIME_WAIT连接过多，可能存在CC攻击: ${TIME_WAIT_CONN}\n"
            fi
            
            if [ ! -z "$ALERT_MSG" ] && [ -f "/root/.monitor_email.conf" ]; then
                send_alert_email "服务器安全告警" "$ALERT_MSG"
            fi
            
            exit 0
            ;;
        --auto-backup)
            # 自动备份
            auto_backup
            exit 0
            ;;
        --clean-logs)
            # 清理日志
            clean_logs
            exit 0
            ;;
    esac
}

# 主程序
main() {
    # 检查命令行参数
    if [ $# -gt 0 ]; then
        handle_args "$@"
    fi
    
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用root权限运行此脚本！${NC}"
        exit 1
    fi
    
    # 检查bc命令
    if ! command -v bc &> /dev/null; then
        echo -e "${YELLOW}正在安装bc计算器...${NC}"
        yum install -y bc 2>/dev/null || apt-get install -y bc 2>/dev/null
    fi
    
    while true; do
        show_header
        show_menu
        read -r choice
        
        case $choice in
            1)
                quick_check
                ;;
            2)
                detailed_check
                ;;
            3)
                real_time_monitor
                ;;
            4)
                auto_fix_all
                ;;
            5)
                show_header
                performance_advice
                ;;
            6)
                show_header
                security_hardening
                ;;
            7)
                show_header
                set_resource_limits
                ;;
            8)
                show_header
                cron_management
                ;;
            9)
                show_header
                EMAIL_CONFIG
                ;;
            10)
                show_header
                log_analysis
                ;;
            11)
                show_header
                auto_backup
                ;;
            12)
                show_header
                system_recovery
                ;;
            13)
                show_header
                generate_report
                ;;
            14)
                show_header
                echo -e "${CYAN}监控日志内容:${NC}"
                if [ -f "$LOG_FILE" ]; then
                    cat "$LOG_FILE"
                else
                    echo "暂无日志文件"
                fi
                ;;
            15)
                show_header
                clean_logs
                ;;
            16)
                echo -e "${GREEN}感谢使用宝塔面板安全监控系统！${NC}"
                echo -e "${CYAN}作者: 咸鱼神秘人 | 微信: dingyanan2008 | QQ: 314450957${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项，请重新选择！${NC}"
                ;;
        esac
        
        echo ""
        echo -e "${YELLOW}按回车键继续...${NC}"
        read -r
    done
}

# 启动主程序
main "$@"