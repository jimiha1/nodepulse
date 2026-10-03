# 2026-10-03 CF Server Card Redesign Specification

## 1. Background & Goals
The current ServerBox app's server status card (`CfServerCard` in `lib/view/page/server/cf_card.dart`) displays raw metrics in plain text rows with uneven wrap spacing. The presentation lacks visual hierarchy, lacks graphical progress feedback for resources, and omits the recently added packet loss rate (`loss_ct`, `loss_cu`, `loss_cm`).

This specification outlines the redesign of `CfServerCard` into a modern layered dashboard layout (Approach 1: Modern Layered Dashboard) with:
- Clear 3-tier hierarchy: Header, Resource Progress Gauges, and Structured Metrics Panel.
- Colored linear progress indicators for CPU, Memory, and Disk usage.
- Standardized Chinese telecom labels (`电信`, `联通`, `移动`) for both ping latency and packet loss.
- High visual cohesion across both Light and Dark (AMOLED) modes.

## 2. Component Architecture & Visual Layout

### 2.1 Header Section
- **Status Indicator**: 8dp circle (green `#34C759` for online, grey for offline).
- **Server Name**: Bold 15sp text (`UIs.text15Bold`), single line with ellipsis.
- **Region Badge**: Rounded container (4dp radius) with 2-letter uppercase region code (e.g. `JP`), using `colorScheme.secondaryContainer`.
- **Group Tag**: Secondary muted text with group name if present.
- **OS & Uptime**: OS distribution icon (`distIconOf`) + formatted uptime (e.g. `14d 6h`) aligned to the trailing edge.

### 2.2 Resource Progress Gauges (CPU / Memory / Disk)
3 standardized vertical rows with fixed label and percentage columns followed by a colored linear progress bar and detail text:
- **CPU Row**:
  - Label: `CPU` (fixed width 42dp, 12sp grey)
  - Percent: `XX.X%` (fixed width 52dp, 13sp bold)
  - Progress Bar: Height 5dp, rounded corners (radius 2.5dp). Track color `Colors.grey.withValues(alpha: 0.15)`. Bar color: `<60%` `#34C759` (green), `60%~85%` `#FF9F0A` (orange), `>85%` `#FF3B30` (red).
  - Detail: Core count (e.g. `4核` or `x4`).
- **Memory Row**:
  - Label: `内存` (12sp grey)
  - Percent: `XX.X%` (13sp bold)
  - Progress Bar: `#0A84FF` (system blue).
  - Detail: Used / Total (e.g. `3.6 GB / 8.0 GB`).
- **Disk Row**:
  - Label: `磁盘` (12sp grey)
  - Percent: `XX.X%` (13sp bold)
  - Progress Bar: `#FF9F0A` (amber orange).
  - Detail: Used / Total (e.g. `62.0 GB / 100 GB`).

### 2.3 Metrics Grid Panel
Sub-panel enclosed with subtle background padding or clean vertical spacing:
1. **Network Bandwidth & Traffic Quota**:
   - Real-time: `↓ {inSpeed}/s  ↑ {outSpeed}/s` with custom colored icons/arrows.
   - Monthly Traffic: `↓ {rxMonthly}  ↑ {txMonthly}` or `{used} / {quota} ({usedRatio}%)`.
2. **Tri-Network Latency (三网延迟)**:
   - `电信 {ms}ms  |  联通 {ms}ms  |  移动 {ms}ms` (omitted if unconfigured/null).
3. **Tri-Network Packet Loss (三网丢包率)**:
   - `丢包: 电信 {loss}%  |  联通 {loss}%  |  移动 {loss}%` (colored red if loss > 0%).
4. **System Diagnostics & Expiry**:
   - `负载: {load1} {load5}  |  TCP: {tcp}  UDP: {udp}`.
   - `到期: {expireDate}` (if configured and `showExpire` is true).

## 3. Data Flow & Testing
- Source models: `CfServer` (`lib/data/model/cf/cf_server.dart`).
- Existing unit tests in `test/unit/server/cf/cf_card_test.dart` will be updated to reflect the enriched widget structure and assert presence of progress indicators and packet loss metrics.
