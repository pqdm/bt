#!/bin/bash

# 宝塔面板服务器维护工具 - 恶意文件清理模块（优化版）

# 宝塔面板白名单配置文件路径
BT_WHITELIST_CONFIG="/root/cc_config_bt_whitelist.conf"

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

# 加载宝塔面板白名单配置
load_bt_whitelist_config() {
    if [ -f "$BT_WHITELIST_CONFIG" ]; then
        source "$BT_WHITELIST_CONFIG"
    else
        echo -e "${YELLOW}警告: 宝塔面板白名单配置文件不存在: $BT_WHITELIST_CONFIG${NC}"
        echo -e "${YELLOW}使用默认白名单配置${NC}"
    fi
}

# 检查文件是否在宝塔面板白名单中
is_bt_whitelist_file() {
    local file_path="$1"
    
    # 加载白名单配置
    load_bt_whitelist_config
    
    # 宝塔面板核心目录白名单
    local bt_dirs=(
        "/www/server/panel"
        "/www/server/nginx"
        "/www/server/apache"
        "/www/server/mysql"
        "/www/server/php"
        "/www/server/redis"
        "/www/server/mongodb"
        "/www/server/pure-ftpd"
        "/www/server/phpmyadmin"
        "/www/server/phpmyadmin4"
        "/www/server/phpmyadmin5"
        "/www/server/phpmyadmin6"
        "/www/server/phpmyadmin7"
        "/www/server/phpmyadmin8"
        "/www/server/phpmyadmin9"
        "/www/server/phpmyadmin10"
        "/www/server/phpmyadmin11"
        "/www/server/phpmyadmin12"
        "/www/server/phpmyadmin13"
        "/www/server/phpmyadmin14"
        "/www/server/phpmyadmin15"
        "/www/server/phpmyadmin16"
        "/www/server/phpmyadmin17"
        "/www/server/phpmyadmin18"
        "/www/server/phpmyadmin19"
        "/www/server/phpmyadmin20"
        "/www/server/phpmyadmin21"
        "/www/server/phpmyadmin22"
        "/www/server/phpmyadmin23"
        "/www/server/phpmyadmin24"
        "/www/server/phpmyadmin25"
        "/www/server/phpmyadmin26"
        "/www/server/phpmyadmin27"
        "/www/server/phpmyadmin28"
        "/www/server/phpmyadmin29"
        "/www/server/phpmyadmin30"
        "/www/server/phpmyadmin31"
        "/www/server/phpmyadmin32"
        "/www/server/phpmyadmin33"
        "/www/server/phpmyadmin34"
        "/www/server/phpmyadmin35"
        "/www/server/phpmyadmin36"
        "/www/server/phpmyadmin37"
        "/www/server/phpmyadmin38"
        "/www/server/phpmyadmin39"
        "/www/server/phpmyadmin40"
        "/www/server/phpmyadmin41"
        "/www/server/phpmyadmin42"
        "/www/server/phpmyadmin43"
        "/www/server/phpmyadmin44"
        "/www/server/phpmyadmin45"
        "/www/server/phpmyadmin46"
        "/www/server/phpmyadmin47"
        "/www/server/phpmyadmin48"
        "/www/server/phpmyadmin49"
        "/www/server/phpmyadmin50"
        "/www/server/phpmyadmin51"
        "/www/server/phpmyadmin52"
        "/www/server/phpmyadmin53"
        "/www/server/phpmyadmin54"
        "/www/server/phpmyadmin55"
        "/www/server/phpmyadmin56"
        "/www/server/phpmyadmin57"
        "/www/server/phpmyadmin58"
        "/www/server/phpmyadmin59"
        "/www/server/phpmyadmin60"
        "/www/server/phpmyadmin61"
        "/www/server/phpmyadmin62"
        "/www/server/phpmyadmin63"
        "/www/server/phpmyadmin64"
        "/www/server/phpmyadmin65"
        "/www/server/phpmyadmin66"
        "/www/server/phpmyadmin67"
        "/www/server/phpmyadmin68"
        "/www/server/phpmyadmin69"
        "/www/server/phpmyadmin70"
        "/www/server/phpmyadmin71"
        "/www/server/phpmyadmin72"
        "/www/server/phpmyadmin73"
        "/www/server/phpmyadmin74"
        "/www/server/phpmyadmin75"
        "/www/server/phpmyadmin76"
        "/www/server/phpmyadmin77"
        "/www/server/phpmyadmin78"
        "/www/server/phpmyadmin79"
        "/www/server/phpmyadmin80"
        "/www/server/phpmyadmin81"
        "/www/server/phpmyadmin82"
        "/www/server/phpmyadmin83"
        "/www/server/phpmyadmin84"
        "/www/server/phpmyadmin85"
        "/www/server/phpmyadmin86"
        "/www/server/phpmyadmin87"
        "/www/server/phpmyadmin88"
        "/www/server/phpmyadmin89"
        "/www/server/phpmyadmin90"
        "/www/server/phpmyadmin91"
        "/www/server/phpmyadmin92"
        "/www/server/phpmyadmin93"
        "/www/server/phpmyadmin94"
        "/www/server/phpmyadmin95"
        "/www/server/phpmyadmin96"
        "/www/server/phpmyadmin97"
        "/www/server/phpmyadmin98"
        "/www/server/phpmyadmin99"
        "/www/server/phpmyadmin100"
    )
    
    # 检查是否在宝塔面板目录中
    for bt_dir in "${bt_dirs[@]}"; do
        if [[ "$file_path" == "$bt_dir"* ]]; then
            return 0  # 在白名单中
        fi
    done
    
    # 宝塔面板特定文件名白名单
    local bt_files=(
        "icon-backdoor.svg"
        "icon-rootkit.svg"
        "sw_php_backdoor.py"
        "sw_strace_backdoor.py"
        "sw_php_backdoor.pl"
        "sw_strace_backdoor.pl"
        ".start_task.pl"
        ".panelTask.pl"
        ".fluah_time"
    )
    
    local filename=$(basename "$file_path")
    for bt_file in "${bt_files[@]}"; do
        if [[ "$filename" == "$bt_file" ]]; then
            return 0  # 在白名单中
        fi
    done
    
    return 1  # 不在白名单中
}

