[English](README.md) | [简体中文](README_zh.md)

<h2 align="center">NodePulse</h2>

<div align="center">
  <img alt="lang" src="https://img.shields.io/badge/language-Dart%20%7C%20Kotlin-blue">
  <img alt="framework" src="https://img.shields.io/badge/framework-Flutter-cyan">
  <img alt="platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Linux%20%7C%20Windows-green">
  <img alt="license" src="https://img.shields.io/badge/license-AGPLv3-yellow">
</div>

<p align="center">
专为 <b><a href="https://github.com/vaxilu/x-ui">CF-Server-Monitor</a></b>（基于 Cloudflare Workers 的无服务器探针）定制的现代轻量跨平台客户端与 Android 原生桌面小组件。
</p>

---

## ✨ 核心特性

- ⚡ **专一且轻量**：精简了庞杂的 SSH、本地脚本和终端依赖，开箱直连 CF-Server-Monitor 接口（`/api/servers`、`/api/history` 与实时 WebSocket 推送），秒级响应。
- 📱 **Android 4x2 原生桌面小组件 (AppWidgets)**：
  - **读数胶囊模式**：8 格精美胶囊网格，聚合 CPU、内存、硬盘、上下行网速、月度流量以及三网网络诊断。
  - **图表走势模式**：2x2 多维指标历史折线走势，桌面随时掌握负载动态。
  - **三网深度监控**：完整支持中国电信、中国联通、中国移动三网独立 Ping 延迟与丢包率解析及展示。
- 🎨 **Monochrome Minimal 极致极简设计**：
  - 模块化 2x2 信息卡片（实时速率、月度流量、三网网络/丢包、系统运行状态）。
  - 等宽数字排版（`FontFeature.tabularFigures()`），信息对齐工整，字重反差层次分明。
  - 负载自适应颜色条（正常绿色 / 警戒橙色 / 过载红色）。
- 📊 **智能分层与同心圆图表**：解决三网丢包率同为 0.0% 时点位互相重叠遮挡的痛点，采用分级同心圆与阶梯线宽呈现。
- 🔄 **WebSocket 长连接实时刷新**：内置心跳保活机制与断线指数退避重连算法。

---

## 🚀 快速开始

### 开发环境要求
- Flutter SDK `>=3.3.0`
- Android SDK (用于编译 Android 客户端与桌面微件)

### 构建与运行

```bash
# 克隆仓库
git clone https://github.com/jimiha1/cf_server_box.git
cd cf_server_box

# 安装 Flutter 依赖
flutter pub get

# 在连接的真机或模拟器上运行
flutter run

# 编译 Android Release APK
flutter build apk --release
```

---

## 🛠️ 配置说明

1. 启动 **CF ServerBox** 应用；
2. 进入 **设置** -> **CF 探针监控**；
3. 填写您的 CF-Server-Monitor 服务地址（例如：`https://monitor.yourdomain.com`）；
4. 若探针开启了登录鉴权，请输入对应管理员凭证或 API Token；
5. 在手机桌面上长按添加 **4x2 尺寸微件**，选择目标服务器及展示模式（胶囊读数/走势图表）即可。

---

## 📄 开源许可

本项目遵循 GNU Affero General Public License v3.0 (AGPLv3) 开源协议。
