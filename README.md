# 󰏖 pkg-browser

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-Zsh-f0a429.svg?logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![Platform](https://img.shields.io/badge/Platform-Debian%20%7C%20Ubuntu%20%7C%20Termux-E95420.svg?logo=ubuntu&logoColor=white)](#-prerequisites--dependencies)
[![FZF Powered](https://img.shields.io/badge/Search-fzf%20v0.58+-3572A5.svg?logo=gnubash&logoColor=white)](https://github.com/junegunn/fzf)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](https://github.com/Lakmal2078/pkg-browser/pulls)

> **A blazing-fast, modern interactive terminal package browser and manager for Debian, Ubuntu, and Termux (Android).**  
> Powered by `fzf`, built in pure Zsh, and styled with multi-border layouts, Nerd Font icons, and live multi-tab preview panels.

---

## 📌 Table of Contents

- [💡 Overview](#-overview)
- [✨ Key Features](#-key-features)
- [⌨️ Interactive Keybindings](#️-interactive-keybindings)
- [🎨 Built-in Themes](#-built-in-themes)
- [🛠️ Prerequisites & Dependencies](#️-prerequisites--dependencies)
- [🚀 Quick Start & Installation](#-quick-start--installation)
- [📁 Paths & Configuration](#-paths--configuration)
- [🗑️ Uninstallation](#️-uninstallation)
- [🤝 Contributing & Support](#-contributing--support)
- [📄 License](#-license)

---

## 💡 Overview

Managing packages in Debian-based distributions and Termux often involves jumping between `apt search`, `apt show`, `dpkg -L`, and `apt-cache rdepends`.

**`pkg-browser`** consolidates the entire workflow into a single, intuitive, high-performance Terminal User Interface (TUI). With dynamic live caching, subshell-isolated executions, and responsive floating panes, you can browse, inspect, and manage tens of thousands of packages smoothly in real time.

---

## ✨ Key Features

* **⚡ Ultra-Fast Fuzzy Search:** Powered by `fzf` with smart pre-indexed caching for instant loading of 60,000+ packages without lag.
* **󰗚 4-in-1 Dynamic Preview Tabs (`CTRL-T`):**
  1. **ℹ️ Info Tab:** Detailed package metadata, installed/candidate versions, maintainer details, and fractional Unicode progress bars (`█▉▊▋▌▍▎▏`) for package sizes.
  2. **🌳 Deps Tab:** Recursive dependency resolution trees showing both direct dependencies (`Depends`, `Recommends`) and reverse dependencies (`Needed-by`).
  3. **📂 Files Tab:** Complete file tree installed by the package on your system, enhanced with syntax-colored file types and directories.
  4. **📜 Log Tab:** Upstream Debian/Ubuntu changelog viewer rendered via `glow` (Markdown) with local operation history.
* **󰍉 Deep File-to-Package Lookup (`CTRL-S`):**
  - Instant reverse-search to identify which package owns any binary, library, or configuration file on your machine.
* **󰏖 Dynamic Nerd Font Icons:**
  - Automatic language and tool identification mapping distinct icons for Python, Node.js, Rust, Go, C/C++, Docker, Git, Web servers, and system utilities.
* **🎨 Built-in Theme Engine (`CTRL-Y`):**
  - Switch on the fly between curated palettes: **Cyber** (Catppuccin/Cyberpunk), **Nord**, **Gruvbox**, **Rosé Pine**, and **Monochrome**. Your chosen theme is persisted across sessions.
* **📊 Live Statistics & Activity Logging:**
  - Integrated status panel tracking installed, available, and upgradable package counts with real-time visual capacity bars.
  - Automatic audit trail saved to `~/.cache/pkg-browser/activity.log`.
* **🛡️ Security & Portability:**
  - Built with defensive shell practices: TOCTOU symlink protection, strict input sanitization, subshell isolation, and native support for Termux path prefixes.

---

## ⌨️ Interactive Keybindings

| Keybinding | Action |
| :--- | :--- |
| **`ENTER`** | **Install or Remove** the currently selected package(s) with confirmation dialog |
| **`TAB`** | **Multi-selection:** Toggle selection for batch install or remove |
| **`CTRL-F`** | **Cycle Filter Modes:** `All` ➜ `Installed` ➜ `Available` |
| **`CTRL-T`** | **Cycle Preview Tabs:** `Info` ➜ `Deps` (Dependency Tree) ➜ `Files` ➜ `Log` |
| **`CTRL-S`** | **Deep File Search:** Search packages by file path or binary name |
| **`CTRL-R`** | **Refresh Cache:** Re-synchronize package lists and local state |
| **`CTRL-Y`** | **Theme Selector:** Open interactive visual theme picker |
| **`ESC` / `q`** | **Exit / Cancel:** Close dialog or exit browser |

---

## 🎨 Built-in Themes

`pkg-browser` comes bundled with 5 aesthetic color schemes configured for terminal transparency and contrast:

| Theme | Description |
| :--- | :--- |
| **`cyber`** *(Default)* | Vibrant Cyberpunk / Catppuccin palette with purple borders and cyan accents |
| **`nord`** | Arctic, north-bluish clean palette |
| **`gruvbox`** | Warm, retro groove with yellow/orange earth tones |
| **`rose`** | Soft, minimalist Rosé Pine pastel styling |
| **`mono`** | High-contrast monochrome grayscale scheme |

Press **`CTRL-Y`** anywhere inside `pkg-browser` to preview and switch themes instantly.

---

## 🛠️ Prerequisites & Dependencies

To experience the full UI (including language icons and symbols), ensure a **[Nerd Font](https://www.nerdfonts.com/)** is enabled in your terminal emulator (e.g. Kitty, Alacritty, WezTerm, iTerm2, or Termux).

### Required:
* `zsh` (Z Shell)
* `fzf` (Fuzzy Finder - v0.58 or higher recommended for floating borders)
* `apt` & `dpkg` (Standard on Debian, Ubuntu, Linux Mint, and Termux)

### Optional Enhancers (Recommended):
* `glow` - Renders rich markdown changelogs in the preview pane.
* `bat` / `batcat` - Adds syntax highlighting to file trees and configuration previews.
* `curl` - Fetches live upstream changelogs.

### One-Command Dependency Setup:

**On Debian / Ubuntu / Linux Mint:**
```bash
sudo apt update
sudo apt install -y zsh fzf curl bat glow
```

**On Termux (Android):**
```bash
pkg update
pkg install -y zsh fzf curl bat glow
```

---

## 🚀 Quick Start & Installation

### Option 1: Automated Installer (Recommended)

Clone the repository and run `install.sh`:
```bash
git clone https://github.com/Lakmal2078/pkg-browser.git
cd pkg-browser
chmod +x install.sh
./install.sh
```

The installer will:
1. Validate required and optional dependencies.
2. Install `pkg-browser` into `/usr/local/bin` (or `$PREFIX/bin` on Termux).
3. Create a convenient short command alias: **`pkgb`**.

You can then launch the app anytime from any directory:
```bash
pkg-browser
# or simply:
pkgb
```

---

### Option 2: Manual Run

If you prefer not to install system-wide:
```bash
git clone https://github.com/Lakmal2078/pkg-browser.git
cd pkg-browser
chmod +x pkg-browser.zsh
./pkg-browser.zsh
```

---

## 📁 Paths & Configuration

All runtime cache files, pre-built indexes, and configs are stored strictly adhering to the XDG Base Directory specification:

| File / Directory | Purpose |
| :--- | :--- |
| `~/.cache/pkg-browser/` | Base cache directory |
| `~/.cache/pkg-browser/all.txt` | Cached list of all repository packages |
| `~/.cache/pkg-browser/installed.txt` | Cached list of locally installed packages |
| `~/.cache/pkg-browser/available.txt` | Cached list of non-installed available packages |
| `~/.cache/pkg-browser/theme` | Persisted user theme preference |
| `~/.cache/pkg-browser/activity.log` | Timestamped action audit log (install / remove / search) |

---

## 🗑️ Uninstallation

An uninstaller script is included to cleanly remove the application:

```bash
# Keep local user cache & activity logs:
./uninstall.sh

# Completely purge binaries, cache, and history:
./uninstall.sh --purge
```

---

## 🤝 Contributing & Support

Contributions, bug reports, and feature requests are very welcome!
1. Fork the Project (`https://github.com/Lakmal2078/pkg-browser/fork`)
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'feat: Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more details.
