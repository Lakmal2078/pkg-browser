# 󰏖 pkg-browser

An interactive, modern terminal-based package browser and manager for **Debian, Ubuntu, and Termux (Android)**. Built entirely in Zsh, leveraging the power of `fzf` for an ultra-fast, minimalist, and responsive visual interface.

Styled with a sleek **Tokyo Night** and custom pastel theme layout, featuring smooth Unicode progress bars, Nerd Font icons, and interactive previews.

---

## ✨ Features

* **󰏖 Rich Visual List:** Standard terminal icons replaced with crisp Nerd Font icons mapped dynamically to language and tool types (e.g., Python, Rust, Git, Nginx).
* **󰝶 Multi-Border Layout:** Utilizes latest `fzf` features (v0.58+) to separate Search, List, and Preview panels into clean floating-style panes.
* **󰦨 Smooth Progress Bars:** Uses fractional Unicode blocks (`█▉▊▋▌▍▎▏`) to represent package size indicators accurately and fluidly.
* **󰗚 Multi-tab Interactive Preview:** Cycle through dynamic preview tabs:
  1. **Info:** Basic package information, size, and ASCII arts.
  2. **Deps:** Recursive dependency trees (`Depends` / `Recommends` / `Needed-by`).
  3. **Files:** List of files inside installed packages (with syntax-colored file types).
  4. **Log:** Live Debian changelog rendering and local installation history.
* **󰍉 Deep File Search:** Search and find which package owns a specific file path or executable.
* **🎨 Theme Engine:** Toggle between predefined themes (Tokyo Night, Cyberpunk, Nord, Gruvbox, Rose Pine, Monochrome) using a visual theme picker.
* **󰇚 Markdown Integration:** Integrates with `glow` to render rich markdown-style changelogs.

---

## 🛠️ Prerequisites & Dependencies

To experience the full design of the visual interface, a **Nerd Font** must be enabled in your terminal emulator (e.g., Alacritty, Kitty, Termux, iTerm2).

### Required Dependencies:
* `zsh` (Z shell)
* `fzf` (Fuzzy Finder - v0.58 or higher recommended for multi-borders)
* `apt` & `dpkg` (Standard Debian package utilities)

### Optional (Recommended) Enhancements:
* `glow` - Renders rich markdown changelogs.
* `bat` / `batcat` - Syntax highlighting for config/file lists.
* `curl` - Fetches live upstream changelogs.

### Quick Installation of Dependencies:

**On Debian/Ubuntu:**
```bash
sudo apt update
sudo apt install zsh fzf curl bat glow chafa
```

**On Termux (Android):**
```bash
pkg update
pkg install zsh fzf curl bat glow chafa
```

---

## 🚀 Quick Start & Installation

1. **Clone or Download the Script:**
   ```bash
   https://github.com/Lakmal2078/pkgstore_termux.git
   cd pkg-browser
   ```

2. **Make the Script Executable:**
   ```bash
   chmod +x pkg-browser.zsh
   ```

3. **Run the Browser:**
   ```bash
   ./pkg-browser.zsh
   ```

*(Optional)* Create an alias in your `~/.zshrc` to open it quickly from anywhere:
```bash
alias pkgb="~/path/to/pkg-browser.zsh"
```

---

## ⌨️ Interactive Keybindings

Once inside the browser, the following hotkeys are available to manage your workflow:

| Keybinding | Action |
| :--- | :--- |
| **`ENTER`** | Install or Remove the currently selected package(s) |
| **`TAB`** | Toggle multi-selection (Select multiple packages at once) |
| **`CTRL-F`** | Cycle filters between: `All` ➜ `Installed` ➜ `Available` |
| **`CTRL-T`** | Cycle preview tab: `Info` ➜ `Deps` ➜ `Files` ➜ `Log` |
| **`CTRL-S`** | Search package database by file path or filename |
| **`CTRL-R`** | Refresh cache & synchronize packages database |
| **`CTRL-Y`** | Open visual theme selector |
| **`ESC`** | Quit current window or exit program |

---

## 📁 Paths & Configuration

The script stores local configs, logs, and pre-parsed packages lists inside the standard cache directory:
* Cache Directory: `~/.cache/pkg-browser/`
* Local Activity Log: `~/.cache/pkg-browser/activity.log`
* Saved Theme Config: `~/.cache/pkg-browser/theme`

---

## 🤝 Contributing & Support

Suggestions and improvements are always welcome. Feel free to fork the repository, open an issue, or submit a pull request!
```.
