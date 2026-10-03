# Debian 13 Android 与 Flutter 开发环境配置实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 WSL 2 `Debian13` 发行版中为用户 `dev` 部署完整的 Android SDK 命令行工具链、OpenJDK 17、Flutter SDK 以及相关的系统开发依赖与环境变量。

**Architecture:** 通过 apt 安装构建基础依赖与 OpenJDK 17；下载 Google 官方 commandlinetools 并借助 sdkmanager 安装 platform-tools、platforms;android-36、build-tools;36.1.0；克隆并配置配置国内镜像的 Flutter SDK，并在 profile 中统一持久化环境变量。

**Tech Stack:** WSL 2 Debian 13 (Trixie), OpenJDK 17, Android SDK (cmdline-tools 11076708, platform-tools, API 36, build-tools 36.1.0), Flutter SDK (stable).

## Global Constraints

- 所有用户级 SDK 工具安装在 `/home/dev` 目录下（`android-sdk` 与 `development/flutter`）。
- Android SDK 必须包含 `platforms;android-36` 与 `build-tools;36.1.0`（与工程配置严格对齐）。
- 必须预先完成 SDK 协议的自动签署 (`sdkmanager --licenses` 与 `flutter doctor --android-licenses`)。
- 环境变量必须在 `/etc/profile.d/android-flutter.sh` 与 `~/.bashrc` 中持久化，确保交互式与非交互式 shell 均生效。

---

### Task 1: 安装系统构建依赖与 OpenJDK 17

**Files:**
- Modify in Debian13: APT packages installation

**Interfaces:**
- Consumes: Debian 13 网络连接与清华 apt 源
- Produces: `java` (OpenJDK 17), `unzip`, `zip`, `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, `liblzma-dev`

- [ ] **Step 1: 安装基础软件包**

```bash
wsl -d Debian13 -u root -- bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jdk unzip zip curl wget git clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev"
```

- [ ] **Step 2: 验证 Java 版本与安装路径**

```bash
wsl -d Debian13 -- bash -c "java -version && which java"
```
预期输出: 包含 `openjdk version "17.`。

---

### Task 2: 安装配置 Android Command-line Tools 与核心组件

**Files:**
- Create in Debian13: `/home/dev/android-sdk/`
- Target path: `/home/dev/android-sdk/cmdline-tools/latest/bin/sdkmanager`
- Target components: `platform-tools`, `platforms;android-36`, `build-tools;36.1.0`

**Interfaces:**
- Consumes: OpenJDK 17
- Produces: 可用的 `sdkmanager`, `adb`, `aapt` 及 Android 36 SDK 库

- [ ] **Step 1: 下载并解压 Android cmdline-tools**

```bash
wsl -d Debian13 -u dev -- bash -c "mkdir -p ~/android-sdk/cmdline-tools && cd /tmp && curl -o commandlinetools.zip -L https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip && unzip -q commandlinetools.zip && rm -rf ~/android-sdk/cmdline-tools/latest && mv cmdline-tools ~/android-sdk/cmdline-tools/latest && rm -f commandlinetools.zip"
```

- [ ] **Step 2: 使用 sdkmanager 安装 SDK 组件并自动签署协议**

```bash
wsl -d Debian13 -u dev -- bash -c "export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 && export ANDROID_HOME=$HOME/android-sdk && yes | $HOME/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses && $HOME/android-sdk/cmdline-tools/latest/bin/sdkmanager --install 'platform-tools' 'platforms;android-36' 'build-tools;36.1.0'"
```

- [ ] **Step 3: 验证 SDK 组件安装情况**

```bash
wsl -d Debian13 -u dev -- bash -c "export ANDROID_HOME=$HOME/android-sdk && $HOME/android-sdk/cmdline-tools/latest/bin/sdkmanager --list_installed"
```
预期输出包含:
- `build-tools;36.1.0`
- `platform-tools`
- `platforms;android-36`

---

### Task 3: 安装与配置 Flutter SDK

**Files:**
- Create in Debian13: `/home/dev/development/flutter`

**Interfaces:**
- Consumes: git, curl, Android SDK
- Produces: `/home/dev/development/flutter/bin/flutter` 可执行环境

- [ ] **Step 1: 克隆 Flutter SDK stable 分支并设置国内镜像环境变量**

```bash
wsl -d Debian13 -u dev -- bash -c "mkdir -p ~/development && cd ~/development && if [ ! -d flutter ]; then git clone https://mirrors.tuna.tsinghua.edu.cn/git/flutter-sdk.git -b stable flutter || git clone https://github.com/flutter/flutter.git -b stable flutter; fi"
```

- [ ] **Step 2: 绑定 Android SDK 与接受 Flutter 协议**

```bash
wsl -d Debian13 -u dev -- bash -c "export PUB_HOSTED_URL=https://pub.flutter-io.cn && export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn && export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 && export ANDROID_HOME=$HOME/android-sdk && export PATH=$PATH:$HOME/development/flutter/bin && flutter config --android-sdk $HOME/android-sdk && yes | flutter doctor --android-licenses"
```

---

### Task 4: 配置持久化全局环境变量与全链路测试

**Files:**
- Create in Debian13: `/etc/profile.d/android-flutter.sh`
- Modify in Debian13: `/home/dev/.bashrc`

**Interfaces:**
- Consumes: Task 1, 2, 3 的安装路径
- Produces: 系统环境直接识别 `flutter`, `adb`, `sdkmanager`

- [ ] **Step 1: 写入持久化环境变量脚本**

```bash
wsl -d Debian13 -u root -- bash -c "cat << 'EOF' > /etc/profile.d/android-flutter.sh
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=/home/dev/android-sdk
export ANDROID_SDK_ROOT=/home/dev/android-sdk
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

export PATH=\$JAVA_HOME/bin:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools:\$ANDROID_HOME/build-tools/36.1.0:/home/dev/development/flutter/bin:\$PATH
EOF"
```
并在用户 `.bashrc` 追加保证交互式登录自动加载：
```bash
wsl -d Debian13 -u dev -- bash -c "grep -q 'android-flutter.sh' ~/.bashrc || echo 'source /etc/profile.d/android-flutter.sh' >> ~/.bashrc"
```

- [ ] **Step 2: 执行全链路验收检查 (flutter doctor)**

```bash
wsl -d Debian13 -u dev -- bash -lc "flutter doctor -v"
```
预期输出:
- `Flutter (Channel stable)` 正常检测
- `Android toolchain - develop for Android devices` 为绿色勾选 `[✓]` (SDK 36, build-tools 36.1.0, Java 17 全部合格)
