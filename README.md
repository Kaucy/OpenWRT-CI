# OpenWRT-CI

官方版：

https://github.com/immortalwrt/immortalwrt.git

自用版（[LibWrt](https://github.com/LiBwrt/LibWrt) Fork）：

https://github.com/Kaucy/LibWrt.git

# U-BOOT

高通版-沉心：

https://github.com/chenxin527/uboot-ipq60xx-emmc-build.git

https://github.com/chenxin527/uboot-ipq60xx-nand-build.git

https://github.com/chenxin527/uboot-ipq60xx-nor-build.git

高通版-小猪：

https://github.com/1980490718/u-boot-2016.git

联发科-全新版：

https://github.com/VIKINGYFY/UBOOT-CI/releases

联发科-官方版：

https://drive.wrt.moe/uboot/mediatek

# 固件简要说明

固件每天早上5点自动编译。

固件信息里的时间为编译开始的时间，方便核对上游源码提交时间。

MEDIATEK系列、QUALCOMMAX系列、ROCKCHIP系列、X86系列。

# 目录简要说明

workflows——自定义CI配置

Scripts——自定义脚本

Config——自定义配置


# QCA-IPQ60XX-USB

该工作流使用 `Kaucy/LibWrt` 的 `main-nss` 分支，启用 NSS、USB 主控以及 RNDIS、ECM、EEM、NCM、MBIM、QMI 等 USB 网络接入支持。默认主题为 Argon，主机名为 `YKWRT`，管理地址为 `192.168.88.1`，账号/密码为 `root` / `password`。DHCP 地址池随 LAN 网段生效，默认从 `192.168.88.100` 开始。

雅典娜屏幕控制包只加入 `jdcloud_re-cs-02` 的设备镜像；同一次多设备编译产生的其他固件不会包含该包。屏幕默认启用，仅显示闪烁冒号的 `小时:分钟`。

APK 源会在 CI 生成 `distfeeds.list` 后逐项检查 USTC 镜像；USTC 存在对应 `packages.adb` 时才替换，缺失或暂时不可访问的仓库继续使用 ImmortalWrt 官方源。当前 USTC 的 ImmortalWrt snapshots 目录可能尚未同步，因此不会盲目替换为 404 地址。

## 设备型号对照表

| 固件设备名 | 产品型号/名称 |
| --- | --- |
| `8devices_mango-dvk` | 8devices Mango-DVK |
| `alfa-network_ap120c-ax` | ALFA Network AP120C-AX |
| `cambiumnetworks_xe3-4` | Cambium Networks XE3-4 |
| `glinet_gl-ax1800` | GL.iNet GL-AX1800 (Flint) |
| `glinet_gl-axt1800` | GL.iNet GL-AXT1800 (Slate AX) |
| `jdcloud_re-cs-02` | 京东云雅典娜 AX6600 (RE-CS-02) |
| `jdcloud_re-cs-07` | 京东云 RE-CS-07 |
| `jdcloud_re-ss-01` | 京东云亚瑟 AX1800 Pro (RE-SS-01) |
| `kt_ar06-012h` | KT AR06-012H |
| `lg_gapd-7500` | LG GAPD-7500 |
| `link_nn6000-v1` | LiNK NN6000 V1 |
| `link_nn6000-v2` | LiNK NN6000 V2 |
| `linksys_mr7350` | Linksys MR7350 |
| `linksys_mr7500` | Linksys MR7500 |
| `qihoo_360v6` | 360 V6 |
| `yuncore_fap650` | YunCore FAP650 |
