#!/bin/bash

# 宝塔面板服务器维护工具 - 系统优化模块

# 优化系统参数
optimize_system() {
    echo -e "${BLUE}【优化系统参数】${NC}"
    echo "=================================="
    
    # 备份原始配置
    if [ -f "/etc/sysctl.conf" ]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    echo -e "${YELLOW}正在优化系统参数...${NC}"
    
    # 添加系统参数优化
    cat >> /etc/sysctl.conf << 'EOF'
# CC防护系统优化参数
# 增加TCP连接数限制
net.ipv4.tcp_max_syn_backlog = 65536
net.core.somaxconn = 65536
net.core.netdev_max_backlog = 65536

# 启用SYN Cookies防护SYN洪水攻击
net.ipv4.tcp_syncookies = 1

# 减少TIME_WAIT状态连接数
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# 增加本地端口范围
net.ipv4.ip_local_port_range = 1024 65535

# 限制ICMP流量
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# 防止一些常见攻击
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
EOF

    # 应用系统参数
    sysctl -p > /dev/null 2>&1
    
    echo -e "${GREEN}✅ 系统参数已优化${NC}"
    log_message "OPTIMIZER: System parameters optimized"
    
    # 优化打开文件数限制
    optimize_file_limits
    
    return 0
}

# 优化文件描述符限制
optimize_file_limits() {
    echo -e "${BLUE}【优化文件描述符限制】${NC}"
    echo "=================================="
    
    # 备份原始配置
    if [ -f "/etc/security/limits.conf" ]; then
        cp /etc/security/limits.conf /etc/security/limits.conf.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    echo -e "${YELLOW}正在优化文件描述符限制...${NC}"
    
    # 添加文件描述符限制优化
    cat >> /etc/security/limits.conf << 'EOF'
# CC防护系统优化参数
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
EOF

    echo -e "${GREEN}✅ 文件描述符限制已优化${NC}"
    log_message "OPTIMIZER: File descriptor limits optimized"
    
    return 0
}

# 优化Web服务器配置
optimize_web_server() {
    echo -e "${BLUE}【优化Web服务器配置】${NC}"
    echo "=================================="
    
    local web_server=${WEB_SERVER:-"nginx"}
    
    if [ "$web_server" == "nginx" ]; then
        optimize_nginx
    elif [ "$web_server" == "apache" ]; then
        optimize_apache
    else
        echo -e "${YELLOW}⚠️ 不支持的Web服务器类型: $web_server${NC}"
        return 1
    fi
    
    return 0
}

