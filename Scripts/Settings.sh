#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改immortalwrt.lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_SH=$(find ./target/linux/{mediatek/filogic,qualcommax}/base-files/etc/uci-defaults/ -type f -name "*set-wireless.sh" 2>/dev/null)
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_SH" ]; then
	#修改WIFI名称
	sed -i "s/BASE_SSID='.*'/BASE_SSID='$WRT_SSID'/g" $WIFI_SH
	#修改WIFI密码
	sed -i "s/BASE_WORD='.*'/BASE_WORD='$WRT_WORD'/g" $WIFI_SH
elif [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/ssid='.*'/ssid='$WRT_SSID'/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key='$WRT_WORD'/g" $WIFI_UC
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#仅为 QCA-IPQ60XX-USB 预置用户指定的 root 密码；其它工作流仍保持原有登录策略。
if [ "$WRT_CONFIG" = "IPQ60XX-WIFI-YES-USB-YES" ]; then
	SHADOW_FILE="./package/base-files/files/etc/shadow"
	if [ ! -f "$SHADOW_FILE" ]; then
		echo "ERROR: shadow template not found: $SHADOW_FILE"
		exit 1
	fi
	PW_HASH=$(openssl passwd -6 -salt YKWRT "$WRT_PW")
	sed -i "s#^root:[^:]*:#root:$PW_HASH:#" "$SHADOW_FILE"
	grep -q '^root:\$6\$YKWRT\
fi

#rootfs 生成 distfeeds.list 后逐项探测 USTC APK 镜像。
APK_MIRROR_SCRIPT="./scripts/replace-apk-mirrors.sh"
APK_BASE_FILES="./package/base-files/Makefile"
cp "$GITHUB_WORKSPACE/Files/replace-apk-mirrors.sh" "$APK_MIRROR_SCRIPT"
chmod 0755 "$APK_MIRROR_SCRIPT"
sed -i $'/VERSION_SED_SCRIPT.*distfeeds\\.list/a\\\t$(TOPDIR)/scripts/replace-apk-mirrors.sh $(1)/etc/apk/repositories.d/distfeeds.list' "$APK_BASE_FILES"
if ! grep -q $'^\t$(TOPDIR)/scripts/replace-apk-mirrors.sh.*distfeeds.list' "$APK_BASE_FILES"; then
	echo "ERROR: failed to install selective APK mirror hook"
	exit 1
fi

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#无WIFI配置标志
if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
	echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi
 "$SHADOW_FILE" || {
		echo "ERROR: failed to set the default root password"
		exit 1
	}

	# 保留 tag 内置的固定 releases/X.Y.Z 软件源；禁止首次启动时改回滚动或不兼容镜像。
	CHINESE_DEFAULTS="./package/emortal/default-settings/files/99-default-settings-chinese"
	if [ -f "$CHINESE_DEFAULTS" ]; then
		sed -i '/sed -i\.bak .*distfeeds\.list/d' "$CHINESE_DEFAULTS"
	fi

	# 即使上游默认值以后变化，也强制固件与 APK 仓库使用同一个 release 版本。
	if [ -z "$WRT_VERSION" ]; then
		echo "ERROR: WRT_VERSION is required for QCA-IPQ60XX-USB"
		exit 1
	fi
	echo "CONFIG_VERSION_NUMBER=\"$WRT_VERSION\"" >> ./.config
	echo "CONFIG_VERSION_REPO=\"https://downloads.immortalwrt.org/releases/$WRT_VERSION\"" >> ./.config
fi

#rootfs 生成 distfeeds.list 后逐项探测 USTC APK 镜像。
APK_MIRROR_SCRIPT="./scripts/replace-apk-mirrors.sh"
APK_BASE_FILES="./package/base-files/Makefile"
cp "$GITHUB_WORKSPACE/Files/replace-apk-mirrors.sh" "$APK_MIRROR_SCRIPT"
chmod 0755 "$APK_MIRROR_SCRIPT"
sed -i $'/VERSION_SED_SCRIPT.*distfeeds\\.list/a\\\t$(TOPDIR)/scripts/replace-apk-mirrors.sh $(1)/etc/apk/repositories.d/distfeeds.list' "$APK_BASE_FILES"
if ! grep -q $'^\t$(TOPDIR)/scripts/replace-apk-mirrors.sh.*distfeeds.list' "$APK_BASE_FILES"; then
	echo "ERROR: failed to install selective APK mirror hook"
	exit 1
fi

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#无WIFI配置标志
if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
	echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#无WIFI配置调整Q6大小
	if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi
