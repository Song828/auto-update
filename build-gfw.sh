#!/bin/sh
# 构建 gfw.conf 用于 SmartDNS
# 会从多个源下载规则，合并去重，生成标准格式，并在文件头部写入生成时间

TMP1="/tmp/temp_gfwlist1"
TMP2="/tmp/temp_gfwlist2"
TMP3="/tmp/temp_gfwlist3"
TMP_ALL="/tmp/temp_gfwlist"
OUTFILE="gfw.conf"

# 下载 gfwlist（base64 格式，需要解码）
wget -qO- https://raw.githubusercontent.com/gfwlist/gfwlist/master/gfwlist.txt | \
    base64 -d | sort -u | sed '/^$\|@@/d' | \
    sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' | \
    sed '/apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /qq\.com/d' | \
    sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+$/d' | \
    grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | \
    sed 's#^\.\+##' | sort -u > "$TMP1"

# 下载 fancyss 规则
wget -qO- https://raw.githubusercontent.com/hq450/fancyss/master/rules/gfwlist.conf | \
    sed 's/ipset=\/\.//g; s/\/gfwlist//g; /^server/d' > "$TMP2"

# 下载 Loyalsoldier 的 v2ray-rules-dat
wget -qO- https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/gfw.txt > "$TMP3"

# 合并三个源，去重、清理
cat "$TMP1" "$TMP2" "$TMP3" | sort -u | sed 's/^\.*//g' > "$TMP_ALL"

# 生成 gfw.conf
{
    # 文件头部，带生成时间（UTC）
    printf "# gfw.conf generated at %s UTC\n" "$(date -u '+%Y-%m-%d %H:%M:%S')"

    # 把域名转换为 SmartDNS 规则
    sed 's/^/domain-rules \//; s/$/\/ -nameserver ext -ipset ext -address #6/' "$TMP_ALL"
} > "$OUTFILE"

# 清理临时文件
rm -f "$TMP1" "$TMP2" "$TMP3" "$TMP_ALL"

echo "生成完成: $OUTFILE"
head -n 5 "$OUTFILE"   # 显示前5行供调试
