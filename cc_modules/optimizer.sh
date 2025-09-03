#!/bin/bash

# CC攻击防护系统 - 系统优化模块

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
    cp "$nginx_conf" "${nginx_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    
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
    
    # 重启Nginx
    if command -v systemctl &> /dev/null; then
        systemctl restart nginx
    else
        service nginx restart
    fi
    
    echo -e "${GREEN}✅ Nginx配置已优化${NC}"
    log_message "OPTIMIZER: Nginx configuration optimized"
    
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
    cp "$apache_conf" "${apache_conf}.backup.$(date +%Y%m%d_%H%M%S)"
    
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
    
    # 重启Apache
    if command -v systemctl &> /dev/null; then
        systemctl restart httpd
    else
        service httpd restart
    fi
    
    echo -e "${GREEN}✅ Apache配置已优化${NC}"
    log_message "OPTIMIZER: Apache configuration optimized"
    
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
    
    for php_dir in $php_versions; do
        local version=$(basename "$php_dir")
        local php_fpm_conf="$php_dir/etc/php-fpm.conf"
        
        if [ ! -f "$php_fpm_conf" ]; then
            echo -e "${YELLOW}⚠️ PHP-FPM配置文件不存在: $php_fpm_conf${NC}"
            continue
        fi
        
        echo -e "${YELLOW}正在优化PHP-FPM $version 配置...${NC}"
        
        # 备份原始配置
        cp "$php_fpm_conf" "${php_fpm_conf}.backup.$(date +%Y%m%d_%H%M%S)"
        
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
        
        # 重启PHP-FPM
        if command -v systemctl &> /dev/null; then
            systemctl restart php-fpm-$version
        else
            service php-fpm-$version restart
        fi
        
        echo -e "${GREEN}✅ PHP-FPM $version 配置已优化${NC}"
        log_message "OPTIMIZER: PHP-FPM $version configuration optimized"
    done
    
    return 0
}
