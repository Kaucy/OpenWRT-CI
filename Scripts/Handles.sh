#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#仅为雅典娜 RE-CS-02 镜像追加点阵屏控制包。
#配合 TARGET_PER_DEVICE_ROOTFS，使同一份配置生成的亚瑟 RE-SS-01 镜像不包含这些包。
ATHENA_DEVICE_FILE="$GITHUB_WORKSPACE/wrt/target/linux/qualcommax/image/ipq60xx.mk"
if [ ! -f "$ATHENA_DEVICE_FILE" ]; then
	echo "ERROR: IPQ60xx device definition not found: $ATHENA_DEVICE_FILE"
	exit 1
fi

sed -i '/^define Device\/jdcloud_re-cs-02$/,/^endef$/ {
	/^[[:space:]]*DEVICE_PACKAGES :=/ {
		/athena-led/! s/$/ athena-led luci-app-athena-led/
	}
}' "$ATHENA_DEVICE_FILE"

if ! sed -n '/^define Device\/jdcloud_re-cs-02$/,/^endef$/p' "$ATHENA_DEVICE_FILE" | \
	grep -q 'DEVICE_PACKAGES :=.*athena-led.*luci-app-athena-led'; then
	echo "ERROR: failed to add Athena screen packages to jdcloud_re-cs-02"
	exit 1
fi

if sed -n '/^define Device\/jdcloud_re-ss-01$/,/^endef$/p' "$ATHENA_DEVICE_FILE" | \
	grep -qE 'athena-led|luci-app-athena-led'; then
	echo "ERROR: Athena screen packages leaked into jdcloud_re-ss-01"
	exit 1
fi

echo "Athena screen packages have been added to jdcloud_re-cs-02 only."

#预置HomeProxy数据
if [ -d *"homeproxy"* ]; then
	echo " "

	HP_RULE="surge"
	HP_PATH="homeproxy/root/etc/homeproxy"

	rm -rf ./$HP_PATH/resources/*

	git clone -q --depth=1 --single-branch --branch "release" "https://github.com/Loyalsoldier/surge-rules.git" ./$HP_RULE/
	cd ./$HP_RULE/ && RES_VER=$(git log -1 --pretty=format:'%s' | grep -o "[0-9]*")

	echo $RES_VER | tee china_ip4.ver china_ip6.ver china_list.ver gfw_list.ver
	awk -F, '/^IP-CIDR,/{print $2 > "china_ip4.txt"} /^IP-CIDR6,/{print $2 > "china_ip6.txt"}' cncidr.txt
	sed 's/^\.//g' direct.txt > china_list.txt ; sed 's/^\.//g' gfw.txt > gfw_list.txt
	mv -f ./{china_*,gfw_list}.{ver,txt} ../$HP_PATH/resources/

	cd .. && rm -rf ./$HP_RULE/

	cd $PKG_PATH && echo "homeproxy date has been updated!"
fi

#修改argon主题字体和颜色
if [ -d *"luci-theme-argon"* ]; then
	echo " " && cd ./luci-theme-argon/

	sed -i "s/primary '.*'/primary '#31a1a1'/; s/'0.2'/'0.5'/; s/'none'/'bing'/; s/'600'/'normal'/" ./luci-app-argon-config/root/etc/config/argon

	cd $PKG_PATH && echo "theme-argon has been fixed!"
fi

#修改aurora菜单式样
if [ -d *"luci-app-aurora-config"* ]; then
	echo " " && cd ./luci-app-aurora-config/

	sed -i "s/nav_type '.*'/nav_type 'dropdown'/g" $(find ./root/usr/share/aurora/ -type f -name "*.template")

	cd $PKG_PATH && echo "theme-aurora has been fixed!"
fi

#修改mini-diskmanager菜单位置
if [ -d *"luci-app-mini-diskmanager"* ]; then
	echo " " && cd ./luci-app-mini-diskmanager/

	sed -i "s/services/system/g" ./luci-app-mini-diskmanager/root/usr/share/luci/menu.d/luci-app-mini-diskmanager.json

	cd $PKG_PATH && echo "mini-diskmanager has been fixed!"
fi

#修复TailScale配置文件冲突
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	echo " "

	sed -i '/\/files/d' $TS_FILE

	cd $PKG_PATH && echo "tailscale has been fixed!"
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi
