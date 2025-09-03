#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}开始卸载宝塔面板服务器维护工具...${NC}"

# 清理防火墙规则
echo -e "${YELLOW}清理防火墙规则...${NC}"
if [ -f "/usr/local/bin/ding" ]; then
    /usr/local/bin/ding --clean-firewall 2>/dev/null
fi

# 删除自启动服务
echo -e "${YELLOW}删除自启动服务...${NC}"
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

# 删除主脚本
echo -e "${YELLOW}删除主脚本...${NC}"
rm -f /usr/local/bin/ding
rm -f /root/cc_defense.sh

# 删除配置文件
echo -e "${YELLOW}删除配置文件...${NC}"
rm -f /root/cc_config.conf
rm -f /root/cc_blacklist.txt
rm -f /root/cc_whitelist.txt

# 删除模块文件
echo -e "${YELLOW}删除模块文件...${NC}"
rm -rf /root/cc_modules

# 删除日志文件
echo -e "${YELLOW}删除日志文件...${NC}"
rm -f /var/log/cc_defense.log

echo -e "${GREEN}宝塔面板服务器维护工具已成功卸载!${NC}"
