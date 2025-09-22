#!/bin/bash

# 宝塔面板服务器维护工具 - 实时监控模块

# ------------------------------
# CPU 统计辅助函数
# ------------------------------

# 使用 mpstat（若可用）做一次采样，输出汇总和每核
cpu_stats_with_mpstat() {
	local interval="$1"
	local count="$2"

	# 汇总平均（%usr %sys %iowait %steal %idle）
	local avg_line
	avg_line=$(mpstat ${interval} ${count} | awk '/Average:/ && $2 ~ /^all$/ {printf "%s %s %s %s %s", $3, $5, $6, $8, $12}')
	# 每核（单次 1 秒即可）
	local per_core
	per_core=$(mpstat -P ALL 1 1 | awk 'NR>4 && $3 != "CPU" {printf "%s %s %s %s %s %s\n", $3, $4, $6, $7, $9, $13}')

	echo "${avg_line}"   # 输出: usr sys iowait steal idle
	echo "--PERCORE--"
	echo "${per_core}"   # 每行: CPU %usr %sys %iowait %steal %idle
}

# 兼容路径：用 /proc/stat 采样两次，计算百分比（一次采样为总量差值的占比）
cpu_stats_with_proc() {
	local sleep_interval="$1"

	# 第一次采样
	local snap1
	snap1=$(cat /proc/stat | grep -E '^cpu')
	sleep ${sleep_interval}
	# 第二次采样
	local snap2
	snap2=$(cat /proc/stat | grep -E '^cpu')

	# 汇总
	local agg1 agg2
	agg1=$(echo "${snap1}" | awk '$1=="cpu" {for(i=2;i<=11;i++) s+=$i; printf "%s %s %s %s %s %s %s %s\n", $2,$3,$4,$5,$6,$7,$8,$9}')
	agg2=$(echo "${snap2}" | awk '$1=="cpu" {for(i=2;i<=11;i++) s+=$i; printf "%s %s %s %s %s %s %s %s\n", $2,$3,$4,$5,$6,$7,$8,$9}')

	# 计算汇总占比
	# 字段: user nice system idle iowait irq softirq steal
	read u1 n1 s1 i1 w1 h1 so1 st1 <<< "${agg1}"
	read u2 n2 s2 i2 w2 h2 so2 st2 <<< "${agg2}"
	local du=$((u2-u1))
	local dn=$((n2-n1))
	local ds=$((s2-s1))
	local di=$((i2-i1))
	local dw=$((w2-w1))
	local dh=$((h2-h1))
	local dso=$((so2-so1))
	local dst=$((st2-st1))
	local total=$((du+dn+ds+di+dw+dh+dso+dst))
	[ ${total} -le 0 ] && total=1
	local p_usr=$(awk -v v=$du -v t=$total 'BEGIN{printf "%.1f", (v*100.0)/t}')
	local p_sys=$(awk -v v=$ds -v t=$total 'BEGIN{printf "%.1f", (v*100.0)/t}')
	local p_wa=$(awk -v v=$dw -v t=$total 'BEGIN{printf "%.1f", (v*100.0)/t}')
	local p_st=$(awk -v v=$dst -v t=$total 'BEGIN{printf "%.1f", (v*100.0)/t}')
	local p_id=$(awk -v v=$di -v t=$total 'BEGIN{printf "%.1f", (v*100.0)/t}')

	# 输出汇总
	echo "${p_usr} ${p_sys} ${p_wa} ${p_st} ${p_id}"
	echo "--PERCORE--"

	# 每核
	echo "${snap1}" | awk '$1 ~ /^cpu[0-9]+$/' > /tmp/cpu_snap1.$$ 2>/dev/null
	echo "${snap2}" | awk '$1 ~ /^cpu[0-9]+$/' > /tmp/cpu_snap2.$$ 2>/dev/null
	paste /tmp/cpu_snap1.$$ /tmp/cpu_snap2.$$ | awk '{
		# 字段偏移：1:name1 2:u1 3:n1 4:s1 5:i1 6:w1 7:h1 8:so1 9:st1 | 10:name2 11:u2 12:n2 13:s2 14:i2 15:w2 16:h2 17:so2 18:st2
		name=$1; u1=$2; n1=$3; s1=$4; i1=$5; w1=$6; h1=$7; so1=$8; st1=$9;
		u2=$11; n2=$12; s2=$13; i2=$14; w2=$15; h2=$16; so2=$17; st2=$18;
		dU=u2-u1; dN=n2-n1; dS=s2-s1; dI=i2-i1; dW=w2-w1; dH=h2-h1; dSO=so2-so1; dST=st2-st1;
		t=dU+dN+dS+dI+dW+dH+dSO+dST; if(t<=0) t=1;
		pUSR=100.0*dU/t; pSYS=100.0*dS/t; pWA=100.0*dW/t; pST=100.0*dST/t; pID=100.0*dI/t;
		printf "%s %.1f %.1f %.1f %.1f %.1f\n", name, pUSR, pSYS, pWA, pST, pID;
	}'
	rm -f /tmp/cpu_snap1.$$ /tmp/cpu_snap2.$$ 2>/dev/null
}

