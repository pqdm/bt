# 宝塔面板服务器维护工具

## 简介
这是一个专为宝塔面板设计的服务器维护工具，可以帮助您保护您的Web服务器免受CC攻击并进行系统维护。

作者: 咸鱼神秘人  
微信: dingyanan2008  
QQ: 314450957

## 功能特点
- 实时监控系统状态
- 分析Web访问日志
- 检测和防御CC攻击
- 监控异常进程
- 管理黑名单和白名单
- 设置防火墙规则
- 设置WAF规则
- 优化系统参数
- 一键安全加固
- 恶意文件清理

## 安装方法

### 方法一：一键安装（推荐）

```bash
# 下载安装脚本
wget https://github.com/pqdm/bt/raw/main/install.sh -O install.sh

# 设置执行权限
chmod +x install.sh

# 运行安装脚本
./install.sh
```

### 方法二：手动安装

```bash
# 创建必要的目录
mkdir -p /root/cc_modules

# 下载主脚本
wget https://github.com/pqdm/bt/raw/main/ding.sh -O /usr/local/bin/ding
chmod +x /usr/local/bin/ding

# 创建软链接
ln -sf /usr/local/bin/ding /root/cc_defense.sh

# 下载配置文件
wget https://github.com/pqdm/bt/raw/main/cc_config.conf -O /root/cc_config.conf

# 下载模块文件
wget https://github.com/pqdm/bt/raw/main/cc_modules/analyzer.sh -O /root/cc_modules/analyzer.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/blacklist.sh -O /root/cc_modules/blacklist.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/cleaner.sh -O /root/cc_modules/cleaner.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/firewall.sh -O /root/cc_modules/firewall.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/monitor.sh -O /root/cc_modules/monitor.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/optimizer.sh -O /root/cc_modules/optimizer.sh
wget https://github.com/pqdm/bt/raw/main/cc_modules/waf.sh -O /root/cc_modules/waf.sh

# 设置执行权限
chmod +x /root/cc_modules/*.sh

# 创建黑白名单文件
touch /root/cc_blacklist.txt
touch /root/cc_whitelist.txt
```

## 使用方法

安装完成后，您可以通过以下命令启动系统：

```bash
ding
```

在主菜单中，您可以选择不同的功能：

1. 实时监控系统
2. 分析Web访问日志
3. 监控CC攻击
4. 监控异常进程
5. 检测系统异常
6. 查看黑名单
7. 管理黑名单
8. 设置防火墙规则
9. 设置WAF规则
10. 优化系统参数
11. 一键安全加固
12. 查看系统信息
13. 配置选项
14. 恶意文件清理
15. 关于
16. 检查更新
17. 卸载工具
0. 退出

或者使用命令行参数：

```bash
# 显示帮助信息
ding --help

# 实时监控系统
ding --monitor

# 分析Web访问日志
ding --analyze

# 查看黑名单
ding --blacklist

# 设置防火墙规则
ding --firewall

# 设置WAF规则
ding --waf

# 优化系统参数
ding --optimize

# 一键安全加固
ding --hardening

# 清理防火墙规则
ding --clean-firewall

# 检查更新
ding --update
```

## 卸载方法

如果您需要卸载宝塔面板服务器维护工具，可以使用以下命令：

```bash
# 下载卸载脚本
wget https://github.com/pqdm/bt/raw/main/uninstall.sh -O uninstall.sh

# 设置执行权限
chmod +x uninstall.sh

# 运行卸载脚本
./uninstall.sh
```

卸载脚本会自动清理防火墙规则、删除所有相关文件和配置。

## 配置说明

配置文件位于 `/root/cc_config.conf`，您可以根据需要修改配置参数。

## 注意事项

1. 本系统需要root权限运行
2. 建议在使用前备份重要数据
3. 本系统仅供学习和研究使用，请勿用于非法用途

## 更新日志

### v2.0.0
- 全新的界面设计
- 增加了更多的防护功能
- 优化了系统性能
- 增加了恶意文件清理功能

## 许可证

本项目采用 MIT 许可证