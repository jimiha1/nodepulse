# AGENTS.md

ServerBox (`flutter_server_box`): a Flutter app for managing Linux/Unix/Windows servers — status charts, SSH terminal, SFTP, Docker/process/service management, RDP/VNC over SSH — in a Rust workspace monorepo. Ships for iOS, macOS, Android, Linux and Windows. AGPLv3.

**Read root `CLAUDE.md` before any non-trivial change.** It carries the detailed notes this file only summarizes. Feature-specific `CLAUDE.md` files sit next to the code: `monitor/`, `crates/sbm_ffi/`, `ios/`, `macos/`, `android/`, `lib/data/store/`, `lib/data/model/file/` (SFTP), `lib/data/model/server/benchmark/`, `lib/core/service/`, `lib/view/page/server/monitor_settings/`, plus `docs/dev/virt.md`. `RETIREMENT.md` indexes pending data-migration retirements — read it before touching `SchemaVersion` or Hive shims.

## Commands (`make help` lists all)

- `make deps` → `make run`. **The app is usually already running from the user's IDE — do not start a second `flutter run`.** Apply changes through the dart MCP server (`dtd` → `listDtdUris` → `connect` → `hot_reload`; `hot_restart` for anything before `runApp`).
- `make analyze` — `flutter analyze lib test integration_test`.
- `make gen` — build_runner + `flutter gen-l10n`. A stale build cache **hangs** (0% CPU, no output) instead of failing: `make gen-build-clean`. A SIGKILLed run leaves `.dart_tool/build/lock/build_runner.lock` behind.
- `make test` / `make test-one TEST=test/unit/...` (both build `sbm_ffi` first). Use `--timeout 30s`. Rust: `cargo test --workspace`. Monitor panel: `cd monitor/frontend && npm run test && npm run check`.
- `make build PLATFORM=<android|ios|macos|linux|windows>`; `make monitor-dev` (API :3770, panel :3000).
- `test/unit/` is split by feature, not layer (`ssh/`, `terminal/`, `server/`, `virt/`, `store/`, `app/`, …).

## Hard rules

- **Never run code formatters.** Formatting is deliberate; match the style of the file you edit.
- Never hand-edit `*.g.dart` / `*.freezed.dart`. Run `make gen` after changing freezed/json_serializable/hive/riverpod-annotated models; `flutter gen-l10n` after ARB edits, and check `libL10n` (fl_lib) before adding a new string.
- Never run `flutter_rust_bridge_codegen integrate` (reformats every package and submodule). Run `generate` after changing `crates/sbm_ffi/src/api`; output is `lib/src/rust/`, do not edit. The `flutter_rust_bridge` version is pinned in both `pubspec.yaml` and `crates/sbm_ffi/Cargo.toml` and must equal the codegen version, or `RustLib.init` fails at launch.
- `packages/` entries are vendored Dart forks as git submodules (dartssh2, xterm, fl_lib, fl_build, flutter_pty, …): change them in the submodule and PR there. The Agent is `packages/fl_pi_llm` — its own Cargo workspace, shared with GPT Box; this app only hooks into it via `lib/core/llm/`.
- Commit messages: one lowercase prefix + imperative description, in English — `feat:`, `fix:`, `docs:`, `opt.:`, `rm:`, `refactor:`, `test:`, `chore:`, `migrate:`.

## Architecture boundaries

- `crates/sbm_parser/` — single source of truth for status parsing (used by the app via FFI and by the monitor). Parsers are pure and emit raw counters; rates and time series stay with the caller. Porting rule ("test as spec"): port a module's Dart fixture tests to Rust first; delete the Dart side only after the FFI result is asserted identical (`tests/dart_compat.rs`, `script_compat.rs`).
- `crates/sbm_ffi/` — FRB bindings; `crates/sbm_native/` — monitor-only native sampler (the app always collects remotely).
- `lib/`: `core/` utilities, `view/` pages and widgets, `data/{model,provider,store}/` (freezed models, Riverpod providers, stores), `src/rust/` generated, `hive/` legacy adapters kept only for `HiveImport`.
- A server is reached over SSH, a `monitor` agent's HTTP API, both, or is this device. **`ServerNotifier.ensureExec()` is the one place a command reaches a server**; **`ServerTcpDialer` (`lib/core/utils/server_tcp.dart`) is the one place a TCP connection is made**. Ask `ServerCapabilities`, never the transport type.
- Storage: one encrypted SQLite file; Drift owns the DDL only, queries are hand-written. **A schema step is three edits** (migration class, `SchemaVersion.current`, `kSchemaMigrations`); never regenerate a test fixture to make a test pass. Details: `lib/data/store/CLAUDE.md`.

## UI conventions

- GetIt for stores and services; use `fl_lib` widgets (`CustomAppBar`, `context.showRoundDialog`, `Input`, `Btnx.cancelOk`). Split UI into build / actions / utils with `extension on`.
- Dialog traps: `Btn.ok(onTap:)` must pop the dialog itself; `showRoundDialog` uses the root navigator, so `context.pop()` from a dialog closes the page — use `context.popDialog()`.
- A page embedding `SSHPage` inherits its `PopScope(canPop: false)`: a plain `BackButton()` types Esc instead of leaving. Give it `onPressed: () => context.pop()`.

## Environment gotchas

- The Makefile needs bash (`SHELL := /bin/bash`); on Windows run make from Git Bash.
- Git may fail with `detected dubious ownership` on this checkout — the fix it prints (`git config --global --add safe.directory D:/flutter_server_box`) is a user-level decision; surface it, don't apply it unprompted.
- Native iOS/macOS/Windows CI builds run only by hand (`workflow_dispatch` in `analysis.yml`); `CLAUDE.md` § CI lists exactly which diffs justify triggering one.