# 展示 CPU 概览（多次采样 + 告警）
show_cpu_overview() {
	local cores=$(nproc 2>/dev/null || echo 1)
	local usr sys wa st id
	if command -v mpstat &>/dev/null; then
		# 取 3 次 1 秒平均
		local line
		line=$(cpu_stats_with_mpstat 1 3 | head -n1)
		read usr sys wa st id <<< "${line}"
	else
		# /proc/stat 两次采样，做 3 次取均值
		local i sumu=0 sums=0 sumw=0 sumst=0 sumid=0
		for i in 1 2 3; do
			read u s w stl idl <<< "$(cpu_stats_with_proc 1)"
			sumu=$(awk -v a=$sumu -v b=$u 'BEGIN{printf "%.1f", a+b}')
			sums=$(awk -v a=$sums -v b=$s 'BEGIN{printf "%.1f", a+b}')
			sumw=$(awk -v a=$sumw -v b=$w 'BEGIN{printf "%.1f", a+b}')
			sumst=$(awk -v a=$sumst -v b=$stl 'BEGIN{printf "%.1f", a+b}')
			sumid=$(awk -v a=$sumid -v b=$idl 'BEGIN{printf "%.1f", a+b}')
		done
		usr=$(awk -v v=$sumu 'BEGIN{printf "%.1f", v/3}')
		sys=$(awk -v v=$sums 'BEGIN{printf "%.1f", v/3}')
		wa=$(awk -v v=$sumw 'BEGIN{printf "%.1f", v/3}')
		st=$(awk -v v=$sumst 'BEGIN{printf "%.1f", v/3}')
		id=$(awk -v v=$sumid 'BEGIN{printf "%.1f", v/3}')
	fi

	local used=$(awk -v a=$usr -v b=$sys -v c=$wa -v d=$st -v e=$id 'BEGIN{printf "%.1f", 100.0-e}')
	echo -e "${BLUE}CPU(3s平均)${NC} cores:${CYAN}${cores}${NC} used:${YELLOW}${used}%${NC} us:${YELLOW}${usr}%${NC} sy:${YELLOW}${sys}%${NC} wa:${YELLOW}${wa}%${NC} st:${YELLOW}${st}%${NC} id:${YELLOW}${id}%${NC}"

	# 告警阈值：业务打满/IO等待/宿主争用
	if awk -v u=$used 'BEGIN{exit !(u>=85)}'; then
		echo -e "${RED}⚠️ CPU使用率高(>=85%)，可能业务打满${NC}"
	fi
	if awk -v w=$wa 'BEGIN{exit !(w>=10)}'; then
		echo -e "${RED}⚠️ IO等待较高(wa>=10%)，可能磁盘瓶颈${NC}"
	fi
	if awk -v s=$st 'BEGIN{exit !(s>=10)}'; then
		echo -e "${RED}⚠️ Steal偏高(st>=10%)，可能宿主机CPU争用${NC}"
	fi
}

# 展示每核（一次采样）
show_cpu_per_core() {
	if command -v mpstat &>/dev/null; then
		mpstat -P ALL 1 1 | awk 'NR>4 && $3 != "CPU" {printf "%s  used:%5.1f%%  us:%4.1f sy:%4.1f wa:%4.1f st:%4.1f id:%4.1f\n", $3, 100-$13, $4, $6, $7, $9, $13}'
	else
		# /proc/stat 单次 1s 采样
		cpu_stats_with_proc 1 > /tmp/cpu_agg.$$ 2>/dev/null
		# 重新做一次，为了取每核（cpu_stats_with_proc 已经在内部输出了 PERCORE 之后的行，这里简化为重复一次专取 per-core）
		local snap
		snap=$(cpu_stats_with_proc 1)
		# 无法直接拿到 per-core细节（函数中已打印），此处备用：直接做一次 1s 采样并计算 per-core
		echo "--" >/dev/null
	fi
}

