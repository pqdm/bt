#!/bin/bash

# CC攻击防护系统 - IP黑名单管理模块

# 黑名单文件
BLACKLIST_FILE="/root/cc_blacklist.txt"
WHITELIST_FILE="/root/cc_whitelist.txt"

# 初始化黑名单
init_blacklist() {
    echo -e "${BLUE}【初始化黑名单】${NC}"
    echo "=================================="
    
    # 创建黑名单文件
    if [ ! -f "$BLACKLIST_FILE" ]; then
        touch "$BLACKLIST_FILE"
        echo -e "${GREEN}✅ 创建黑名单文件: $BLACKLIST_FILE${NC}"
    fi
    
    # 创建白名单文件
    if [ ! -f "$WHITELIST_FILE" ]; then
        touch "$WHITELIST_FILE"
        echo "127.0.0.1" > "$WHITELIST_FILE"
        echo "::1" >> "$WHITELIST_FILE"
        echo -e "${GREEN}✅ 创建白名单文件: $WHITELIST_FILE${NC}"
    fi
    
    log_message "BLACKLIST: Blacklist and whitelist initialized"
    
    return 0
}

# 添加IP到黑名单
add_to_blacklist() {
    local ip="$1"
    local reason="$2"
    local duration="$3"
    
    # 验证IP格式
    if ! is_valid_ip "$ip"; then
        echo -e "${RED}❌ 无效的IP地址: $ip${NC}"
        return 1
    fi
    
    # 检查是否在白名单中
    if is_in_whitelist "$ip"; then
        echo -e "${YELLOW}⚠️ IP $ip 在白名单中，无法加入黑名单${NC}"
        return 1
    fi
    
    # 检查是否已在黑名单中
    if is_in_blacklist "$ip"; then
        echo -e "${YELLOW}⚠️ IP $ip 已在黑名单中${NC}"
        return 0
    fi
    
    # 添加到黑名单
    local timestamp=$(date +%s)
    local expiry=0
    
    if [ -n "$duration" ] && [ "$duration" -gt 0 ]; then
        expiry=$((timestamp + duration))
    fi
    
    echo "$ip|$timestamp|$expiry|$reason" >> "$BLACKLIST_FILE"
    
    # 添加防火墙规则
    if command -v iptables &> /dev/null; then
        iptables -A INPUT -s "$ip" -j DROP
        echo -e "${GREEN}✅ IP $ip 已添加到黑名单和防火墙规则${NC}"
    else
        echo -e "${GREEN}✅ IP $ip 已添加到黑名单${NC}"
    fi
    
    log_message "BLACKLIST: Added IP $ip to blacklist: $reason"
    
    return 0
}

# 从黑名单中移除IP
remove_from_blacklist() {
    local ip="$1"
    
    # 验证IP格式
    if ! is_valid_ip "$ip"; then
        echo -e "${RED}❌ 无效的IP地址: $ip${NC}"
        return 1
    fi
    
    # 检查是否在黑名单中
    if ! is_in_blacklist "$ip"; then
        echo -e "${YELLOW}⚠️ IP $ip 不在黑名单中${NC}"
        return 0
    fi
    
    # 从黑名单文件中移除
    grep -v "^$ip|" "$BLACKLIST_FILE" > "${BLACKLIST_FILE}.tmp"
    mv "${BLACKLIST_FILE}.tmp" "$BLACKLIST_FILE"
    
    # 移除防火墙规则
    if command -v iptables &> /dev/null; then
        iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
        echo -e "${GREEN}✅ IP $ip 已从黑名单和防火墙规则中移除${NC}"
    else
        echo -e "${GREEN}✅ IP $ip 已从黑名单中移除${NC}"
    fi
    
    log_message "BLACKLIST: Removed IP $ip from blacklist"
    
    return 0
}

# 添加IP到白名单
add_to_whitelist() {
    local ip="$1"
    
    # 验证IP格式
    if ! is_valid_ip "$ip"; then
        echo -e "${RED}❌ 无效的IP地址: $ip${NC}"
        return 1
    fi
    
    # 检查是否已在白名单中
    if is_in_whitelist "$ip"; then
        echo -e "${YELLOW}⚠️ IP $ip 已在白名单中${NC}"
        return 0
    fi
    
    # 如果在黑名单中，先移除
    if is_in_blacklist "$ip"; then
        remove_from_blacklist "$ip"
    fi
    
    # 添加到白名单
    echo "$ip" >> "$WHITELIST_FILE"
    
    echo -e "${GREEN}✅ IP $ip 已添加到白名单${NC}"
    log_message "BLACKLIST: Added IP $ip to whitelist"
    
    return 0
}

