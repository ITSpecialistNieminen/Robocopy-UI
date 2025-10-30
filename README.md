# 🪟 Robocopy GUI for PowerShell

A simple yet powerful **graphical interface for Robocopy** (Robust File Copy), built entirely in **PowerShell and WPF**.  
It allows users to select source and destination directories, adjust parameters, and monitor progress in real time — all without using the command line.

---

## 🚀 Features

- **User-friendly GUI** for building complex Robocopy commands  
- **Live output window** showing Robocopy’s progress in real time  
- **Command preview and confirmation prompt** before execution  
- **Optional parameters** can be toggled on/off dynamically  
- **Supports all major Robocopy flags**, including `/MT`, `/LOG`, `/MIR`, `/E`, `/Z`, etc.  
- **Non-blocking execution:** UI stays responsive during long copy operations  
- **Help window** explaining each parameter in plain English  

---

## 🧩 Requirements

- **Windows 10 / 11**
- **PowerShell 5.1** or newer  
- **Robocopy** (built into Windows)
- No external dependencies required

---

## ⚙️ How to Run

1. Save the script as `RobocopyUI.ps1`.
2. Right-click → **Run with PowerShell**, or launch manually:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\RobocopyUI.ps1
