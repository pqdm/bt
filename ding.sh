#!/bin/bash

# 宝塔面板服务器维护工具 - 主模块
# 作者: 咸鱼神秘人
# 版本: 2.0.0
# 联系方式: 微信dingyanan2008 QQ314450957

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置文件和模块路径
CONFIG_FILE="/root/cc_config.conf"
MODULES_DIR="/root/cc_modules"
LOG_FILE="/var/log/cc_defense.log"
VERSION_FILE="/root/VERSION"

# 获取版本号
get_version() {
    if [ -f "$VERSION_FILE" ]; then
        VERSION=$(cat "$VERSION_FILE" | tr -d '\n\r')
    else
        VERSION="2.1.0"
    fi
}

# 加载配置文件
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo -e "${RED}错误: 配置文件不存在 $CONFIG_FILE${NC}"
        exit 1
    fi
}

# 创建目录
create_dirs() {
    if [ ! -d "$MODULES_DIR" ]; then
        mkdir -p "$MODULES_DIR"
    fi
}

# 记录日志
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 显示标题
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               宝塔面板服务器维护工具 v$VERSION               ║${NC}"
    echo -e "${CYAN}║            BT Panel Server Maintenance Tool                  ║${NC}"
    echo -e "${CYAN}║                                                              ║${NC}"
    echo -e "${CYAN}║  作者: 咸鱼神秘人                                            ║${NC}"
    echo -e "${CYAN}║  微信: dingyanan2008                                         ║${NC}"
    echo -e "${CYAN}║  QQ: 314450957                                               ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示菜单
show_menu() {
    show_header
    echo -e "${BLUE}【主菜单 - 请选择功能分类】${NC}"
    echo "=================================================================="
    echo -e "${GREEN}📊 系统监控${NC}                    ${GREEN}🔍 日志分析${NC}"
    printf "%-32s %s\n" "${CYAN}1.${NC} 实时监控系统" "${CYAN}4.${NC} 分析Web访问日志"
    printf "%-32s %s\n" "${CYAN}2.${NC} 检测系统异常" "${CYAN}5.${NC} 监控CC攻击"
    printf "%-32s %s\n" "${CYAN}3.${NC} 查看系统信息" "${CYAN}6.${NC} 监控异常进程"
    echo ""
    echo -e "${GREEN}🛡️ 安全防护${NC}                    ${GREEN}🗑️ 系统清理${NC}"
    printf "%-32s %s\n" "${CYAN}7.${NC} 查看黑名单" "${CYAN}13.${NC} 恶意文件清理"
    printf "%-32s %s\n" "${CYAN}8.${NC} 管理黑名单" "${CYAN}14.${NC} 系统垃圾清理"
    printf "%-32s %s\n" "${CYAN}9.${NC} 设置防火墙规则" "${CYAN}15.${NC} 深度清理系统"
    printf "%-32s %s\n" "${CYAN}10.${NC} 设置WAF规则" "${CYAN}16.${NC} 预估清理空间"
    printf "%-32s %s\n" "${CYAN}11.${NC} SSH端口安全变更" "${CYAN}17.${NC} 清理策略推荐"
    printf "%-32s %s\n" "${CYAN}12.${NC} 检查SSH连接状态" "${CYAN}18.${NC} 清理安全检查"
    echo ""
    echo -e "${GREEN}⚡ 性能优化${NC}                    ${GREEN}🚨 应急处理${NC}"
    printf "%-32s %s\n" "${CYAN}19.${NC} 优化系统参数" "${CYAN}22.${NC} 一键处理CC攻击"
    printf "%-32s %s\n" "${CYAN}20.${NC} CPU进程清理" "${CYAN}23.${NC} 清理可疑进程(挖矿/木马)"
    printf "%-32s %s\n" "${CYAN}21.${NC} 内存进程清理" "${CYAN}24.${NC} 一键安全加固"
    echo ""
    echo -e "${GREEN}⚙️ 系统管理${NC}"
    printf "%-32s %s\n" "${CYAN}25.${NC} 配置选项" "${CYAN}27.${NC} 检查更新"
    printf "%-32s %s\n" "${CYAN}26.${NC} 关于" "${CYAN}28.${NC} 卸载工具"
    printf "%-32s %s\n" "${CYAN}0.${NC} 退出" ""
    echo "=================================================================="
    echo -ne "${YELLOW}请输入选择: ${NC}"
}

