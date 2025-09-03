#!/bin/bash

# 宝塔面板服务器维护工具 - 流量分析模块

# 分析日志文件
analyze_logs() {
    echo -e "${BLUE}【分析Web访问日志】${NC}"
    echo "=================================="
    
    # 查找所有访问日志
    local log_files=($(find /www/wwwlogs/ -name "*.log" -type f 2>/dev/null))
    
    if [ ${#log_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ 未找到Web访问日志文件${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}找到 ${#log_files[@]} 个日志文件，开始分析...${NC}"
    
    # 分析每个日志文件
    for log_file in "${log_files[@]}"; do
        analyze_single_log "$log_file"
    done
    
    return 0
}

# 分析单个日志文件
analyze_single_log() {
    local log_file="$1"
    local file_name=$(basename "$log_file")
    
    echo -e "${BLUE}分析日志文件: $file_name${NC}"
    
    # 检查文件是否存在且可读
    if [ ! -f "$log_file" ] || [ ! -r "$log_file" ]; then
        echo -e "${RED}❌ 无法读取日志文件: $log_file${NC}"
        return 1
    fi
    
    # 获取最近10分钟的日志
    local time_pattern=$(date -d '10 minutes ago' +'%d/%b/%Y:%H:%M')
    local recent_logs=$(grep -a "$time_pattern" "$log_file" 2>/dev/null)
    
    if [ -z "$recent_logs" ]; then
        echo -e "${YELLOW}⚠️ 最近10分钟没有访问记录${NC}"
        return 0
    fi
    
    # 分析IP访问频率
    echo -e "${CYAN}访问频率最高的IP (最近10分钟):${NC}"
    echo "$recent_logs" | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
    
    # 分析请求URL
    echo -e "${CYAN}访问频率最高的URL (最近10分钟):${NC}"
    echo "$recent_logs" | awk '{print $7}' | sort | uniq -c | sort -nr | head -10
    
    # 分析HTTP状态码
    echo -e "${CYAN}HTTP状态码分布 (最近10分钟):${NC}"
    echo "$recent_logs" | awk '{print $9}' | sort | uniq -c | sort -nr
    
    # 分析请求方法
    echo -e "${CYAN}请求方法分布 (最近10分钟):${NC}"
    echo "$recent_logs" | awk '{print $6}' | tr -d '"' | sort | uniq -c | sort -nr
    
    # 检测异常请求模式
    detect_attack_patterns "$log_file" "$recent_logs"
    
    return 0
}

# 检测攻击模式
detect_attack_patterns() {
    local log_file="$1"
    local recent_logs="$2"
    
    echo -e "${BLUE}【检测攻击模式】${NC}"
    echo "=================================="
    
    # 检测CC攻击模式
    detect_cc_attack "$log_file" "$recent_logs"
    
    # 检测SQL注入攻击
    detect_sql_injection "$log_file" "$recent_logs"
    
    # 检测XSS攻击
    detect_xss_attack "$log_file" "$recent_logs"
    
    # 检测路径遍历攻击
    detect_path_traversal "$log_file" "$recent_logs"
    
    # 检测命令注入攻击
    detect_command_injection "$log_file" "$recent_logs"
    
    return 0
}

# 检测CC攻击
detect_cc_attack() {
    local log_file="$1"
    local recent_logs="$2"
    
    echo -e "${BLUE}检测CC攻击模式...${NC}"
    
    # 设置阈值
    local ip_threshold=${CC_IP_THRESHOLD:-100}  # 单IP请求阈值
    local url_threshold=${CC_URL_THRESHOLD:-50}  # 单URL请求阈值
    local time_window=${CC_TIME_WINDOW:-600}  # 时间窗口（秒）
    
    # 分析IP访问频率
    local high_freq_ips=$(echo "$recent_logs" | awk '{print $1}' | sort | uniq -c | sort -nr | awk -v threshold="$ip_threshold" '$1 > threshold {print $2 "|" $1}')
    
    if [ -n "$high_freq_ips" ]; then
        echo -e "${RED}⚠️ 检测到可能的CC攻击! 以下IP在短时间内发送大量请求:${NC}"
        echo -e "${CYAN}IP地址            请求数${NC}"
        echo "------------------------"
        
        while IFS="|" read -r ip count; do
            printf "%-18s %s\n" "$ip" "$count"
            
            # 自动加入黑名单
            if [ "${AUTO_BLACKLIST:-true}" = "true" ]; then
                if ! is_in_whitelist "$ip"; then
                    add_to_blacklist "$ip" "CC攻击: $count 请求/10分钟" 3600
                fi
            fi
        done <<< "$high_freq_ips"
        
        log_message "ANALYZER: Detected potential CC attack from multiple IPs"
    else
        echo -e "${GREEN}✅ 未检测到CC攻击模式${NC}"
    fi
    
    # 分析URL访问频率
    local high_freq_urls=$(echo "$recent_logs" | awk '{print $7}' | sort | uniq -c | sort -nr | awk -v threshold="$url_threshold" '$1 > threshold {print $2 "|" $1}')
    
    if [ -n "$high_freq_urls" ]; then
        echo -e "${YELLOW}⚠️ 以下URL在短时间内被大量请求:${NC}"
        echo -e "${CYAN}URL                                             请求数${NC}"
        echo "-------------------------------------------------------------"
        
        while IFS="|" read -r url count; do
            printf "%-50s %s\n" "$url" "$count"
        done <<< "$high_freq_urls"
        
        log_message "ANALYZER: Detected high frequency requests to specific URLs"
    fi
    
    return 0
}

# 检测SQL注入攻击
detect_sql_injection() {
    local log_file="$1"
    local recent_logs="$2"
    
    echo -e "${BLUE}检测SQL注入攻击...${NC}"
    
    # SQL注入特征
    local sql_patterns=(
        "SELECT.*FROM"
        "UNION.*SELECT"
        "INSERT.*INTO"
        "UPDATE.*SET"
        "DELETE.*FROM"
        "DROP.*TABLE"
        "OR.*1=1"
        "AND.*1=1"
        "SLEEP\([0-9]+\)"
        "BENCHMARK\("
        "WAITFOR.*DELAY"
    )
    
    local detected=false
    
    for pattern in "${sql_patterns[@]}"; do
        local matches=$(echo "$recent_logs" | grep -i -E "$pattern" | awk '{print $1 "|" $7}')
        
        if [ -n "$matches" ]; then
            if [ "$detected" = false ]; then
                echo -e "${RED}⚠️ 检测到可能的SQL注入攻击:${NC}"
                echo -e "${CYAN}IP地址            URL${NC}"
                echo "-----------------------------------------------"
                detected=true
            fi
            
            while IFS="|" read -r ip url; do
                if [ -n "$ip" ] && [ -n "$url" ]; then
                    printf "%-18s %s\n" "$ip" "$url"
                    
                    # 自动加入黑名单
                    if [ "${AUTO_BLACKLIST:-true}" = "true" ]; then
                        if ! is_in_whitelist "$ip"; then
                            add_to_blacklist "$ip" "SQL注入攻击" 86400
                        fi
                    fi
                fi
            done <<< "$matches"
        fi
    done
    
    if [ "$detected" = false ]; then
        echo -e "${GREEN}✅ 未检测到SQL注入攻击${NC}"
    else
        log_message "ANALYZER: Detected potential SQL injection attacks"
    fi
    
    return 0
}

# 检测XSS攻击
detect_xss_attack() {
    local log_file="$1"
    local recent_logs="$2"
    
    echo -e "${BLUE}检测XSS攻击...${NC}"
    
    # XSS攻击特征
    local xss_patterns=(
        "<script>"
        "javascript:"
        "onload="
        "onerror="
        "onclick="
        "onmouseover="
        "eval\("
        "document\.cookie"
        "alert\("
        "String\.fromCharCode"
    )
    
    local detected=false
    
    for pattern in "${xss_patterns[@]}"; do
        local matches=$(echo "$recent_logs" | grep -i -E "$pattern" | awk '{print $1 "|" $7}')
        
        if [ -n "$matches" ]; then
            if [ "$detected" = false ]; then
                echo -e "${RED}⚠️ 检测到可能的XSS攻击:${NC}"
                echo -e "${CYAN}IP地址            URL${NC}"
                echo "-----------------------------------------------"
                detected=true
            fi
            
            while IFS="|" read -r ip url; do
                if [ -n "$ip" ] && [ -n "$url" ]; then
                    printf "%-18s %s\n" "$ip" "$url"
                    
                    # 自动加入黑名单
                    if [ "${AUTO_BLACKLIST:-true}" = "true" ]; then
                        if ! is_in_whitelist "$ip"; then
                            add_to_blacklist "$ip" "XSS攻击" 86400
                        fi
                    fi
                fi
            done <<< "$matches"
        fi
    done
    
    if [ "$detected" = false ]; then
        echo -e "${GREEN}✅ 未检测到XSS攻击${NC}"
    else
        log_message "ANALYZER: Detected potential XSS attacks"
    fi
    
    return 0
}

# 检测路径遍历攻击
detect_path_traversal() {
    local log_file="$1"
    local recent_logs="$2"
    
    echo -e "${BLUE}检测路径遍历攻击...${NC}"
    
    # 路径遍历特征
    local path_patterns=(
        "\.\./\.\."
        "%2e%2e/%2e%2e"
        "\.\.%2f\.\.%2f"
        "/etc/passwd"
        "/etc/shadow"
        "/proc/self"
        "WEB-INF"
        "wp-config\.php"
        "config\.php"
        ".git/"
    )
    
    local detected=false
    
    for pattern in "${path_patterns[@]}"; do
        local matches=$(echo "$recent_logs" | grep -i -E "$pattern" | awk '{print $1 "|" $7}')
        
        if [ -n "$matches" ]; then
            if [ "$detected" = false ]; then
                echo -e "${RED}⚠️ 检测到可能的路径遍历攻击:${NC}"
                echo -e "${CYAN}IP地址            URL${NC}"
                echo "-----------------------------------------------"
                detected=true
            fi
            
            while IFS="|" read -r ip url; do
                if [ -n "$ip" ] && [ -n "$url" ]; then
                    printf "%-18s %s\n" "$ip" "$url"
                    
                    # 自动加入黑名单
                    if [ "${AUTO_BLACKLIST:-true}" = "true" ]; then
                        if ! is_in_whitelist "$ip"; then
                            add_to_blacklist "$ip" "路径遍历攻击" 86400
                        fi
                    fi
                fi
            done <<< "$matches"
        fi
    done
    
    if [ "$detected" = false ]; then
        echo -e "${GREEN}✅ 未检测到路径遍历攻击${NC}"
    else
        log_message "ANALYZER: Detected potential path traversal attacks"
    fi
    
    return 0
}

# 检测命令注入攻击
detect_command_injection() {
    local log_file="$1"
    local recent_logs="$2"
    
    echo -e "${BLUE}检测命令注入攻击...${NC}"
    
    # 命令注入特征
    local cmd_patterns=(
        ";\s*[a-zA-Z]+"
        "&&\s*[a-zA-Z]+"
        "\|\|\s*[a-zA-Z]+"
        "\|\s*[a-zA-Z]+"
        "`[^`]+`"
        "\$\([^)]+\)"
        "system\("
        "exec\("
        "shell_exec\("
        "passthru\("
    )
    
    local detected=false
    
    for pattern in "${cmd_patterns[@]}"; do
        local matches=$(echo "$recent_logs" | grep -i -E "$pattern" | awk '{print $1 "|" $7}')
        
        if [ -n "$matches" ]; then
            if [ "$detected" = false ]; then
                echo -e "${RED}⚠️ 检测到可能的命令注入攻击:${NC}"
                echo -e "${CYAN}IP地址            URL${NC}"
                echo "-----------------------------------------------"
                detected=true
            fi
            
            while IFS="|" read -r ip url; do
                if [ -n "$ip" ] && [ -n "$url" ]; then
                    printf "%-18s %s\n" "$ip" "$url"
                    
                    # 自动加入黑名单
                    if [ "${AUTO_BLACKLIST:-true}" = "true" ]; then
                        if ! is_in_whitelist "$ip"; then
                            add_to_blacklist "$ip" "命令注入攻击" 86400
                        fi
                    fi
                fi
            done <<< "$matches"
        fi
    done
    
    if [ "$detected" = false ]; then
        echo -e "${GREEN}✅ 未检测到命令注入攻击${NC}"
    else
        log_message "ANALYZER: Detected potential command injection attacks"
    fi
    
    return 0
}

# 实时监控日志
monitor_logs_realtime() {
    echo -e "${BLUE}【实时监控Web访问日志】${NC}"
    echo "=================================="
    
    # 查找最新的访问日志
    local log_files=($(find /www/wwwlogs/ -name "*.log" -type f -mtime -1 2>/dev/null | sort -r))
    
    if [ ${#log_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}⚠️ 未找到最近的Web访问日志文件${NC}"
        return 1
    fi
    
    local main_log="${log_files[0]}"
    echo -e "${YELLOW}正在监控日志文件: $(basename "$main_log")${NC}"
    echo -e "${YELLOW}按 Ctrl+C 停止监控${NC}"
    
    # 使用tail -f监控日志
    tail -f "$main_log" | while read -r line; do
        # 提取IP和URL
        local ip=$(echo "$line" | awk '{print $1}')
        local url=$(echo "$line" | awk '{print $7}')
        local status=$(echo "$line" | awk '{print $9}')
        
        # 检查是否是黑名单IP
        if is_in_blacklist "$ip"; then
            echo -e "${RED}⚠️ 黑名单IP访问: $ip - $url (状态码: $status)${NC}"
            continue
        fi
        
        # 检查是否包含攻击特征
        if echo "$line" | grep -q -i -E "(SELECT.*FROM|UNION.*SELECT|<script>|javascript:|\.\.\/\.\.|;.*[a-zA-Z]+)"; then
            echo -e "${RED}⚠️ 检测到可能的攻击: $ip - $url (状态码: $status)${NC}"
            
            # 自动加入黑名单
            if [ "${AUTO_BLACKLIST:-true}" = "true" ]; then
                if ! is_in_whitelist "$ip"; then
                    add_to_blacklist "$ip" "实时检测到攻击行为" 3600
                fi
            fi
        else
            # 正常请求，显示简要信息
            echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $ip - $url (状态码: $status)"
        fi
    done
    
    return 0
}

# 分析TCP连接
analyze_connections() {
    echo -e "${BLUE}【分析TCP连接】${NC}"
    echo "=================================="
    
    # 检查netstat命令
    if ! command -v netstat &> /dev/null; then
        echo -e "${RED}❌ netstat命令不可用${NC}"
        return 1
    fi
    
    # 获取连接统计
    local total_conn=$(netstat -an | wc -l)
    local established=$(netstat -an | grep ESTABLISHED | wc -l)
    local time_wait=$(netstat -an | grep TIME_WAIT | wc -l)
    local close_wait=$(netstat -an | grep CLOSE_WAIT | wc -l)
    local syn_recv=$(netstat -an | grep SYN_RECV | wc -l)
    
    echo -e "${CYAN}连接统计:${NC}"
    echo "总连接数: $total_conn"
    echo "ESTABLISHED: $established"
    echo "TIME_WAIT: $time_wait"
    echo "CLOSE_WAIT: $close_wait"
    echo "SYN_RECV: $syn_recv"
    
    # 分析连接IP分布
    echo -e "${CYAN}连接IP分布:${NC}"
    echo -e "IP地址            连接数"
    echo "------------------------"
    netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 | while read count ip; do
        printf "%-18s %s\n" "$ip" "$count"
    done
    
    # 检测SYN洪水攻击
    if [ $syn_recv -gt 100 ]; then
        echo -e "${RED}⚠️ 检测到可能的SYN洪水攻击! SYN_RECV连接数: $syn_recv${NC}"
        log_message "ANALYZER: Detected potential SYN flood attack, SYN_RECV: $syn_recv"
        
        # 分析SYN_RECV连接的源IP
        echo -e "${CYAN}SYN_RECV连接源IP:${NC}"
        netstat -an | grep SYN_RECV | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 | while read count ip; do
            printf "%-18s %s\n" "$ip" "$count"
            
            # 自动加入黑名单
            if [ "${AUTO_BLACKLIST:-true}" = "true" ] && [ $count -gt 20 ]; then
                if ! is_in_whitelist "$ip"; then
                    add_to_blacklist "$ip" "SYN洪水攻击: $count SYN连接" 3600
                fi
            fi
        done
    fi
    
    # 检测连接异常
    if [ $time_wait -gt 1000 ]; then
        echo -e "${YELLOW}⚠️ TIME_WAIT连接数异常高: $time_wait${NC}"
        log_message "ANALYZER: High number of TIME_WAIT connections: $time_wait"
    fi
    
    if [ $close_wait -gt 100 ]; then
        echo -e "${YELLOW}⚠️ CLOSE_WAIT连接数异常高: $close_wait${NC}"
        log_message "ANALYZER: High number of CLOSE_WAIT connections: $close_wait"
    fi
    
    return 0
}
