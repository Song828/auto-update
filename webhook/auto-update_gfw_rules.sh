#!/bin/sh
# SmartDNS 规则统一更新脚本 (GFW + AD Rules)
# 自动检测系统环境 (OpenWrt / Ubuntu) 并执行相应操作
# 由 Webhook 触发，仅在有变更时重启服务。

# --- 配置区 ---
# 日志文件路径
LOG_FILE="/tmp/smart-rule-update.log"
# SmartDNS 配置文件存放目录 (请根据实际情况修改)
CONF_DIR="/App/smartdns/conf"
# SmartDNS 主配置文件路径 (OpenWrt 重启时需要)
SMARTDNS_CONF="$CONF_DIR/smartdns.conf"
# GitHub 用户名和仓库名
GIT_USER="Song828"
GIT_REPO="auto-update"
# --- 配置区结束 ---

# 日志函数 (使用 sh 兼容语法)
log() {
    echo "$(date '+%T') $1"
}

# 主执行函数
main() {
    log "=================================================="
    log "开始更新 SmartDNS 规则..."
    
    UPDATE_FLAG=0
    
    # 定义需要同步的所有规则文件列表 (使用 sh 兼容的字符串)
    FILES_TO_UPDATE="gfw.conf anti-ad-for-smartdns.conf anti-ad-white-for-smartdns.conf"

    # 循环处理每一个文件
    for filename in $FILES_TO_UPDATE; do
        local_path="$CONF_DIR/$filename"
        tmp_path="/tmp/$filename.new"
        url="https://raw.githubusercontent.com/${GIT_USER}/${GIT_REPO}/main/${filename}"

        # 下载
        wget -qO "$tmp_path" "$url"
        
        # 检查下载是否成功
        if [ ! -s "$tmp_path" ]; then
            log "下载失败 ${filename}"
            continue
        fi

        # 比较文件内容，如果不同则替换
        if ! cmp -s "$tmp_path" "$local_path"; then
            mv "$tmp_path" "$local_path"
            log "更新 ${filename}"
            UPDATE_FLAG=1
        else
            rm "$tmp_path"
        fi
    done

    # 根据标记决定是否重启服务
    if [ "$UPDATE_FLAG" -eq 1 ]; then
        log "检测到规则更新，重启 SmartDNS 服务..."

        # --- 核心：自动检测系统并执行不同的重启命令 ---
        if [ -f /etc/openwrt_release ]; then
            # 这是 OpenWrt 系统
            log "检测到 OpenWrt，使用 killall 方式重启..."
            killall -9 smartdns >/dev/null 2>&1
            /App/smartdns/smartdns -c "$SMARTDNS_CONF" &
        else
            # 默认为 Ubuntu 或其他 systemd 系统
            log "检测到类 Ubuntu 系统，使用 systemctl 方式重启..."
            sudo systemctl restart smartdns.service
        fi
        
        # 简单的重启成功/失败检查 (通过检查进程)
        if pgrep -x "smartdns" >/dev/null; then
            log "服务重启成功"
        else
            log "服务重启失败！"
        fi
    else
        log "所有规则文件均无变化，无需操作"
    fi
    log "更新任务结束"
    log "=================================================="
}

# 执行主函数，并将所有输出记录到日志
main >> "$LOG_FILE" 2>&1