# 加载模块
load_modules() {
    # 检查模块目录
    if [ ! -d "$MODULES_DIR" ]; then
        echo -e "${RED}错误: 模块目录不存在 $MODULES_DIR${NC}"
        exit 1
    fi
    
    # 加载分析模块
    if [ -f "$MODULES_DIR/analyzer.sh" ]; then
        source "$MODULES_DIR/analyzer.sh"
    else
        echo -e "${RED}错误: 分析模块不存在 $MODULES_DIR/analyzer.sh${NC}"
        exit 1
    fi
    
    # 加载黑名单模块
    if [ -f "$MODULES_DIR/blacklist.sh" ]; then
        source "$MODULES_DIR/blacklist.sh"
    else
        echo -e "${RED}错误: 黑名单模块不存在 $MODULES_DIR/blacklist.sh${NC}"
        exit 1
    fi
    
    # 加载WAF模块
    if [ -f "$MODULES_DIR/waf.sh" ]; then
        source "$MODULES_DIR/waf.sh"
    else
        echo -e "${RED}错误: WAF模块不存在 $MODULES_DIR/waf.sh${NC}"
        exit 1
    fi
    
    # 加载防火墙模块
    if [ -f "$MODULES_DIR/firewall.sh" ]; then
        source "$MODULES_DIR/firewall.sh"
    else
        echo -e "${RED}错误: 防火墙模块不存在 $MODULES_DIR/firewall.sh${NC}"
        exit 1
    fi
    
    # 加载优化模块
    if [ -f "$MODULES_DIR/optimizer.sh" ]; then
        source "$MODULES_DIR/optimizer.sh"
    else
        echo -e "${RED}错误: 优化模块不存在 $MODULES_DIR/optimizer.sh${NC}"
        exit 1
    fi
    
    # 加载监控模块
    if [ -f "$MODULES_DIR/monitor.sh" ]; then
        source "$MODULES_DIR/monitor.sh"
    else
        echo -e "${RED}错误: 监控模块不存在 $MODULES_DIR/monitor.sh${NC}"
        exit 1
    fi
    
    # 加载清理模块
    if [ -f "$MODULES_DIR/cleaner.sh" ]; then
        source "$MODULES_DIR/cleaner.sh"
    else
        echo -e "${RED}错误: 清理模块不存在 $MODULES_DIR/cleaner.sh${NC}"
        exit 1
    fi
    
    # 加载系统垃圾清理模块
    if [ -f "$MODULES_DIR/garbage_cleaner.sh" ]; then
        source "$MODULES_DIR/garbage_cleaner.sh"
    else
        echo -e "${YELLOW}警告: 系统垃圾清理模块不存在 $MODULES_DIR/garbage_cleaner.sh${NC}"
    fi
    
    # 加载清理分析模块
    if [ -f "$MODULES_DIR/cleanup_analyzer.sh" ]; then
        source "$MODULES_DIR/cleanup_analyzer.sh"
    else
        echo -e "${YELLOW}警告: 清理分析模块不存在 $MODULES_DIR/cleanup_analyzer.sh${NC}"
    fi
    
    # 加载更新模块
    if [ -f "$MODULES_DIR/updater.sh" ]; then
        source "$MODULES_DIR/updater.sh"
    else
        echo -e "${YELLOW}警告: 更新模块不存在 $MODULES_DIR/updater.sh${NC}"
        # 不退出，因为更新模块不是必需的
    fi
}

# 检查依赖
check_dependencies() {
    local missing_deps=()
    
    # 基本工具
    for cmd in grep awk sed bc curl netstat ps top; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    # 如果有缺失的依赖
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${YELLOW}警告: 以下依赖未安装: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}尝试安装缺失的依赖...${NC}"
        
        # 检测系统类型
        if [ -f /etc/redhat-release ]; then
            # CentOS/RHEL
            yum -y install ${missing_deps[*]} net-tools bc
        elif [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            apt-get update
            apt-get -y install ${missing_deps[*]} net-tools bc
        else
            echo -e "${RED}错误: 无法确定系统类型，请手动安装缺失的依赖${NC}"
            return 1
        fi
    fi
    
    return 0
}

