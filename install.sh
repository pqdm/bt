#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}开始安装宝塔面板服务器维护工具...${NC}"

# 创建必要的目录
mkdir -p /root/cc_modules

# 下载主脚本
echo -e "${YELLOW}下载主脚本...${NC}"
wget https://github.com/pqdm/bt/raw/main/ding.sh -O /usr/local/bin/ding
chmod +x /usr/local/bin/ding

# 创建软链接到/root目录
echo -e "${YELLOW}创建软链接...${NC}"
ln -sf /usr/local/bin/ding /root/cc_defense.sh

# 下载配置文件
echo -e "${YELLOW}下载配置文件...${NC}"
wget https://github.com/pqdm/bt/raw/main/cc_config.conf -O /root/cc_config.conf
wget https://github.com/pqdm/bt/raw/main/cc_config_bt_whitelist.conf -O /root/cc_config_bt_whitelist.conf

# 下载模块文件
echo -e "${YELLOW}下载模块文件...${NC}"
wget https://github.com/pqdm/bt/raw/main/cc_modules/analyzer.sh -O /root/cc_modules/analyzer.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/blacklist.sh -O /root/cc_modules/blacklist.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/cleaner.sh -O /root/cc_modules/cleaner.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/firewall.sh -O /root/cc_modules/firewall.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/monitor.sh -O /root/cc_modules/monitor.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/optimizer.sh -O /root/cc_modules/optimizer.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/waf.sh -O /root/cc_modules/waf.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/updater.sh -O /root/cc_modules/updater.sh

# 设置执行权限
echo -e "${YELLOW}设置执行权限...${NC}"
chmod +x /root/cc_modules/*.sh

# 创建黑白名单文件
touch /root/cc_blacklist.txt
touch /root/cc_whitelist.txt

echo -e "${GREEN}宝塔面板服务器维护工具安装完成!${NC}"
echo -e "${GREEN}现在可以通过运行 'ding' 命令来启动系统${NC}"