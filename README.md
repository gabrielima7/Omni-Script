# 🚀 Omni-Script

**Modular Infrastructure as Code Framework for Hybrid Deployments**

Deploy applications across **Docker**, **Podman**, **LXC**, and **Bare Metal** with a single unified CLI.

---

## ⚡ Quick Install

```bash
curl -sSL https://raw.githubusercontent.com/gabrielima7/Linux-Library/main/install.sh | bash
```

After installation, restart your terminal or run:
```bash
source ~/.bashrc
```

---

## 📋 Features

- 🎯 **Any-Target Architecture** - Docker, Podman, LXC, Bare Metal
- 🔍 **Smart Search** - Docker Hub, Quay.io, and package managers
- 🏗️ **Builder Stack** - Compose complete environments interactively
- 🔐 **Secure by Default** - Auto-generated 32-char passwords
- 💾 **Universal Backup** - Target-agnostic backup & restore
- 🎨 **Beautiful UI** - Spinners, progress bars, ASCII art

---

## 🛠️ Usage

```bash
# Show help
omni help

# Search for packages and images
omni search nginx

# Install an application
omni install nginx --target docker

# Build a custom stack
omni stack build

# Backup an application
omni backup portainer

# View configuration
omni config show
```

---

## 📁 Project Structure

```
├── omni.sh                 # Main CLI entry point
├── install.sh              # One-liner installer
├── global.conf             # Global configuration
├── lib/
│   ├── core/               # Core engine (constants, logger, utils)
│   ├── ui/                 # UI components (colors, spinners, prompts)
│   ├── registry/           # Smart search (Docker Hub, packages)
│   ├── adapters/           # Target adapters (Docker, Podman, LXC)
│   ├── config/             # Configuration parser
│   └── security/           # Credential generation
├── modules/
│   ├── installer/          # Main installer engine
│   ├── builder/            # Builder Stack
│   └── backup/             # Universal backup
└── recipes/                # Application recipes (coming soon)
```

---

## 🐳 Supported Targets

| Target | Status | Description |
|--------|--------|-------------|
| Docker | ✅ | Docker + Docker Compose |
| Podman | ✅ | Podman + Podman Compose |
| LXC | ✅ | LXC/LXD containers |
| Bare Metal | ✅ | Native OS installation |

---

## 📦 Requirements

- Bash 4.0+
- curl
- git
- jq (optional, for enhanced search)

---

## 🤝 Contributing

Contributions are welcome! Please read the Contributing Guidelines.

---

## 📄 License

MIT License - See LICENSE for details.

---

<p align="center">
  <strong>Made with ❤️ by <a href="https://github.com/gabrielima7">gabrielima7</a></strong>
</p>