# 优化Nginx配置
optimize_nginx() {
    echo -e "${BLUE}【优化Nginx配置】${NC}"
    echo "=================================="
    
    local nginx_conf="/www/server/nginx/conf/nginx.conf"
    
    if [ ! -f "$nginx_conf" ]; then
        echo -e "${YELLOW}⚠️ Nginx配置文件不存在: $nginx_conf${NC}"
        return 1
    fi
    
    # 备份原始配置
    local backup_file="${nginx_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$nginx_conf" "$backup_file"
    echo -e "${CYAN}配置已备份到: $backup_file${NC}"
    
    echo -e "${YELLOW}正在优化Nginx配置...${NC}"
    
    # 检查工作进程数
    local cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    if grep -q "worker_processes" "$nginx_conf"; then
        sed -i "s/worker_processes.*/worker_processes $cpu_cores;/" "$nginx_conf"
    else
        sed -i "1i worker_processes $cpu_cores;" "$nginx_conf"
    fi
    
    # 添加事件优化
    if grep -q "worker_connections" "$nginx_conf"; then
        sed -i "s/worker_connections.*/worker_connections 65535;/" "$nginx_conf"
    else
        if grep -q "events {" "$nginx_conf"; then
            sed -i "/events {/a \    worker_connections 65535;" "$nginx_conf"
        else
            sed -i "1i events {\n    worker_connections 65535;\n}" "$nginx_conf"
        fi
    fi
    
    # 添加优化配置
    if ! grep -q "client_max_body_size" "$nginx_conf"; then
        sed -i "/http {/a \    client_max_body_size 50m;\n    client_body_buffer_size 256k;\n    client_header_buffer_size 1k;\n    large_client_header_buffers 4 32k;\n    sendfile on;\n    tcp_nopush on;\n    tcp_nodelay on;\n    keepalive_timeout 60;\n    keepalive_requests 1000;\n    reset_timedout_connection on;\n    server_tokens off;" "$nginx_conf"
    fi
    
    # 配置变更前校验
    echo -e "${YELLOW}正在校验Nginx配置语法...${NC}"
    if command -v nginx &> /dev/null; then
        if nginx -t 2>/dev/null; then
            echo -e "${GREEN}✅ Nginx配置语法校验通过${NC}"
        else
            echo -e "${RED}❌ Nginx配置语法校验失败，正在回滚...${NC}"
            cp -f "$backup_file" "$nginx_conf"
            echo -e "${YELLOW}⚠️ 已回滚到原始配置${NC}"
            log_message "OPTIMIZER: Nginx config validation failed, rolled back"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ 无法找到nginx命令，跳过语法校验${NC}"
    fi
    
    # 重启Nginx
    echo -e "${YELLOW}正在重启Nginx服务...${NC}"
    if command -v systemctl &> /dev/null; then
        if systemctl restart nginx 2>/dev/null; then
            echo -e "${GREEN}✅ Nginx重启成功${NC}"
        else
            echo -e "${RED}❌ Nginx重启失败，正在回滚...${NC}"
            cp -f "$backup_file" "$nginx_conf"
            systemctl restart nginx 2>/dev/null
            echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启${NC}"
            log_message "OPTIMIZER: Nginx restart failed, rolled back"
            return 1
        fi
    else
        if service nginx restart 2>/dev/null; then
            echo -e "${GREEN}✅ Nginx重启成功${NC}"
        else
            echo -e "${RED}❌ Nginx重启失败，正在回滚...${NC}"
            cp -f "$backup_file" "$nginx_conf"
            service nginx restart 2>/dev/null
            echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启${NC}"
            log_message "OPTIMIZER: Nginx restart failed, rolled back"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ Nginx配置已优化${NC}"
    log_message "OPTIMIZER: Nginx configuration optimized successfully"
    
    return 0
}

