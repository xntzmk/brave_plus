# Brave++ —— Chrome++ 的 Brave Origin 适配版

把 [Chrome++](https://github.com/Bush2021/chrome_plus)（GPL-3.0）移植到 **Brave Origin** 上的版本。
不是新写的浏览器补丁：仍然走 `version.dll` 劫持 + Detours + UI Automation，只改了两处适配。

- 基于上游 **1.18.3**（commit `6cef3cb`）
- 实测环境：Brave Origin 156.1.98.63 / Windows 11 26340

## 功能

| 功能 | 说明 |
|---|---|
| 右键关闭标签 | 右键点标签即关；`Shift+右键` 保留原生菜单 |
| 双击关闭标签 | 双击标签关闭 |
| 滚轮切标签 | 鼠标在标签栏滚动切换 |
| 按住右键滚轮 | 在页面任意位置按住右键滚动切标签 |
| 保留最后标签 | 最后一个标签不是新标签页时，先开一个新标签页再关旧的，窗口保留 |
| 最后一个标签是新标签页 | 直接关闭窗口（本移植新增的行为） |
| 切标签快捷键 | `[tabs] prev_tab_key` / `next_tab_key` 可配置，默认 `,` / `.` |

## 安装

1. 完全退出 Brave；
2. 以管理员身份运行 `install.bat`（自动找 Brave 目录、备份旧文件、复制 `version.dll` + `chrome++.ini`）；
3. 启动 Brave。

卸载：退出 Brave，管理员运行 `uninstall.bat`（会还原 `.bak`）。或手动删掉
`...\BraveSoftware\Brave-Origin\Application\version.dll` 和 `chrome++.ini`。

## 配置（chrome++.ini）

```ini
[general]
data_dir=none          ; 必须保留，否则会启用便携目录、丢掉原 profile
cache_dir=none

[tabs]
right_click_close=1
double_click_close=1
keep_last_tab=1
wheel_tab=1
wheel_tab_when_press_rbutton=1

prev_tab_key=,         ; 上一个标签 (command 34017)
next_tab_key=.         ; 下一个标签 (command 34016)
```

⚠️ `prev_tab_key` / `next_tab_key` 是**裸键全局拦截**，不判断焦点：设成 `,` `.` 之后，
浏览器里任何地方（地址栏、网页输入框）按这两个键都会被切换标签，**打不出逗号和点号**。
想保留打字就把值改成带修饰键的写法，例如 `Alt+,` / `Alt+.`，改完重启 Brave 即可，无需重编译。

## 和上游的差异

| 文件 | 改动 |
|---|---|
| `src/uia.cc` | UIA 类名映射 Chrome → Brave（`BraveTab` / `BraveTabContainer` / `BraveTabStrip` / `BraveVerticalTabStripRegionView` / `BraveHorizontalTabStripRegionView` / `BraveBrowserView` / `VerticalTabNewTabButton`） |
| `src/tabbookmark.cc` | 最后一个标签是新标签页时直接关窗口，而不是替换成新标签页 |
| `src/utils.cc` | 新增 `lbracket` / `rbracket` / `oem4` / `oem6` 按键别名（`[` 不能写在 INI 行首） |
| `src/config.*`、`src/keymapping.cc` | 新增 `[tabs] prev_tab_key` / `next_tab_key` 配置项 |

## 已知限制

- 只适配 Brave 的**垂直标签栏**结构；横向标签栏未实测。
- 依赖 Brave 的控件类名，Brave 大版本更新后可能失效（重新核对 UIA 类名即可）。
- 与鼠标手势软件可能冲突（上游已知限制，`wheel_tab_when_press_rbutton`）。
- 无签名的 `version.dll` 劫持可能被 SmartScreen / 杀软误报，请核对 Release 里的 SHA256。

## 构建

需要 VS 2022 Build Tools（C++ 工作负载，含 CMake/Ninja）：

```bat
git submodule update --init
build.cmd vs x64 release
```

产物：`out\x64\release\version.dll`。
打包发布：`pwsh brave\pack.ps1 -Version 1.18.3-brave.1`（生成带 SHA256 的 zip）。

## 许可

GPL-3.0，与上游一致。源码即本仓库；分发二进制请保留本仓库地址。
本项目与 Brave Software 无关，属非官方移植。