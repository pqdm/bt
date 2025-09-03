#!/bin/bash

# CC攻击防护系统 - 恶意文件清理模块

# 定位和清理恶意文件
locate_malicious_files() {
    echo -e "${BLUE}【定位恶意文件】${NC}"
    echo "=================================="
    
    # 获取可疑进程PID
    local pid="$1"
    local found_files=false
    
    if [ -z "$pid" ]; then
        echo -ne "${YELLOW}请输入要检查的进程PID: ${NC}"
        read pid
    fi
    
    # 验证PID是否存在
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo -e "${RED}❌ 进程 $pid 不存在${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}正在检查进程 $pid 的相关文件...${NC}"
    
    # 显示进程详细信息
    echo -e "${CYAN}进程信息:${NC}"
    ps -p $pid -o pid,ppid,user,cmd,etime
    
    # 获取进程可执行文件路径
    local exe_path=$(readlink -f /proc/$pid/exe 2>/dev/null)
    if [ -n "$exe_path" ] && [ -f "$exe_path" ]; then
        echo -e "${CYAN}可执行文件: $exe_path${NC}"
        found_files=true
        
        # 检查文件权限和所有者
        echo -e "${CYAN}文件权限:${NC}"
        ls -la "$exe_path"
        
        # 检查文件类型
        echo -e "${CYAN}文件类型:${NC}"
        file "$exe_path"
        
        # 检查文件创建/修改时间
        echo -e "${CYAN}文件时间:${NC}"
        stat "$exe_path" | grep -E "Modify|Change"
        
        # 检查文件是否隐藏在系统目录中
        if echo "$exe_path" | grep -q -E "/(tmp|dev|var/tmp|proc|sys|run|lib|usr/lib|bin|sbin|usr/bin|usr/sbin)/"; then
            echo -e "${RED}⚠️ 警告: 可执行文件位于系统目录，可能是恶意程序${NC}"
        fi
        
        # 提示是否删除文件
        echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
        read answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            # 先终止进程
            kill -9 $pid 2>/dev/null
            
            # 删除文件
            if rm -f "$exe_path" 2>/dev/null; then
                echo -e "${GREEN}✅ 文件已删除: $exe_path${NC}"
                log_message "CLEANER: Malicious file deleted: $exe_path"
            else
                echo -e "${RED}❌ 无法删除文件，尝试使用强制方式${NC}"
                
                # 尝试更改权限后删除
                chmod 777 "$exe_path" 2>/dev/null
                if rm -f "$exe_path" 2>/dev/null; then
                    echo -e "${GREEN}✅ 文件已删除: $exe_path${NC}"
                    log_message "CLEANER: Malicious file deleted: $exe_path"
                else
                    echo -e "${RED}❌ 无法删除文件: $exe_path${NC}"
                    log_message "CLEANER: Failed to delete malicious file: $exe_path"
                fi
            fi
        fi
    else
        echo -e "${YELLOW}⚠️ 无法获取可执行文件路径${NC}"
    fi
    
    # 检查进程打开的文件
    echo -e "${CYAN}进程打开的文件:${NC}"
    if command -v lsof &> /dev/null; then
        local open_files=$(lsof -p $pid 2>/dev/null | grep -v -E "/(proc|sys|dev)/")
        if [ -n "$open_files" ]; then
            echo "$open_files"
            found_files=true
            
            # 提示是否查看详细信息
            echo -ne "${YELLOW}是否查看可疑文件详细信息? (y/n): ${NC}"
            read answer
            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                local file_paths=$(echo "$open_files" | awk '{print $9}' | grep -v -E "^/dev/|^/proc/|^pipe:|^socket:")
                for file in $file_paths; do
                    if [ -f "$file" ]; then
                        echo -e "${CYAN}文件: $file${NC}"
                        ls -la "$file"
                        file "$file"
                        
                        # 提示是否删除文件
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
                    fi
                done
            fi
        else
            echo -e "${YELLOW}未找到打开的文件${NC}"
        fi
    else
        echo -e "${YELLOW}lsof命令不可用，无法列出打开的文件${NC}"
    fi
    
    # 检查进程的网络连接
    echo -e "${CYAN}进程的网络连接:${NC}"
    local connections=$(netstat -anp 2>/dev/null | grep $pid)
    if [ -n "$connections" ]; then
        echo "$connections"
        
        # 提取远程IP地址
        local remote_ips=$(echo "$connections" | grep -v "127.0.0.1" | awk '{print $5}' | cut -d: -f1 | sort | uniq)
        if [ -n "$remote_ips" ]; then
            echo -e "${RED}⚠️ 检测到可疑远程连接:${NC}"
            echo "$remote_ips"
            
            # 提示是否将IP加入黑名单
            for ip in $remote_ips; do
                if [ -n "$ip" ] && [ "$ip" != "*" ] && [ "$ip" != "0.0.0.0" ]; then
                    echo -ne "${YELLOW}是否将IP $ip 加入黑名单? (y/n): ${NC}"
                    read answer
                    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                        if type add_to_blacklist &>/dev/null; then
                            add_to_blacklist "$ip" "恶意程序连接" 86400
                        else
                            echo -e "${RED}❌ 黑名单功能不可用${NC}"
                        fi
                    fi
                fi
            done
        fi
    else
        echo -e "${YELLOW}未找到网络连接${NC}"
    fi
    
    # 检查启动项
    check_startup_entries
    
    # 检查定时任务
    check_cron_jobs
    
    # 检查Web目录中的可疑文件
    check_web_malware
    
    if [ "$found_files" = false ]; then
        echo -e "${YELLOW}未找到与进程 $pid 相关的可疑文件${NC}"
    fi
    
    return 0
}

