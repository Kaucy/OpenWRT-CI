#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./ \;
		rm -rf ./$REPO_NAME/
	elif [[ "$PKG_SPECIAL" == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

# 调用示例
# UPDATE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# UPDATE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "argon" "sbwml/luci-theme-argon" "openwrt-25.12"
UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"
UPDATE_PACKAGE "noobwrt" "nooblk-98/luci-theme-noobwrt" "master"
UPDATE_PACKAGE "shadcn" "eamonxg/luci-theme-shadcn" "main"
UPDATE_PACKAGE "theme-fluent" "LazuliKao/luci-theme-fluent" "main"

UPDATE_PACKAGE "homeproxy" "VIKINGYFY/homeproxy" "main"
UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"

UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"
UPDATE_PACKAGE "diskmanager" "4IceG/luci-app-mini-diskmanager" "main"
UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
UPDATE_PACKAGE "netwizard" "sirpdboy/luci-app-netwizard" "main"
UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
#QModem 上游保留了两个当前源码树不存在的非默认可选依赖，删除声明以避免包扫描警告。
#默认使用 vendor QMI 驱动和 quectel-CM-5G-M，不影响 USB QMI/MBIM/NCM 功能。
sed -i '/GENERIC_MHI_PCIe_DRIVER:kmod-mhi-wwan \\/d' ./QModem/application/qmodem/Makefile
sed -i '/USING_QWRT_QUECTEL_CM_5G:quectel-CM-5G \\/d' ./QModem/application/qmodem/Makefile
#QModem 放到“网络”菜单，并统一所有控制器、跳转和前端链接的路径。
QMODEM_CONTROLLER="./QModem/luci/luci-app-qmodem/luasrc/controller/qmodem.lua"
if [ ! -f "$QMODEM_CONTROLLER" ]; then
	echo "ERROR: QModem controller not found: $QMODEM_CONTROLLER"
	exit 1
fi
sed -i '/entry({"admin", "modem"}, firstchild()/d' "$QMODEM_CONTROLLER"
find ./QModem/luci -type f \
	\( -name '*.lua' -o -name '*.htm' -o -name '*.js' -o -name '*.json' \) \
	-exec sed -i \
		-e 's/"admin", "modem"/"admin", "network"/g' \
		-e 's#admin/modem/qmodem#admin/network/qmodem#g' {} +
sed -i 's/luci\.i18n\.translate("QModem")/luci.i18n.translate("Qmodem 模块管理")/' "$QMODEM_CONTROLLER"
if ! grep -q 'entry({"admin", "network", "qmodem"}.*Qmodem 模块管理' "$QMODEM_CONTROLLER"; then
	echo "ERROR: failed to move and rename the QModem menu"
	exit 1
fi
UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
UPDATE_PACKAGE "timecontrol" "sirpdboy/luci-app-timecontrol" "main"
UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "gecoosac luci-app-timewol luci-app-wolplus"
#不再提供集客 AC 控制器。
find ./packages -type d -iname '*gecoosac*' -prune -exec rm -rf {} + 2>/dev/null || true
UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"

#从仓库中的指定目录提取单个软件包，避免引入大杂烩仓库的其它包
UPDATE_PACKAGE_PATH() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_PATH=$4
	local TMP_DIR="package-${PKG_NAME}"

	rm -rf "$PKG_NAME" "$TMP_DIR"
	find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec rm -rf {} + 2>/dev/null
	git clone --depth=1 --single-branch --branch "$PKG_BRANCH" "https://github.com/$PKG_REPO.git" "$TMP_DIR"
	cp -rf "$TMP_DIR/$PKG_PATH" "./$PKG_NAME"
	rm -rf "$TMP_DIR"
}

#雅典娜屏幕只用于 QCA-IPQ60XX-USB；固定到具备完整 Release 资产的 v2.4.0。
if [ "$WRT_CONFIG" = "IPQ60XX-WIFI-YES-USB-YES" ]; then
	UPDATE_PACKAGE_PATH "athena-led" "unraveloop/JDC-AX6600-Athena-LED-Controller" "v2.4.0" "athena-led"
	UPDATE_PACKAGE_PATH "luci-app-athena-led" "unraveloop/JDC-AX6600-Athena-LED-Controller" "v2.4.0" "luci-app-athena-led"

	#默认启用，只保留单一“小时:分钟”页面，冒号使用 timeBlink 模式闪烁。
	ATHENA_CONFIG="./athena-led/files/athena_led.config"
	ATHENA_MAKEFILE="./athena-led/Makefile"
	if [ ! -f "$ATHENA_CONFIG" ] || [ ! -f "$ATHENA_MAKEFILE" ]; then
		echo "ERROR: Athena LED package layout changed"
		exit 1
	fi
	sed -i \
		-e "s/option enabled '0'/option enabled '1'/" \
		-e "s/option profile_mode 'multi'/option profile_mode 'single'/" \
		-e '/^config multi_module$/,/^[[:space:]]*$/d' \
		-e '/^config single_module$/,/^[[:space:]]*$/d' \
		"$ATHENA_CONFIG"
	cat >> "$ATHENA_CONFIG" <<'EOF'

config single_module
    option module 'time_group'
    option param 'timeBlink'
    option duration '86400'
EOF
	#上游自定义 postinst 在制作镜像时不会启用服务，直接写入 rc.d 启动链接。
	sed -i $'/$(INSTALL_CONF) \\.\\/files\\/athena_led.config/a\\\t$(INSTALL_DIR) $(1)/etc/rc.d\\\n\tln -sf ../init.d/athena_led $(1)/etc/rc.d/S99athena_led' "$ATHENA_MAKEFILE"
	if ! grep -q "option enabled '1'" "$ATHENA_CONFIG" || \
		! grep -q "option param 'timeBlink'" "$ATHENA_CONFIG" || \
		[ "$(grep -c '^config single_module$' "$ATHENA_CONFIG")" -ne 1 ] || \
		grep -q '^config multi_module$' "$ATHENA_CONFIG" || \
		! grep -q $'^\t$(INSTALL_DIR) $(1)/etc/rc.d' "$ATHENA_MAKEFILE" || \
		! grep -q $'^\tln -sf ../init.d/athena_led $(1)/etc/rc.d/S99athena_led' "$ATHENA_MAKEFILE"; then
		echo "ERROR: failed to apply Athena LED defaults"
		exit 1
	fi
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_MARK=${2:-false}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

	if [ -z "$PKG_FILES" ]; then
		echo "$PKG_NAME not found!"
		return
	fi

	echo -e "\n$PKG_NAME version update has started!"

	for PKG_FILE in $PKG_FILES; do
		local PKG_REPO=$(grep -Po "PKG_SOURCE_URL:=https://.*github.com/\K[^/]+/[^/]+(?=.*)" $PKG_FILE)
		local PKG_TAG=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease == $PKG_MARK)) | first | .tag_name")

		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")
		local OLD_URL=$(grep -Po "PKG_SOURCE_URL:=\K.*" "$PKG_FILE")
		local OLD_FILE=$(grep -Po "PKG_SOURCE:=\K.*" "$PKG_FILE")
		local OLD_HASH=$(grep -Po "PKG_HASH:=\K.*" "$PKG_FILE")

		local PKG_URL=$([[ "$OLD_URL" == *"releases"* ]] && echo "${OLD_URL%/}/$OLD_FILE" || echo "${OLD_URL%/}")

		local NEW_VER=$(echo $PKG_TAG | sed -E 's/[^0-9]+/\./g; s/^\.|\.$//g')
		local NEW_URL=$(echo $PKG_URL | sed "s/\$(PKG_VERSION)/$NEW_VER/g; s/\$(PKG_NAME)/$PKG_NAME/g")
		local NEW_HASH=$(curl -sL "$NEW_URL" | sha256sum | cut -d ' ' -f 1)

		echo "old version: $OLD_VER $OLD_HASH"
		echo "new version: $NEW_VER $NEW_HASH"

		if [[ "$NEW_VER" =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
			echo "$PKG_FILE version has been updated!"
		else
			echo "$PKG_FILE version is already the latest!"
		fi
	done
}

#UPDATE_VERSION "软件包名" "测试版，true，可选，默认为否"
UPDATE_VERSION "sing-box"

#引入私有扩展脚本
if [ -f "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh" ]; then
	source "$GITHUB_WORKSPACE/Scripts/PRIVATE.sh"
fi
