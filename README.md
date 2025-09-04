# 宝塔面板服务器维护工具

## 简介
这是一个专为宝塔面板设计的服务器维护工具，可以帮助您保护您的Web服务器免受CC攻击并进行系统维护。

作者: 咸鱼神秘人  
微信: dingyanan2008  
QQ: 314450957

## 功能特点
- **实时监控系统状态** - 监控CPU、内存、网络连接等系统资源
- **分析Web访问日志** - 智能分析访问日志，识别异常流量模式
- **检测和防御CC攻击** - 自动检测并防御CC攻击，支持多种防护策略
- **监控异常进程** - 实时监控系统进程，识别可疑和恶意进程
- **管理黑名单和白名单** - 灵活的IP黑白名单管理，支持自动和手动管理
- **设置防火墙规则** - 强大的防火墙管理，支持基本和高级规则配置
- **设置WAF规则** - Web应用防火墙规则配置，保护Web应用安全
- **优化系统参数** - 自动优化系统参数，提升服务器性能和安全性
- **一键安全加固** - 一键执行全面的安全加固配置
- **恶意文件清理** - 扫描和清理系统中的恶意文件
- **CPU进程清理** - 自动修复高CPU使用率问题
- **内存进程清理** - 自动修复高内存使用率问题
- **一键处理CC攻击** - 快速响应和处理CC攻击事件
- **清理可疑进程** - 自动清理挖矿木马等可疑进程
- **宝塔面板文件白名单** - 智能识别宝塔面板文件，避免误判

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

## 快速开始

### 1. 安装工具
```bash
# 一键安装
wget https://github.com/pqdm/bt/raw/main/install.sh -O install.sh
chmod +x install.sh
./install.sh
```

### 2. 启动工具
```bash
ding
```

### 3. 基本使用流程
1. **首次使用** - 建议先执行"一键安全加固"进行全面配置
2. **日常监控** - 使用"实时监控系统"查看服务器状态
3. **日志分析** - 定期使用"分析Web访问日志"检查异常流量
4. **攻击处理** - 发现攻击时使用"一键处理CC攻击"快速响应

## 使用方法

安装完成后，您可以通过以下命令启动系统：

```bash
ding
```

在主菜单中，您可以选择不同的功能：

1. **实时监控系统** - 实时监控系统资源使用情况
2. **分析Web访问日志** - 分析Web服务器访问日志
3. **监控CC攻击** - 实时监控和检测CC攻击
4. **监控异常进程** - 监控系统中的异常进程
5. **检测系统异常** - 检测系统运行异常
6. **查看黑名单** - 查看当前黑名单和白名单
7. **管理黑名单** - 管理IP黑名单和白名单
8. **设置防火墙规则** - 配置防火墙规则
9. **设置WAF规则** - 配置Web应用防火墙规则
10. **优化系统参数** - 优化系统性能参数
11. **一键安全加固** - 执行全面的安全加固
12. **查看系统信息** - 显示详细的系统信息
13. **配置选项** - 管理工具配置
14. **恶意文件清理** - 扫描和清理恶意文件
15. **CPU进程清理** - 自动修复高CPU使用率
16. **内存进程清理** - 自动修复高内存使用率
17. **一键处理CC攻击** - 快速处理CC攻击
18. **清理可疑进程** - 清理挖矿木马等可疑进程
19. **关于** - 显示工具信息
20. **检查更新** - 检查工具更新
21. **卸载工具** - 卸载维护工具
0. **退出** - 退出程序

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

# 显示版本信息
ding --version
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

## 技术架构

本工具采用模块化设计，主要包含以下组件：

### 核心模块
- **主控制模块** (`ding.sh`) - 程序入口和菜单控制
- **配置管理** (`cc_config.conf`) - 统一配置管理

### 功能模块
- **analyzer.sh** - 日志分析和流量监控
- **blacklist.sh** - 黑白名单管理
- **cleaner.sh** - 恶意文件清理
- **firewall.sh** - 防火墙规则管理
- **monitor.sh** - 系统实时监控
- **optimizer.sh** - 系统优化和性能调优
- **updater.sh** - 自动更新检查
- **waf.sh** - Web应用防火墙管理