# 实时监控系统状态
monitor_system() {
    echo -e "${BLUE}【实时监控系统状态】${NC}"
    echo "=================================="
    echo -e "${YELLOW}按 'q' 返回主菜单，按 Ctrl+C 停止监控${NC}"
    echo ""
    
    local update_interval=${MONITOR_INTERVAL:-5}
    
    # 设置非阻塞读取
    if [ -t 0 ]; then  # 确保是在终端中运行
        # 保存当前终端设置
        local saved_stty=$(stty -g)
        # 设置终端为非规范模式，无回显
        stty -icanon -echo
    fi
    
    while true; do
        clear
        show_header
        
        # 当前时间
        echo -e "${CYAN}当前时间: $(date)${NC}"
        echo "=================================="
        
        # 系统负载
        local load=$(uptime | awk -F'load average:' '{print $2}')
        echo -e "${BLUE}系统负载:${NC} $load"
        
	# CPU 使用（多次采样 + 分项 + 告警）
	show_cpu_overview
	echo -e "${BLUE}每核用量(一次采样)${NC}"
	show_cpu_per_core | head -n 16
        
        # 内存使用率
        local mem_info=$(free -m | grep Mem)
        local mem_total=$(echo $mem_info | awk '{print $2}')
        local mem_used=$(echo $mem_info | awk '{print $3}')
        local mem_usage=$(echo "scale=2; $mem_used*100/$mem_total" | bc)
        echo -e "${BLUE}内存使用率:${NC} ${YELLOW}${mem_usage}%${NC} (${mem_used}MB / ${mem_total}MB)"
        
        # 网络连接数
        local total_conn=$(netstat -an | wc -l)
        local established=$(netstat -an | grep ESTABLISHED | wc -l)
        local time_wait=$(netstat -an | grep TIME_WAIT | wc -l)
        echo -e "${BLUE}网络连接:${NC} 总计: ${total_conn}, ESTABLISHED: ${established}, TIME_WAIT: ${time_wait}"
        
        # 进程数
        local process_count=$(ps -ef | wc -l)
        echo -e "${BLUE}进程数:${NC} ${process_count}"
        
        # 磁盘使用率
        echo -e "${BLUE}磁盘使用率:${NC}"
        df -h | grep -v "tmpfs" | grep -v "udev" | grep -v "loop" | awk '{print $1 "\t" $5 "\t" $6}'
        
        # 异常进程检测
        echo -e "${BLUE}CPU占用最高的进程:${NC}"
        ps aux --sort=-%cpu | head -6 | awk 'NR>1 {printf "%-10s %-8s %-5s %-5s %s\n", $1, $2, $3, $4, $11}'
        
        # 网络流量
        echo -e "${BLUE}网络流量:${NC}"
        if command -v ifstat &> /dev/null; then
            ifstat -i eth0 1 1 | awk 'NR>2 {printf "入站: %s KB/s, 出站: %s KB/s\n", $1, $2}'
        else
            echo "ifstat命令不可用，无法显示网络流量"
        fi
        
        # 检测异常连接
        detect_abnormal_connections
        
        sleep $update_interval
    done
}

# 检测异常连接
detect_abnormal_connections() {
    # 检测连接数异常的IP
    local high_conn_ips=$(netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | awk '$1 > 20 {print $2 "|" $1}')
    
    if [ -n "$high_conn_ips" ]; then
        echo -e "${RED}⚠️ 检测到连接数异常的IP:${NC}"
        echo -e "${CYAN}IP地址            连接数${NC}"
        echo "------------------------"
        
        while IFS="|" read -r ip count; do
            printf "%-18s %s\n" "$ip" "$count"
            
            # 自动加入黑名单
            if [ "${AUTO_BLACKLIST:-true}" = "true" ] && [ $count -gt 50 ]; then
                if ! is_in_whitelist "$ip" && ! is_in_blacklist "$ip"; then
                    add_to_blacklist "$ip" "连接数异常: $count 个连接" 3600
                fi
            fi
        done <<< "$high_conn_ips"
    fi
}