# 初始化
initialize() {
    # 获取版本号
    get_version
    
    # 创建目录
    create_dirs
    
    # 加载配置
    load_config
    
    # 检查依赖
    check_dependencies
    
    # 加载模块
    load_modules
    
    # 初始化黑名单
    init_blacklist
    
    log_message "System initialized"
}

# 处理菜单选择
handle_menu() {
    local choice=$1
    
    case $choice in
        1)
            # 实时监控系统
            monitor_system
            ;;
        2)
            # 检测系统异常
            detect_system_anomalies
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        3)
            # 查看系统信息
            show_system_info
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        4)
            # 分析Web访问日志
            analyze_logs
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        5)
            # 监控CC攻击
            monitor_cc_attack
            ;;
        6)
            # 监控异常进程
            monitor_processes
            ;;
        7)
            # 查看黑名单
            show_blacklist
            echo ""
            show_whitelist
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        8)
            # 管理黑名单
            blacklist_menu
            ;;
        9)
            # 设置防火墙规则
            firewall_menu
            ;;
        10)
            # 设置WAF规则
            waf_menu
            ;;
        11)
            # SSH端口安全变更
            if type change_ssh_port_safely &>/dev/null; then
                change_ssh_port_safely
            else
                echo -e "${RED}错误: 优化模块未加载或不支持change_ssh_port_safely${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        12)
            # 检查SSH连接状态
            if type check_ssh_status &>/dev/null; then
                check_ssh_status
            else
                echo -e "${RED}错误: 优化模块未加载或不支持check_ssh_status${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        13)
            # 恶意文件清理
            malware_menu
            ;;
        14)
            # 系统垃圾清理
            if type clean_system_garbage &>/dev/null; then
                clean_system_garbage
            else
                echo -e "${RED}错误: 清理模块未加载或不支持clean_system_garbage${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        15)
            # 深度清理系统
            if type deep_clean_system &>/dev/null; then
                deep_clean_system
            else
                echo -e "${RED}错误: 清理模块未加载或不支持deep_clean_system${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        16)
            # 预估清理空间
            if type estimate_cleanup_space &>/dev/null; then
                estimate_cleanup_space
            else
                echo -e "${RED}错误: 清理模块未加载或不支持estimate_cleanup_space${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        17)
            # 清理策略推荐
            if type recommend_cleanup_strategy &>/dev/null; then
                recommend_cleanup_strategy
            else
                echo -e "${RED}错误: 清理模块未加载或不支持recommend_cleanup_strategy${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        18)
            # 清理安全检查
            if type safety_check &>/dev/null; then
                safety_check
            else
                echo -e "${RED}错误: 清理模块未加载或不支持safety_check${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        19)
            # 优化系统参数
            optimizer_menu
            ;;
        20)
            # CPU进程清理
            if type fix_high_cpu &>/dev/null; then
                fix_high_cpu
            else
                echo -e "${RED}错误: 优化模块未加载或不支持fix_high_cpu${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        21)
            # 内存进程清理
            if type fix_high_memory &>/dev/null; then
                fix_high_memory
            else
                echo -e "${RED}错误: 优化模块未加载或不支持fix_high_memory${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        22)
            # 一键处理CC攻击
            if type fix_cc_attack &>/dev/null; then
                fix_cc_attack
            else
                echo -e "${RED}错误: 优化模块未加载或不支持fix_cc_attack${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        23)
            # 清理可疑进程
            if type fix_suspicious_processes &>/dev/null; then
                fix_suspicious_processes
            else
                echo -e "${RED}错误: 优化模块未加载或不支持fix_suspicious_processes${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        24)
            # 一键安全加固
            security_hardening
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        25)
            # 配置选项
            config_menu
            ;;
        26)
            # 关于
            show_about
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        27)
            # 检查更新
            if type check_update &>/dev/null; then
                check_update
            else
                echo -e "${RED}错误: 更新模块未加载${NC}"
            fi
            echo -e "${YELLOW}按任意键继续...${NC}"
            read -n 1
            ;;
        28)
            # 卸载工具
            echo -e "${YELLOW}确定要卸载宝塔面板服务器维护工具吗? (y/n): ${NC}"
            read confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                echo -e "${YELLOW}开始卸载...${NC}"
                
                # 清理防火墙规则
                clean_firewall_rules
                
                # 删除自启动服务
                if [ -f "/etc/systemd/system/cc-firewall.service" ]; then
                    systemctl disable cc-firewall.service 2>/dev/null
                    systemctl stop cc-firewall.service 2>/dev/null
                    rm -f /etc/systemd/system/cc-firewall.service
                    systemctl daemon-reload
                fi
                
                if [ -f "/etc/init.d/cc-firewall" ]; then
                    if command -v chkconfig &> /dev/null; then
                        chkconfig cc-firewall off
                        chkconfig --del cc-firewall
                    elif command -v update-rc.d &> /dev/null; then
                        update-rc.d -f cc-firewall remove
                    fi
                    rm -f /etc/init.d/cc-firewall
                fi
                
                # 删除配置文件和模块文件
                rm -f /root/cc_config.conf
                rm -f /root/cc_blacklist.txt
                rm -f /root/cc_whitelist.txt
                rm -rf /root/cc_modules
                rm -f /var/log/cc_defense.log
                
                # 删除主脚本前显示成功信息
                echo -e "${GREEN}宝塔面板服务器维护工具已成功卸载!${NC}"
                
                # 删除自身
                rm -f /usr/local/bin/ding
                rm -f /root/cc_defense.sh
                
                # 退出
                exit 0
            else
                echo -e "${YELLOW}取消卸载操作${NC}"
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
            fi
            ;;
        0)
            # 退出
            echo -e "${GREEN}感谢使用宝塔面板服务器维护工具，再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 无效的选择${NC}"
            sleep 1
            ;;
    esac
}

