[English](README.md) | [简体中文](README_zh.md)

<h2 align="center">CF ServerBox</h2>

<div align="center">
  <img alt="lang" src="https://img.shields.io/badge/language-Dart%20%7C%20Kotlin-blue">
  <img alt="framework" src="https://img.shields.io/badge/framework-Flutter-cyan">
  <img alt="platform" src="https://img.shields.io/badge/platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Linux%20%7C%20Windows-green">
  <img alt="license" src="https://img.shields.io/badge/license-AGPLv3-yellow">
</div>

<p align="center">
A modern, lightweight cross-platform client and Android Home Screen AppWidget dedicated to <b><a href="https://github.com/vaxilu/x-ui">CF-Server-Monitor</a></b> (Cloudflare Workers serverless monitor).
</p>

---

## ✨ Features

- ⚡ **Lightweight & Dedicated**: Refactored to communicate directly with CF-Server-Monitor (`/api/servers`, `/api/history`, WebSocket real-time updates) without bulky SSH or agent dependencies.
- 📱 **Android Home Screen AppWidgets (4x2)**:
  - **Reading Mode**: 8-cell capsule grid showing CPU, Memory, Disk, Speed, Traffic, tri-network latency & tri-network packet loss rate.
  - **Chart Mode**: 2x2 multi-series historical trend charts for real-time monitoring directly from your launcher.
  - **Tri-Network Diagnostics**: Specialized support for China Telecom (电信), China Unicom (联通), and China Mobile (移动) ping latency and loss rates.
- 🎨 **Monochrome Minimal Aesthetics**:
  - Modular 2x2 card layout: Realtime Bandwidth, Monthly Traffic, Tri-network Ping & Loss, and System Status.
  - Adaptive resource progress bars for quick load visual checks.
  - Aligned figures with `FontFeature.tabularFigures()`.
- 📊 **Staggered Multi-Series Graphs**: Smart concentric circle dots and tiered line strokes ensuring 0.0% coincident packet loss points remain completely distinguishable.
- 🔄 **WebSocket Low-Latency Sync**: Live metric updates via WebSocket with automatic exponential backoff reconnection.

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK `>=3.3.0`
- Android SDK (for Android build and AppWidget functionality)

### Build & Run

```bash
# Clone the repository
git clone https://github.com/jimiha1/cf_server_box.git
cd cf_server_box

# Install Flutter dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK for Android
flutter build apk --release
```

---

## 🛠️ Configuration

1. Launch **CF ServerBox**.
2. Go to **Settings** -> **Cloudflare Server Monitor**.
3. Enter your deployed CF-Server-Monitor URL (e.g. `https://monitor.yourdomain.com`).
4. If your monitor has admin authentication enabled, enter your credentials or API token.
5. Add the **4x2 Widget** on your Android home screen and choose your preferred server node and display mode.

---

## 📄 License

This project is licensed under the terms of the GNU Affero General Public License v3.0 (AGPLv3).