# 实时监控日志
monitor_logs() {
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
    echo -e "${YELLOW}按 'q' 返回主菜单，按 Ctrl+C 停止监控${NC}"
    
    # 设置非阻塞读取
    if [ -t 0 ]; then  # 确保是在终端中运行
        # 保存当前终端设置
        local saved_stty=$(stty -g)
        # 设置终端为非规范模式，无回显
        stty -icanon -echo
    fi
    
    # 使用非阻塞方式监控日志
    local log_pos=$(wc -l < "$main_log")
    
    while true; do
        # 检查是否有新行
        local current_lines=$(wc -l < "$main_log")
        if [ "$current_lines" -gt "$log_pos" ]; then
            # 读取新行
            local new_lines=$((current_lines - log_pos))
            tail -n "$new_lines" "$main_log" | while read -r line; do
                # 提取IP和URL
                local ip=$(echo "$line" | awk '{print $1}')
                local url=$(echo "$line" | awk '{print $7}')
                local status=$(echo "$line" | awk '{print $9}')
                local user_agent=$(echo "$line" | grep -o '"Mozilla[^"]*"')
                
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
            log_pos=$current_lines
        fi
        
        # 非阻塞方式检查是否有按键输入
        if [ -t 0 ]; then  # 确保是在终端中运行
            read -t 0.1 -n 1 key
            if [ "$key" = "q" ]; then
                # 恢复终端设置
                if [ -n "$saved_stty" ]; then
                    stty "$saved_stty"
                fi
                echo -e "\n${GREEN}返回主菜单...${NC}"
                return 0
            fi
        fi
        
        sleep 1
    done
    
    # 恢复终端设置（以防意外退出循环）
    if [ -t 0 ] && [ -n "$saved_stty" ]; then
        stty "$saved_stty"
    fi
}

# 监控CC攻击
monitor_cc_attack() {
    echo -e "${BLUE}【监控CC攻击】${NC}"
    echo "=================================="
    echo -e "${YELLOW}按 'q' 返回主菜单，按 Ctrl+C 停止监控${NC}"
    echo ""
    
    local update_interval=${MONITOR_INTERVAL:-5}
    
    # 设置非阻塞读取
    if [ -t 0 ]; then  # 确保是在终端中运行
        # 保存当前终端设置
        local saved_stty=$(stty -g)
        # 设置终端为非规范模式，无回显
        stty -icanon -echo
    fi
    
    while true; do
        clear
        show_header
        
        # 当前时间
        echo -e "${CYAN}当前时间: $(date)${NC}"
        echo "=================================="
        
        # 网络连接数
        local total_conn=$(netstat -an | wc -l)
        local established=$(netstat -an | grep ESTABLISHED | wc -l)
        local time_wait=$(netstat -an | grep TIME_WAIT | wc -l)
        local syn_recv=$(netstat -an | grep SYN_RECV | wc -l)
        
        echo -e "${BLUE}网络连接:${NC}"
        echo "总连接数: $total_conn"
        echo "ESTABLISHED: $established"
        echo "TIME_WAIT: $time_wait"
        echo "SYN_RECV: $syn_recv"
        
        # 检测SYN洪水攻击
        if [ $syn_recv -gt 100 ]; then
            echo -e "${RED}⚠️ 检测到可能的SYN洪水攻击! SYN_RECV连接数: $syn_recv${NC}"
            
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
        
        # 分析连接IP分布
        echo -e "${CYAN}连接IP分布:${NC}"
        echo -e "IP地址            连接数"
        echo "------------------------"
        netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 | while read count ip; do
            printf "%-18s %s\n" "$ip" "$count"
            
            # 自动加入黑名单
            if [ "${AUTO_BLACKLIST:-true}" = "true" ] && [ $count -gt 50 ]; then
                if ! is_in_whitelist "$ip" && ! is_in_blacklist "$ip"; then
                    add_to_blacklist "$ip" "连接数异常: $count 个连接" 3600
                fi
            fi
        done
        
        # 分析Web服务器访问
        if [ -d "/www/wwwlogs/" ]; then
            local recent_logs=$(find /www/wwwlogs/ -name "*.log" -type f -mmin -5 -exec grep -l "$(date +"%d/%b/%Y:%H:%M" -d "5 minutes ago")" {} \; 2>/dev/null)
            
            if [ -n "$recent_logs" ]; then
                echo -e "${CYAN}最近5分钟的访问频率最高的IP:${NC}"
                for log in $recent_logs; do
                    grep -a "$(date +"%d/%b/%Y:%H:%M" -d "5 minutes ago")" "$log" | awk '{print $1}' | sort | uniq -c | sort -nr | head -10
                done
            fi
        fi
        
        # 非阻塞方式检查是否有按键输入
        if [ -t 0 ]; then  # 确保是在终端中运行
            read -t 0.1 -n 1 key
            if [ "$key" = "q" ]; then
                # 恢复终端设置
                if [ -n "$saved_stty" ]; then
                    stty "$saved_stty"
                fi
                echo -e "\n${GREEN}返回主菜单...${NC}"
                return 0
            fi
        fi
        
        sleep $update_interval
    done
    
    # 恢复终端设置（以防意外退出循环）
    if [ -t 0 ] && [ -n "$saved_stty" ]; then
        stty "$saved_stty"
    fi
}