# 黑名单管理菜单
blacklist_menu() {
    while true; do
        show_header
        echo -e "${BLUE}【黑名单管理】${NC}"
        echo "=================================="
        echo -e "${CYAN}1.${NC} 查看黑名单"
        echo -e "${CYAN}2.${NC} 查看白名单"
        echo -e "${CYAN}3.${NC} 添加IP到黑名单"
        echo -e "${CYAN}4.${NC} 从黑名单中移除IP"
        echo -e "${CYAN}5.${NC} 添加IP到白名单"
        echo -e "${CYAN}6.${NC} 从白名单中移除IP"
        echo -e "${CYAN}7.${NC} 清理过期的黑名单"
        echo -e "${CYAN}0.${NC} 返回主菜单"
        echo "=================================="
        echo -ne "${YELLOW}请输入选择: ${NC}"
        
        read choice
        
        case $choice in
            1)
                show_blacklist
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            2)
                show_whitelist
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            3)
                echo -ne "${YELLOW}请输入要添加到黑名单的IP: ${NC}"
                read ip
                echo -ne "${YELLOW}请输入原因: ${NC}"
                read reason
                echo -ne "${YELLOW}请输入封禁时长(秒)，0表示永久: ${NC}"
                read duration
                
                add_to_blacklist "$ip" "$reason" "$duration"
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            4)
                echo -ne "${YELLOW}请输入要从黑名单中移除的IP: ${NC}"
                read ip
                
                remove_from_blacklist "$ip"
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            5)
                echo -ne "${YELLOW}请输入要添加到白名单的IP: ${NC}"
                read ip
                
                add_to_whitelist "$ip"
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            6)
                echo -ne "${YELLOW}请输入要从白名单中移除的IP: ${NC}"
                read ip
                
                remove_from_whitelist "$ip"
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            7)
                cleanup_blacklist
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}错误: 无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 防火墙菜单
firewall_menu() {
    while true; do
        show_header
        echo -e "${BLUE}【防火墙管理】${NC}"
        echo "=================================="
        echo -e "${CYAN}1.${NC} 设置基本防火墙规则"
        echo -e "${CYAN}2.${NC} 设置高级防火墙规则"
        echo -e "${CYAN}3.${NC} 设置CC攻击防护规则"
        echo -e "${CYAN}4.${NC} 应用黑名单到防火墙"
        echo -e "${CYAN}5.${NC} 显示防火墙规则"
        echo -e "${CYAN}6.${NC} 配置防火墙自启动"
        echo -e "${CYAN}7.${NC} 清理防火墙规则"
        echo -e "${CYAN}8.${NC} 恢复默认防火墙规则"
        echo -e "${CYAN}0.${NC} 返回主菜单"
        echo "=================================="
        echo -ne "${YELLOW}请输入选择: ${NC}"
        
        read choice
        
        case $choice in
            1)
                setup_basic_firewall
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            2)
                setup_advanced_firewall
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            3)
                setup_cc_protection
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            4)
                apply_blacklist_to_firewall
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            5)
                show_firewall_rules
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            6)
                setup_firewall_autostart
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            7)
                clean_firewall_rules
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            8)
                restore_firewall_defaults
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}错误: 无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# WAF菜单
waf_menu() {
    while true; do
        show_header
        echo -e "${BLUE}【WAF管理】${NC}"
        echo "=================================="
        echo -e "${CYAN}1.${NC} 创建WAF规则"
        echo -e "${CYAN}2.${NC} 应用WAF规则"
        echo -e "${CYAN}3.${NC} 移除WAF规则"
        echo -e "${CYAN}4.${NC} 测试WAF规则"
        echo -e "${CYAN}5.${NC} 显示WAF状态"
        echo -e "${CYAN}0.${NC} 返回主菜单"
        echo "=================================="
        echo -ne "${YELLOW}请输入选择: ${NC}"
        
        read choice
        
        case $choice in
            1)
                create_waf_rules
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            2)
                apply_waf_rules
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            3)
                remove_waf_rules
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            4)
                test_waf_rules
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            5)
                show_waf_status
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}错误: 无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 优化菜单
optimizer_menu() {
    while true; do
        show_header
        echo -e "${BLUE}【系统优化】${NC}"
        echo "=================================="
        echo -e "${CYAN}1.${NC} 优化系统参数"
        echo -e "${CYAN}2.${NC} 优化文件描述符限制"
        echo -e "${CYAN}3.${NC} 优化Web服务器配置"
        echo -e "${CYAN}4.${NC} 优化PHP-FPM配置"
        echo -e "${CYAN}0.${NC} 返回主菜单"
        echo "=================================="
        echo -ne "${YELLOW}请输入选择: ${NC}"
        
        read choice
        
        case $choice in
            1)
                optimize_system
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            2)
                optimize_file_limits
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            3)
                optimize_web_server
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            4)
                optimize_php_fpm
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}错误: 无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 配置菜单
config_menu() {
    while true; do
        show_header
        echo -e "${BLUE}【配置选项】${NC}"
        echo "=================================="
        echo -e "${CYAN}1.${NC} 编辑配置文件"
        echo -e "${CYAN}2.${NC} 重新加载配置"
        echo -e "${CYAN}3.${NC} 查看日志"
        echo -e "${CYAN}4.${NC} 清空日志"
        echo -e "${CYAN}0.${NC} 返回主菜单"
        echo "=================================="
        echo -ne "${YELLOW}请输入选择: ${NC}"
        
        read choice
        
        case $choice in
            1)
                # 编辑配置文件
                if command -v nano &> /dev/null; then
                    nano "$CONFIG_FILE"
                elif command -v vim &> /dev/null; then
                    vim "$CONFIG_FILE"
                else
                    vi "$CONFIG_FILE"
                fi
                ;;
            2)
                # 重新加载配置
                load_config
                echo -e "${GREEN}✅ 配置已重新加载${NC}"
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            3)
                # 查看日志
                if [ -f "$LOG_FILE" ]; then
                    if command -v less &> /dev/null; then
                        less "$LOG_FILE"
                    else
                        cat "$LOG_FILE"
                    fi
                else
                    echo -e "${RED}❌ 日志文件不存在${NC}"
                fi
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            4)
                # 清空日志
                if [ -f "$LOG_FILE" ]; then
                    > "$LOG_FILE"
                    echo -e "${GREEN}✅ 日志已清空${NC}"
                else
                    echo -e "${RED}❌ 日志文件不存在${NC}"
                fi
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}错误: 无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 一键安全加固
security_hardening() {
    echo -e "${BLUE}【一键安全加固】${NC}"
    echo "=================================="
    
    echo -e "${YELLOW}正在执行安全加固...${NC}"
    
    # 优化系统参数
    optimize_system
    
    # 设置基本防火墙规则
    setup_basic_firewall
    
    # 设置高级防火墙规则
    setup_advanced_firewall
    
    # 设置CC攻击防护规则
    setup_cc_protection
    
    # 应用黑名单到防火墙
    apply_blacklist_to_firewall
    
    # 配置防火墙自启动
    setup_firewall_autostart
    
    # 创建WAF规则
    create_waf_rules
    
    # 应用WAF规则
    apply_waf_rules
    
    # 优化Web服务器配置
    optimize_web_server
    
    # 优化PHP-FPM配置
    optimize_php_fpm
    
    echo -e "${GREEN}✅ 安全加固完成${NC}"
    log_message "SECURITY: Security hardening completed"
    
    return 0
}