# 扫描系统中的恶意文件
scan_malicious_files() {
    echo -e "${BLUE}【扫描系统恶意文件】${NC}"
    echo "=================================="
    
    echo -e "${YELLOW}正在扫描系统中的恶意文件...${NC}"
    
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
                
                # 检查每个可执行文件
                echo "$exec_files" | while read file; do
                    echo -e "${CYAN}检查文件: $file${NC}"
                    ls -la "$file"
                    file "$file"
                    
                    # 提示是否删除文件
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
                done
            else
                echo -e "${GREEN}✅ 未发现可执行文件${NC}"
            fi
            
            # 查找隐藏文件
            local hidden_files=$(find "$dir" -name ".*" -type f 2>/dev/null)
            if [ -n "$hidden_files" ]; then
                echo -e "${YELLOW}发现隐藏文件:${NC}"
                echo "$hidden_files"
                
                # 检查每个隐藏文件
                echo "$hidden_files" | while read file; do
                    echo -e "${CYAN}检查文件: $file${NC}"
                    ls -la "$file"
                    file "$file"
                    
                    # 提示是否删除文件
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
        local found_files=$(find / -name "*$pattern*" -type f 2>/dev/null | grep -v "/proc/" | grep -v "/sys/")
        
        if [ -n "$found_files" ]; then
            echo -e "${YELLOW}发现可疑文件:${NC}"
            echo "$found_files"
            
            # 检查每个可疑文件
            echo "$found_files" | while read file; do
                echo -e "${CYAN}检查文件: $file${NC}"
                ls -la "$file"
                file "$file"
                
                # 提示是否删除文件
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
        echo "$large_files" | while read file; do
            echo -e "${CYAN}文件: $file ($(du -h "$file" | awk '{print $1}'))${NC}"
            ls -la "$file"
            file "$file"
            
            # 提示是否删除文件
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
        done
    else
        echo -e "${GREEN}✅ 未发现异常大小的文件${NC}"
    fi
    
    return 0
}

