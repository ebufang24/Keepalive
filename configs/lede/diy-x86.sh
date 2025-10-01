#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-Selfuse.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.1.2/g' package/base-files/files/bin/config_generate

# Hostname
sed -i 's/LEDE/fang/g' package/base-files/files/bin/config_generate

sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/arm/index.htm

# Timezone
#sed -i "s/'UTC'/'CST-8'\n   set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

# cpufreq
#sed -i 's/LUCI_DEPENDS.*/LUCI_DEPENDS:=\@\(arm\|\|aarch64\)/g' package/lean/luci-app-cpufreq/Makefile
#sed -i 's/services/system/g' package/lean/luci-app-cpufreq/luasrc/controller/cpufreq.lua

# Change default theme
sed -i 's#luci-theme-bootstrap#luci-theme-opentomcat#g' feeds/luci/collections/luci/Makefile
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap

# Add additional packages
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/{alist,adguardhome,mosdns,xray*,v2ray*,v2ray*,sing*,smartdns}
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang
git clone https://github.com/kenzok8/golang feeds/packages/lang/golang
sed -i 's|^PKG_VERSION.*|PKG_VERSION:=25.8.3|' feeds/small/xray-core/Makefile
sed -i 's|^PKG_HASH.*|PKG_HASH:=a7d3785fdd46f1b045b1ef49a2a06e595c327f514b5ee8cd2ae7895813970b2c|' feeds/small/xray-core/Makefile
#sed -i 's|^PKG_VERSION.*|PKG_VERSION:=1.11.15|' feeds/small/sing-box/Makefile
#sed -i 's|^PKG_HASH.*|PKG_HASH:=97d58dd873d7cf9b5e4b4aca5516568f3b2e6f5c3dbc93241c82fff5e4a609fd|' feeds/small/sing-box/Makefile
git clone --depth=1 https://github.com/Leo-Jo-My/luci-theme-opentomcat.git package/luci-theme-opentomcat
#sed -i 's|^KERNEL_PATCHVER:=.*|KERNEL_PATCHVER:=6.1|' target/linux/x86/Makefile

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
fetch_repo_dir \
    "https://github.com/openwrt/packages.git" \
    "74abe2d0643d480c6260c1bc3a58e17f0c632f8b" \
    "net/openssh" \
    "feeds/packages/net/openssh"
    
# 固定 openssl (lede 仓库）    
fetch_repo_dir \
    "https://github.com/coolsnowwolf/lede.git" \
    "4afbc322bfb064e30871e6d34793ab347402f8e0" \
    "package/libs/openssl" \
    "package/libs/openssl"
    
# Delete mosdns
#rm -rf feeds/packages/net/mosdns

# Update Go Version
#rm -rf feeds/packages/lang/golang && git clone -b 22.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# dockerd去版本验证
#sed -i 's/^\s*$[(]call\sEnsureVendoredVersion/#&/' feeds/packages/utils/dockerd/Makefile

sed -i '750a\
                <tr><td width="33%">&#32534;&#35793;&#32773;&#58;&#32;&#83;&#105;&#108;</td><td><a href="https://t.me/passwall2" style="color: black;" target="_blank">&#32676;&#32452;&#38142;&#25509;</a></td></tr>\
                <tr><td width="33%">&#28304;&#30721;&#58;&#32;&#108;&#101;&#100;&#101;</td><td><a href="https://github.com/coolsnowwolf/lede" style="color: black;" target="_blank">&#28304;&#30721;&#38142;&#25509;</a></td></tr>
' package/lean/autocore/files/x86/index.htm