# 显示系统信息
show_system_info() {
    echo -e "${BLUE}【系统信息】${NC}"
    echo "=================================="
    
    # 系统信息
    echo -e "${CYAN}系统信息:${NC}"
    uname -a
    
    # CPU信息
    echo -e "${CYAN}CPU信息:${NC}"
    grep "model name" /proc/cpuinfo | head -1
    echo "CPU核心数: $(grep -c ^processor /proc/cpuinfo)"
    
    # 内存信息
    echo -e "${CYAN}内存信息:${NC}"
    free -h
    
    # 磁盘信息
    echo -e "${CYAN}磁盘信息:${NC}"
    df -h | grep -v "tmpfs" | grep -v "udev" | grep -v "loop"
    
    # 网络信息
    echo -e "${CYAN}网络信息:${NC}"
    ip addr | grep inet | grep -v "127.0.0.1" | grep -v "::1"
    
    # 进程信息
    echo -e "${CYAN}进程信息:${NC}"
    ps -ef | wc -l
    
    # 连接信息
    echo -e "${CYAN}连接信息:${NC}"
    netstat -an | wc -l
    
    # Web服务器信息
    echo -e "${CYAN}Web服务器信息:${NC}"
    if command -v nginx -v &> /dev/null; then
        nginx -v
    elif command -v httpd -v &> /dev/null; then
        httpd -v
    else
        echo "未检测到Web服务器"
    fi
    
    # PHP信息
    echo -e "${CYAN}PHP信息:${NC}"
    if command -v php -v &> /dev/null; then
        php -v
    else
        echo "未检测到PHP"
    fi
    
    # 防火墙信息
    echo -e "${CYAN}防火墙信息:${NC}"
    if command -v iptables -L &> /dev/null; then
        iptables -L | grep -c "Chain"
    else
        echo "未检测到iptables"
    fi
    
    return 0
}