# 监控异常进程
monitor_processes() {
    echo -e "${BLUE}【监控异常进程】${NC}"
    echo "=================================="
    echo -e "${YELLOW}按 'q' 返回主菜单，按 Ctrl+C 停止监控${NC}"
    echo ""
    
    local update_interval=${MONITOR_INTERVAL:-5}
    
    # 设置非阻塞读取
    if [ -t 0 ]; then  # 确保是在终端中运行
        # 保存当前终端设置
        local saved_stty=$(stty -g)
        # 设置终端为非规范模式，无回显
        stty -icanon -echo
    fi
    
    while true; do
        clear
        show_header
        
        # 当前时间
        echo -e "${CYAN}当前时间: $(date)${NC}"
        echo "=================================="
        
        # CPU 使用（多次采样 + 分项 + 告警）
        show_cpu_overview
        echo -e "${BLUE}每核用量(一次采样)${NC}"
        show_cpu_per_core | head -n 16
        
        # 内存使用率
        local mem_info=$(free -m | grep Mem)
        local mem_total=$(echo $mem_info | awk '{print $2}')
        local mem_used=$(echo $mem_info | awk '{print $3}')
        local mem_usage=$(echo "scale=2; $mem_used*100/$mem_total" | bc)
        echo -e "${BLUE}内存使用率:${NC} ${YELLOW}${mem_usage}%${NC} (${mem_used}MB / ${mem_total}MB)"
        
        # 异常进程检测
        echo -e "${BLUE}CPU占用最高的进程:${NC}"
        echo -e "${CYAN}用户     PID    CPU%   内存%  命令${NC}"
        echo "---------------------------------------"
        ps aux --sort=-%cpu | head -11 | awk 'NR>1 {printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $11}'
        
        # 内存占用最高的进程
        echo -e "${BLUE}内存占用最高的进程:${NC}"
        echo -e "${CYAN}用户     PID    CPU%   内存%  命令${NC}"
        echo "---------------------------------------"
        ps aux --sort=-%mem | head -11 | awk 'NR>1 {printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $11}'
        
        # 检测可疑进程
        detect_suspicious_processes
        
        # 非阻塞方式检查是否有按键输入
        if [ -t 0 ]; then  # 确保是在终端中运行
            read -t 0.1 -n 1 key
            if [ "$key" = "q" ]; then
                # 恢复终端设置
                if [ -n "$saved_stty" ]; then
                    stty "$saved_stty"
                fi
                echo -e "\n${GREEN}返回主菜单...${NC}"
                return 0
            fi
        fi
        
        sleep $update_interval
    done
    
    # 恢复终端设置（以防意外退出循环）
    if [ -t 0 ] && [ -n "$saved_stty" ]; then
        stty "$saved_stty"
    fi
}