# 从白名单中移除IP
remove_from_whitelist() {
    local ip="$1"
    
    # 验证IP格式
    if ! is_valid_ip "$ip"; then
        echo -e "${RED}❌ 无效的IP地址: $ip${NC}"
        return 1
    fi
    
    # 检查是否在白名单中
    if ! is_in_whitelist "$ip"; then
        echo -e "${YELLOW}⚠️ IP $ip 不在白名单中${NC}"
        return 0
    fi
    
    # 从白名单文件中移除
    grep -v "^$ip$" "$WHITELIST_FILE" > "${WHITELIST_FILE}.tmp"
    mv "${WHITELIST_FILE}.tmp" "$WHITELIST_FILE"
    
    echo -e "${GREEN}✅ IP $ip 已从白名单中移除${NC}"
    log_message "BLACKLIST: Removed IP $ip from whitelist"
    
    return 0
}

# 检查IP是否在黑名单中
is_in_blacklist() {
    local ip="$1"
    
    if [ ! -f "$BLACKLIST_FILE" ]; then
        return 1
    fi
    
    if grep -q "^$ip|" "$BLACKLIST_FILE"; then
        return 0
    else
        return 1
    fi
}

# 检查IP是否在白名单中
is_in_whitelist() {
    local ip="$1"
    
    if [ ! -f "$WHITELIST_FILE" ]; then
        return 1
    fi
    
    if grep -q "^$ip$" "$WHITELIST_FILE"; then
        return 0
    else
        return 1
    fi
}

# 清理过期的黑名单IP
cleanup_blacklist() {
    echo -e "${BLUE}【清理过期黑名单】${NC}"
    echo "=================================="
    
    if [ ! -f "$BLACKLIST_FILE" ]; then
        echo -e "${YELLOW}⚠️ 黑名单文件不存在${NC}"
        return 1
    fi
    
    local current_time=$(date +%s)
    local count=0
    
    # 创建临时文件
    local temp_file="${BLACKLIST_FILE}.tmp"
    > "$temp_file"
    
    # 处理每一行
    while IFS="|" read -r ip timestamp expiry reason; do
        # 如果过期时间大于0且当前时间超过过期时间，则移除
        if [ "$expiry" -gt 0 ] && [ "$current_time" -gt "$expiry" ]; then
            # 从防火墙规则中移除
            if command -v iptables &> /dev/null; then
                iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
            fi
            count=$((count + 1))
        else
            # 保留未过期的记录
            echo "$ip|$timestamp|$expiry|$reason" >> "$temp_file"
        fi
    done < "$BLACKLIST_FILE"
    
    # 替换原文件
    mv "$temp_file" "$BLACKLIST_FILE"
    
    echo -e "${GREEN}✅ 已清理 $count 个过期的黑名单IP${NC}"
    log_message "BLACKLIST: Cleaned up $count expired blacklist entries"
    
    return 0
}

# 显示黑名单
show_blacklist() {
    echo -e "${BLUE}【当前黑名单】${NC}"
    echo "=================================="
    
    if [ ! -f "$BLACKLIST_FILE" ] || [ ! -s "$BLACKLIST_FILE" ]; then
        echo -e "${YELLOW}黑名单为空${NC}"
        return 0
    fi
    
    echo -e "${CYAN}IP地址            添加时间                过期时间                原因${NC}"
    echo "--------------------------------------------------------------------------------"
    
    while IFS="|" read -r ip timestamp expiry reason; do
        local add_time=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S")
        local exp_time="永久"
        
        if [ "$expiry" -gt 0 ]; then
            exp_time=$(date -d "@$expiry" "+%Y-%m-%d %H:%M:%S")
        fi
        
        printf "%-18s %-24s %-24s %s\n" "$ip" "$add_time" "$exp_time" "$reason"
    done < "$BLACKLIST_FILE"
    
    return 0
}

# 显示白名单
show_whitelist() {
    echo -e "${BLUE}【当前白名单】${NC}"
    echo "=================================="
    
    if [ ! -f "$WHITELIST_FILE" ] || [ ! -s "$WHITELIST_FILE" ]; then
        echo -e "${YELLOW}白名单为空${NC}"
        return 0
    fi
    
    echo -e "${CYAN}IP地址${NC}"
    echo "----------------"
    
    while read -r ip; do
        echo "$ip"
    done < "$WHITELIST_FILE"
    
    return 0
}

# 验证IP地址格式
is_valid_ip() {
    local ip="$1"
    
    # IPv4格式验证
    if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -r -a octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ]; then
                return 1
            fi
        done
        return 0
    # 简单的IPv6格式验证
    elif [[ "$ip" =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]]; then
        return 0
    else
        return 1
    fi
}