# 检查启动项
check_startup_entries() {
    echo -e "${BLUE}【检查启动项】${NC}"
    echo "=================================="
    
    # 检查系统启动服务
    if command -v systemctl &> /dev/null; then
        echo -e "${CYAN}检查系统服务...${NC}"
        local services=$(systemctl list-unit-files --type=service | grep enabled)
        echo "$services"
        
        # 提示是否检查可疑服务
        echo -ne "${YELLOW}是否检查可疑服务详细信息? (y/n): ${NC}"
        read answer
        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
            echo -ne "${YELLOW}请输入要检查的服务名称: ${NC}"
            read service_name
            
            if [ -n "$service_name" ]; then
                systemctl status "$service_name"
                
                # 获取服务文件路径
                local service_path=$(systemctl show -p FragmentPath "$service_name" | cut -d= -f2)
                if [ -n "$service_path" ]; then
                    echo -e "${CYAN}服务文件: $service_path${NC}"
                    cat "$service_path"
                    
                    # 提示是否禁用服务
                    echo -ne "${YELLOW}是否禁用此服务? (y/n): ${NC}"
                    read answer
                    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                        systemctl disable "$service_name"
                        systemctl stop "$service_name"
                        echo -e "${GREEN}✅ 服务已禁用: $service_name${NC}"
                        log_message "CLEANER: Service disabled: $service_name"
                    fi
                fi
            fi
        fi
    fi
    
    # 检查rc.local
    if [ -f "/etc/rc.local" ]; then
        echo -e "${CYAN}检查 /etc/rc.local...${NC}"
        cat "/etc/rc.local"
    fi
    
    # 检查init.d脚本
    echo -e "${CYAN}检查 /etc/init.d/ 目录...${NC}"
    ls -la /etc/init.d/
    
    # 检查用户级启动项
    echo -e "${CYAN}检查用户级启动项...${NC}"
    for user_home in /home/*; do
        if [ -d "$user_home/.config/autostart" ]; then
            echo -e "${CYAN}检查 $user_home/.config/autostart...${NC}"
            ls -la "$user_home/.config/autostart"
        fi
    done
    
    return 0
}

# 检查定时任务
check_cron_jobs() {
    echo -e "${BLUE}【检查定时任务】${NC}"
    echo "=================================="
    
    # 检查系统定时任务
    echo -e "${CYAN}检查系统定时任务...${NC}"
    for cron_file in /etc/cron.d/* /etc/crontab; do
        if [ -f "$cron_file" ]; then
            echo -e "${CYAN}文件: $cron_file${NC}"
            cat "$cron_file"
            echo ""
        fi
    done
    
    # 检查用户定时任务
    echo -e "${CYAN}检查用户定时任务...${NC}"
    for user in $(cut -f1 -d: /etc/passwd); do
        crontab -l -u "$user" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${CYAN}用户 $user 的定时任务:${NC}"
            crontab -l -u "$user"
            echo ""
        fi
    done
    
    return 0
}

# 检查Web目录中的恶意文件
check_web_malware() {
    echo -e "${BLUE}【检查Web目录恶意文件】${NC}"
    echo "=================================="
    
    # 定义Web目录
    local web_dirs=(
        "/www/wwwroot"
        "/var/www/html"
        "/usr/share/nginx/html"
        "/var/www"
    )
    
    # 定义恶意文件特征
    local web_malware_patterns=(
        "eval(base64_decode"
        "eval(gzinflate"
        "eval(str_rot13"
        "eval(gzuncompress"
        "eval(\$_POST"
        "eval(\$_GET"
        "eval(\$_REQUEST"
        "eval(\$_COOKIE"
        "system("
        "shell_exec("
        "passthru("
        "exec("
        "base64_decode("
        "file_put_contents("
        "assert("
    )
    
    # 检查每个Web目录
    for dir in "${web_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "${CYAN}检查Web目录: $dir${NC}"
            
            # 查找PHP文件
            local php_files=$(find "$dir" -name "*.php" -type f 2>/dev/null)
            if [ -n "$php_files" ]; then
                echo -e "${CYAN}发现 $(echo "$php_files" | wc -l) 个PHP文件${NC}"
                
                # 检查每个恶意文件特征
                for pattern in "${web_malware_patterns[@]}"; do
                    echo -e "${CYAN}搜索: $pattern${NC}"
                    local suspicious_files=$(grep -l "$pattern" $php_files 2>/dev/null)
                    
                    if [ -n "$suspicious_files" ]; then
                        echo -e "${YELLOW}发现可疑文件:${NC}"
                        echo "$suspicious_files"
                        
                        # 提示是否查看详细信息
                        echo -ne "${YELLOW}是否查看可疑文件详细信息? (y/n): ${NC}"
                        read answer
                        if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                            echo "$suspicious_files" | while read file; do
                                echo -e "${CYAN}文件: $file${NC}"
                                ls -la "$file"
                                echo -e "${CYAN}可疑代码:${NC}"
                                grep -n "$pattern" "$file"
                                
                                # 提示是否删除文件
                                echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
                                read answer
                                if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                                    if rm -f "$file" 2>/dev/null; then
                                        echo -e "${GREEN}✅ 文件已删除: $file${NC}"
                                        log_message "CLEANER: Web malware deleted: $file"
                                    else
                                        echo -e "${RED}❌ 无法删除文件: $file${NC}"
                                        log_message "CLEANER: Failed to delete web malware: $file"
                                    fi
                                fi
                            done
                        fi
                    else
                        echo -e "${GREEN}✅ 未发现可疑文件: $pattern${NC}"
                    fi
                done
                
                # 查找最近修改的PHP文件
                echo -e "${CYAN}检查最近24小时内修改的PHP文件...${NC}"
                local recent_files=$(find "$dir" -name "*.php" -type f -mtime -1 2>/dev/null)
                
                if [ -n "$recent_files" ]; then
                    echo -e "${YELLOW}最近修改的文件:${NC}"
                    echo "$recent_files"
                    
                    # 提示是否查看详细信息
                    echo -ne "${YELLOW}是否查看最近修改文件详细信息? (y/n): ${NC}"
                    read answer
                    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                        echo "$recent_files" | while read file; do
                            echo -e "${CYAN}文件: $file${NC}"
                            ls -la "$file"
                            echo -e "${CYAN}文件内容预览:${NC}"
                            head -20 "$file"
                            
                            # 提示是否删除文件
                            echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
                            read answer
                            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                                if rm -f "$file" 2>/dev/null; then
                                    echo -e "${GREEN}✅ 文件已删除: $file${NC}"
                                    log_message "CLEANER: Recent suspicious file deleted: $file"
                                else
                                    echo -e "${RED}❌ 无法删除文件: $file${NC}"
                                    log_message "CLEANER: Failed to delete recent suspicious file: $file"
                                fi
                            fi
                        done
                    fi
                else
                    echo -e "${GREEN}✅ 未发现最近修改的PHP文件${NC}"
                fi
            else
                echo -e "${GREEN}✅ 未发现PHP文件${NC}"
            fi
            
            # 查找隐藏文件和目录
            echo -e "${CYAN}检查隐藏文件和目录...${NC}"
            local hidden_items=$(find "$dir" -name ".*" ! -name "." ! -name ".." 2>/dev/null)
            
            if [ -n "$hidden_items" ]; then
                echo -e "${YELLOW}发现隐藏文件和目录:${NC}"
                echo "$hidden_items"
                
                # 提示是否查看详细信息
                echo -ne "${YELLOW}是否查看隐藏文件详细信息? (y/n): ${NC}"
                read answer
                if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                    echo "$hidden_items" | while read item; do
                        if [ -f "$item" ]; then
                            echo -e "${CYAN}文件: $item${NC}"
                            ls -la "$item"
                            file "$item"
                            
                            # 提示是否删除文件
                            echo -ne "${YELLOW}是否删除此文件? (y/n): ${NC}"
                            read answer
                            if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
                                if rm -f "$item" 2>/dev/null; then
                                    echo -e "${GREEN}✅ 文件已删除: $item${NC}"
                                    log_message "CLEANER: Hidden file deleted: $item"
                                else
                                    echo -e "${RED}❌ 无法删除文件: $item${NC}"
                                    log_message "CLEANER: Failed to delete hidden file: $item"
                                fi
                            fi
                        fi
                    done
                fi
            else
                echo -e "${GREEN}✅ 未发现隐藏文件和目录${NC}"
            fi
        fi
    done
    
    return 0
}
