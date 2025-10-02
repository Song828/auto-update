#!/bin/sh
# 构建 gfw.conf 用于 SmartDNS
# 会从多个源下载规则，合并去重，并内置更新检查逻辑。
# 只有在域名列表内容实际发生变化时，才会更新 gfw.conf 文件并写入新时间戳。

# --- 临时文件定义 ---
TMP1="/tmp/temp_gfwlist1"
TMP2="/tmp/temp_gfwlist2"
TMP3="/tmp/temp_gfwlist3"
TMP_ALL="/tmp/temp_gfwlist_all"
TMP_NEW_CONTENT="/tmp/gfw_new_content"
OUTFILE="gfw.conf"

# --- 下载并处理规则源 ---

# 1. 下载 gfwlist (base64)
wget -qO- https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt | \
    base64 -d | sort -u | sed '/^$\|@@/d' | \
    sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | \
    sed '/apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' | \
    sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+$/d' | \
    grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | \
    sed 's#^\.\+##' | sort -u > "$TMP1"

# 2. 下载 fancyss 规则
wget -qO- https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf | \
    sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > "$TMP2"

# 3. 下载 Loyalsoldier 的 v2ray-rules-dat
wget -qO- https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/gfw.txt > "$TMP3"

# --- 合并、去重并生成 SmartDNS 格式 ---

# 合并所有源，排序去重
cat "$TMP1" "$TMP2" "$TMP3" | sort -u | sed '/^$/d; s/^\.*//g' > "$TMP_ALL"

# 将合并后的域名列表转换为 SmartDNS 规则，存入临时内容文件 (不带时间戳)
sed 's/^/domain-rules \//; s/$/\/ -nameserver ext -ipset ext -address #6/' "$TMP_ALL" > "$TMP_NEW_CONTENT"

# --- 核心逻辑：检查内容是否有变化 ---

# 检查旧文件是否存在，以及新旧内容是否不同 (忽略旧文件第一行的时间戳)
if [ ! -f "$OUTFILE" ] || ! diff -q "$TMP_NEW_CONTENT" <(tail -n +2 "$OUTFILE" 2>/dev/null); then
    echo "检测到 gfw.conf 规则有更新，正在生成新文件..."
    # 内容有变化，生成带有新时间戳的完整 gfw.conf 文件
    {
        printf "# gfw.conf generated at %s UTC\n" "$(date -u '+%Y-%m-%d %H:%M:%S')"
        cat "$TMP_NEW_CONTENT"
    } > "$OUTFILE"
    
    echo "生成完成: $OUTFILE"
    head -n 5 "$OUTFILE"
else
    echo "gfw.conf 规则内容无变化，跳过文件更新。"
fi

# --- 清理所有临时文件 ---
rm -f "$TMP1" "$TMP2" "$TMP3" "$TMP_ALL" "$TMP_NEW_CONTENT"
