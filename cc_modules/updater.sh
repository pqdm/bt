#!/bin/bash

# 宝塔面板服务器维护工具 - 更新模块

# 版本信息
GITHUB_REPO="pqdm/bt"
GITHUB_RAW_URL="https://raw.githubusercontent.com/pqdm/bt/main"
GITHUB_API_URL="https://api.github.com/repos/pqdm/bt"

# 本地版本定义（当无法从远程获取时使用）
LOCAL_LATEST_VERSION="2.1.2"

# 检查更新
check_update() {
    echo -e "${BLUE}【检查更新】${NC}"
    echo "=================================="
    
    echo -e "${YELLOW}当前版本: v${VERSION}${NC}"
    echo -e "${YELLOW}正在检查最新版本...${NC}"
    
    # 检查网络连接
    echo -e "${YELLOW}检查网络连接...${NC}"
    local ping_result=0
    if command -v ping &> /dev/null; then
        if ping -c 1 -W 3 github.com &> /dev/null || ping -c 1 -W 3 raw.githubusercontent.com &> /dev/null; then
            echo -e "${GREEN}✅ 网络连接正常${NC}"
        else
            echo -e "${YELLOW}⚠️ 无法ping通GitHub，但仍将尝试连接${NC}"
            ping_result=1
        fi
    else
        echo -e "${YELLOW}⚠️ 系统中没有ping命令，跳过网络检查${NC}"
    fi
    
    # 获取最新版本信息
    local latest_version=""
    
    # 直接从仓库的配置文件获取版本信息
    echo -e "${YELLOW}正在获取最新版本信息...${NC}"
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 下载远程配置文件
    echo -e "${CYAN}尝试从配置文件获取版本: ${GITHUB_RAW_URL}/cc_config.conf${NC}"
    if command -v curl &> /dev/null; then
        if curl -s -m 10 "${GITHUB_RAW_URL}/cc_config.conf" -o "$temp_file"; then
            # 从配置文件中提取版本号
            if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
                latest_version=$(grep "VERSION=" "$temp_file" | cut -d'"' -f2)
                echo -e "${CYAN}从配置文件获取到版本: ${latest_version}${NC}"
            else
                echo -e "${YELLOW}配置文件下载失败或为空${NC}"
            fi
        else
            echo -e "${YELLOW}无法下载配置文件${NC}"
        fi
    elif command -v wget &> /dev/null; then
        if wget -q -T 10 "${GITHUB_RAW_URL}/cc_config.conf" -O "$temp_file"; then
            # 从配置文件中提取版本号
            if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
                latest_version=$(grep "VERSION=" "$temp_file" | cut -d'"' -f2)
                echo -e "${CYAN}从配置文件获取到版本: ${latest_version}${NC}"
            else
                echo -e "${YELLOW}配置文件下载失败或为空${NC}"
            fi
        else
            echo -e "${YELLOW}无法下载配置文件${NC}"
        fi
    else
        echo -e "${RED}错误: 未找到curl或wget命令${NC}"
        rm -f "$temp_file" 2>/dev/null
        return 1
    fi
    
    # 清理临时文件
    rm -f "$temp_file" 2>/dev/null
    
    # 如果仍然无法获取版本信息，尝试使用备用方法
    if [ -z "$latest_version" ]; then
        echo -e "${YELLOW}尝试备用方法获取版本信息...${NC}"
        echo -e "${CYAN}尝试从VERSION文件获取: ${GITHUB_RAW_URL}/VERSION${NC}"
        
        # 使用简单的HTTP请求
        if command -v curl &> /dev/null; then
            latest_version=$(curl -s -m 10 "${GITHUB_RAW_URL}/VERSION" 2>/dev/null | tr -d '\n\r')
            echo -e "${CYAN}从VERSION文件获取到: '${latest_version}'${NC}"
        elif command -v wget &> /dev/null; then
            latest_version=$(wget -q -T 10 -O- "${GITHUB_RAW_URL}/VERSION" 2>/dev/null | tr -d '\n\r')
            echo -e "${CYAN}从VERSION文件获取到: '${latest_version}'${NC}"
        fi
    fi
    
    if [ -z "$latest_version" ]; then
        echo -e "${YELLOW}⚠️ 无法从远程获取版本信息，使用本地版本信息${NC}"
        latest_version="$LOCAL_LATEST_VERSION"
        echo -e "${CYAN}使用本地回退版本: ${latest_version}${NC}"
        
        # 如果仍然为空，则使用当前版本
        if [ -z "$latest_version" ]; then
            echo -e "${RED}错误: 无法获取版本信息${NC}"
            return 1
        fi
    fi
    
    echo -e "${YELLOW}最新版本: v${latest_version}${NC}"
    
    # 比较版本号
    if [ "$VERSION" = "$latest_version" ]; then
        echo -e "${GREEN}✅ 您的版本已是最新 (v${VERSION})${NC}"
        echo ""
        echo -e "${CYAN}当前功能特性:${NC}"
        echo -e "  • 智能异常IP检测和自动黑名单"
        echo -e "  • 系统垃圾清理和深度清理"
        echo -e "  • 实时监控和安全防护"
        echo -e "  • 恶意文件扫描和清理"
        echo -e "  • 性能优化和系统加固"
        echo ""
        
        # 检查是否有本地更新
        check_local_updates
        
        return 0
    else
        echo -e "${YELLOW}发现新版本: v${latest_version}${NC}"
        echo -e "${CYAN}建议更新以获取最新功能和安全修复${NC}"
        echo ""
        echo -e "${YELLOW}是否要更新? (y/n): ${NC}"
        read update_choice
        
        if [[ "$update_choice" == "y" || "$update_choice" == "Y" ]]; then
            update_tool "$latest_version"
        else
            echo -e "${YELLOW}已取消更新${NC}"
            echo -e "${CYAN}提示: 建议定期检查更新以获取最新的安全功能${NC}"
        fi
    fi
    
    return 0
}