# 检测可疑进程
detect_suspicious_processes() {
    echo -e "${BLUE}【检测可疑进程】${NC}"
    
    # 可疑进程名称列表
    local suspicious_names=(
        "minerd"
        "cryptonight"
        "stratum"
        "monero"
        "xmrig"
        "xmr-stak"
        "cpuminer"
        "coinhive"
        "zzh"
        "ddg"
        "ddog"
        "ddos"
        "miner"
        "nmap"
        "scan"
        "exploit"
        "htcap"
        "bruteforce"
    )
    
    # 检查可疑进程
    local found=false
    for name in "${suspicious_names[@]}"; do
        local suspicious_procs=$(ps aux | grep -i "$name" | grep -v "grep" | grep -v "cc_defense")
        
        if [ -n "$suspicious_procs" ]; then
            if [ "$found" = false ]; then
                echo -e "${RED}⚠️ 检测到可疑进程:${NC}"
                echo -e "${CYAN}用户     PID    CPU%   内存%  命令${NC}"
                echo "---------------------------------------"
                found=true
            fi
            
            echo "$suspicious_procs" | awk '{printf "%-8s %-6s %-6s %-6s %s\n", $1, $2, $3, $4, $11}'
            
            # 获取进程信息
            local pid=$(echo "$suspicious_procs" | awk '{print $2}' | head -1)
            
            if [ -n "$pid" ]; then
                # 显示进程详细信息
                echo -e "${YELLOW}进程 $pid 详细信息:${NC}"
                ps -p $pid -o pid,ppid,user,cmd,etime
                
                # 显示进程打开的文件
                if command -v lsof &> /dev/null; then
                    echo -e "${YELLOW}进程 $pid 打开的文件:${NC}"
                    lsof -p $pid 2>/dev/null | head -5
                fi
                
                # 显示进程的网络连接
                echo -e "${YELLOW}进程 $pid 的网络连接:${NC}"
                netstat -anp 2>/dev/null | grep $pid | head -5
                
                # 提示是否终止进程
                if [ "${AUTO_KILL_SUSPICIOUS:-false}" = "true" ]; then
                    echo -e "${RED}自动终止可疑进程 $pid${NC}"
                    kill -9 $pid 2>/dev/null
                    log_message "MONITOR: Automatically killed suspicious process $pid"
                fi
            fi
        fi
    done
    
    if [ "$found" = false ]; then
        echo -e "${GREEN}✅ 未检测到可疑进程${NC}"
    fi
}

# IP异常统计文件
ANOMALY_IP_LOG="/root/anomaly_ip.log"

# 记录异常IP
record_anomaly_ip() {
    local ip="$1"
    local reason="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 记录到日志文件
    echo "${timestamp}|${ip}|${reason}" >> "$ANOMALY_IP_LOG"
    
    # 统计该IP的异常次数
    local count=$(grep "|${ip}|" "$ANOMALY_IP_LOG" | wc -l)
    
    echo -e "${YELLOW}记录异常IP: ${ip} (原因: ${reason}) - 累计异常次数: ${count}${NC}"
    
    # 如果异常次数达到5次以上，自动加入黑名单
    if [ $count -ge 5 ]; then
        if ! is_in_whitelist "$ip" && ! is_in_blacklist "$ip"; then
            echo -e "${RED}⚠️ IP ${ip} 异常次数达到 ${count} 次，自动加入黑名单${NC}"
            add_to_blacklist "$ip" "累计异常${count}次自动加入" 7200  # 加入黑名单2小时
            log_message "MONITOR: Auto-blacklisted IP $ip after $count anomalies"
            
            # 发送告警
            if [ "${ENABLE_EMAIL_ALERTS:-false}" = "true" ]; then
                send_alert_email "自动黑名单告警" "IP地址 $ip 因累计异常 $count 次已被自动加入黑名单"
            fi
        else
            echo -e "${YELLOW}IP ${ip} 已在白名单或黑名单中，跳过自动加入${NC}"
        fi
    fi
}

