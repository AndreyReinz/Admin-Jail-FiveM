# AJail - Advanced Prison System for FiveM

![GitHub](https://img.shields.io/github/license/yourusername/ajail?color=blue)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/yourusername/ajail)

A sophisticated jail system for FiveM servers featuring custom locations, anti-escape mechanisms, and persistent sentences.

## ✨ Features

- 🏢 **Custom Jail Location** - Configurable prison coordinates
- 🚫 **Anti-Escape System** - Teleport-back and vehicle blocking
- ⏳ **Time-Based Sentences** - Automatic release after sentence completion
- 💾 **Persistence** - Saves jail data across server restarts
- 👮 **Admin Commands** - Easy-to-use `/ajail` and `/unjail` commands
- 🔒 **Full Action Restriction** - Blocks weapons, attacks, and vehicles
- 📢 **Custom Notifications** - Clear in-game messages for all parties

## 🚀 Installation

1. Download the latest release
2. Extract into your `resources` folder
3. Add to `server.cfg`:
   ```lua
   ensure ajail