# 优化Apache配置
optimize_apache() {
    echo -e "${BLUE}【优化Apache配置】${NC}"
    echo "=================================="
    
    local apache_conf="/www/server/apache/conf/httpd.conf"
    
    if [ ! -f "$apache_conf" ]; then
        echo -e "${YELLOW}⚠️ Apache配置文件不存在: $apache_conf${NC}"
        return 1
    fi
    
    # 备份原始配置
    local backup_file="${apache_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$apache_conf" "$backup_file"
    echo -e "${CYAN}配置已备份到: $backup_file${NC}"
    
    echo -e "${YELLOW}正在优化Apache配置...${NC}"
    
    # 优化MPM配置
    local cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    local max_clients=$((cpu_cores * 256))
    
    if grep -q "<IfModule mpm_prefork_module>" "$apache_conf"; then
        sed -i "/<IfModule mpm_prefork_module>/,/<\/IfModule>/c\
<IfModule mpm_prefork_module>\n\
    StartServers             $cpu_cores\n\
    MinSpareServers          $((cpu_cores * 2))\n\
    MaxSpareServers          $((cpu_cores * 4))\n\
    ServerLimit              $max_clients\n\
    MaxRequestWorkers        $max_clients\n\
    MaxConnectionsPerChild   10000\n\
</IfModule>" "$apache_conf"
    fi
    
    # 添加安全配置
    if ! grep -q "ServerTokens Prod" "$apache_conf"; then
        echo "ServerTokens Prod" >> "$apache_conf"
    fi
    
    if ! grep -q "ServerSignature Off" "$apache_conf"; then
        echo "ServerSignature Off" >> "$apache_conf"
    fi
    
    # 配置变更前校验
    echo -e "${YELLOW}正在校验Apache配置语法...${NC}"
    if command -v apachectl &> /dev/null; then
        if apachectl configtest 2>/dev/null; then
            echo -e "${GREEN}✅ Apache配置语法校验通过${NC}"
        else
            echo -e "${RED}❌ Apache配置语法校验失败，正在回滚...${NC}"
            cp -f "$backup_file" "$apache_conf"
            echo -e "${YELLOW}⚠️ 已回滚到原始配置${NC}"
            log_message "OPTIMIZER: Apache config validation failed, rolled back"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ 无法找到apachectl命令，跳过语法校验${NC}"
    fi
    
    # 重启Apache
    echo -e "${YELLOW}正在重启Apache服务...${NC}"
    if command -v systemctl &> /dev/null; then
        if systemctl restart httpd 2>/dev/null; then
            echo -e "${GREEN}✅ Apache重启成功${NC}"
        else
            echo -e "${RED}❌ Apache重启失败，正在回滚...${NC}"
            cp -f "$backup_file" "$apache_conf"
            systemctl restart httpd 2>/dev/null
            echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启${NC}"
            log_message "OPTIMIZER: Apache restart failed, rolled back"
            return 1
        fi
    else
        if service httpd restart 2>/dev/null; then
            echo -e "${GREEN}✅ Apache重启成功${NC}"
        else
            echo -e "${RED}❌ Apache重启失败，正在回滚...${NC}"
            cp -f "$backup_file" "$apache_conf"
            service httpd restart 2>/dev/null
            echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启${NC}"
            log_message "OPTIMIZER: Apache restart failed, rolled back"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ Apache配置已优化${NC}"
    log_message "OPTIMIZER: Apache configuration optimized successfully"
    
    return 0
}

