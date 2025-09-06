#!/bin/bash

# 宝塔面板服务器维护工具 - 清理分析模块
# 作者: 咸鱼神秘人
# 版本: 2.1.0

# 预估清理空间功能
estimate_cleanup_space() {
    echo -e "${BLUE}【预估清理空间】${NC}"
    echo "=================================="
    
    local estimated_space=0
    local temp_files=0
    local log_files=0
    local cache_files=0
    
    echo -e "${YELLOW}正在分析系统垃圾文件...${NC}"
    
    # 估算临时文件
    echo -e "${CYAN}分析临时文件...${NC}"
    if [ -d "/tmp" ]; then
        temp_files=$(find /tmp -type f -mtime +1 -not -path "*/.*" -not -name "*.sock" -not -name "systemd-*" -not -name "ssh-*" -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
        estimated_space=$((estimated_space + temp_files))
    fi
    
    # 估算日志文件
    echo -e "${CYAN}分析日志文件...${NC}"
    local log_dirs=("/var/log" "/var/log/nginx" "/var/log/apache2" "/var/log/httpd" "/www/wwwlogs")
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            local dir_size=$(find "$log_dir" -name "*.log" -mtime +30 -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
            log_files=$((log_files + dir_size))
        fi
    done
    estimated_space=$((estimated_space + log_files))
    
    # 估算缓存文件
    echo -e "${CYAN}分析缓存文件...${NC}"
    local cache_dirs=("/var/cache/yum" "/var/cache/dnf" "/var/cache/apt/archives")
    for cache_dir in "${cache_dirs[@]}"; do
        if [ -d "$cache_dir" ]; then
            local dir_size=$(du -sb "$cache_dir" 2>/dev/null | awk '{print $1}' || echo 0)
            cache_files=$((cache_files + dir_size))
        fi
    done
    estimated_space=$((estimated_space + cache_files))
    
    echo "=================================="
    echo -e "${CYAN}预估结果:${NC}"
    echo -e "  临时文件: $(format_size $temp_files)"
    echo -e "  过期日志: $(format_size $log_files)"
    echo -e "  系统缓存: $(format_size $cache_files)"
    echo "=================================="
    echo -e "${GREEN}预计可释放空间: $(format_size $estimated_space)${NC}"
    
    if [ "$estimated_space" -gt 1048576 ]; then  # 大于1MB才建议清理
        echo -ne "${YELLOW}是否继续执行清理? (y/n): ${NC}"
        read confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            return 0
        else
            echo -e "${YELLOW}取消清理操作${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}系统很干净，无需清理${NC}"
        return 1
    fi
}

# 智能磁盘空间分析
analyze_disk_usage() {
    echo -e "${BLUE}【智能磁盘分析】${NC}"
    echo "=================================="
    
    # 检查磁盘使用率
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | tr -d '%')
    local disk_free=$(df -h / | tail -1 | awk '{print $4}')
    
    echo -e "${CYAN}当前磁盘状态:${NC}"
    echo -e "  使用率: ${disk_usage}%"
    echo -e "  可用空间: ${disk_free}"
    
    if [ "$disk_usage" -gt 90 ]; then
        echo -e "${RED}⚠️ 磁盘空间严重不足！建议立即执行深度清理${NC}"
        return 2  # 需要深度清理
    elif [ "$disk_usage" -gt 80 ]; then
        echo -e "${YELLOW}⚠️ 磁盘空间紧张，建议执行标准清理${NC}"
        return 1  # 需要标准清理
    else
        echo -e "${GREEN}✅ 磁盘空间充足${NC}"
        return 0  # 无需清理
    fi
}

# 清理策略推荐
recommend_cleanup_strategy() {
    echo -e "${BLUE}【清理策略推荐】${NC}"
    echo "=================================="
    
    analyze_disk_usage
    local disk_status=$?
    
    case $disk_status in
        2)
            echo -e "${RED}推荐策略: 深度清理${NC}"
            echo -e "  • 清理所有临时文件和缓存"
            echo -e "  • 清理数据库日志和网站缓存"
            echo -e "  • 清理Docker容器和镜像"
            echo -e "  • 优化文件系统缓存"
            ;;
        1)
            echo -e "${YELLOW}推荐策略: 标准清理${NC}"
            echo -e "  • 清理系统垃圾文件"
            echo -e "  • 清理过期日志文件"
            echo -e "  • 清理包管理器缓存"
            ;;
        0)
            echo -e "${GREEN}推荐策略: 维护性清理${NC}"
            echo -e "  • 清理临时文件"
            echo -e "  • 清理浏览器缓存"
            echo -e "  • 清理系统日志"
            ;;
    esac
    
    echo "=================================="
    echo -ne "${YELLOW}是否按推荐策略执行清理? (y/n): ${NC}"
    read confirm
    
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        case $disk_status in
            2) deep_clean_system ;;
            1) clean_system_garbage ;;
            0) clean_system_garbage ;;
        esac
    fi
}

