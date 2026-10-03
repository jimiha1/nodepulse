# WSL 2 安装 Debian 13 (Trixie) 到 D 盘设计规范

## 1. 概述与目标

在 Windows 宿主机上通过 WSL 2 将 Debian 13 (Trixie) 发行版直接部署在 D 盘（物理路径 `D:\WSL\Debian13\`），不经过 C 盘中转或占用系统盘空间，配置 systemd 支持、普通用户及国内镜像源加速。

## 2. 软硬件环境与现状

- **宿主系统**：Windows 10.0.19045 x64，已具备 WSL 2 环境。
- **磁盘状态**：D 盘剩余可用空间 ~131.5 GB，空间充裕。
- **WSL 当前状态**：已启用 WSL 功能，当前未安装发行版。

## 3. 部署架构与路径规则

| 项目 | 目标路径/参数 | 说明 |
| :--- | :--- | :--- |
| **WSL 发行版名称** | `Debian13` | 在 `wsl -l -v` 中登记的唯一分发名称 |
| **安装目录 (VHDX)** | `D:\WSL\Debian13` | 存放 `ext4.vhdx` 虚拟磁盘镜像文件 |
| **临时下载目录** | `D:\WSL\temp` | 存放下载的 rootfs 压缩包，导入后清理 |
| **WSL 版本** | WSL 2 | 完整 Linux 内核与虚拟化支持 |

## 4. 实施流程

### 阶段一：准备目录与获取 rootfs 镜像
1. 创建目录 `D:\WSL\Debian13` 和 `D:\WSL\temp`。
2. 下载 Debian 官方云镜像/LXC 根文件系统压缩包（rootfs tarball）：
   - 源地址优先使用国内高速镜像源（如清华/中科大/网易镜像源中提供的 Debian minbase / rootfs tarball）。
   - 下载至 `D:\WSL\temp\debian-rootfs.tar.xz` 或解压为 `.tar`。

### 阶段二：通过 WSL 2 导入至 D 盘
1. 使用 PowerShell 执行无侵入导入命令：
   ```powershell
   wsl --import Debian13 D:\WSL\Debian13 D:\WSL\temp\debian-rootfs.tar --version 2
   ```
2. 验证实例状态：
   ```powershell
   wsl -l -v
   ```
   确认 `Debian13` 处于 Stopped 状态且 VERSION 为 2。
3. 清理 `D:\WSL\temp` 临时下载文件以释放空间。

### 阶段三：配置 Debian 13 (Trixie) 镜像源与系统升级
1. 进入系统（root 身份）：
   ```powershell
   wsl -d Debian13 -u root
   ```
2. 配置 `/etc/apt/sources.list` 或 `/etc/apt/sources.list.d/debian.sources`，指定 `trixie` 软件源（清华大学镜像源）：
   ```sources.list
   deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie main contrib non-free non-free-firmware
   deb https://mirrors.tuna.tsinghua.edu.cn/debian/ trixie-updates main contrib non-free non-free-firmware
   deb https://mirrors.tuna.tsinghua.edu.cn/debian-security trixie-security main contrib non-free non-free-firmware
   ```
3. 更新索引并执行完整发行版升级：
   ```bash
   apt-get update
   apt-get dist-upgrade -y
   ```

### 阶段四：用户权限、基础组件与 WSL 特性配置
1. 安装关键基础组件：
   ```bash
   apt-get install -y sudo curl wget git ca-certificates locales procps
   ```
2. 配置系统区域设置（生成 `en_US.UTF-8` 及 `zh_CN.UTF-8`）。
3. 创建普通用户（默认同宿主用户名或指定用户名），赋予 `sudo` 组权限并设置密码。
4. 编写 `/etc/wsl.conf`：
   ```ini
   [boot]
   systemd = true

   [user]
   default = <普通用户名>

   [interop]
   enabled = true
   appendWindowsPath = true
   ```
5. 退出实例并在 Windows 端执行 `wsl --terminate Debian13` 重启生效。

## 5. 验收标准

1. `wsl -l -v` 显示 `Debian13` 实例正常注册且为 Version 2。
2. 物理文件 `D:\WSL\Debian13\ext4.vhdx` 存在，C 盘空间未增加大文件。
3. 执行 `wsl -d Debian13`：
   - 默认以非 root 用户登录并位于该用户的 home 目录。
   - `cat /etc/os-release` 确认 `VERSION_ID` 或 `VERSION_CODENAME` 为 `trixie` (Debian 13)。
   - `sudo systemctl status` 确认 systemd 正常运行。