# 获取文件类型和详细注释
get_file_analysis() {
    local file_path="$1"
    local file_type=$(file "$file_path" 2>/dev/null)
    local filename=$(basename "$file_path")
    local analysis=""
    
    # 检查是否是宝塔面板文件
    if is_bt_whitelist_file "$file_path"; then
        analysis="${GREEN}✅ 宝塔面板文件 - 安全${NC}"
        if [[ "$filename" == "icon-backdoor.svg" || "$filename" == "icon-rootkit.svg" ]]; then
            analysis="${analysis}\n${YELLOW}注释: 这是宝塔面板的图标文件，用于UI显示${NC}"
        elif [[ "$filename" == "sw_php_backdoor.py" || "$filename" == "sw_strace_backdoor.py" ]]; then
            analysis="${analysis}\n${YELLOW}注释: 这是宝塔面板的安全检测组件，用于检测PHP后门${NC}"
        elif [[ "$filename" == "sw_php_backdoor.pl" || "$filename" == "sw_strace_backdoor.pl" ]]; then
            analysis="${analysis}\n${YELLOW}注释: 这是宝塔面板的安全检测结果文件${NC}"
        elif [[ "$filename" == ".start_task.pl" || "$filename" == ".panelTask.pl" ]]; then
            analysis="${analysis}\n${YELLOW}注释: 这是宝塔面板的任务文件，用于定时任务管理${NC}"
        elif [[ "$filename" == ".fluah_time" ]]; then
            analysis="${analysis}\n${YELLOW}注释: 这是宝塔面板的缓存时间戳文件${NC}"
        fi
        return 0
    fi
    
    # 分析其他文件类型
    if echo "$file_type" | grep -q "ELF"; then
        analysis="${YELLOW}⚠️ 可执行程序${NC}"
        if [[ "$filename" == *"minerd"* || "$filename" == *"xmrig"* || "$filename" == *"cpuminer"* ]]; then
            analysis="${analysis}\n${RED}❌ 疑似挖矿程序${NC}"
        elif [[ "$filename" == *"kworker"* || "$filename" == *"kthread"* ]]; then
            analysis="${analysis}\n${RED}❌ 疑似恶意内核模块${NC}"
        else
            analysis="${analysis}\n${YELLOW}注释: 如果您不认识此程序，请谨慎处理${NC}"
        fi
    elif echo "$file_type" | grep -q "script"; then
        analysis="${YELLOW}⚠️ 脚本文件${NC}"
        if [[ "$filename" == *"miner.sh"* || "$filename" == *"ddos.pl"* ]]; then
            analysis="${analysis}\n${RED}❌ 疑似恶意脚本${NC}"
        else
            analysis="${analysis}\n${YELLOW}注释: 可能是自动化任务脚本，请检查内容${NC}"
        fi
    elif [[ "$filename" == *".fluah_time" ]]; then
        analysis="${YELLOW}⚠️ 时间戳文件${NC}\n${YELLOW}注释: 这可能是挖矿程序的时间戳文件${NC}"
    else
        analysis="${CYAN}ℹ️ 普通文件${NC}"
    fi
    
    echo -e "$analysis"
    return 1
}