# 清理安全检查
safety_check() {
    echo -e "${BLUE}【清理安全检查】${NC}"
    echo "=================================="
    
    local warnings=0
    
    # 检查重要服务状态
    echo -e "${CYAN}检查系统服务状态...${NC}"
    local important_services=("nginx" "apache2" "mysql" "redis" "php-fpm")
    
    for service in "${important_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}✅ $service 服务运行正常${NC}"
        elif systemctl is-enabled --quiet "$service" 2>/dev/null; then
            echo -e "${YELLOW}⚠️ $service 服务已安装但未运行${NC}"
            warnings=$((warnings + 1))
        fi
    done
    
    # 检查磁盘剩余空间
    echo -e "${CYAN}检查磁盘剩余空间...${NC}"
    local free_space=$(df / | tail -1 | awk '{print $4}')
    if [ "$free_space" -lt 1048576 ]; then  # 小于1GB
        echo -e "${RED}⚠️ 磁盘剩余空间不足1GB，清理时请谨慎${NC}"
        warnings=$((warnings + 1))
    else
        echo -e "${GREEN}✅ 磁盘剩余空间充足${NC}"
    fi
    
    # 检查系统负载
    echo -e "${CYAN}检查系统负载...${NC}"
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
    local cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    
    if (( $(echo "$load > $cpu_cores" | bc 2>/dev/null || echo 0) )); then
        echo -e "${YELLOW}⚠️ 系统负载较高 ($load)，建议稍后执行清理${NC}"
        warnings=$((warnings + 1))
    else
        echo -e "${GREEN}✅ 系统负载正常${NC}"
    fi
    
    echo "=================================="
    if [ "$warnings" -gt 0 ]; then
        echo -e "${YELLOW}发现 $warnings 个潜在问题，建议谨慎执行清理${NC}"
        echo -ne "${YELLOW}是否继续执行清理? (y/n): ${NC}"
        read confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo -e "${YELLOW}已取消清理操作${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ 系统状态良好，可以安全执行清理${NC}"
    fi
    
    return 0
}

# 清理性能统计
cleanup_performance_stats() {
    local start_time=$1
    local cleaned_size=$2
    local files_count=${3:-0}
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo -e "${BLUE}【清理性能统计】${NC}"
    echo "=================================="
    echo -e "${CYAN}执行时间: ${duration}秒${NC}"
    
    if [ "$duration" -gt 0 ]; then
        local speed_mb=$(echo "scale=2; $cleaned_size / $duration / 1024 / 1024" | bc 2>/dev/null || echo "0")
        echo -e "${CYAN}清理速度: ${speed_mb}MB/s${NC}"
        
        if [ "$files_count" -gt 0 ]; then
            local file_speed=$(echo "scale=2; $files_count / $duration" | bc 2>/dev/null || echo "0")
            echo -e "${CYAN}文件处理速度: ${file_speed}个/秒${NC}"
        fi
    fi
    
    echo -e "${CYAN}释放空间: $(format_size $cleaned_size)${NC}"
    echo "=================================="
}

# 生成清理报告
generate_cleanup_report() {
    local cleanup_type="$1"
    local cleaned_size="$2"
    local duration="$3"
    local details="$4"
    
    local report_file="/tmp/cleanup_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
========================================
宝塔面板服务器维护工具 - 清理报告
========================================
报告生成时间: $(date)
清理类型: $cleanup_type
执行时长: ${duration}秒
释放空间: $(format_size $cleaned_size)
系统信息: $(uname -a)
========================================
磁盘使用情况 (清理后):
$(df -h /)
========================================
详细信息:
$details
========================================
EOF
    
    echo -e "${GREEN}✅ 清理报告已生成: $report_file${NC}"
    echo -e "${CYAN}可使用以下命令查看报告: cat $report_file${NC}"
}
