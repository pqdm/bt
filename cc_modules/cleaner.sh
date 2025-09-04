#!/bin/bash

# 宝塔面板服务器维护工具 - 恶意文件清理模块（优化版）

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

# 其他函数保持不变...
# 这里可以添加其他清理函数