# 优化PHP-FPM配置
optimize_php_fpm() {
    echo -e "${BLUE}【优化PHP-FPM配置】${NC}"
    echo "=================================="
    
    # 查找所有PHP版本
    local php_versions=$(find /www/server/php -maxdepth 1 -type d -name "[0-9]*" | sort)
    
    if [ -z "$php_versions" ]; then
        echo -e "${YELLOW}⚠️ 未找到PHP安装目录${NC}"
        return 1
    fi
    
    local success_count=0
    local total_count=0
    
    for php_dir in $php_versions; do
        local version=$(basename "$php_dir")
        local php_fpm_conf="$php_dir/etc/php-fpm.conf"
        
        if [ ! -f "$php_fpm_conf" ]; then
            echo -e "${YELLOW}⚠️ PHP-FPM配置文件不存在: $php_fpm_conf${NC}"
            continue
        fi
        
        total_count=$((total_count + 1))
        echo -e "${YELLOW}正在优化PHP-FPM $version 配置...${NC}"
        
        # 备份原始配置
        local backup_file="${php_fpm_conf}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$php_fpm_conf" "$backup_file"
        echo -e "${CYAN}配置已备份到: $backup_file${NC}"
        
        # 优化PHP-FPM进程数
        local mem_total=$(free -m | grep Mem | awk '{print $2}')
        local max_children=10
        
        # 根据内存大小调整进程数
        if [ $mem_total -ge 16000 ]; then
            max_children=50
        elif [ $mem_total -ge 8000 ]; then
            max_children=30
        elif [ $mem_total -ge 4000 ]; then
            max_children=20
        elif [ $mem_total -ge 2000 ]; then
            max_children=15
        fi
        
        # 更新PHP-FPM配置
        sed -i "s/pm.max_children = [0-9]*/pm.max_children = $max_children/" "$php_fpm_conf"
        sed -i "s/pm.start_servers = [0-9]*/pm.start_servers = $((max_children / 4))/" "$php_fpm_conf"
        sed -i "s/pm.min_spare_servers = [0-9]*/pm.min_spare_servers = $((max_children / 6))/" "$php_fpm_conf"
        sed -i "s/pm.max_spare_servers = [0-9]*/pm.max_spare_servers = $((max_children / 3))/" "$php_fpm_conf"
        
        # 配置变更前校验
        echo -e "${YELLOW}正在校验PHP-FPM $version 配置...${NC}"
        local php_fpm_bin="$php_dir/sbin/php-fpm"
        if [ -f "$php_fpm_bin" ]; then
            if $php_fpm_bin -t 2>/dev/null; then
                echo -e "${GREEN}✅ PHP-FPM $version 配置语法校验通过${NC}"
            else
                echo -e "${RED}❌ PHP-FPM $version 配置语法校验失败，正在回滚...${NC}"
                cp -f "$backup_file" "$php_fpm_conf"
                echo -e "${YELLOW}⚠️ 已回滚到原始配置${NC}"
                log_message "OPTIMIZER: PHP-FPM $version config validation failed, rolled back"
                continue
            fi
        else
            echo -e "${YELLOW}⚠️ 无法找到PHP-FPM $version 二进制文件，跳过语法校验${NC}"
        fi
        
        # 重启PHP-FPM
        echo -e "${YELLOW}正在重启PHP-FPM $version 服务...${NC}"
        if command -v systemctl &> /dev/null; then
            if systemctl restart php-fpm-$version 2>/dev/null; then
                echo -e "${GREEN}✅ PHP-FPM $version 重启成功${NC}"
                success_count=$((success_count + 1))
                log_message "OPTIMIZER: PHP-FPM $version configuration optimized successfully"
            else
                echo -e "${RED}❌ PHP-FPM $version 重启失败，正在回滚...${NC}"
                cp -f "$backup_file" "$php_fpm_conf"
                systemctl restart php-fpm-$version 2>/dev/null
                echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启${NC}"
                log_message "OPTIMIZER: PHP-FPM $version restart failed, rolled back"
            fi
        else
            if service php-fpm-$version restart 2>/dev/null; then
                echo -e "${GREEN}✅ PHP-FPM $version 重启成功${NC}"
                success_count=$((success_count + 1))
                log_message "OPTIMIZER: PHP-FPM $version configuration optimized successfully"
            else
                echo -e "${RED}❌ PHP-FPM $version 重启失败，正在回滚...${NC}"
                cp -f "$backup_file" "$php_fpm_conf"
                service php-fpm-$version restart 2>/dev/null
                echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启${NC}"
                log_message "OPTIMIZER: PHP-FPM $version restart failed, rolled back"
            fi
        fi
    done
    
    if [ $success_count -gt 0 ]; then
        echo -e "${GREEN}✅ 成功优化了 $success_count/$total_count 个PHP-FPM版本${NC}"
    else
        echo -e "${RED}❌ 所有PHP-FPM版本优化失败${NC}"
        return 1
    fi
    
    return 0
}

# 自动修复CPU占用过高
fix_high_cpu() {
    echo -e "${BLUE}【自动修复CPU占用过高】${NC}"
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
    php_versions=$(find /www/server/php -maxdepth 1 -type d -name "[0-9]*" | sort)
    
    for php_dir in $php_versions; do
        version=$(basename "$php_dir")
        if command -v systemctl &> /dev/null; then
            systemctl restart php-fpm-$version 2>/dev/null
        else
            service php-fpm-$version restart 2>/dev/null
        fi
    done
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
    
    return 0
}

