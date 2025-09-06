#!/bin/bash

# 宝塔面板服务器维护工具 - 系统垃圾清理模块
# 作者: 咸鱼神秘人
# 版本: 2.1.0

# 格式化文件大小（兼容性函数）
format_size() {
    local size=$1
    if command -v numfmt >/dev/null 2>&1; then
        echo "$size" | numfmt --to=iec
    else
        # 简单的文件大小格式化
        if [ "$size" -lt 1024 ]; then
            echo "${size}B"
        elif [ "$size" -lt 1048576 ]; then
            echo "$((size/1024))K"
        elif [ "$size" -lt 1073741824 ]; then
            echo "$((size/1048576))M"
        else
            echo "$((size/1073741824))G"
        fi
    fi
}

# 系统垃圾清理功能
clean_system_garbage() {
    echo -e "${BLUE}【系统垃圾清理】${NC}"
    echo "=================================="
    
    local start_time=$(date +%s)
    local total_cleaned=0
    local files_count=0
    
    # 执行安全检查
    if ! safety_check; then
        return 1
    fi
    
    echo -e "${YELLOW}正在清理系统垃圾文件...${NC}"
    
    # 清理临时文件
    echo -e "${CYAN}1. 清理临时文件...${NC}"
    local temp_size=0
    
    # /tmp目录清理（保留重要文件）
    if [ -d "/tmp" ]; then
        temp_size=$(find /tmp -type f -mtime +1 -not -path "*/.*" -not -name "*.sock" -not -name "systemd-*" -not -name "ssh-*" -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
        if [ "$temp_size" -gt 0 ]; then
            find /tmp -type f -mtime +1 -not -path "*/.*" -not -name "*.sock" -not -name "systemd-*" -not -name "ssh-*" -delete 2>/dev/null
            echo -e "${GREEN}✅ 清理 /tmp 临时文件: $(format_size $temp_size)${NC}"
            total_cleaned=$((total_cleaned + temp_size))
        fi
    fi
    
    # /var/tmp目录清理
    if [ -d "/var/tmp" ]; then
        local var_temp_size=$(find /var/tmp -type f -mtime +3 -not -path "*/.*" -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
        if [ "$var_temp_size" -gt 0 ]; then
            find /var/tmp -type f -mtime +3 -not -path "*/.*" -delete 2>/dev/null
            echo -e "${GREEN}✅ 清理 /var/tmp 临时文件: $(format_size $var_temp_size)${NC}"
            total_cleaned=$((total_cleaned + var_temp_size))
        fi
    fi
    
    # 清理日志文件
    echo -e "${CYAN}2. 清理过期日志文件...${NC}"
    local log_dirs=("/var/log" "/var/log/nginx" "/var/log/apache2" "/var/log/httpd" "/www/wwwlogs")
    
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            # 清理超过30天的日志文件
            local log_size=$(find "$log_dir" -name "*.log" -mtime +30 -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
            if [ "$log_size" -gt 0 ]; then
                find "$log_dir" -name "*.log" -mtime +30 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理 $log_dir 过期日志: $(format_size $log_size)${NC}"
                total_cleaned=$((total_cleaned + log_size))
            fi
            
            # 清理压缩日志文件
            local gz_size=$(find "$log_dir" -name "*.gz" -mtime +7 -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
            if [ "$gz_size" -gt 0 ]; then
                find "$log_dir" -name "*.gz" -mtime +7 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理 $log_dir 压缩日志: $(format_size $gz_size)${NC}"
                total_cleaned=$((total_cleaned + gz_size))
            fi
        fi
    done
    
    # 清理包管理器缓存
    echo -e "${CYAN}3. 清理包管理器缓存...${NC}"
    
    # 清理yum缓存（CentOS/RHEL）
    if command -v yum &> /dev/null; then
        local yum_cache_size=$(du -sb /var/cache/yum 2>/dev/null | awk '{print $1}' || echo 0)
        if [ "$yum_cache_size" -gt 0 ]; then
            yum clean all &>/dev/null
            echo -e "${GREEN}✅ 清理YUM缓存: $(format_size $yum_cache_size)${NC}"
            total_cleaned=$((total_cleaned + yum_cache_size))
        fi
    fi
    
    # 清理dnf缓存（Fedora/新版CentOS）
    if command -v dnf &> /dev/null; then
        local dnf_cache_size=$(du -sb /var/cache/dnf 2>/dev/null | awk '{print $1}' || echo 0)
        if [ "$dnf_cache_size" -gt 0 ]; then
            dnf clean all &>/dev/null
            echo -e "${GREEN}✅ 清理DNF缓存: $(format_size $dnf_cache_size)${NC}"
            total_cleaned=$((total_cleaned + dnf_cache_size))
        fi
    fi
    
    # 清理apt缓存（Debian/Ubuntu）
    if command -v apt-get &> /dev/null; then
        local apt_cache_size=$(du -sb /var/cache/apt/archives 2>/dev/null | awk '{print $1}' || echo 0)
        if [ "$apt_cache_size" -gt 0 ]; then
            apt-get clean &>/dev/null
            echo -e "${GREEN}✅ 清理APT缓存: $(format_size $apt_cache_size)${NC}"
            total_cleaned=$((total_cleaned + apt_cache_size))
        fi
    fi
    
    # 清理回收站
    echo -e "${CYAN}4. 清理回收站...${NC}"
    local trash_dirs=("/root/.local/share/Trash" "/home/*/.local/share/Trash")
    
    for trash_pattern in "${trash_dirs[@]}"; do
        for trash_dir in $trash_pattern; do
            if [ -d "$trash_dir" ]; then
                local trash_size=$(du -sb "$trash_dir" 2>/dev/null | awk '{print $1}' || echo 0)
                if [ "$trash_size" -gt 0 ]; then
                    rm -rf "$trash_dir"/* 2>/dev/null
                    echo -e "${GREEN}✅ 清理回收站 $trash_dir: $(format_size $trash_size)${NC}"
                    total_cleaned=$((total_cleaned + trash_size))
                fi
            fi
        done
    done
    
    # 清理核心转储文件
    echo -e "${CYAN}5. 清理核心转储文件...${NC}"
    local core_size=$(find / -name "core" -type f -size +1M -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
    if [ "$core_size" -gt 0 ]; then
        find / -name "core" -type f -size +1M -delete 2>/dev/null
        echo -e "${GREEN}✅ 清理核心转储文件: $(format_size $core_size)${NC}"
        total_cleaned=$((total_cleaned + core_size))
    fi
    
    # 清理PHP会话文件
    echo -e "${CYAN}6. 清理PHP会话文件...${NC}"
    local php_session_dirs=("/var/lib/php/sessions" "/var/lib/php5/sessions" "/var/lib/php7/sessions" "/var/lib/php8/sessions" "/tmp")
    
    for session_dir in "${php_session_dirs[@]}"; do
        if [ -d "$session_dir" ]; then
            local session_size=$(find "$session_dir" -name "sess_*" -mtime +1 -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
            if [ "$session_size" -gt 0 ]; then
                find "$session_dir" -name "sess_*" -mtime +1 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理PHP会话文件: $(format_size $session_size)${NC}"
                total_cleaned=$((total_cleaned + session_size))
            fi
        fi
    done
    
    # 清理宝塔面板缓存（安全清理）
    echo -e "${CYAN}7. 清理宝塔面板缓存...${NC}"
    local bt_cache_dirs=("/www/server/panel/logs" "/www/server/panel/temp")
    
    for cache_dir in "${bt_cache_dirs[@]}"; do
        if [ -d "$cache_dir" ]; then
            local cache_size=$(find "$cache_dir" -name "*.log" -mtime +7 -exec du -cb {} + 2>/dev/null | tail -1 | awk '{print $1}' 2>/dev/null || echo 0)
            if [ "$cache_size" -gt 0 ]; then
                find "$cache_dir" -name "*.log" -mtime +7 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理宝塔面板缓存: $(format_size $cache_size)${NC}"
                total_cleaned=$((total_cleaned + cache_size))
            fi
        fi
    done
    
    # 清理systemd日志
    echo -e "${CYAN}8. 清理systemd日志...${NC}"
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --vacuum-time=30d >/dev/null 2>&1
        journalctl --vacuum-size=100M >/dev/null 2>&1
        echo -e "${GREEN}✅ 清理systemd日志完成${NC}"
    fi
    
    # 清理扩展包缓存
    echo -e "${CYAN}9. 清理扩展包缓存...${NC}"
    
    # pip缓存
    if command -v pip >/dev/null 2>&1; then
        local pip_cache_dir=$(pip cache dir 2>/dev/null || echo "/root/.cache/pip")
        if [ -d "$pip_cache_dir" ]; then
            local pip_cache_size=$(du -sb "$pip_cache_dir" 2>/dev/null | awk '{print $1}' || echo 0)
            if [ "$pip_cache_size" -gt 0 ]; then
                pip cache purge >/dev/null 2>&1
                echo -e "${GREEN}✅ 清理pip缓存: $(format_size $pip_cache_size)${NC}"
                total_cleaned=$((total_cleaned + pip_cache_size))
            fi
        fi
    fi
    
    # npm缓存
    if command -v npm >/dev/null 2>&1; then
        local npm_cache_dir=$(npm config get cache 2>/dev/null || echo "/root/.npm")
        if [ -d "$npm_cache_dir" ]; then
            local npm_cache_size=$(du -sb "$npm_cache_dir" 2>/dev/null | awk '{print $1}' || echo 0)
            if [ "$npm_cache_size" -gt 0 ]; then
                npm cache clean --force >/dev/null 2>&1
                echo -e "${GREEN}✅ 清理npm缓存: $(format_size $npm_cache_size)${NC}"
                total_cleaned=$((total_cleaned + npm_cache_size))
            fi
        fi
    fi
    
    # gem缓存
    if command -v gem >/dev/null 2>&1; then
        gem cleanup >/dev/null 2>&1
        echo -e "${GREEN}✅ 清理gem缓存${NC}"
    fi
    
    echo "=================================="
    echo -e "${GREEN}✅ 系统垃圾清理完成！${NC}"
    echo -e "${GREEN}总计清理空间: $(format_size $total_cleaned)${NC}"
    
    # 显示磁盘空间使用情况
    echo -e "${CYAN}当前磁盘使用情况:${NC}"
    df -h / | tail -1
    
    # 显示性能统计
    cleanup_performance_stats "$start_time" "$total_cleaned" "$files_count"
    
    # 生成清理报告
    local cleanup_details="系统垃圾清理完成
- 清理临时文件
- 清理过期日志
- 清理包管理器缓存
- 清理回收站
- 清理PHP会话文件
- 清理宝塔面板缓存
- 清理systemd日志
- 清理扩展包缓存"
    
    generate_cleanup_report "系统垃圾清理" "$total_cleaned" "$(($(date +%s) - start_time))" "$cleanup_details"
    
    log_message "GARBAGE_CLEANER: System garbage cleanup completed, freed space: $(format_size $total_cleaned)"
    
    return 0
}