# 检查本地更新
check_local_updates() {
    echo -e "${BLUE}【本地更新检查】${NC}"
    echo "=================================="
    
    # 检查模块完整性
    local missing_modules=()
    local modules=("analyzer.sh" "blacklist.sh" "cleaner.sh" "firewall.sh" "monitor.sh" "optimizer.sh" "waf.sh" "updater.sh" "garbage_cleaner.sh" "cleanup_analyzer.sh")
    
    for module in "${modules[@]}"; do
        if [ ! -f "/root/cc_modules/$module" ]; then
            missing_modules+=($module)
        fi
    done
    
    if [ ${#missing_modules[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️ 发现缺失的模块:${NC}"
        for module in "${missing_modules[@]}"; do
            echo -e "  • $module"
        done
        echo ""
        echo -e "${YELLOW}是否要修复缺失的模块? (y/n): ${NC}"
        read fix_choice
        
        if [[ "$fix_choice" == "y" || "$fix_choice" == "Y" ]]; then
            echo -e "${YELLOW}正在修复缺失的模块...${NC}"
            # 这里可以添加从备份或重新生成模块的逻辑
            echo -e "${YELLOW}提示: 请重新运行安装脚本以修复缺失的模块${NC}"
        fi
    else
        echo -e "${GREEN}✅ 所有模块完整${NC}"
        
        # 检查配置文件
        if [ -f "/root/cc_config.conf" ]; then
            echo -e "${GREEN}✅ 配置文件正常${NC}"
        else
            echo -e "${YELLOW}⚠️ 配置文件缺失${NC}"
        fi
        
        # 检查日志文件
        local log_file="/var/log/cc_defense.log"
        if [ -f "$log_file" ]; then
            local log_size=$(du -h "$log_file" | cut -f1)
            echo -e "${GREEN}✅ 日志文件正常 (大小: $log_size)${NC}"
            
            # 如果日志文件太大，提示清理
            local log_size_mb=$(du -m "$log_file" | cut -f1)
            if [ $log_size_mb -gt 100 ]; then
                echo -e "${YELLOW}⚠️ 日志文件较大 ($log_size)，建议定期清理${NC}"
            fi
        else
            echo -e "${CYAN}ℹ️ 日志文件将在首次运行时创建${NC}"
        fi
    fi
}

# 更新工具
update_tool() {
    local new_version=$1
    
    echo -e "${BLUE}【更新工具】${NC}"
    echo "=================================="
    echo -e "${YELLOW}正在更新到版本 v${new_version}...${NC}"
    
    # 创建备份目录
    local backup_dir="/root/cc_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$backup_dir"
    
    # 备份当前文件
    echo -e "${YELLOW}备份当前文件...${NC}"
    cp -f /usr/local/bin/ding "$backup_dir/" 2>/dev/null
    cp -f /root/cc_config.conf "$backup_dir/" 2>/dev/null
    cp -rf /root/cc_modules "$backup_dir/" 2>/dev/null
    
    # 下载新版本
    echo -e "${YELLOW}下载新版本文件...${NC}"
    
    # 下载主脚本
    if ! download_file "${GITHUB_RAW_URL}/ding.sh" "/usr/local/bin/ding" "主脚本"; then
        echo -e "${RED}更新失败: 无法下载主脚本${NC}"
        restore_backup "$backup_dir"
        return 1
    fi
    chmod +x /usr/local/bin/ding
    
    # 创建软链接
    ln -sf /usr/local/bin/ding /root/cc_defense.sh
    
    # 下载配置文件（如果不存在）
    if [ ! -f "/root/cc_config.conf" ]; then
        if ! download_file "${GITHUB_RAW_URL}/cc_config.conf" "/root/cc_config.conf" "配置文件"; then
            echo -e "${RED}更新失败: 无法下载配置文件${NC}"
            restore_backup "$backup_dir"
            return 1
        fi
    else
        # 更新配置文件中的版本号
        sed -i "s/VERSION=\"[0-9.]*\"/VERSION=\"$new_version\"/" /root/cc_config.conf
    fi
    
    # 创建模块目录
    mkdir -p /root/cc_modules
    
    # 下载模块文件
    local modules=("analyzer.sh" "blacklist.sh" "cleaner.sh" "firewall.sh" "monitor.sh" "optimizer.sh" "waf.sh" "updater.sh")
    
    for module in "${modules[@]}"; do
        if ! download_file "${GITHUB_RAW_URL}/cc_modules/${module}" "/root/cc_modules/${module}" "模块 ${module}"; then
            echo -e "${RED}更新失败: 无法下载模块 ${module}${NC}"
            restore_backup "$backup_dir"
            return 1
        fi
        chmod +x "/root/cc_modules/${module}"
    done
    
    echo -e "${GREEN}✅ 更新完成! 当前版本: v${new_version}${NC}"
    echo -e "${YELLOW}备份文件已保存在: ${backup_dir}${NC}"
    
    # 提示重启工具
    echo -e "${YELLOW}请重新启动工具以应用更新${NC}"
    
    return 0
}

# 恢复备份
restore_backup() {
    local backup_dir=$1
    
    echo -e "${YELLOW}恢复备份...${NC}"
    
    cp -f "$backup_dir/ding" /usr/local/bin/ding 2>/dev/null
    cp -f "$backup_dir/cc_config.conf" /root/cc_config.conf 2>/dev/null
    cp -rf "$backup_dir/cc_modules" /root/ 2>/dev/null
    
    echo -e "${YELLOW}备份已恢复${NC}"
    
    return 0
}

# 下载文件
download_file() {
    local url="$1"
    local dest="$2"
    local desc="$3"
    
    echo -e "${YELLOW}下载${desc}...${NC}"
    
    # 创建目标目录（如果不存在）
    mkdir -p "$(dirname "$dest")"
    
    # 下载文件
    if command -v curl &> /dev/null; then
        if ! curl -s -m 30 --retry 3 --retry-delay 2 "$url" -o "$dest"; then
            echo -e "${RED}错误: 使用curl下载${desc}失败${NC}"
            return 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -q -T 30 -t 3 "$url" -O "$dest"; then
            echo -e "${RED}错误: 使用wget下载${desc}失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}错误: 未找到curl或wget命令${NC}"
        return 1
    fi
    
    # 检查文件是否成功下载
    if [ ! -s "$dest" ]; then
        echo -e "${RED}错误: 下载的${desc}为空${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ ${desc}下载成功${NC}"
    return 0
}
