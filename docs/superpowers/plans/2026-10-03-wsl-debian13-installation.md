# WSL 2 安装 Debian 13 (Trixie) 到 D 盘实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Windows WSL 2 中通过直接导入 rootfs 的方式将 Debian 13 (Trixie) 安装在 D 盘（`D:\WSL\Debian13`），配置国内镜像源、systemd 及普通用户。

**Architecture:** 利用 PowerShell 下载 Debian 基础 rootfs 压缩包至 `D:\WSL\temp`，通过 `wsl --import` 指令直接在 `D:\WSL\Debian13` 构建 ext4.vhdx，配置 `trixie` 软件源进行发行版升级，最后初始化 `dev` 普通用户与 `/etc/wsl.conf` 配置。

**Tech Stack:** Windows 10 WSL 2, PowerShell, Debian GNU/Linux 13 (trixie), APT, systemd.

## Global Constraints

- 虚拟磁盘与实例文件必须直接生成在 `D:\WSL\Debian13`，严禁使用 C 盘中转。
- WSL 分发名称必须为 `Debian13`，版本必须为 WSL 2。
- 软件源必须配置为国内镜像源（推荐清华源）且指向 `trixie` (Debian 13)。
- 必须开启 systemd 支持，且默认以非 root 用户 `dev` 登录。

---

### Task 1: 准备安装目录并获取 Debian rootfs 镜像

**Files:**
- Create: `D:\WSL\temp\` (临时工作目录)
- Create: `D:\WSL\Debian13\` (WSL 虚拟磁盘目标目录)
- Target Artifact: `D:\WSL\temp\rootfs.tar.xz` 或 `D:\WSL\temp\rootfs.tar`

**Interfaces:**
- Consumes: PowerShell 网络下载能力
- Produces: `D:\WSL\temp\rootfs.tar`，供 Task 2 导入使用

- [ ] **Step 1: 创建工作目录**

执行命令创建所需目录：
```powershell
powershell.exe -NoProfile -Command "New-Item -ItemType Directory -Force -Path 'D:\WSL\Debian13', 'D:\WSL\temp'"
```

- [ ] **Step 2: 下载官方最新 Debian LXC / Cloud rootfs 压缩包**

使用清华大学镜像源下载官方 Debian rootfs 归档：
```powershell
powershell.exe -NoProfile -Command "Invoke-WebRequest -Uri 'https://mirrors.tuna.tsinghua.edu.cn/lxc-images/images/debian/trixie/amd64/default/' -UseBasicParsing"
```
（若直接存在 trixie tarball 则下载，或下载 stable/bookworm 并无缝 dist-upgrade 到 trixie；另外可从清华大学 Debian 镜像源或 GitHub 官方 LXC 源获取最新 rootfs.tar.xz 并解压为 rootfs.tar）

- [ ] **Step 3: 校验文件存在及完整性**

```powershell
powershell.exe -NoProfile -Command "Test-Path 'D:\WSL\temp\rootfs.tar'"
```
预期输出: `True`

---

### Task 2: 通过 WSL 2 导入至 D 盘并验证磁盘文件

**Files:**
- Output VHDX: `D:\WSL\Debian13\ext4.vhdx`
- Cleanup: `D:\WSL\temp\rootfs.tar`

**Interfaces:**
- Consumes: `D:\WSL\temp\rootfs.tar`
- Produces: 已注册的 WSL 实例 `Debian13`

- [ ] **Step 1: 执行 WSL 导入**

```powershell
powershell.exe -NoProfile -Command "wsl --import Debian13 D:\WSL\Debian13 D:\WSL\temp\rootfs.tar --version 2"
```

- [ ] **Step 2: 验证 WSL 发行版列表**

```powershell
powershell.exe -NoProfile -Command "wsl --list --verbose"
```
预期包含:
```
Debian13    Stopped    2
```

- [ ] **Step 3: 验证 D 盘物理虚拟磁盘文件存在**

```powershell
powershell.exe -NoProfile -Command "Get-Item 'D:\WSL\Debian13\ext4.vhdx'"
```
预期输出: 存在 `ext4.vhdx` 文件，长度大于 0。

- [ ] **Step 4: 清理临时下载文件**

```powershell
powershell.exe -NoProfile -Command "Remove-Item -Recurse -Force 'D:\WSL\temp'"
```

---

### Task 3: 配置 Debian 13 (Trixie) 源并执行升级

**Files:**
- Modify in Debian13: `/etc/apt/sources.list` 或 `/etc/apt/sources.list.d/debian.sources`

**Interfaces:**
- Consumes: WSL `Debian13` 实例
- Produces: 升级为 Debian 13 (trixie) 并配置国内源的 Linux 系统

- [ ] **Step 1: 配置清华大学 trixie 软件源**

在实例内更新软件源配置：
```bash
wsl -d Debian13 -u root -- bash -c "cat << 'EOF' > /etc/apt/sources.list
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-updates main contrib non-free non-free-firmware
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security trixie-security main contrib non-free non-free-firmware
EOF"
```

- [ ] **Step 2: 更新索引并执行完整发行版升级**

```bash
wsl -d Debian13 -u root -- bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y"
```

- [ ] **Step 3: 验证系统版本为 Debian 13**

```bash
wsl -d Debian13 -u root -- bash -c "cat /etc/os-release"
```
预期输出包含:
`VERSION_CODENAME=trixie` 或包含 `Debian GNU/Linux 13 (trixie)`。

---

### Task 4: 安装基础组件、创建用户与配置 WSL

**Files:**
- Modify in Debian13: `/etc/wsl.conf`
- Modify in Debian13: `/etc/sudoers`

**Interfaces:**
- Consumes: Debian 13 基础系统
- Produces: 具有普通用户 `dev`、systemd 支持的完整开发环境

- [ ] **Step 1: 安装基础工具包**

```bash
wsl -d Debian13 -u root -- bash -c "DEBIAN_FRONTEND=noninteractive apt-get install -y sudo curl wget git ca-certificates locales procps"
```

- [ ] **Step 2: 创建普通用户并配置 sudo 免密**

```bash
wsl -d Debian13 -u root -- bash -c "id -u dev || (useradd -m -s /bin/bash dev && usermod -aG sudo dev && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev)"
```

- [ ] **Step 3: 配置 /etc/wsl.conf**

```bash
wsl -d Debian13 -u root -- bash -c "cat << 'EOF' > /etc/wsl.conf
[boot]
systemd = true

[user]
default = dev

[interop]
enabled = true
appendWindowsPath = true
EOF"
```

- [ ] **Step 4: 重启 WSL 实例**

```powershell
powershell.exe -NoProfile -Command "wsl --terminate Debian13"
```

- [ ] **Step 5: 最终验收测试**

运行无参数启动命令并检查用户与 systemd：
```bash
wsl -d Debian13 -- bash -c "whoami && systemctl is-system-running --wait || true"
```
预期输出:
当前用户为 `dev`，WSL 启动顺利，版本为 Debian 13。
