# Design: CF ServerBox Documentation & New Repo Release

## 1. Context & Motivation
The `flutter_server_box` codebase has been refocused and streamlined to serve as a dedicated, lightweight cross-platform client and Android home-screen widget system for **Cloudflare Workers Server Monitor** (`CF-Server-Monitor`).

Key enhancements made in this version:
- **Dedicated CF-Server-Monitor Client**: Tailored exclusively to the Cloudflare Workers backend (`/api/servers`, `/api/history`, WebSocket real-time updates).
- **Home Screen AppWidgets**: Android 4x2 widgets featuring Reading Mode (8 capsule metric grid) and Chart Mode (2x2 time-series charts), including Chinese tri-network latency and packet loss rates (电信 / 联通 / 移动).
- **Redesigned Server Card (Scheme C + Scheme 2 Typography)**: Modular 2x2 cards (Real-time Bandwidth, Monthly Traffic, Tri-network Ping/Loss, System Load & Connections), tabular aligned monospace figures, and load-adaptive progress bars.
- **Enhanced Data Visualization**: Staggered concentric markers in `chart.dart` preventing point overlap when packet loss is identically 0.0%, and split latency/loss charts.

The user wants to:
1. Re-generate a comprehensive `README.md` and `README_zh.md` accurately describing what this project is and how to use/build it.
2. Clean up temporary screenshot files and unneeded build artifacts.
3. Commit all recent changes with clean git history.
4. Create and push to a brand-new public GitHub repository: `https://github.com/jimiha1/cf_server_box`.

---

## 2. Deliverables & Specifications

### 2.1 Documentation (`README.md` & `README_zh.md`)
- **Title**: `CF ServerBox` (`cf_server_box`)
- **Badges**: Flutter, Dart, Android, License (AGPLv3)
- **Features Breakdown**:
  - 🌐 **Cloudflare Workers Native**: Low-cost, serverless server monitoring architecture.
  - 📱 **Android Desktop Widgets**: 4x2 rich capsule reading and multi-chart monitoring modes, tri-network latency & loss rates.
  - 🎨 **Monochrome Minimal UI**: Modern 2x2 modular blocks, high readability, load indicators.
  - ⚡ **WebSocket Real-time Synchronization**: Push updates without continuous polling overhead.
- **Quick Start & Build Instructions**:
  - `flutter pub get`
  - `flutter run` / `flutter build apk --release`
  - Android AppWidget configuration notes.

### 2.2 Repository Cleanup & Git Operations
- Clean up root-level test screenshots (`screenshot_*.png`, `phone_launch_screenshot.png`).
- Check and update `.gitignore` if needed to exclude local debug screencaps.
- Use `gh repo create cf_server_box --public --source=. --remote=origin-new --push` (or set up remote `origin` to `https://github.com/jimiha1/cf_server_box.git`).
- Push current branch to the new repository's `main` branch.

---

## 3. Verification & Acceptance Criteria
- `README.md` and `README_zh.md` render cleanly with correct formatting.
- `flutter analyze` passes with zero issues.
- `flutter test test/unit/server/cf/` passes (42/42 tests).
- New public repository `https://github.com/jimiha1/cf_server_box` is successfully created and has the latest commits.