# 检测系统异常
detect_system_anomalies() {
    echo -e "${BLUE}【检测系统异常】${NC}"
    echo "=================================="
    
    local anomalies_found=false
    # 收集本次检测到的异常IP（去重前临时文件）
    local _abn_tmp="/tmp/abnormal_ips_$$.list"
    : > "${_abn_tmp}"
    # 退出时清理
    trap 'rm -f "${_abn_tmp}" 2>/dev/null' EXIT
    
    # 检查CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    if [ $(echo "$cpu_usage > 90" | bc) -eq 1 ]; then
        echo -e "${RED}⚠️ CPU使用率异常高: ${cpu_usage}%${NC}"
        anomalies_found=true
        
        # 显示CPU占用最高的进程
        echo -e "${YELLOW}CPU占用最高的进程:${NC}"
        ps aux --sort=-%cpu | head -5
    fi
    
    # 检查内存使用率
    local mem_info=$(free -m | grep Mem)
    local mem_total=$(echo $mem_info | awk '{print $2}')
    local mem_used=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$(echo "scale=2; $mem_used*100/$mem_total" | bc)
    
    if [ $(echo "$mem_usage > 90" | bc) -eq 1 ]; then
        echo -e "${RED}⚠️ 内存使用率异常高: ${mem_usage}%${NC}"
        anomalies_found=true
        
        # 显示内存占用最高的进程
        echo -e "${YELLOW}内存占用最高的进程:${NC}"
        ps aux --sort=-%mem | head -5
    fi
    
    # 检查磁盘使用率
    local disk_usage=$(df -h | grep -v "tmpfs" | grep -v "udev" | grep -v "loop" | awk '{print $5}' | tr -d '%' | sort -nr | head -1)
    if [ $disk_usage -gt 90 ]; then
        echo -e "${RED}⚠️ 磁盘使用率异常高: ${disk_usage}%${NC}"
        anomalies_found=true
        
        # 显示磁盘使用情况
        echo -e "${YELLOW}磁盘使用情况:${NC}"
        df -h | grep -v "tmpfs" | grep -v "udev" | grep -v "loop"
    fi
    
    # 检查网络连接数
    local total_conn=$(netstat -an | wc -l)
    if [ $total_conn -gt 1000 ]; then
        echo -e "${RED}⚠️ 网络连接数异常高: ${total_conn}${NC}"
        anomalies_found=true
        
        # 显示连接分布
        echo -e "${YELLOW}连接状态分布:${NC}"
        netstat -an | awk '{print $6}' | sort | uniq -c | sort -nr
        
        # 检查连接数异常的IP并记录
        echo -e "${YELLOW}连接数最高的IP地址:${NC}"
        netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -nr | head -10 | while read count ip; do
            printf "%-8s %s\n" "$count" "$ip"
            
            # 如果单个IP连接数超过20，记录为异常IP
            if [ $count -gt 20 ]; then
                record_anomaly_ip "$ip" "异常连接${count}个"
                echo "$ip" >> "${_abn_tmp}"
            fi
        done
    fi
    
    # 检查系统负载
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
    local cpu_cores=$(grep -c ^processor /proc/cpuinfo)
    
    if [ $(echo "$load > $cpu_cores" | bc) -eq 1 ]; then
        echo -e "${RED}⚠️ 系统负载异常高: ${load} (CPU核心数: ${cpu_cores})${NC}"
        anomalies_found=true
    fi
    
    # 检查异常登录
    local failed_logins=$(grep "Failed password" /var/log/secure 2>/dev/null || grep "Failed password" /var/log/auth.log 2>/dev/null)
    if [ -n "$failed_logins" ]; then
        local failed_count=$(echo "$failed_logins" | wc -l)
        if [ $failed_count -gt 10 ]; then
            echo -e "${RED}⚠️ 检测到大量失败登录尝试: ${failed_count}次${NC}"
            anomalies_found=true
            
            # 显示失败登录IP分布并记录异常IP
            echo -e "${YELLOW}失败登录IP分布:${NC}"
            echo "$failed_logins" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort | uniq -c | sort -nr | head -10 | while read count ip; do
                printf "%-8s %s\n" "$count" "$ip"
                
                # 如果单个IP失败登录次数超过5次，记录为异常IP
                if [ $count -gt 5 ]; then
                    record_anomaly_ip "$ip" "失败登录${count}次"
                    echo "$ip" >> "${_abn_tmp}"
                fi
            done
        fi
    fi
    
    if [ "$anomalies_found" = false ]; then
        echo -e "${GREEN}✅ 未检测到系统异常${NC}"
    fi

    # 一键加入黑名单（可选）
    if [ -s "${_abn_tmp}" ]; then
        echo ""
        echo -e "${YELLOW}本次检测到的异常IP（候选加入黑名单）:${NC}"
        sort -u "${_abn_tmp}" | nl -w2 -s'. '
        echo -ne "${YELLOW}是否将以上异常IP一键加入黑名单(2小时)? (y/n): ${NC}"
        read _confirm_black
        if [[ "${_confirm_black}" == "y" || "${_confirm_black}" == "Y" ]]; then
            local _added=0 _skipped=0
            while read _ip; do
                [ -z "${_ip}" ] && continue
                if is_in_whitelist "${_ip}"; then
                    echo -e "${GREEN}跳过白名单IP: ${_ip}${NC}"
                    _skipped=$((_skipped+1))
                    continue
                fi
                if is_in_blacklist "${_ip}"; then
                    echo -e "${YELLOW}已在黑名单: ${_ip}${NC}"
                    _skipped=$((_skipped+1))
                    continue
                fi
                add_to_blacklist "${_ip}" "系统异常检测: 异常行为" 7200
                echo -e "${RED}已加入黑名单: ${_ip}${NC}"
                _added=$((_added+1))
            done < <(sort -u "${_abn_tmp}")
            echo -e "${CYAN}汇总: 新增 ${_added} 个IP到黑名单，跳过 ${_skipped} 个${NC}"
        fi
    fi
}

