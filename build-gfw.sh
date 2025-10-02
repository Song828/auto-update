#!/bin/sh
# 优化仅在规则内容发生实质性变化时才更新 gfw.conf 文件

# 任何命令失败则立即退出
set -e

# --- 变量定义 ---
TMP_DIR="/tmp/smartdns_rules"
TMP1="$TMP_DIR/temp_gfwlist1"
TMP2="$TMP_DIR/temp_gfwlist2"
TMP3="$TMP_DIR/temp_gfwlist3"
TMP_ALL="$TMP_DIR/temp_gfwlist_all"
TMP_NEW_BODY="$TMP_DIR/temp_new_body.conf"
OUTFILE="gfw.conf"

# --- 初始化 ---
# 创建临时目录
mkdir -p "$TMP_DIR"
# 设置陷阱，确保脚本退出时总是清理临时文件
trap 'rm -rf "$TMP_DIR"' EXIT

echo "开始构建 gfw.conf 规则..."

# --- 下载与处理规则 ---
echo "1/4: 下载 gfwlist..."
wget -qO- https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt | \
    base64 -d | sort -u | sed '/^$\|@@/d' | \
    sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | \
    sed '/apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' | \
    sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+$/d' | \
    grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | \
    sed 's#^\.\+##' | sort -u > "$TMP1"

echo "2/4: 下载 fancyss 规则..."
wget -qO- https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf | \
    sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > "$TMP2"

echo "3/4: 下载 Loyalsoldier 规则..."
wget -qO- https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/gfw.txt > "$TMP3"

# --- 合并、去重并生成新规则主体 ---
echo "4/4: 合并规则并生成 SmartDNS 格式..."
cat "$TMP1" "$TMP2" "$TMP3" | sort -u | sed '/^$/d; s/^\.*//g' > "$TMP_ALL"
sed 's/^/domain-rules \//; s/$/\/ -nameserver ext -ipset ext -address #6/' "$TMP_ALL" > "$TMP_NEW_BODY"

# --- 对比并决定是否更新 ---
# 检查旧文件是否存在，并且新旧规则主体是否相同
if [ -f "$OUTFILE" ] && diff -q <(tail -n +2 "$OUTFILE") "$TMP_NEW_BODY" >/dev/null; then
    echo "☑️ GFW 规则内容无变化，无需更新文件。"
    exit 0
fi

# --- 写入新文件 ---
echo "✅ 检测到 GFW 规则更新，正在生成新的 $OUTFILE..."
{
    # 文件头部，带生成时间（UTC）
    printf "# gfw.conf generated at %s UTC\n" "$(date -u '+%Y-%m-%d %H:%M:%S')"
    # 规则主体
    cat "$TMP_NEW_BODY"
} > "$OUTFILE"

echo "🎉 成功生成新的 $OUTFILE"
head -n 5 "$OUTFILE" # 显示前5行供调试
