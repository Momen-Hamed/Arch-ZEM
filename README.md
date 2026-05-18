# ✨ Arch-ZEM

[![License](https://img.shields.io/github/license/Momen-Hamed/Arch-ZEM?color=blueviolet)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/Momen-Hamed/Arch-ZEM?color=green)](https://github.com/Momen-Hamed/Arch-ZEM/commits)
[![Issues](https://img.shields.io/github/issues/Momen-Hamed/Arch-ZEM?color=orange)](https://github.com/Momen-Hamed/Arch-ZEM/issues)
[![Made with Hyprland](https://img.shields.io/badge/Hyprland-Window%20Manager-blue)](https://github.com/hyprwm/Hyprland)

---

## 🌟 Overview

**Arch-ZEM** is a simple yet elegant Arch Linux configuration powered by [Hyprland](https://github.com/hyprwm/Hyprland). It combines stunning visuals with a streamlined, efficient workflow — designed for maximum productivity and minimal resource usage. This setup is perfect for users who want a balance of “fancy looks” and high performance, whether on a modern or modest system.

---

## 🎨 Features

- 🪟 **Hyprland Window Manager** with fluid animations and advanced features  
- 🧩 Custom, minimal [Shell scripts](#file-structure) for automation and workflow  
- 🎭 Beautiful desktop styling driven by [CSS](#file-structure) & theming  
- 🌑 Integrated status bars, custom widgets, and notification systems  
- ⚡️ Lightweight: optimized for speed and low resource usage  
- 🔧 Modular configs — swap themes, layouts, and tools with ease  
- 🔒 Privacy-respecting, no bloatware, and easily extensible

---

## 📸 Preview
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/52fa67c7-8479-4419-87f0-e1b3ece368cc" />

### Clean
<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/7eeed71c-926a-454d-8d95-c3b395aaf89a" />

---

## 🚀 Getting Started

> **WARNING:** This configuration is for advanced users comfortable with Arch Linux and using the terminal.
  
### 🏁 Quick Install

```sh
git clone https://github.com/Momen-Hamed/Arch-ZEM.git
cd Arch-ZEM
./install.sh       # or the appropriate setup script
```

- Ensure you are running this on top of a **fresh Arch Linux installation**
- Review and edit the configs as per your hardware and preferences  
- (Optional) Restore dotfiles/symlinks via the setup tools in the repo

### 📦 Dependencies

You’ll need:
- [Arch Linux](https://archlinux.org/)
- [Hyprland](https://github.com/hyprwm/Hyprland)
- Fonts: `JetBrainsMono`, `Nerd Fonts`
- Utilities: `waybar`, `wofi`, `alacritty`, `kitty`, etc.
- Python, Shell, Lua interpreters
  
---

## 🗂️ File Structure

| Language      | % Use | Main Purpose                  |
|:--------------|:------|:-----------------------------|
| **CSS**       | 46.2  | Theming styles, Waybar, etc. |
| **Shell**     | 34.5  | Scripts, automation, setup   |
| **GLSL**      | 4.8   | Custom shaders/visuals       |
| **Lua**       | 4.5   | Widget configs/scripts       |
| **Python**    | 4.4   | Helper scripts, automation   |
| **JavaScript**| 3.8   | Statusbar logic, widgets     |
| **Other**     | 1.8   | Miscellaneous                |

The repo is modular — explore each directory for more details and tweaks.

---

## 🛠️ Customization & Advanced Usage

- 🎨 **Change Themes:** Swap CSS in the `styles/` folder or edit `waybar/config.css`
- 🪄 **Keybindings:** Edit `hypr/hyprland.conf` or `config/`
- 🔄 **Autostart/Startup:** Add or remove scripts in the `autostart/` or `scripts/`
- 🧠 **Extensions:** Add more scripts (Python, Shell, Lua...) for new features

See [`docs/CUSTOMIZE.md`](docs/CUSTOMIZE.md) for advanced guides.

---

## 💬 Community & Support

- [GitHub Issues](https://github.com/Momen-Hamed/Arch-ZEM/issues) — report bugs, request features
- [Discussions](https://github.com/Momen-Hamed/Arch-ZEM/discussions) — share your setup, tips, screenshots!
- **Pull Requests are welcome!**

---

## 📄 License

Distributed under the [MIT License](LICENSE).

---

> _“Maximum effect — minimum distraction.”_
> _ Most of work done by [Ziad Lawatey](https://github.com/ziadlawatey) all thanks to him!
> — Also by [Momen-Hamed](https://github.com/Momen-Hamed) with ❤️ for the Linux community.