# 扫描系统中的恶意文件（优化版）
scan_malicious_files() {
    echo -e "${BLUE}【扫描系统恶意文件】${NC}"
    echo "=================================="
    
    echo -e "${YELLOW}正在扫描系统中的恶意文件...${NC}"
    echo -e "${GREEN}注意: 宝塔面板相关文件将被自动排除${NC}"
    
    # 定义恶意文件特征
    local malware_patterns=(
        # 挖矿程序
        "minerd"
        "xmrig"
        "cpuminer"
        "coinhive"
        "monero"
        "cryptonight"
        # 后门和木马
        "backdoor"
        "rootkit"
        "trojan"
        # 恶意脚本
        "ddos.pl"
        "miner.sh"
        "kworker"
        "kthread"
        "kdevtmpfs"
        "kauditd"
        "kintegrityd"
    )
    
    # 定义可疑目录
    local suspicious_dirs=(
        "/tmp"
        "/var/tmp"
        "/dev/shm"
        "/run/shm"
        "/var/run/shm"
        "/var/spool/cron"
        "/var/spool/anacron"
    )
    
    # 检查可疑目录
    for dir in "${suspicious_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${CYAN}检查目录: $dir${NC}"
            
            # 查找可执行文件
            local exec_files=$(find "$dir" -type f -executable 2>/dev/null)
            if [ -n "$exec_files" ]; then
                echo -e "${YELLOW}发现可执行文件:${NC}"
                echo "$exec_files"
                
                # 将文件列表保存到数组
                local file_array=()
                while read -r line; do
                    file_array+=("$line")
                done <<< "$exec_files"
                
                # 检查每个可执行文件
                for file in "${file_array[@]}"; do
                    echo -e "${CYAN}检查文件: $file${NC}"
                    ls -la "$file"
                    
                    # 获取文件分析
                    local analysis=$(get_file_analysis "$file")
                    echo -e "$analysis"
                    
                    # 如果不在白名单中，提示是否删除
                    if ! is_bt_whitelist_file "$file"; then
                        echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
                        read answer
                        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                            if rm -f "$file" 2>/dev/null; then
                                echo -e "${GREEN}✅ 文件已删除: $file${NC}"
                                log_message "CLEANER: Suspicious file deleted: $file"
                            else
                                echo -e "${RED}❌ 无法删除文件: $file${NC}"
                                log_message "CLEANER: Failed to delete suspicious file: $file"
                            fi
                        fi
                    else
                        echo -e "${GREEN}✅ 跳过宝塔面板文件: $file${NC}"
                    fi
                done
            else
                echo -e "${GREEN}✅ 未发现可执行文件${NC}"
            fi
            
            # 查找隐藏文件
            local hidden_files=$(find "$dir" -name ".*" -type f 2>/dev/null)
            if [ -n "$hidden_files" ]; then
                echo -e "${YELLOW}发现隐藏文件:${NC}"
                echo "$hidden_files"
                
                # 将文件列表保存到数组
                local file_array=()
                while read -r line; do
                    file_array+=("$line")
                done <<< "$hidden_files"
                
                # 检查每个隐藏文件
                for file in "${file_array[@]}"; do
                    echo -e "${CYAN}检查文件: $file${NC}"
                    ls -la "$file"
                    
                    # 获取文件分析
                    local analysis=$(get_file_analysis "$file")
                    echo -e "$analysis"
                    
                    # 如果不在白名单中，提示是否删除
                    if ! is_bt_whitelist_file "$file"; then
                        echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
                        read answer
                        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                            if rm -f "$file" 2>/dev/null; then
                                echo -e "${GREEN}✅ 文件已删除: $file${NC}"
                                log_message "CLEANER: Hidden file deleted: $file"
                            else
                                echo -e "${RED}❌ 无法删除文件: $file${NC}"
                                log_message "CLEANER: Failed to delete hidden file: $file"
                            fi
                        fi
                    else
                        echo -e "${GREEN}✅ 跳过宝塔面板文件: $file${NC}"
                    fi
                done
            else
                echo -e "${GREEN}✅ 未发现隐藏文件${NC}"
            fi
        fi
    done
    
    # 使用find命令查找可疑文件名
    echo -e "${CYAN}搜索可疑文件名...${NC}"
    for pattern in "${malware_patterns[@]}"; do
        echo -e "${CYAN}搜索: $pattern${NC}"
        local found_files=$(find / -name "*$pattern*" -type f 2>/dev/null | grep -v "/proc/" | grep -v "/sys/" | grep -v "/www/server/")
        
        if [ -n "$found_files" ]; then
            echo -e "${YELLOW}发现可疑文件:${NC}"
            echo "$found_files"
            
            # 将文件列表保存到数组
            local file_array=()
            while read -r line; do
                file_array+=("$line")
            done <<< "$found_files"
            
            # 检查每个可疑文件
            for file in "${file_array[@]}"; do
                echo -e "${CYAN}检查文件: $file${NC}"
                ls -la "$file"
                
                # 获取文件分析
                local analysis=$(get_file_analysis "$file")
                echo -e "$analysis"
                
                # 如果不在白名单中，提示是否删除
                if ! is_bt_whitelist_file "$file"; then
                    echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
                    read answer
                    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                        if rm -f "$file" 2>/dev/null; then
                            echo -e "${GREEN}✅ 文件已删除: $file${NC}"
                            log_message "CLEANER: Malicious file deleted: $file"
                        else
                            echo -e "${RED}❌ 无法删除文件: $file${NC}"
                            log_message "CLEANER: Failed to delete malicious file: $file"
                        fi
                    fi
                else
                    echo -e "${GREEN}✅ 跳过宝塔面板文件: $file${NC}"
                fi
            done
        else
            echo -e "${GREEN}✅ 未发现可疑文件: $pattern${NC}"
        fi
    done
    
    # 检查大文件（可能是隐藏的挖矿程序）
    echo -e "${CYAN}检查异常大小的文件...${NC}"
    local large_files=$(find /tmp /var/tmp /dev/shm -type f -size +5M 2>/dev/null)
    
    if [ -n "$large_files" ]; then
        echo -e "${YELLOW}发现大文件:${NC}"
        
        # 将文件列表保存到数组
        local file_array=()
        while read -r line; do
            file_array+=("$line")
        done <<< "$large_files"
        
        # 检查每个大文件
        for file in "${file_array[@]}"; do
            echo -e "${CYAN}文件: $file ($(du -h "$file" | awk '{print $1}'))${NC}"
            ls -la "$file"
            
            # 获取文件分析
            local analysis=$(get_file_analysis "$file")
            echo -e "$analysis"
            
            # 如果不在白名单中，提示是否删除
            if ! is_bt_whitelist_file "$file"; then
                echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
                read answer
                if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                    if rm -f "$file" 2>/dev/null; then
                        echo -e "${GREEN}✅ 文件已删除: $file${NC}"
                        log_message "CLEANER: Large suspicious file deleted: $file"
                    else
                        echo -e "${RED}❌ 无法删除文件: $file${NC}"
                        log_message "CLEANER: Failed to delete large suspicious file: $file"
                    fi
                fi
            else
                echo -e "${GREEN}✅ 跳过宝塔面板文件: $file${NC}"
            fi
        done
    else
        echo -e "${GREEN}✅ 未发现异常大小的文件${NC}"
    fi
    
    return 0
}

