# AutoKillSYS - Process Management & Auto-Kill System

A powerful terminal-based process management utility written in Bash that monitors system processes and automatically terminates resource-hungry applications.

<div align="center">

![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![Bash](https://img.shields.io/badge/Bash-121011?style=for-the-badge&logo=gnu-bash&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)

</div>

## System Overview

![System Overview](images/system%20overview.png)

## 🌟 Features

- **Real-time Process Monitoring** - Live CPU and memory usage with beautiful visual bars
- **Auto-Kill System** - Automatically terminate processes exceeding CPU/memory thresholds
- **Interactive UI** - Navigate and manage processes with keyboard shortcuts
- **Multiple Sort Options** - Sort by CPU, memory, PID, or process name
- **Comprehensive Logging** - Track all actions with detailed timestamps
- **System Overview** - View overall CPU, RAM, and active process count
- **Safe Filtering** - Prevents accidental termination of critical system processes
- **Customizable Thresholds** - Set your own CPU and memory limits

## 📋 Requirements

- Linux/Unix system
- Bash 4.0+
- `ps`, `awk`, `sed` utilities (usually pre-installed)
- Terminal with minimum dimensions: 70×24 characters
- 256-color terminal support (recommended)

## 🚀 Installation

### Clone the Repository

```bash
git clone https://github.com/if-i-shajan/AutoKill-SYS.git
cd AutoKill-SYS
```

### Make Executable

```bash
chmod +x AutoKillSYS.sh
```

## 💻 Usage

### Basic Run

```bash
./AutoKillSYS.sh
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `K` | Kill selected process |
| `A` | Toggle Auto-Kill mode |
| `↑` / `↓` | Navigate through processes |
| `S` | Change sort order (CPU → Memory → PID → Name) |
| `T` | Set CPU/Memory thresholds |
| `L` | View activity log |
| `V` | Toggle view (Top 15 / All processes) |
| `R` | Refresh display |
| `Q` | Quit application |

## 🎯 How It Works

### Manual Process Killing

1. Use **↑/↓** arrow keys to select a process
2. Press **K** to kill the highlighted process
3. Confirm with **Y** when prompted

### Auto-Kill Mode

1. Press **A** to enable auto-kill (you'll see `● AUTO-KILL ON`)
2. Press **T** to set thresholds:
   - CPU threshold (default: 80%)
   - Memory threshold (default: 80%)
3. AutoKillSYS will automatically terminate any process exceeding these thresholds
4. Protected processes (systemd, init, bash, sshd) are never killed

### Monitoring and Logging

- All actions are logged to `/tmp/autokillsys.log`
- Press **L** to view the last 40 log entries
- Each log entry includes timestamp, process name, PID, and resource usage

## 📊 Display Information

- **PID** - Process ID
- **CPU%** - CPU usage percentage with visual bar
- **MEM%** - Memory usage percentage with visual bar
- **STAT** - Process state (R=Running, D=Disk, Z=Zombie, T=Stopped)
- **PROCESS** - Process name/command

### Color Coding

- 🔴 **Red** - High resource usage (≥85%)
- 🟠 **Orange** - Medium resource usage (≥60%)
- 🟡 **Yellow** - Elevated resource usage (≥35%)
- 🟢 **Green** - Normal resource usage

## 🛡️ Safety Features

The following critical processes are protected from auto-kill:

- `systemd` - System and service manager
- `init` - System initialization
- `bash` - Shell
- `sshd` - SSH daemon
- `AutoKillSYS*` - The script itself

## 📝 Configuration

Default settings can be modified in the script:

```bash
ACPU=80      # Auto-kill CPU threshold (%)
AMEM=80      # Auto-kill Memory threshold (%)
REFRESH=3    # Display refresh interval (seconds)
SHOWALL=0    # Show all processes (0=Top 15, 1=All)
SORTBY="cpu" # Default sort order
```

## 📂 Log File

Activity logs are stored at: `/tmp/autokillsys.log`

Example log entries:
```
[2024-01-15 14:32:15] AutoKillSYS started Mon Jan 15 14:32:15 UTC 2024
[2024-01-15 14:32:28] KILLED pid=1234 name=runaway_process
[2024-01-15 14:33:45] AUTO-KILLED pid=5678 name=memory_hog cpu=92% mem=85%
```

## ⚙️ System Requirements

- **OS**: Linux (any distribution)
- **Architecture**: x86_64, ARM, or any architecture with Bash support
- **Permissions**: Requires `sudo` or root access to kill processes not owned by current user
- **Dependencies**: Standard Unix utilities (pre-installed on most systems)

## 🔧 Troubleshooting

### Terminal Too Small Error
```
Terminal too small: need 90×26 minimum, got 80×24.
```
**Solution**: Maximize your terminal window or use a larger font size.

### Permission Denied When Killing Process
```
bash: kill: (1234): Operation not permitted
```
**Solution**: Run AutoKillSYS with `sudo`: `sudo ./AutoKillSYS.sh`

### Script Not Starting
**Solution**: Ensure the script is executable:
```bash
chmod +x AutoKillSYS.sh
```

## 📚 Use Cases

- **Development** - Kill runaway processes during development
- **Server Management** - Monitor and manage resource-hungry applications
- **Education** - Learn about process management on Linux
- **System Maintenance** - Quick cleanup of misbehaving processes

## 🎓 Educational Value

This project demonstrates several Linux/Unix concepts:

- **Process Management** - Using `ps` command to monitor processes
- **Bash Scripting** - Advanced Bash features (arrays, color codes, terminal control)
- **Terminal Control** - ANSI escape codes for UI rendering
- **System Monitoring** - Reading `/proc/stat` for CPU and system info
- **Signal Handling** - Using `kill` command and signal handling
- **Logging** - Creating and managing system logs

## 🤝 Contributing

Contributions are welcome! Please feel free to:

- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Devs

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/if-i-shajan">
        <img src="https://github.com/if-i-shajan.png" width="100px" height="100px" style="object-fit:cover;" alt="Shajan"/>
        <br/>
        <b>J.M. Ifthakharul Islam Shajan</b>
      </a>
  </tr>
</table>

Created as part of the 7th Semester Operating Systems Lab coursework.

## 🙏 Acknowledgments

- Inspired by process management tools like `top`, `htop`, and `kill`
- Built for educational purposes to understand process management
- Thanks to the Linux community for the amazing tools and documentation

## 📮 Contact & Support

For questions, issues, or feedback:
- 📧 Email:  jmifthakharul.shajan@gmail.com
- 🐛 Issues: [GitHub Issues](https://github.com/if-i-shajan/AutoKill-SYS/issues)

---

<div align="center">

**Made with ❤️ for the Linux Community**

[⬆ Back to Top](#autokillsys---process-management--auto-kill-system)

</div>