# 自动修复内存占用过高
fix_high_memory() {
    echo -e "${BLUE}【自动修复内存占用过高】${NC}"
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
    
    # 3. 重启高内存占用的服务（MySQL/Redis）
    echo -e "${YELLOW}3. 重启高内存占用服务...${NC}"
    MYSQL_MEM=$(ps aux | grep mysql | grep -v grep | awk '{sum+=$4} END {print sum}')
    if [ -n "$MYSQL_MEM" ] && (( $(echo "$MYSQL_MEM > 20" | bc -l) )); then
        echo -e "${YELLOW}MySQL内存占用较高，重启MySQL...${NC}"
        systemctl restart mysql 2>/dev/null || service mysql restart 2>/dev/null
        echo -e "${GREEN}✅ MySQL重启完成${NC}"
        log_message "AUTO_FIX: MySQL restarted due to high memory usage"
    fi
    
    REDIS_MEM=$(ps aux | grep redis | grep -v grep | awk '{sum+=$4} END {print sum}')
    if [ -n "$REDIS_MEM" ] && (( $(echo "$REDIS_MEM > 10" | bc -l) )); then
        echo -e "${YELLOW}Redis内存占用较高，重启Redis...${NC}"
        systemctl restart redis 2>/dev/null || service redis restart 2>/dev/null
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
    
    return 0
}

# 自动修复CC攻击（TIME_WAIT过多）
fix_cc_attack() {
    echo -e "${BLUE}【自动修复CC攻击】${NC}"
    echo "=================================="
    
    log_message "AUTO_FIX: Starting CC attack fix"
    
    # 1. 重启Nginx清理连接
    echo -e "${YELLOW}1. 重启Nginx清理连接...${NC}"
    systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Nginx重启成功${NC}"
        log_message "AUTO_FIX: Nginx restarted successfully"
    else
        echo -e "${RED}❌ Nginx重启失败${NC}"
        log_message "AUTO_FIX: Nginx restart failed"
    fi
    
    # 2. 重启PHP-FPM
    echo -e "${YELLOW}2. 重启PHP-FPM...${NC}"
    php_versions=$(find /www/server/php -maxdepth 1 -type d -name "[0-9]*" | sort)
    for php_dir in $php_versions; do
        version=$(basename "$php_dir")
        systemctl restart php-fpm-$version 2>/dev/null || service php-fpm-$version restart 2>/dev/null
    done
    echo -e "${GREEN}✅ PHP-FPM重启完成${NC}"
    log_message "AUTO_FIX: PHP-FPM restarted"
    
    # 3. 清理TIME_WAIT连接
    echo -e "${YELLOW}3. 清理TIME_WAIT连接...${NC}"
    echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
    echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle 2>/dev/null
    echo -e "${GREEN}✅ TIME_WAIT连接清理完成${NC}"
    log_message "AUTO_FIX: TIME_WAIT connections cleared"
    
    # 4. 添加iptables限连（如可用）
    if command -v iptables &> /dev/null; then
        echo -e "${YELLOW}4. 添加防火墙防护规则...${NC}"
        iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 50 -j DROP 2>/dev/null
        iptables -A INPUT -p tcp --dport 443 -m connlimit --connlimit-above 50 -j DROP 2>/dev/null
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
    
    if [ "$NEW_TIME_WAIT" -lt 500 ]; then
        echo -e "${GREEN}✅ CC攻击修复成功！${NC}"
        log_message "AUTO_FIX: CC attack fixed successfully"
    else
        echo -e "${YELLOW}⚠️  CC攻击可能仍在持续，建议手动检查${NC}"
        log_message "AUTO_FIX: CC attack may still be ongoing"
    fi
    
    return 0
}