# 系统垃圾清理功能
clean_system_garbage() {
    echo -e "${BLUE}【系统垃圾清理】${NC}"
    echo "=================================="
    
    local start_time=$(date +%s)
    local total_cleaned=0
    local files_count=0
    local temp_log="/tmp/cleanup_log.txt"
    
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
            echo -e "${GREEN}✅ 清理 /var/tmp 临时文件: $(echo $var_temp_size | numfmt --to=iec)${NC}"
            total_cleaned=$((total_cleaned + var_temp_size))
        fi
    fi
    
    # 清理日志文件
    echo -e "${CYAN}2. 清理过期日志文件...${NC}"
    local log_dirs=("/var/log" "/var/log/nginx" "/var/log/apache2" "/var/log/httpd" "/www/wwwlogs")
    
    for log_dir in "${log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            # 清理超过30天的日志文件
            local log_size=$(find "$log_dir" -name "*.log" -mtime +30 2>/dev/null | xargs du -cb 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
            if [ "$log_size" -gt 0 ]; then
                find "$log_dir" -name "*.log" -mtime +30 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理 $log_dir 过期日志: $(echo $log_size | numfmt --to=iec)${NC}"
                total_cleaned=$((total_cleaned + log_size))
            fi
            
            # 清理压缩日志文件
            local gz_size=$(find "$log_dir" -name "*.gz" -mtime +7 2>/dev/null | xargs du -cb 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
            if [ "$gz_size" -gt 0 ]; then
                find "$log_dir" -name "*.gz" -mtime +7 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理 $log_dir 压缩日志: $(echo $gz_size | numfmt --to=iec)${NC}"
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
            echo -e "${GREEN}✅ 清理YUM缓存: $(echo $yum_cache_size | numfmt --to=iec)${NC}"
            total_cleaned=$((total_cleaned + yum_cache_size))
        fi
    fi
    
    # 清理dnf缓存（Fedora/新版CentOS）
    if command -v dnf &> /dev/null; then
        local dnf_cache_size=$(du -sb /var/cache/dnf 2>/dev/null | awk '{print $1}' || echo 0)
        if [ "$dnf_cache_size" -gt 0 ]; then
            dnf clean all &>/dev/null
            echo -e "${GREEN}✅ 清理DNF缓存: $(echo $dnf_cache_size | numfmt --to=iec)${NC}"
            total_cleaned=$((total_cleaned + dnf_cache_size))
        fi
    fi
    
    # 清理apt缓存（Debian/Ubuntu）
    if command -v apt-get &> /dev/null; then
        local apt_cache_size=$(du -sb /var/cache/apt/archives 2>/dev/null | awk '{print $1}' || echo 0)
        if [ "$apt_cache_size" -gt 0 ]; then
            apt-get clean &>/dev/null
            echo -e "${GREEN}✅ 清理APT缓存: $(echo $apt_cache_size | numfmt --to=iec)${NC}"
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
                    echo -e "${GREEN}✅ 清理回收站 $trash_dir: $(echo $trash_size | numfmt --to=iec)${NC}"
                    total_cleaned=$((total_cleaned + trash_size))
                fi
            fi
        done
    done
    
    # 清理核心转储文件
    echo -e "${CYAN}5. 清理核心转储文件...${NC}"
    local core_size=$(find / -name "core" -type f -size +1M 2>/dev/null | xargs du -cb 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
    if [ "$core_size" -gt 0 ]; then
        find / -name "core" -type f -size +1M -delete 2>/dev/null
        echo -e "${GREEN}✅ 清理核心转储文件: $(echo $core_size | numfmt --to=iec)${NC}"
        total_cleaned=$((total_cleaned + core_size))
    fi
    
    # 清理PHP会话文件
    echo -e "${CYAN}6. 清理PHP会话文件...${NC}"
    local php_session_dirs=("/var/lib/php/sessions" "/var/lib/php5/sessions" "/var/lib/php7/sessions" "/var/lib/php8/sessions" "/tmp")
    
    for session_dir in "${php_session_dirs[@]}"; do
        if [ -d "$session_dir" ]; then
            local session_size=$(find "$session_dir" -name "sess_*" -mtime +1 2>/dev/null | xargs du -cb 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
            if [ "$session_size" -gt 0 ]; then
                find "$session_dir" -name "sess_*" -mtime +1 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理PHP会话文件: $(echo $session_size | numfmt --to=iec)${NC}"
                total_cleaned=$((total_cleaned + session_size))
            fi
        fi
    done
    
    # 清理宝塔面板缓存（安全清理）
    echo -e "${CYAN}7. 清理宝塔面板缓存...${NC}"
    local bt_cache_dirs=("/www/server/panel/logs" "/www/server/panel/temp")
    
    for cache_dir in "${bt_cache_dirs[@]}"; do
        if [ -d "$cache_dir" ]; then
            local cache_size=$(find "$cache_dir" -name "*.log" -mtime +7 2>/dev/null | xargs du -cb 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
            if [ "$cache_size" -gt 0 ]; then
                find "$cache_dir" -name "*.log" -mtime +7 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理宝塔面板缓存: $(echo $cache_size | numfmt --to=iec)${NC}"
                total_cleaned=$((total_cleaned + cache_size))
            fi
        fi
    done
    
    # 清理systemd日志
    echo -e "${CYAN}8. 清理systemd日志...${NC}"
    if command -v journalctl >/dev/null 2>&1; then
        local log_size_before=$(journalctl --disk-usage 2>/dev/null | grep -o '[0-9.]*[MGT]' | head -1 || echo "0")
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
    
    log_message "CLEANER: System garbage cleanup completed, freed space: $(format_size $total_cleaned)"
    
    return 0
}

# 深度清理功能
deep_clean_system() {
    echo -e "${BLUE}【深度系统清理】${NC}"
    echo "=================================="
    echo -e "${RED}警告: 深度清理将执行更彻底的清理操作${NC}"
    echo -e "${RED}请确保您已经备份重要数据！${NC}"
    echo ""
    
    # 执行安全检查
    if ! safety_check; then
        return 1
    fi
    
    echo -ne "${YELLOW}确定要继续深度清理吗? (y/n): ${NC}"
    read confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${YELLOW}取消深度清理操作${NC}"
        return 0
    fi
    
    local start_time=$(date +%s)
    local total_cleaned=0
    local files_count=0
    
    echo -e "${YELLOW}正在执行深度清理...${NC}"
    
    # 1. 清理Docker相关（如果存在）
    echo -e "${CYAN}1. 清理Docker相关文件...${NC}"
    if command -v docker &> /dev/null; then
        # 清理停止的容器
        local stopped_containers=$(docker ps -aq --filter "status=exited" 2>/dev/null)
        if [ -n "$stopped_containers" ]; then
            docker rm $stopped_containers &>/dev/null
            echo -e "${GREEN}✅ 清理停止的Docker容器${NC}"
        fi
        
        # 清理无用的镜像
        local dangling_images=$(docker images -q --filter "dangling=true" 2>/dev/null)
        if [ -n "$dangling_images" ]; then
            docker rmi $dangling_images &>/dev/null
            echo -e "${GREEN}✅ 清理无用的Docker镜像${NC}"
        fi
        
        # 清理系统数据
        docker system prune -f &>/dev/null
        echo -e "${GREEN}✅ 清理Docker系统数据${NC}"
    fi
    
    # 2. 清理内核相关文件
    echo -e "${CYAN}2. 清理旧内核文件...${NC}"
    if command -v package-cleanup &> /dev/null; then
        package-cleanup --oldkernels --count=1 -y &>/dev/null
        echo -e "${GREEN}✅ 清理旧内核文件${NC}"
    elif command -v apt-get &> /dev/null; then
        apt-get autoremove --purge -y &>/dev/null
        echo -e "${GREEN}✅ 自动清理无用软件包${NC}"
    fi
    
    # 3. 清理数据库日志
    echo -e "${CYAN}3. 清理数据库日志...${NC}"
    
    # MySQL/MariaDB日志清理
    local mysql_log_dirs=("/var/log/mysql" "/var/log/mariadb" "/www/server/mysql/data")
    for log_dir in "${mysql_log_dirs[@]}"; do
        if [ -d "$log_dir" ]; then
            local db_log_size=$(find "$log_dir" -name "*-bin.*" -mtime +7 2>/dev/null | xargs du -cb 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
            if [ "$db_log_size" -gt 0 ]; then
                find "$log_dir" -name "*-bin.*" -mtime +7 -delete 2>/dev/null
                echo -e "${GREEN}✅ 清理数据库二进制日志: $(echo $db_log_size | numfmt --to=iec)${NC}"
                total_cleaned=$((total_cleaned + db_log_size))
            fi
        fi
    done
    
    # 4. 清理编译缓存
    echo -e "${CYAN}4. 清理编译缓存...${NC}"
    local compile_dirs=("/tmp/pear" "/root/.cache" "/home/*/.cache")
    
    for cache_pattern in "${compile_dirs[@]}"; do
        for cache_dir in $cache_pattern; do
            if [ -d "$cache_dir" ]; then
                local cache_size=$(du -sb "$cache_dir" 2>/dev/null | awk '{print $1}' || echo 0)
                if [ "$cache_size" -gt 0 ]; then
                    rm -rf "$cache_dir"/* 2>/dev/null
                    echo -e "${GREEN}✅ 清理编译缓存 $cache_dir: $(echo $cache_size | numfmt --to=iec)${NC}"
                    total_cleaned=$((total_cleaned + cache_size))
                fi
            fi
        done
    done
    
    # 5. 清理网站缓存文件
    echo -e "${CYAN}5. 清理网站缓存文件...${NC}"
    local web_cache_dirs=("/www/wwwroot/*/wp-content/cache" "/www/wwwroot/*/cache" "/www/wwwroot/*/tmp")
    
    for cache_pattern in "${web_cache_dirs[@]}"; do
        for cache_dir in $cache_pattern; do
            if [ -d "$cache_dir" ]; then
                local web_cache_size=$(du -sb "$cache_dir" 2>/dev/null | awk '{print $1}' || echo 0)
                if [ "$web_cache_size" -gt 0 ]; then
                    # 只清理缓存文件，不删除目录结构
                    find "$cache_dir" -type f -mtime +1 -delete 2>/dev/null
                    echo -e "${GREEN}✅ 清理网站缓存: $(echo $web_cache_size | numfmt --to=iec)${NC}"
                    total_cleaned=$((total_cleaned + web_cache_size))
                fi
            fi
        done
    done
    
    # 6. 清理系统字体缓存
    echo -e "${CYAN}6. 清理系统字体缓存...${NC}"
    if command -v fc-cache &> /dev/null; then
        fc-cache -f &>/dev/null
        echo -e "${GREEN}✅ 重建字体缓存${NC}"
    fi
    
    # 7. 清理man页面缓存
    echo -e "${CYAN}7. 清理man页面缓存...${NC}"
    if [ -d "/var/cache/man" ]; then
        local man_cache_size=$(du -sb /var/cache/man 2>/dev/null | awk '{print $1}' || echo 0)
        if [ "$man_cache_size" -gt 0 ]; then
            rm -rf /var/cache/man/* 2>/dev/null
            echo -e "${GREEN}✅ 清理man页面缓存: $(echo $man_cache_size | numfmt --to=iec)${NC}"
            total_cleaned=$((total_cleaned + man_cache_size))
        fi
    fi
    
    # 8. 优化文件系统
    echo -e "${CYAN}8. 优化文件系统...${NC}"
    
    # 同步文件系统
    sync
    echo -e "${GREEN}✅ 同步文件系统${NC}"
    
    # 清理页面缓存、目录项和inode缓存
    if [ -w "/proc/sys/vm/drop_caches" ]; then
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null
        echo -e "${GREEN}✅ 清理系统缓存${NC}"
    fi
    
    # 9. 清理孤立文件
    echo -e "${CYAN}9. 查找并清理孤立文件...${NC}"
    
    # 查找大于100MB的大文件
    echo -e "${YELLOW}查找大文件 (>100MB)...${NC}"
    local large_files=$(find / -type f -size +100M -not -path "/proc/*" -not -path "/sys/*" -not -path "/dev/*" -not -path "/www/server/*" 2>/dev/null | head -10)
    
    if [ -n "$large_files" ]; then
        echo -e "${YELLOW}发现以下大文件:${NC}"
        echo "$large_files" | while read file; do
            if [ -f "$file" ]; then
                echo "$(du -h "$file" 2>/dev/null) $file"
            fi
        done
        echo -e "${YELLOW}请手动检查这些文件是否需要清理${NC}"
    fi
    
    # 10. 清理空目录
    echo -e "${CYAN}10. 清理空目录...${NC}"
    local empty_dirs=$(find /tmp /var/tmp -type d -empty 2>/dev/null)
    if [ -n "$empty_dirs" ]; then
        echo "$empty_dirs" | xargs rmdir 2>/dev/null
        echo -e "${GREEN}✅ 清理空目录${NC}"
    fi
    
    echo "=================================="
    echo -e "${GREEN}✅ 深度清理完成！${NC}"
    echo -e "${GREEN}总计清理空间: $(format_size $total_cleaned)${NC}"
    
    # 显示磁盘空间使用情况
    echo -e "${CYAN}当前磁盘使用情况:${NC}"
    df -h | grep -E "^/dev/"
    
    # 显示性能统计
    cleanup_performance_stats "$start_time" "$total_cleaned" "$files_count"
    
    # 生成清理报告
    local cleanup_details="深度系统清理完成
- 清理Docker相关文件
- 清理旧内核文件
- 清理数据库日志
- 清理编译缓存
- 清理网站缓存文件
- 清理系统字体缓存
- 清理man页面缓存
- 优化文件系统
- 清理孤立文件
- 清理空目录"
    
    generate_cleanup_report "深度系统清理" "$total_cleaned" "$(($(date +%s) - start_time))" "$cleanup_details"
    
    log_message "CLEANER: Deep system cleanup completed, freed space: $(format_size $total_cleaned)"
    
    return 0
}

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

# 其他函数保持不变...
# 这里可以添加其他清理函数