# 恶意文件清理菜单
malware_menu() {
    while true; do
        show_header
        echo -e "${BLUE}【恶意文件清理】${NC}"
        echo "=================================="
        echo -e "${CYAN}1.${NC} 定位恶意进程文件"
        echo -e "${CYAN}2.${NC} 扫描系统恶意文件"
        echo -e "${CYAN}3.${NC} 系统垃圾清理"
        echo -e "${CYAN}4.${NC} 深度清理系统"
        echo -e "${CYAN}5.${NC} 预估清理空间"
        echo -e "${CYAN}6.${NC} 清理策略推荐"
        echo -e "${CYAN}7.${NC} 清理安全检查"
        echo -e "${CYAN}8.${NC} 检查启动项"
        echo -e "${CYAN}9.${NC} 检查定时任务"
        echo -e "${CYAN}10.${NC} 检查Web目录恶意文件"
        echo -e "${CYAN}0.${NC} 返回主菜单"
        echo "=================================="
        echo -ne "${YELLOW}请输入选择: ${NC}"
        
        read choice
        
        case $choice in
            1)
                echo -ne "${YELLOW}请输入要检查的进程PID: ${NC}"
                read pid
                locate_malicious_files "$pid"
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            2)
                scan_malicious_files
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            3)
                clean_system_garbage
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            4)
                deep_clean_system
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            5)
                estimate_cleanup_space
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            6)
                recommend_cleanup_strategy
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            7)
                safety_check
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            8)
                check_startup_entries
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            9)
                check_cron_jobs
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            10)
                check_web_malware
                echo -e "${YELLOW}按任意键继续...${NC}"
                read -n 1
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}错误: 无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 显示关于信息
show_about() {
    echo -e "${BLUE}【关于】${NC}"
    echo "=================================="
    echo -e "${CYAN}宝塔面板服务器维护工具 v$VERSION${NC}"
    echo -e "${CYAN}作者: 咸鱼神秘人${NC}"
    echo -e "${CYAN}微信: dingyanan2008${NC}"
    echo -e "${CYAN}QQ: 314450957${NC}"
    echo -e "${CYAN}版权所有 © 2025${NC}"
    echo -e "${CYAN}本程序是一个功能强大的宝塔面板服务器维护工具，用于保护Web服务器免受CC攻击并进行系统维护。${NC}"
    echo -e "${CYAN}主要功能包括：${NC}"
    echo -e "${CYAN}1. 实时监控系统状态${NC}"
    echo -e "${CYAN}2. 分析Web访问日志${NC}"
    echo -e "${CYAN}3. 检测和防御CC攻击${NC}"
    echo -e "${CYAN}4. 监控异常进程${NC}"
    echo -e "${CYAN}5. 管理黑名单和白名单${NC}"
    echo -e "${CYAN}6. 设置防火墙规则${NC}"
    echo -e "${CYAN}7. 设置WAF规则${NC}"
    echo -e "${CYAN}8. 优化系统参数${NC}"
    echo -e "${CYAN}9. 一键安全加固${NC}"
    echo -e "${CYAN}10. 恶意文件清理${NC}"
    echo -e "${CYAN}使用本程序前，请确保您已经了解相关风险和责任。${NC}"
    echo -e "${CYAN}本程序仅供学习和研究使用，请勿用于非法用途。${NC}"
    echo -e "${CYAN}如有任何问题或建议，请联系作者。${NC}"
    
    return 0
}

