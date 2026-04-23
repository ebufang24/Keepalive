#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-ARMv8.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# ---------------------------
# 修正默认 LAN IP 与主机名（兼容新版 Lede）
# ---------------------------

# 目标配置
NEW_IP="192.168.1.2"
NEW_HOST="fang"

# 1️⃣ 修改 config_generate（防止旧逻辑仍生效）
find package/base-files -type f -name config_generate -exec sed -i "s/192\.168\.1\.1/${NEW_IP}/g" {} +
find package/base-files -type f -name config_generate -exec sed -i "s/\bLEDE\b/${NEW_HOST}/g" {} +

# 2️⃣ 修改新版 /etc/board.d/99-lan-ip 默认 LAN IP（若存在）
if grep -q "99-lan-ip" package/base-files/Makefile 2>/dev/null; then
    echo "🧩 Detected new 99-lan-ip system, patching default IP..."
    sed -i "s/192\.168\.1\.1/${NEW_IP}/g" package/base-files/Makefile
fi

# 3️⃣ 修改 generate_static_system 主机名（LEDE -> fang）
find package/base-files -type f -exec sed -i "s#set system.@system\[-1\]\.hostname='LEDE'#set system.@system[-1].hostname='${NEW_HOST}'#g" {} +

# 4️⃣ 打印确认（在 Actions 日志里可见）
echo "🔍 Verifying IP/hostname replacements:"
grep -RIn --exclude-dir=.git -E "${NEW_IP}|${NEW_HOST}" package/base-files || echo "⚠️ 未找到替换行，可能源结构变动"

sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/arm/index.htm

# Enable AAAA
sed -i 's/filter_aaaa	1/filter_aaaa	0/g' package/network/services/dnsmasq/files/dhcp.conf

# Timezone
#sed -i "s/'UTC'/'CST-8'\n   set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

# cpufreq
sed -i 's/LUCI_DEPENDS.*/LUCI_DEPENDS:=\@\(arm\|\|aarch64\)/g' feeds/luci/applications/luci-app-cpufreq/Makefile
sed -i 's/services/system/g' feeds/luci/applications/luci-app-cpufreq/luasrc/controller/cpufreq.lua

# Change default theme
#sed -i 's#luci-theme-bootstrap#luci-theme-opentomcat#g' feeds/luci/collections/luci/Makefile
#sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap

# Add additional packages
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/small/luci-app-bypass
rm -rf feeds/small/luci-app-ssr-plus
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang
#git clone --depth=1 https://github.com/Leo-Jo-My/luci-theme-opentomcat.git package/luci-theme-opentomcat
#sed -i 's|^PKG_VERSION.*|PKG_VERSION:=25.8.3|' feeds/small/xray-core/Makefile
#sed -i 's|^PKG_HASH.*|PKG_HASH:=a7d3785fdd46f1b045b1ef49a2a06e595c327f514b5ee8cd2ae7895813970b2c|' feeds/small/xray-core/Makefile
#############################################
# 🔧 Fix: disable erofs-utils (404 source)
#############################################
sed -i '/erofs-utils/d' tools/Makefile
echo "# CONFIG_TOOLS_EROFS_UTILS is not set" >> .config

# diy.sh - 固定多个仓库的指定目录到特定 commit

set -e

# 通用函数: 从指定仓库、commit 拉取某个目录
fetch_repo_dir() {
    local REPO_URL=$1   # 仓库地址
    local COMMIT=$2     # commit id
    local SRC_DIR=$3    # 仓库里的目录 (例如 net/openssh)
    local DEST_DIR=$4   # 本地目标目录 (例如 feeds/packages/net/openssh)

    echo "固定 $SRC_DIR 到 $COMMIT 来自 $REPO_URL"

    rm -rf "$DEST_DIR"
    TMP_DIR=$(mktemp -d)

    git -C "$TMP_DIR" init
    git -C "$TMP_DIR" remote add origin "$REPO_URL"
    git -C "$TMP_DIR" config core.sparseCheckout true
    echo "$SRC_DIR/*" > "$TMP_DIR/.git/info/sparse-checkout"

    git -C "$TMP_DIR" fetch --depth=1 origin "$COMMIT"
    git -C "$TMP_DIR" checkout FETCH_HEAD

    mkdir -p "$(dirname $DEST_DIR)"
    mv "$TMP_DIR/$SRC_DIR" "$DEST_DIR"

    rm -rf "$TMP_DIR"

    echo "✅ $DEST_DIR 已固定到 $COMMIT"
}

# ================= 使用示例 =================

# 固定 openssh (packages 仓库)
#fetch_repo_dir \
#    "https://github.com/openwrt/packages.git" \
#    "74abe2d0643d480c6260c1bc3a58e17f0c632f8b" \
#    "net/openssh" \
#    "feeds/packages/net/openssh"
    
# 固定 openssl (lede 仓库）    
#fetch_repo_dir \
#    "https://github.com/coolsnowwolf/lede.git" \
#    "4afbc322bfb064e30871e6d34793ab347402f8e0" \
#    "package/libs/openssl" \
#    "package/libs/openssl"

# 固定 kenzo/luci-app-argone-config    
#fetch_repo_dir \
#    "https://github.com/kenzok8/openwrt-packages.git" \
#    "975682568be6782d568901094ae20d25602e4d62" \
#    "luci-app-argone-config" \
#    "feeds/kenzo/luci-app-argone-config"

# 固定 small/sing-box   
# 删除所有来源
#rm -rf feeds/*/sing-box
#rm -rf package/feeds/*/sing-box

# 放到最高优先级
#fetch_repo_dir \
#  "https://github.com/kenzok8/small.git" \
#  "f3015e9de136abef113abc011f926e7862c48e19" \
#  "sing-box" \
#  "package/sing-box"
    
# Delete mosdns
#rm -rf feeds/packages/net/mosdns

# Update Go Version
#rm -rf feeds/packages/lang/golang && git clone -b 22.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

#git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
#git clone https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# dockerd去版本验证
#sed -i 's/^\s*$[(]call\sEnsureVendoredVersion/#&/' feeds/packages/utils/dockerd/Makefile

# containerd Has验证
#sed -i 's/PKG_HASH:=.*/PKG_HASH:=skip/g' feeds/packages/utils/containerd/Makefile

sed -i '741a\
                <tr><td width="33%">&#32534;&#35793;&#32773;&#58;&#32;&#83;&#105;&#108;</td><td><a href="https://t.me/passwall2" style="color: black;" target="_blank">&#32676;&#32452;&#38142;&#25509;</a></td></tr>\
                <tr><td width="33%">&#28304;&#30721;&#58;&#32;&#108;&#101;&#100;&#101;</td><td><a href="https://github.com/coolsnowwolf/lede" style="color: black;" target="_blank">&#28304;&#30721;&#38142;&#25509;</a></td></tr>
' package/lean/autocore/files/arm/index.htm

#curl -fsSL https://raw.githubusercontent.com/yunxi993/OpenWrt-ARMv8/main/patch/Makefile > feeds/packages/utils/xfsprogs/Makefile
#curl -fsSL https://raw.githubusercontent.com/Potterli20/packages/master/utils/zstd/Makefile > feeds/packages/utils/zstd/Makefile
