#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

PKG_PATH="$GITHUB_WORKSPACE/wrt/package/"

#仅为 QCA-IPQ60XX-USB 中的雅典娜 RE-CS-02 镜像追加点阵屏控制包。
#配合 TARGET_PER_DEVICE_ROOTFS，使同一次编译产生的其他设备镜像不包含这些包。
if [ "$WRT_CONFIG" = "IPQ60XX-WIFI-YES-USB-YES" ]; then
	ATHENA_CONFIG="$PKG_PATH/athena-led/files/athena_led.config"
	if [ ! -f "$ATHENA_CONFIG" ]; then
		echo "ERROR: Athena LED default configuration not found: $ATHENA_CONFIG"
		exit 1
	fi
	#默认熄灭机身四枚状态灯；LuCI 中对应四个“熄灭”选项均为已勾选。
	sed -i \
		-e "s/option disable_led_clock '0'/option disable_led_clock '1'/" \
		-e "s/option disable_led_medal '0'/option disable_led_medal '1'/" \
		-e "s/option disable_led_up '0'/option disable_led_up '1'/" \
		-e "s/option disable_led_down '0'/option disable_led_down '1'/" \
		"$ATHENA_CONFIG"
	for option in clock medal up down; do
		grep -q "option disable_led_${option} '1'" "$ATHENA_CONFIG" || {
			echo "ERROR: failed to disable Athena ${option} LED by default"
			exit 1
		}
	done

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
fi

#Samba4 与 Tailscale 统一放到“服务”菜单。
SAMBA_MENU=$(find ../feeds/luci/ -type f -path '*/luci-app-samba4/root/usr/share/luci/menu.d/*.json' -print -quit 2>/dev/null)
if [ -n "$SAMBA_MENU" ]; then
	sed -i 's#admin/nas/samba4#admin/services/samba4#g' "$SAMBA_MENU"
	grep -q 'admin/services/samba4' "$SAMBA_MENU" || {
		echo "ERROR: failed to move Samba4 to Services"
		exit 1
	}
fi

TAILSCALE_MENU=$(find ../feeds/luci/ ./ -type f -path '*/luci-app-tailscale-community/root/usr/share/luci/menu.d/*.json' -print -quit 2>/dev/null)
if [ -n "$TAILSCALE_MENU" ]; then
	sed -i 's#admin/vpn/tailscale#admin/services/tailscale#g' "$TAILSCALE_MENU"
	grep -q 'admin/services/tailscale' "$TAILSCALE_MENU" || {
		echo "ERROR: failed to move Tailscale to Services"
		exit 1
	}
fi

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

#修改 Argon 默认背景、品牌字体和颜色。
if [ -d *"luci-theme-argon"* ]; then
	echo " " && cd ./luci-theme-argon/

	ARGON_CONFIG=./luci-app-argon-config/root/etc/config/argon
	ARGON_THEME=./luci-theme-argon
	ARGON_LOGIN="$ARGON_THEME/ucode/template/themes/argon/sysauth.ut"
	ARGON_CSS="$ARGON_THEME/htdocs/luci-static/argon/css/cascade.css"
	ARGON_IMAGE="$ARGON_THEME/htdocs/luci-static/argon/img/ykwrt-landscape.svg"

	sed -i \
		-e "s/primary '.*'/primary '#31a1a1'/" \
		-e "s/transparency '0.2'/transparency '0.5'/" \
		-e "s/online_wallpaper '.*'/online_wallpaper 'none'/" \
		-e "s/font_weight '600'/font_weight 'normal'/" "$ARGON_CONFIG"
	cp "$GITHUB_WORKSPACE/Files/argon-landscape.svg" "$ARGON_IMAGE"
	sed -i 's#/img/bg\.webp#/img/ykwrt-landscape.svg#g' "$ARGON_LOGIN"
	sed -i 's#font-family: "Sniglet-Regular";#font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "Microsoft YaHei", Arial, sans-serif;#g' "$ARGON_CSS"

	if ! grep -q "online_wallpaper 'none'" "$ARGON_CONFIG" || \
		! grep -q 'ykwrt-landscape.svg' "$ARGON_LOGIN" || \
		grep -q 'font-family: "Sniglet-Regular"' "$ARGON_CSS"; then
		echo "ERROR: failed to apply YKWRT Argon defaults"
		exit 1
	fi

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

#校验 Tailscale 核心包必须安装 UCI 配置和 procd 启动脚本。
TS_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/tailscale/Makefile")
if [ -f "$TS_FILE" ]; then
	grep -q 'tailscale\.init.*etc/init.d/tailscale' "$TS_FILE" || {
		echo "ERROR: Tailscale init script install rule is missing"
		exit 1
	}
	grep -q 'tailscale\.conf.*etc/config/tailscale' "$TS_FILE" || {
		echo "ERROR: Tailscale UCI config install rule is missing"
		exit 1
	}
	echo "Tailscale package contents have been verified."
fi

#修复Rust编译失败
RUST_FILE=$(find ../feeds/packages/ -maxdepth 3 -type f -wholename "*/rust/Makefile")
if [ -f "$RUST_FILE" ]; then
	echo " "

	sed -i 's/ci-llvm=true/ci-llvm=false/g' $RUST_FILE

	cd $PKG_PATH && echo "rust has been fixed!"
fi
