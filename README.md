# ProxySwitcher-ng 中文界面

给 [ProxySwitcher-ng](https://github.com/ymuuuu/proxyswitcher-ng) 增加简体中文界面的小插件。

## 原理

ProxySwitcher-ng 本身没有做本地化（文字硬编码在二进制里）。本插件不改原插件，
而是在运行时注入「设置 → ProxySwitcher-ng」，把界面上的英文替换成中文。

词库在 `/var/jb/usr/share/proxyswitcherng-zh/zh.json`，可以直接编辑，改完 respring 生效。

## 安装

1. 下载 Actions 生成的 `com.codex.proxyswitcherngzh_*_iphoneos-arm64.deb`
2. 用 Sileo / Filza 安装，或 SSH 执行 `dpkg -i xxx.deb`
3. Respring 一次

## 说明

- 依赖 `io.ymuu.proxyswitcherng`
- 只翻译 ProxySwitcher-ng 自身的界面，不影响设置里的其他页面
- 这是运行时翻译，极少数动态拼接的文字可能仍是英文
