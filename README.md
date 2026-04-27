# 🚀 Dev Toolkit

A lightweight, production-ready bootstrap script to set up SSH and GitHub access on a new machine.

---

## ⚡ Quick Start

Run this in your terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/zamirza786/dev-toolkit/main/dev-ssh-setup.sh)
```

---

## 🧠 What This Does

* 🔐 Generates a new SSH key (`ed25519`)
* 🔑 Authenticates with GitHub using GitHub CLI
* ⚙️ Configures SSH (`~/.ssh/config`)
* ➕ Adds SSH key to your GitHub account
* ✅ Verifies SSH connection

---

## 📦 Requirements

* macOS
* Internet connection

The script will automatically install:

* Homebrew (if missing)
* GitHub CLI (`gh`)

---

## 🔒 Security

* No credentials stored
* Uses official GitHub browser authentication
* Private keys never leave your machine

---

## 🔁 Idempotent

Safe to run multiple times:

* Detects existing keys
* Avoids duplicate config
* Reuses authentication

---

## 🧪 Use Cases

* New Mac setup
* Developer onboarding
* Resetting SSH/GitHub config

---

## 👨‍💻 Author

zamirza786

---

## ⭐ Support

If this helped, consider starring the repo on GitHub
