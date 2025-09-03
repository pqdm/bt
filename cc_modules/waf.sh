#!/bin/bash

# 宝塔面板服务器维护工具- Web应用防火墙模块

# 创建WAF规则
create_waf_rules() {
    echo -e "${BLUE}【创建WAF规则】${NC}"
    echo "=================================="
    
    local waf_file=${WAF_RULES_FILE:-"/www/server/nginx/conf/waf.conf"}
    local web_server=${WEB_SERVER:-"nginx"}
    
    # 备份原文件
    if [ -f "$waf_file" ]; then
        cp "$waf_file" "${waf_file}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # 创建WAF规则
    if [ "$web_server" == "nginx" ]; then
        cat > "$waf_file" << 'WAFEOF'
# WAF规则 - 由CC攻击防护系统生成

# 定义限制区域
limit_req_zone $binary_remote_addr zone=req_limit_per_ip:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

# 基本防护规则
map $http_user_agent $block_agent {
    default 0;
    ~*(?:Sogou|YisouSpider|Baiduspider) 0;
    ~*(?:Googlebot|Bingbot|Slurp|DuckDuckBot|Baiduspider|YandexBot|Sogou|Exabot|facebot|ia_archiver) 0;
    ~*(?:zgrab|Wget|curl|python|Java|Go-http-client) 1;
    ~*(?:Scan|Bot|Spider|Crawl) 1;
    ~*(?:nmap|nikto|sqlmap|sqlninja|arachni|metis|sqlmap|sqlninja|nessus|whatweb|Spaidu|Morfeus|ZmEu|Xenu) 1;
    ~*(?:nmap|nikto|sqlmap|sqlninja|arachni|metis|sqlmap|sqlninja|nessus|whatweb|Spaidu|Morfeus|ZmEu|Xenu) 1;
    ~*(?:Morfeus|ZmEu|Xenu|Indy|HTTP_Request|HTTrack|Java/|libwww-perl|lwp-trivial|PHPCrawl|PycURL|Scrapy) 1;
    ~*(?:Fuck|fuck|Shit|shit|Bitch|bitch) 1;
    ~*(?:Acunetix|FHScan|Baiduspider|Baiduspider-image|YoudaoBot|Sogou) 0;
    "" 1;
}

# 阻止恶意请求
map $request_uri $block_uri {
    default 0;
    ~*\.(htaccess|bak|sql|tar|gz|svn|git) 1;
    ~*/(wp-admin|wp-login|wp-content|wp-includes|wp-config|administrator|admin|phpmyadmin|phpMyAdmin) 1;
    ~*/(shell|backdoor|cmd|hack|trojan|webshell|exploit|vulnerable) 1;
    ~*/(etc/passwd|proc/self|etc/shadow|win.ini|boot.ini) 1;
    ~*\.(bash_history|ssh|mysql_history) 1;
}

# 阻止SQL注入
map $args $block_sql_injection {
    default 0;
    ~*select.+from 1;
    ~*union.+select 1;
    ~*concat\(.+\) 1;
    ~*drop.+table 1;
    ~*update.+set 1;
    ~*insert.+into 1;
    ~*delete.+from 1;
    ~*truncate.+table 1;
    ~*exec.+xp 1;
    ~*'|'|";" 1;
    ~*"--" 1;
    ~*"/*" 1;
    ~*"#" 1;
    ~*"=" 0;
}

# 阻止XSS攻击
map $args $block_xss {
    default 0;
    ~*<script 1;
    ~*javascript: 1;
    ~*eval\( 1;
    ~*document\.cookie 1;
    ~*document\.location 1;
    ~*document\.write 1;
    ~*onload= 1;
    ~*onerror= 1;
    ~*onclick= 1;
    ~*onmouseover= 1;
    ~*alert\( 1;
}

# 阻止路径遍历
map $args $block_traversal {
    default 0;
    ~*\.\./\.\. 1;
    ~*%2e%2e/%2e%2e 1;
    ~*\.\.%2f\.\.%2f 1;
}

# 阻止命令注入
map $args $block_command_injection {
    default 0;
    ~*;\s*[a-zA-Z]+ 1;
    ~*&&\s*[a-zA-Z]+ 1;
    ~*\|\|\s*[a-zA-Z]+ 1;
    ~*\|\s*[a-zA-Z]+ 1;
    ~*`[^`]+` 1;
    ~*\$\([^)]+\) 1;
}

# 应用WAF规则
server {
    # 限制请求速率
    limit_req zone=req_limit_per_ip burst=20 nodelay;
    limit_conn conn_limit_per_ip 10;
    
    # 阻止恶意User-Agent
    if ($block_agent) {
        return 403;
    }
    
    # 阻止恶意URI
    if ($block_uri) {
        return 403;
    }
    
    # 阻止SQL注入
    if ($block_sql_injection) {
        return 403;
    }
    
    # 阻止XSS攻击
    if ($block_xss) {
        return 403;
    }
    
    # 阻止路径遍历
    if ($block_traversal) {
        return 403;
    }
    
    # 阻止命令注入
    if ($block_command_injection) {
        return 403;
    }
    
    # 其他安全设置
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options "nosniff";
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self'";
    add_header Referrer-Policy "no-referrer-when-downgrade";
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
WAFEOF
    elif [ "$web_server" == "apache" ]; then
        cat > "$waf_file" << 'WAFEOF'
# WAF规则 - 由CC攻击防护系统生成

# 启用mod_rewrite
<IfModule mod_rewrite.c>
    RewriteEngine On
    
    # 阻止恶意User-Agent
    RewriteCond %{HTTP_USER_AGENT} ^$ [NC,OR]
    RewriteCond %{HTTP_USER_AGENT} (nmap|nikto|sqlmap|sqlninja|arachni|metis|sqlmap|sqlninja|nessus|whatweb|Spaidu|Morfeus|ZmEu|Xenu) [NC,OR]
    RewriteCond %{HTTP_USER_AGENT} (Morfeus|ZmEu|Xenu|Indy|HTTP_Request|HTTrack|Java/|libwww-perl|lwp-trivial|PHPCrawl|PycURL|Scrapy) [NC,OR]
    RewriteCond %{HTTP_USER_AGENT} (Fuck|fuck|Shit|shit|Bitch|bitch) [NC]
    RewriteRule .* - [F,L]
    
    # 阻止恶意URI
    RewriteCond %{REQUEST_URI} \.(htaccess|bak|sql|tar|gz|svn|git) [NC,OR]
    RewriteCond %{REQUEST_URI} /(wp-admin|wp-login|wp-content|wp-includes|wp-config|administrator|admin|phpmyadmin|phpMyAdmin) [NC,OR]
    RewriteCond %{REQUEST_URI} /(shell|backdoor|cmd|hack|trojan|webshell|exploit|vulnerable) [NC,OR]
    RewriteCond %{REQUEST_URI} /(etc/passwd|proc/self|etc/shadow|win.ini|boot.ini) [NC,OR]
    RewriteCond %{REQUEST_URI} \.(bash_history|ssh|mysql_history) [NC]
    RewriteRule .* - [F,L]
    
    # 阻止SQL注入
    RewriteCond %{QUERY_STRING} select.+from [NC,OR]
    RewriteCond %{QUERY_STRING} union.+select [NC,OR]
    RewriteCond %{QUERY_STRING} concat\(.+\) [NC,OR]
    RewriteCond %{QUERY_STRING} drop.+table [NC,OR]
    RewriteCond %{QUERY_STRING} update.+set [NC,OR]
    RewriteCond %{QUERY_STRING} insert.+into [NC,OR]
    RewriteCond %{QUERY_STRING} delete.+from [NC,OR]
    RewriteCond %{QUERY_STRING} truncate.+table [NC,OR]
    RewriteCond %{QUERY_STRING} exec.+xp [NC,OR]
    RewriteCond %{QUERY_STRING} '|'|";" [NC,OR]
    RewriteCond %{QUERY_STRING} "--" [NC,OR]
    RewriteCond %{QUERY_STRING} "/*" [NC,OR]
    RewriteCond %{QUERY_STRING} "#" [NC]
    RewriteRule .* - [F,L]
    
    # 阻止XSS攻击
    RewriteCond %{QUERY_STRING} <script [NC,OR]
    RewriteCond %{QUERY_STRING} javascript: [NC,OR]
    RewriteCond %{QUERY_STRING} eval\( [NC,OR]
    RewriteCond %{QUERY_STRING} document\.cookie [NC,OR]
    RewriteCond %{QUERY_STRING} document\.location [NC,OR]
    RewriteCond %{QUERY_STRING} document\.write [NC,OR]
    RewriteCond %{QUERY_STRING} onload= [NC,OR]
    RewriteCond %{QUERY_STRING} onerror= [NC,OR]
    RewriteCond %{QUERY_STRING} onclick= [NC,OR]
    RewriteCond %{QUERY_STRING} onmouseover= [NC,OR]
    RewriteCond %{QUERY_STRING} alert\( [NC]
    RewriteRule .* - [F,L]
    
    # 阻止路径遍历
    RewriteCond %{QUERY_STRING} \.\./\.\. [NC,OR]
    RewriteCond %{QUERY_STRING} %2e%2e/%2e%2e [NC,OR]
    RewriteCond %{QUERY_STRING} \.\.%2f\.\.%2f [NC]
    RewriteRule .* - [F,L]
    
    # 阻止命令注入
    RewriteCond %{QUERY_STRING} ;\s*[a-zA-Z]+ [NC,OR]
    RewriteCond %{QUERY_STRING} &&\s*[a-zA-Z]+ [NC,OR]
    RewriteCond %{QUERY_STRING} \|\|\s*[a-zA-Z]+ [NC,OR]
    RewriteCond %{QUERY_STRING} \|\s*[a-zA-Z]+ [NC,OR]
    RewriteCond %{QUERY_STRING} `[^`]+` [NC,OR]
    RewriteCond %{QUERY_STRING} \$\([^)]+\) [NC]
    RewriteRule .* - [F,L]
</IfModule>

# 其他安全设置
<IfModule mod_headers.c>
    Header set X-Frame-Options "SAMEORIGIN"
    Header set X-XSS-Protection "1; mode=block"
    Header set X-Content-Type-Options "nosniff"
    Header set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; font-src 'self'; connect-src 'self'"
    Header set Referrer-Policy "no-referrer-when-downgrade"
</IfModule>

# 禁止访问隐藏文件
<FilesMatch "^\.">
    Order allow,deny
    Deny from all
</FilesMatch>
WAFEOF
    else
        echo -e "${RED}❌ 不支持的Web服务器类型: $web_server${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ WAF规则已创建: $waf_file${NC}"
    log_message "WAF: WAF rules created at $waf_file"
    
    return 0
}

# 应用WAF规则
apply_waf_rules() {
    echo -e "${BLUE}【应用WAF规则】${NC}"
    echo "=================================="
    
    local waf_file=${WAF_RULES_FILE:-"/www/server/nginx/conf/waf.conf"}
    local web_server=${WEB_SERVER:-"nginx"}
    local config_file=""
    
    # 检查WAF规则文件
    if [ ! -f "$waf_file" ]; then
        echo -e "${RED}❌ WAF规则文件不存在: $waf_file${NC}"
        echo -e "${YELLOW}正在创建WAF规则文件...${NC}"
        create_waf_rules
    fi
    
    # 根据Web服务器类型应用规则
    if [ "$web_server" == "nginx" ]; then
        config_file="/www/server/nginx/conf/nginx.conf"
        
        if [ ! -f "$config_file" ]; then
            echo -e "${RED}❌ Nginx配置文件不存在: $config_file${NC}"
            return 1
        fi
        
        # 备份配置文件
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # 检查是否已包含WAF规则
        if grep -q "include $waf_file;" "$config_file"; then
            echo -e "${YELLOW}⚠️ Nginx配置已包含WAF规则${NC}"
        else
            # 在http块内添加include语句
            sed -i "/http {/a \    include $waf_file;" "$config_file"
            
            echo -e "${GREEN}✅ WAF规则已应用到Nginx配置${NC}"
            log_message "WAF: WAF rules applied to Nginx configuration"
            
            # 测试配置
            if nginx -t; then
                # 重启Nginx
                if command -v systemctl &> /dev/null; then
                    systemctl restart nginx
                else
                    service nginx restart
                fi
                
                echo -e "${GREEN}✅ Nginx已重启，WAF规则生效${NC}"
            else
                echo -e "${RED}❌ Nginx配置测试失败，恢复备份${NC}"
                cp "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" "$config_file"
                return 1
            fi
        fi
    elif [ "$web_server" == "apache" ]; then
        config_file="/www/server/apache/conf/httpd.conf"
        
        if [ ! -f "$config_file" ]; then
            echo -e "${RED}❌ Apache配置文件不存在: $config_file${NC}"
            return 1
        fi
        
        # 备份配置文件
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # 检查是否已包含WAF规则
        if grep -q "Include $waf_file" "$config_file"; then
            echo -e "${YELLOW}⚠️ Apache配置已包含WAF规则${NC}"
        else
            # 添加Include语句
            echo "Include $waf_file" >> "$config_file"
            
            echo -e "${GREEN}✅ WAF规则已应用到Apache配置${NC}"
            log_message "WAF: WAF rules applied to Apache configuration"
            
            # 测试配置
            if apachectl -t; then
                # 重启Apache
                if command -v systemctl &> /dev/null; then
                    systemctl restart httpd
                else
                    service httpd restart
                fi
                
                echo -e "${GREEN}✅ Apache已重启，WAF规则生效${NC}"
            else
                echo -e "${RED}❌ Apache配置测试失败，恢复备份${NC}"
                cp "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" "$config_file"
                return 1
            fi
        fi
    else
        echo -e "${RED}❌ 不支持的Web服务器类型: $web_server${NC}"
        return 1
    fi
    
    return 0
}

# 移除WAF规则
remove_waf_rules() {
    echo -e "${BLUE}【移除WAF规则】${NC}"
    echo "=================================="
    
    local waf_file=${WAF_RULES_FILE:-"/www/server/nginx/conf/waf.conf"}
    local web_server=${WEB_SERVER:-"nginx"}
    local config_file=""
    
    # 根据Web服务器类型移除规则
    if [ "$web_server" == "nginx" ]; then
        config_file="/www/server/nginx/conf/nginx.conf"
        
        if [ ! -f "$config_file" ]; then
            echo -e "${RED}❌ Nginx配置文件不存在: $config_file${NC}"
            return 1
        fi
        
        # 备份配置文件
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # 移除include语句
        sed -i "\|include $waf_file;|d" "$config_file"
        
        echo -e "${GREEN}✅ WAF规则已从Nginx配置中移除${NC}"
        log_message "WAF: WAF rules removed from Nginx configuration"
        
        # 测试配置
        if nginx -t; then
            # 重启Nginx
            if command -v systemctl &> /dev/null; then
                systemctl restart nginx
            else
                service nginx restart
            fi
            
            echo -e "${GREEN}✅ Nginx已重启，WAF规则已禁用${NC}"
        else
            echo -e "${RED}❌ Nginx配置测试失败，恢复备份${NC}"
            cp "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" "$config_file"
            return 1
        fi
    elif [ "$web_server" == "apache" ]; then
        config_file="/www/server/apache/conf/httpd.conf"
        
        if [ ! -f "$config_file" ]; then
            echo -e "${RED}❌ Apache配置文件不存在: $config_file${NC}"
            return 1
        fi
        
        # 备份配置文件
        cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # 移除Include语句
        sed -i "\|Include $waf_file|d" "$config_file"
        
        echo -e "${GREEN}✅ WAF规则已从Apache配置中移除${NC}"
        log_message "WAF: WAF rules removed from Apache configuration"
        
        # 测试配置
        if apachectl -t; then
            # 重启Apache
            if command -v systemctl &> /dev/null; then
                systemctl restart httpd
            else
                service httpd restart
            fi
            
            echo -e "${GREEN}✅ Apache已重启，WAF规则已禁用${NC}"
        else
            echo -e "${RED}❌ Apache配置测试失败，恢复备份${NC}"
            cp "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" "$config_file"
            return 1
        fi
    else
        echo -e "${RED}❌ 不支持的Web服务器类型: $web_server${NC}"
        return 1
    fi
    
    return 0
}

# 测试WAF规则
test_waf_rules() {
    echo -e "${BLUE}【测试WAF规则】${NC}"
    echo "=================================="
    
    local server_ip=$(hostname -I | awk '{print $1}')
    local test_url="http://$server_ip"
    
    echo -e "${YELLOW}测试WAF规则...${NC}"
    
    # 测试SQL注入防护
    echo -e "${CYAN}测试SQL注入防护:${NC}"
    curl -s -o /dev/null -w "%{http_code}" "$test_url/?id=1' OR 1=1 --"
    echo " <- 应返回403表示WAF规则生效"
    
    # 测试XSS防护
    echo -e "${CYAN}测试XSS防护:${NC}"
    curl -s -o /dev/null -w "%{http_code}" "$test_url/?param=<script>alert(1)</script>"
    echo " <- 应返回403表示WAF规则生效"
    
    # 测试路径遍历防护
    echo -e "${CYAN}测试路径遍历防护:${NC}"
    curl -s -o /dev/null -w "%{http_code}" "$test_url/?file=../../../etc/passwd"
    echo " <- 应返回403表示WAF规则生效"
    
    # 测试命令注入防护
    echo -e "${CYAN}测试命令注入防护:${NC}"
    curl -s -o /dev/null -w "%{http_code}" "$test_url/?cmd=ls;cat /etc/passwd"
    echo " <- 应返回403表示WAF规则生效"
    
    # 测试恶意User-Agent防护
    echo -e "${CYAN}测试恶意User-Agent防护:${NC}"
    curl -s -o /dev/null -w "%{http_code}" -A "sqlmap/1.0" "$test_url"
    echo " <- 应返回403表示WAF规则生效"
    
    echo -e "${GREEN}✅ WAF规则测试完成${NC}"
    
    return 0
}

# 显示WAF规则状态
show_waf_status() {
    echo -e "${BLUE}【WAF规则状态】${NC}"
    echo "=================================="
    
    local waf_file=${WAF_RULES_FILE:-"/www/server/nginx/conf/waf.conf"}
    local web_server=${WEB_SERVER:-"nginx"}
    local config_file=""
    
    # 检查WAF规则文件
    if [ -f "$waf_file" ]; then
        echo -e "${GREEN}✅ WAF规则文件存在: $waf_file${NC}"
        echo -e "${CYAN}WAF规则文件大小: $(du -h "$waf_file" | awk '{print $1}')${NC}"
        echo -e "${CYAN}WAF规则文件修改时间: $(stat -c '%y' "$waf_file")${NC}"
    else
        echo -e "${RED}❌ WAF规则文件不存在: $waf_file${NC}"
    fi
    
    # 根据Web服务器类型检查配置
    if [ "$web_server" == "nginx" ]; then
        config_file="/www/server/nginx/conf/nginx.conf"
        
        if [ ! -f "$config_file" ]; then
            echo -e "${RED}❌ Nginx配置文件不存在: $config_file${NC}"
        else
            if grep -q "include $waf_file;" "$config_file"; then
                echo -e "${GREEN}✅ WAF规则已应用到Nginx配置${NC}"
            else
                echo -e "${RED}❌ WAF规则未应用到Nginx配置${NC}"
            fi
        fi
    elif [ "$web_server" == "apache" ]; then
        config_file="/www/server/apache/conf/httpd.conf"
        
        if [ ! -f "$config_file" ]; then
            echo -e "${RED}❌ Apache配置文件不存在: $config_file${NC}"
        else
            if grep -q "Include $waf_file" "$config_file"; then
                echo -e "${GREEN}✅ WAF规则已应用到Apache配置${NC}"
            else
                echo -e "${RED}❌ WAF规则未应用到Apache配置${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ 不支持的Web服务器类型: $web_server${NC}"
    fi
    
    return 0
}
