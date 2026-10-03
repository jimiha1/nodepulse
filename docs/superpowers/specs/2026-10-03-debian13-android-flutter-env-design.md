# Debian 13 (WSL) Android 与 Flutter 开发环境配置设计规范

## 1. 概述与目标

在已部署于 D 盘的 WSL 2 `Debian13` 系统内，为用户 `dev` 搭建完整的 Android CLI 与 Flutter SDK 开发环境。使之具备直接编译当前项目及其他 Android/Flutter 应用的能力，且工具链版本与当前项目配置（Android Compile SDK 36、Build-tools 36.1.0、Java 17）对齐。

## 2. 软件与路径规划

| 组件 | 版本/分支 | 安装路径 |
| :--- | :--- | :--- |
| **JDK** | OpenJDK 17 | `/usr/lib/jvm/java-17-openjdk-amd64` |
| **Android SDK Root** | API 36, Build-Tools 36.1.0 | `/home/dev/android-sdk` |
| **Android Cmdline-tools** | latest (v11076708+) | `/home/dev/android-sdk/cmdline-tools/latest` |
| **Android Platform Tools** | latest (adb/fastboot) | `/home/dev/android-sdk/platform-tools` |
| **Flutter SDK** | stable | `/home/dev/development/flutter` |

## 3. 详细配置步骤

### 阶段一：系统依赖与 Java 运行时
1. 使用 `apt-get` 安装基础构建工具与 OpenJDK 17：
   ```bash
   apt-get install -y openjdk-17-jdk unzip zip curl wget git clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
   ```
2. 验证 `java -version` 确认版本为 17.x。

### 阶段二：配置 Android 命令行工具与 SDK
1. 下载 Android `commandlinetools-linux` 官方压缩包至临时目录并解压到 `/home/dev/android-sdk/cmdline-tools/latest`。
2. 设定基础环境变量并调用 `sdkmanager` 安装核心组件：
   ```bash
   sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.1.0"
   ```
3. 自动接受所有 SDK 协议：
   ```bash
   yes | sdkmanager --licenses
   ```

### 阶段三：配置 Flutter SDK 与国内镜像源
1. 配置国内镜像源环境变量以加速资源下载：
   ```bash
   export PUB_HOSTED_URL=https://pub.flutter-io.cn
   export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
   ```
2. 克隆 Flutter 官方 stable 分支到 `/home/dev/development/flutter`。
3. 关联 Android SDK 并授权协议：
   ```bash
   flutter config --android-sdk /home/dev/android-sdk
   yes | flutter doctor --android-licenses
   ```

### 阶段四：全局环境变量持久化
在 `/home/dev/.bashrc` 及 `/etc/profile.d/android-flutter.sh` 中持久化以下环境变量：
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=/home/dev/android-sdk
export ANDROID_SDK_ROOT=/home/dev/android-sdk
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

export PATH=$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/36.1.0:/home/dev/development/flutter/bin:$PATH
```

## 4. 验收标准

1. `java -version` 确认 OpenJDK 17 可用。
2. `adb version` 显示 platform-tools 版本。
3. `sdkmanager --list_installed` 包含 `platforms;android-36` 及 `build-tools;36.1.0`。
4. `flutter doctor -v` 显示 Android 工具链为绿色勾选（Java binary, Android SDK, Android licenses 全部通过）。
