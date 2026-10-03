# CF ServerBox Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create new `README.md` and `README_zh.md`, clean up temporary files, commit all project updates, and create and push to a brand-new public GitHub repository `cf_server_box`.

**Architecture:** Update repository documentation to reflect the CF-Server-Monitor specialized cross-platform client and Android widgets. Clean untracked artifacts, commit changes with conventional commit prefixes, create the new remote GitHub repository via `gh` CLI, and push the branch.

**Tech Stack:** Markdown, Git, GitHub CLI (`gh`).

## Global Constraints
- Target repository: `https://github.com/jimiha1/cf_server_box` (Public).
- Codebase must pass `flutter analyze` and `flutter test test/unit/server/cf/`.
- No lingering temporary screenshot `.png` files in the root folder.

---

### Task 1: Generate README.md and README_zh.md

**Files:**
- Create/Overwrite: `README.md`
- Create/Overwrite: `README_zh.md`

- [ ] **Step 1: Write English README.md**
- [ ] **Step 2: Write Simplified Chinese README_zh.md**
- [ ] **Step 3: Verify formatting and links**

---

### Task 2: Workspace Cleanup and Gitignore Update

**Files:**
- Modify: `.gitignore`
- Delete: Root-level `screenshot_*.png`, `phone_launch_screenshot.png`

- [ ] **Step 1: Remove temporary screenshots**
- [ ] **Step 2: Add screenshot pattern to .gitignore**
- [ ] **Step 3: Verify git status is clean of untracked garbage**

---

### Task 3: Commit All Changes

- [ ] **Step 1: Stage and commit documentation and source changes**
```bash
git add .
git commit -m "feat: redesign for CF-Server-Monitor client with Android widgets"
```

---

### Task 4: Create New GitHub Repository and Push

- [ ] **Step 1: Create repository cf_server_box via gh CLI**
```bash
gh repo create cf_server_box --public --source=. --remote=origin-new --push
```
- [ ] **Step 2: Verify repository creation and branch status**
