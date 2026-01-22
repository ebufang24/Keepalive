#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
#sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
# Passwall 官方 feeds（一定要在 small 前面）
sed -i '1i src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '2i src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default

# kenzok8 的包
sed -i '3i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '4i src-git small https://github.com/kenzok8/small' feeds.conf.default

sed -i "48a\\
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config\n\
" package/lean/default-settings/files/zzz-default-settings