# 自动清理可疑挖矿进程
fix_suspicious_processes() {
    echo -e "${BLUE}【自动清理可疑进程】${NC}"
    echo "=================================="
    
    log_message "AUTO_FIX: Starting suspicious process cleanup"
    
    local SUSPICIOUS_PROCESSES=("miner" "xmr" "monero" "coinhive" "cryptonight" "xmrig" "ccminer" "ethminer" "bitcoin" "litecoin" "stratum" "pool" "hashrate")
    local KILLED_COUNT=0
    
    for process in "${SUSPICIOUS_PROCESSES[@]}"; do
        PIDS=$(pgrep -f "$process" 2>/dev/null)
        if [ -n "$PIDS" ]; then
            echo -e "${YELLOW}发现可疑进程: $process${NC}"
            echo -e "进程ID: $PIDS"
            for pid in $PIDS; do
                kill -9 "$pid" 2>/dev/null
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
    
    if [ "$KILLED_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✅ 共清理了 $KILLED_COUNT 个可疑进程${NC}"
        log_message "AUTO_FIX: Cleaned $KILLED_COUNT suspicious processes"
    else
        echo -e "${GREEN}✅ 未发现需要清理的可疑进程${NC}"
        log_message "AUTO_FIX: No suspicious processes found to clean"
    fi
    
    return 0
}

# 恢复优化前配置：sysctl
restore_sysctl_config() {
    echo -e "${BLUE}【恢复sysctl配置】${NC}"
    echo "=================================="
    local latest=$(ls -1 /etc/sysctl.conf.backup.* 2>/dev/null | sort | tail -1)
    if [ -n "$latest" ] && [ -f "$latest" ]; then
        cp -f "$latest" /etc/sysctl.conf
        sysctl -p > /dev/null 2>&1
        echo -e "${GREEN}✅ 已恢复: $latest${NC}"
        log_message "RESTORE: sysctl.conf restored from $latest"
        return 0
    else
        echo -e "${YELLOW}⚠️ 未找到sysctl备份文件${NC}"
        return 1
    fi
}

# 恢复优化前配置：limits
restore_limits_config() {
    echo -e "${BLUE}【恢复limits配置】${NC}"
    echo "=================================="
    local latest=$(ls -1 /etc/security/limits.conf.backup.* 2>/dev/null | sort | tail -1)
    if [ -n "$latest" ] && [ -f "$latest" ]; then
        cp -f "$latest" /etc/security/limits.conf
        echo -e "${GREEN}✅ 已恢复: $latest${NC}"
        log_message "RESTORE: limits.conf restored from $latest"
        return 0
    else
        echo -e "${YELLOW}⚠️ 未找到limits备份文件${NC}"
        return 1
    fi
}

# 恢复优化前配置：Nginx
restore_nginx_config() {
    echo -e "${BLUE}【恢复Nginx配置】${NC}"
    echo "=================================="
    local nginx_conf="/www/server/nginx/conf/nginx.conf"
    local latest=$(ls -1 ${nginx_conf}.backup.* 2>/dev/null | sort | tail -1)
    if [ -n "$latest" ] && [ -f "$latest" ]; then
        cp -f "$latest" "$nginx_conf"
        if command -v systemctl &> /dev/null; then
            systemctl restart nginx 2>/dev/null
        else
            service nginx restart 2>/dev/null
        fi
        echo -e "${GREEN}✅ 已恢复: $latest${NC}"
        log_message "RESTORE: nginx.conf restored from $latest"
        return 0
    else
        echo -e "${YELLOW}⚠️ 未找到Nginx备份文件${NC}"
        return 1
    fi
}

# 恢复优化前配置：Apache
restore_apache_config() {
    echo -e "${BLUE}【恢复Apache配置】${NC}"
    echo "=================================="
    local apache_conf="/www/server/apache/conf/httpd.conf"
    local latest=$(ls -1 ${apache_conf}.backup.* 2>/dev/null | sort | tail -1)
    if [ -n "$latest" ] && [ -f "$latest" ]; then
        cp -f "$latest" "$apache_conf"
        if command -v systemctl &> /dev/null; then
            systemctl restart httpd 2>/dev/null
        else
            service httpd restart 2>/dev/null
        fi
        echo -e "${GREEN}✅ 已恢复: $latest${NC}"
        log_message "RESTORE: httpd.conf restored from $latest"
        return 0
    else
        echo -e "${YELLOW}⚠️ 未找到Apache备份文件${NC}"
        return 1
    fi
}

# 恢复优化前配置：PHP-FPM（遍历各版本）
restore_php_fpm_config() {
    echo -e "${BLUE}【恢复PHP-FPM配置】${NC}"
    echo "=================================="
    local php_versions=$(find /www/server/php -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | sort)
    local restored_any=false
    for php_dir in $php_versions; do
        local php_fpm_conf="$php_dir/etc/php-fpm.conf"
        local latest=$(ls -1 ${php_fpm_conf}.backup.* 2>/dev/null | sort | tail -1)
        if [ -n "$latest" ] && [ -f "$latest" ]; then
            cp -f "$latest" "$php_fpm_conf"
            local version=$(basename "$php_dir")
            if command -v systemctl &> /dev/null; then
                systemctl restart php-fpm-$version 2>/dev/null
            else
                service php-fpm-$version restart 2>/dev/null
            fi
            echo -e "${GREEN}✅ PHP-$version 已恢复: $latest${NC}"
            log_message "RESTORE: php-fpm-$version restored from $latest"
            restored_any=true
        fi
    done
    if [ "$restored_any" != true ]; then
        echo -e "${YELLOW}⚠️ 未找到任何PHP-FPM备份文件${NC}"
        return 1
    fi
    return 0
}

# 一键恢复优化前配置（聚合）
restore_all_optimizations() {
    echo -e "${BLUE}【一键恢复优化前配置】${NC}"
    echo "=================================="
    restore_sysctl_config
    restore_limits_config
    restore_nginx_config
    restore_apache_config
    restore_php_fpm_config
    echo -e "${GREEN}✅ 恢复操作完成${NC}"
    log_message "RESTORE: All optimization configs attempted to restore"
}

# SSH端口变更防锁死功能
change_ssh_port_safely() {
    echo -e "${BLUE}【SSH端口变更防锁死】${NC}"
    echo "=================================="
    
    local current_port=$(grep -E "^Port\s+" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
    if [ -z "$current_port" ]; then
        current_port="22"
    fi
    
    echo -e "${CYAN}当前SSH端口: $current_port${NC}"
    echo -e "${YELLOW}请输入新的SSH端口 (1024-65535):${NC}"
    read -r new_port
    
    # 验证端口号
    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1024 ] || [ "$new_port" -gt 65535 ]; then
        echo -e "${RED}❌ 无效的端口号，请输入1024-65535之间的数字${NC}"
        return 1
    fi
    
    if [ "$new_port" = "$current_port" ]; then
        echo -e "${YELLOW}⚠️ 新端口与当前端口相同，无需更改${NC}"
        return 0
    fi
    
    # 检查端口是否已被占用
    if netstat -tlnp 2>/dev/null | grep -q ":$new_port "; then
        echo -e "${RED}❌ 端口 $new_port 已被占用，请选择其他端口${NC}"
        return 1
    fi
    
    # 备份SSH配置
    local backup_file="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
    cp /etc/ssh/sshd_config "$backup_file"
    echo -e "${CYAN}SSH配置已备份到: $backup_file${NC}"
    
    # 修改SSH端口
    echo -e "${YELLOW}正在修改SSH端口配置...${NC}"
    if grep -q "^Port " /etc/ssh/sshd_config; then
        sed -i "s/^Port .*/Port $new_port/" /etc/ssh/sshd_config
    else
        echo "Port $new_port" >> /etc/ssh/sshd_config
    fi
    
    # 配置语法校验
    echo -e "${YELLOW}正在校验SSH配置语法...${NC}"
    if command -v sshd &> /dev/null; then
        if sshd -t 2>/dev/null; then
            echo -e "${GREEN}✅ SSH配置语法校验通过${NC}"
        else
            echo -e "${RED}❌ SSH配置语法校验失败，正在回滚...${NC}"
            cp -f "$backup_file" /etc/ssh/sshd_config
            echo -e "${YELLOW}⚠️ 已回滚到原始配置${NC}"
            log_message "SSH: Config validation failed, rolled back"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️ 无法找到sshd命令，跳过语法校验${NC}"
    fi
    
    # 测试新端口连接
    echo -e "${YELLOW}正在测试新端口连接...${NC}"
    local test_result=0
    
    # 启动SSH服务（如果未运行）
    if ! systemctl is-active --quiet sshd 2>/dev/null; then
        systemctl start sshd 2>/dev/null
    fi
    
    # 等待服务启动
    sleep 2
    
    # 测试新端口是否可连接
    if timeout 10 bash -c "echo > /dev/tcp/localhost/$new_port" 2>/dev/null; then
        echo -e "${GREEN}✅ 新端口 $new_port 连接测试成功${NC}"
    else
        echo -e "${RED}❌ 新端口 $new_port 连接测试失败${NC}"
        test_result=1
    fi
    
    # 如果测试失败，回滚配置
    if [ $test_result -ne 0 ]; then
        echo -e "${RED}❌ 端口测试失败，正在回滚...${NC}"
        cp -f "$backup_file" /etc/ssh/sshd_config
        systemctl restart sshd 2>/dev/null
        echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启SSH服务${NC}"
        log_message "SSH: Port test failed, rolled back"
        return 1
    fi
    
    # 重启SSH服务
    echo -e "${YELLOW}正在重启SSH服务...${NC}"
    if systemctl restart sshd 2>/dev/null; then
        echo -e "${GREEN}✅ SSH服务重启成功${NC}"
    else
        echo -e "${RED}❌ SSH服务重启失败，正在回滚...${NC}"
        cp -f "$backup_file" /etc/ssh/sshd_config
        systemctl restart sshd 2>/dev/null
        echo -e "${YELLOW}⚠️ 已回滚到原始配置并重启SSH服务${NC}"
        log_message "SSH: Service restart failed, rolled back"
        return 1
    fi
    
    # 最终验证
    sleep 3
    if netstat -tlnp 2>/dev/null | grep -q ":$new_port "; then
        echo -e "${GREEN}✅ SSH端口已成功更改为 $new_port${NC}"
        echo -e "${CYAN}请使用新端口连接: ssh -p $new_port user@server${NC}"
        echo -e "${YELLOW}⚠️ 请确保防火墙已开放新端口 $new_port${NC}"
        log_message "SSH: Port successfully changed to $new_port"
    else
        echo -e "${RED}❌ SSH端口更改失败，正在回滚...${NC}"
        cp -f "$backup_file" /etc/ssh/sshd_config
        systemctl restart sshd 2>/dev/null
        echo -e "${YELLOW}⚠️ 已回滚到原始配置${NC}"
        log_message "SSH: Port change failed, rolled back"
        return 1
    fi
    
    return 0
}

# 检查SSH连接状态
check_ssh_status() {
    echo -e "${BLUE}【检查SSH连接状态】${NC}"
    echo "=================================="
    
    local current_port=$(grep -E "^Port\s+" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
    if [ -z "$current_port" ]; then
        current_port="22"
    fi
    
    echo -e "${CYAN}当前SSH端口: $current_port${NC}"
    echo -e "${CYAN}SSH服务状态:${NC}"
    systemctl status sshd --no-pager -l 2>/dev/null | head -10
    
    echo -e "${CYAN}SSH监听端口:${NC}"
    netstat -tlnp 2>/dev/null | grep sshd | head -5
    
    echo -e "${CYAN}当前SSH连接:${NC}"
    who | grep -E "pts|tty" | wc -l | xargs echo "活跃连接数:"
    
    echo -e "${CYAN}最近登录记录:${NC}"
    last -n 5 2>/dev/null | head -5
    
    return 0
}