# 发送告警邮件
send_alert_email() {
    local subject="$1"
    local message="$2"
    
    # 检查邮件配置
    if [ -z "${ALERT_EMAIL:-}" ]; then
        echo -e "${YELLOW}⚠️ 未配置告警邮箱，无法发送告警${NC}"
        return 1
    fi
    
    # 检查邮件发送工具
    if ! command -v mail &> /dev/null; then
        echo -e "${YELLOW}⚠️ 未安装mail命令，无法发送邮件${NC}"
        return 1
    fi
    
    # 发送邮件
    echo "$message" | mail -s "$subject" "${ALERT_EMAIL}"
    
    echo -e "${GREEN}✅ 告警邮件已发送至 ${ALERT_EMAIL}${NC}"
    log_message "MONITOR: Alert email sent to ${ALERT_EMAIL}: $subject"
    
    return 0
}

# 查看异常IP统计
show_anomaly_ip_stats() {
    echo -e "${BLUE}【异常IP统计】${NC}"
    echo "=================================="
    
    if [ ! -f "$ANOMALY_IP_LOG" ]; then
        echo -e "${YELLOW}暂无异常IP记录${NC}"
        return
    fi
    
    local total_records=$(wc -l < "$ANOMALY_IP_LOG")
    echo -e "${CYAN}总异常记录数: ${total_records}${NC}"
    echo ""
    
    # 显示IP异常次数统计
    echo -e "${YELLOW}IP异常次数排行 (前20名):${NC}"
    echo -e "${CYAN}异常次数  IP地址           最近异常时间${NC}"
    echo "----------------------------------------------------"
    
    awk -F'|' '{print $2}' "$ANOMALY_IP_LOG" | sort | uniq -c | sort -nr | head -20 | while read count ip; do
        # 获取该IP最近的异常时间和原因
        local last_record=$(grep "|${ip}|" "$ANOMALY_IP_LOG" | tail -1)
        local last_time=$(echo "$last_record" | cut -d'|' -f1)
        local last_reason=$(echo "$last_record" | cut -d'|' -f3)
        
        printf "%-8s  %-15s  %s (%s)\n" "$count" "$ip" "$last_time" "$last_reason"
        
        # 检查是否在黑名单中
        if is_in_blacklist "$ip"; then
            echo -e "          ${RED}[已在黑名单]${NC}"
        elif is_in_whitelist "$ip"; then
            echo -e "          ${GREEN}[在白名单中]${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}最近10条异常记录:${NC}"
    echo -e "${CYAN}时间                  IP地址           异常原因${NC}"
    echo "----------------------------------------------------"
    
    tail -10 "$ANOMALY_IP_LOG" | while IFS='|' read -r timestamp ip reason; do
        printf "%-18s  %-15s  %s\n" "$timestamp" "$ip" "$reason"
    done
}

# 清理异常IP日志
clean_anomaly_ip_log() {
    echo -e "${BLUE}【清理异常IP日志】${NC}"
    echo "=================================="
    
    if [ ! -f "$ANOMALY_IP_LOG" ]; then
        echo -e "${YELLOW}异常IP日志文件不存在${NC}"
        return
    fi
    
    local total_records=$(wc -l < "$ANOMALY_IP_LOG")
    echo -e "${CYAN}当前记录数: ${total_records}${NC}"
    
    # 只保留最近30天的记录
    local thirty_days_ago=$(date -d "30 days ago" '+%Y-%m-%d')
    local temp_file="/tmp/anomaly_ip_temp.log"
    
    awk -F'|' -v cutoff="$thirty_days_ago" '$1 >= cutoff' "$ANOMALY_IP_LOG" > "$temp_file"
    
    local remaining_records=$(wc -l < "$temp_file")
    
    if [ $remaining_records -lt $total_records ]; then
        mv "$temp_file" "$ANOMALY_IP_LOG"
        local cleaned_count=$((total_records - remaining_records))
        echo -e "${GREEN}✅ 已清理 ${cleaned_count} 条30天前的记录${NC}"
        echo -e "${CYAN}剩余记录数: ${remaining_records}${NC}"
        log_message "MONITOR: Cleaned $cleaned_count old anomaly IP records"
    else
        rm -f "$temp_file"
        echo -e "${YELLOW}无需清理，所有记录都在30天内${NC}"
    fi
}