### 支持文件
- **install.sh** - 一键安装脚本
- **uninstall.sh** - 一键卸载脚本
- **cc_config_bt_whitelist.conf** - 宝塔面板文件白名单配置

## 配置说明

配置文件位于 `/root/cc_config.conf`，您可以根据需要修改配置参数。

### 主要配置项
- **CC攻击检测阈值** - 设置IP和URL请求频率阈值
- **自动防护配置** - 配置自动黑名单和进程终止
- **监控配置** - 设置监控更新间隔
- **告警配置** - 配置CPU、内存、磁盘使用率告警阈值
- **Web服务器配置** - 支持Nginx和Apache
- **宝塔面板白名单** - 配置宝塔面板文件保护规则

### 宝塔面板白名单配置
宝塔面板文件白名单配置文件位于 `cc_config_bt_whitelist.conf`，包含：
- **核心目录白名单** - 保护宝塔面板相关目录
- **文件名白名单** - 保护宝塔面板特定文件
- **进程白名单** - 保护宝塔面板相关进程
- **文件类型说明** - 提供详细的文件用途说明

## 注意事项

1. 本系统需要root权限运行
2. 建议在使用前备份重要数据
3. 本系统仅供学习和研究使用，请勿用于非法用途

## 更新日志

### v2.0.2 (2025.09.04)
- **重大优化** - 添加宝塔面板文件白名单功能，解决误判问题
- **智能识别** - 自动识别宝塔面板文件，避免误删重要系统文件
- **文件保护** - 保护宝塔面板图标、安全检测、任务管理等文件
- **详细说明** - 为每个文件提供清晰的类型说明和用途
- **提高准确性** - 大幅减少清理功能中的误判情况


### v2.0.1 (2025.09.03)
- 修复了恶意文件清理功能中的用户交互问题
- 添加了文件类型注释，帮助用户识别可疑文件
- 改进了实时监控功能，添加了按'q'键返回主菜单的功能
- 优化了更新检测机制，提高了稳定性
- 新增CPU进程清理功能，自动修复高CPU使用率问题
- 新增内存进程清理功能，自动修复高内存使用率问题
- 新增一键处理CC攻击功能，快速响应攻击事件
- 新增清理可疑进程功能，自动清理挖矿木马等恶意进程
- 优化了主菜单界面，增加了功能描述
- 改进了命令行参数处理，增加了版本信息显示
- 修复了其他已知问题

### v2.0.0
- 全新的界面设计
- 增加了更多的防护功能
- 优化了系统性能
- 增加了恶意文件清理功能
- 模块化架构设计，提高代码可维护性

## 常见问题

### Q: 工具需要什么系统要求？
A: 支持CentOS、Ubuntu、Debian等主流Linux发行版，需要root权限运行。

### Q: 如何配置CC攻击检测阈值？
A: 编辑 `/root/cc_config.conf` 文件，修改 `CC_IP_THRESHOLD` 和 `CC_URL_THRESHOLD` 参数。

### Q: 防火墙规则会影响正常访问吗？
A: 工具会智能识别正常流量，建议先使用白名单功能保护重要IP。

### Q: 如何恢复被误封的IP？
A: 使用"管理黑名单"功能，将IP添加到白名单或从黑名单中移除。

### Q: 工具会自动更新吗？
A: 工具支持检查更新，但需要手动确认是否安装更新。

### Q: 卸载工具会影响服务器安全吗？
A: 卸载时会清理所有相关规则和文件，建议在卸载前备份重要配置。

### Q: 宝塔面板文件会被误判为恶意文件吗？
A: v2.0.2版本已添加宝塔面板文件白名单功能，会自动识别并保护宝塔面板相关文件，避免误判。

### Q: 如何自定义宝塔面板白名单？
A: 编辑 `cc_config_bt_whitelist.conf` 文件，根据需要添加或修改白名单规则。

### Q: 清理功能会删除宝塔面板文件吗？
A: 不会。工具会智能识别宝塔面板文件并自动跳过，确保系统文件安全。

## 许可证

本项目采用 Apache-2.0 license 许可证