# 处理命令行参数
handle_args() {
    if [ $# -eq 0 ]; then
        return 0
    fi
    
    case "$1" in
        --help|-h)
            echo -e "${CYAN}宝塔面板服务器维护工具 v$VERSION${NC}"
            echo -e "${CYAN}用法: $0 [选项]${NC}"
            echo -e "${CYAN}选项:${NC}"
            echo -e "${CYAN}  --help, -h        显示帮助信息${NC}"
            echo -e "${CYAN}  --version, -v     显示版本信息${NC}"
            echo -e "${CYAN}  --monitor         实时监控系统${NC}"
            echo -e "${CYAN}  --analyze         分析Web访问日志${NC}"
            echo -e "${CYAN}  --blacklist       查看黑名单${NC}"
            echo -e "${CYAN}  --firewall        设置防火墙规则${NC}"
            echo -e "${CYAN}  --waf             设置WAF规则${NC}"
            echo -e "${CYAN}  --optimize        优化系统参数${NC}"
            echo -e "${CYAN}  --hardening       一键安全加固${NC}"
            echo -e "${CYAN}  --update          检查更新${NC}"
            exit 0
            ;;
        --version|-v)
            echo -e "${CYAN}宝塔面板服务器维护工具 v$VERSION${NC}"
            exit 0
            ;;
        --monitor)
            initialize
            monitor_system
            exit 0
            ;;
        --analyze)
            initialize
            analyze_logs
            exit 0
            ;;
        --blacklist)
            initialize
            show_blacklist
            exit 0
            ;;
        --firewall)
            initialize
            setup_basic_firewall
            setup_advanced_firewall
            setup_cc_protection
            apply_blacklist_to_firewall
            exit 0
            ;;
        --waf)
            initialize
            create_waf_rules
            apply_waf_rules
            exit 0
            ;;
        --optimize)
            initialize
            optimize_system
            optimize_web_server
            optimize_php_fpm
            exit 0
            ;;
        --hardening)
            initialize
            security_hardening
            exit 0
            ;;
        --update)
            initialize
            if type check_update &>/dev/null; then
                check_update
            else
                echo -e "${RED}错误: 更新模块未加载${NC}"
            fi
            exit 0
            ;;
        --clean-firewall)
            initialize
            clean_firewall_rules
            exit 0
            ;;
        *)
            echo -e "${RED}错误: 无效的参数 $1${NC}"
            echo -e "${CYAN}使用 --help 查看帮助信息${NC}"
            exit 1
            ;;
    esac
}

# 主函数
main() {
    # 处理命令行参数
    handle_args "$@"
    
    # 初始化
    initialize
    
    # 主循环
    while true; do
        show_menu
        read choice
        handle_menu "$choice"
    done
}

# 运行主函数
main "$@"
