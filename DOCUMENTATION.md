# AutoKillSYS - Technical Documentation

## Table of Contents

1. [Architecture](#architecture)
2. [Code Structure](#code-structure)
3. [Core Functions](#core-functions)
4. [Data Structures](#data-structures)
5. [Terminal Control](#terminal-control)
6. [Process Monitoring](#process-monitoring)
7. [Auto-Kill Engine](#auto-kill-engine)
8. [Development Guide](#development-guide)

## Architecture

### Overview

AutoKillSYS follows a **continuous rendering and event-driven** architecture:

```
┌─────────────────────────────────────┐
│         Main Event Loop             │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────┐   ┌───────────┐   │
│  │   Render()   │──→│ Input()   │   │
│  └──────────────┘   └───────────┘   │
│        ↓                     ↑      │
│  ┌──────────────┐           │       │
│  │  Fetch()     │───────────┘       │
│  └──────────────┘                   │
│                                     │
│  ┌──────────────────────────────┐   │
│  │  Auto-Kill Engine            │   │
│  │  (runs in render)            │   │
│  └──────────────────────────────┘   │
│                                     │
└─────────────────────────────────────┘
```

### Flow

1. **main()** - Initializes terminal and enters infinite loop
2. **render()** - Fetches data, builds UI frame, displays it
3. **input()** - Non-blocking read of keyboard input
4. **Auto-Kill Engine** - Executes after UI render if enabled

## Code Structure

### Global Variables

```bash
# Configuration
ACPU=80              # Auto-kill CPU threshold
AMEM=80              # Auto-kill Memory threshold
REFRESH=3            # Display refresh interval (seconds)
SHOWALL=0            # View mode (0=Top15, 1=All)
SORTBY="cpu"         # Sort order

# UI State
SEL=0                # Selected process index
AUTO=0               # Auto-kill mode toggle (0=off, 1=on)

# UI Control
AMSG=""              # Alert message
ATIME=0              # Alert timestamp

# Data Arrays
declare -a PIDS      # Process IDs
declare -a CPU       # CPU percentages
declare -a MEM       # Memory percentages
declare -a NAMES     # Process names
declare -a STATS     # Process states
```

### Color Variables

```bash
# ANSI 256-color codes
R="\033[0m"          # Reset
B="\033[1m"          # Bold
cR, cO, cY, cG       # Red, Orange, Yellow, Green
cC, cW, cGr, cLg     # Cyan, White, Dark Gray, Light Gray
cP, cBd, cHd, cSB    # Pink, Border, Header, Selected BG
```

## Core Functions

### fetch()

Retrieves top processes from the system.

```bash
fetch()
```

**Purpose**: Populate data arrays with current process information

**Process**:
1. Initialize empty arrays
2. Determine sort column based on `SORTBY`
3. Run `ps` command with appropriate sort
4. Limit results (15 or 500 based on `SHOWALL`)
5. Parse output into arrays

**Data Retrieved**:
- PID, CPU%, Memory%, Process State, Process Name

**Performance Note**: Uses `ps` with `--no-headers` for efficiency

### render()

Main UI rendering function.

```bash
render()
```

**Components**:
1. **Header Section**
   - Colorful ASCII logo (5 lines)
   - Subtitle with emojis

2. **Status Bar**
   - Current time, system uptime
   - Auto-kill status with thresholds
   - Current sort order
   - View mode indicator

3. **Process Table**
   - Column headers
   - Process rows with visual bars
   - Scrolling support
   - Selection highlighting

4. **System Summary**
   - Overall CPU usage
   - RAM usage (used/total + percentage)
   - Process count
   - Log file location

5. **Alert Section** (conditional)
   - Shows last action for 4 seconds

6. **Keybind Footer**
   - All available keyboard shortcuts

**Key Features**:
- Dynamic width calculation
- Responsive to terminal size
- Handles small terminal gracefully
- Color-coded resource usage
- Selection highlighting with background color

### input()

Non-blocking keyboard input handler.

```bash
input()
```

**Timeout**: 0.15 seconds (6.66x per second)

**Key Bindings**:
| Key | Function |
|-----|----------|
| `↑` / `↓` | Navigate |
| `K/k` | Kill |
| `A/a` | Auto-kill toggle |
| `S/s` | Sort toggle |
| `T/t` | Threshold settings |
| `L/l` | View log |
| `V/v` | View mode toggle |
| `R/r` | Refresh (no-op) |
| `Q/q` | Quit |

### kill_selected()

Terminates the selected process with confirmation.

```bash
kill_selected()
```

**Steps**:
1. Get selected process PID and name
2. Display confirmation prompt
3. Wait for user input (Y/N)
4. Execute `kill -9 PID`
5. Log the action
6. Set alert message

**Safety**: Requires explicit user confirmation

### set_thresh()

Allows user to set auto-kill thresholds.

```bash
set_thresh()
```

**Prompts**:
1. CPU threshold (0-100%)
2. Memory threshold (0-100%)

**Validation**: Only accepts numeric values ≤ 100%

**Logging**: Records new thresholds in log

### view_log()

Displays the last 40 log entries.

```bash
view_log()
```

**Features**:
- Exits UI mode temporarily
- Shows last 40 lines of `/tmp/autokillsys.log`
- Color-coded display
- Waits for user keypress before returning

### bar()

Creates ASCII progress bars with color coding.

```bash
bar() { local v=$1 w=$2; ... }
```

**Parameters**:
- `$1` - Value (0-100)
- `$2` - Width in characters

**Output**: Colored bar with fill and empty blocks
- 🔴 Red: ≥ 85%
- 🟠 Orange: ≥ 60%
- 🟡 Yellow: ≥ 35%
- 🟢 Green: < 35%

### pad_line()

Pads UI lines to exact width, handling ANSI escape codes.

```bash
pad_line() { local width=$1 content=$2; ... }
```

**Purpose**: Ensures consistent line widths despite invisible ANSI codes

**Method**: Strips escape codes, calculates visible length, adds padding

## Data Structures

### Process Array Design

Uses parallel arrays for efficiency:

```bash
PIDS[i]    ← Process ID
CPU[i]     ← CPU usage %
MEM[i]     ← Memory usage %
NAMES[i]   ← Process name
STATS[i]   ← Process state
```

**Array Index**: Same index refers to same process across all arrays

**Advantages**:
- Simple indexing
- Memory efficient
- Fast lookup

## Terminal Control

### ANSI Escape Codes

```bash
# Cursor Control
goto()       # Move cursor to X,Y: printf "\033[Y;XH"
hide_cur()   # Hide cursor: printf '\033[?25l'
show_cur()   # Show cursor: printf '\033[?25h'

# Screen Control
clr()        # Clear screen and home cursor
tput smcup   # Save terminal state
tput rmcup   # Restore terminal state

# Dimensions
ROWS()       # Get terminal height
COLS()       # Get terminal width
```

### Color System

```bash
# Format: \033[38;5;<color>m
# Example: \033[38;5;196m = Red
# Followed by text, then \033[0m = Reset
```

**Color Palette**:
- 196 = Red, 208 = Orange, 226 = Yellow, 82 = Green
- 87 = Cyan, 255 = White, 240 = Dark Gray, 247 = Light Gray
- 213 = Pink, 238 = Border

## Process Monitoring

### Data Source: ps Command

```bash
ps ax -o pid,%cpu,%mem,stat,comm --no-headers
```

**Output Columns**:
1. PID - Process ID
2. %CPU - CPU usage percentage
3. %MEM - Memory usage percentage
4. STAT - Process state
5. COMM - Command name

### Sorting Options

```bash
SORTBY="cpu"   → sort -k3 -rn  (CPU column)
SORTBY="mem"   → sort -k4 -rn  (Memory column)
SORTBY="pid"   → sort -k1 -rn  (PID column)
SORTBY="name"  → sort -k5 -rn  (Name column)
```

### Display Limits

```bash
SHOWALL=0  → Top 15 processes
SHOWALL=1  → All processes (up to 500)
```

## Auto-Kill Engine

### Algorithm

Runs after every render when `AUTO=1`:

```
for each process in PIDS[]:
    if (CPU% > ACPU OR Memory% > AMEM):
        if process in PROTECTED_LIST:
            continue
        else:
            kill -9 process
            log action
            show alert
```

### Protected Processes

```bash
systemd, init, bash, sshd, AutoKillSYS*, ps, awk
```

These critical processes cannot be auto-killed regardless of resource usage.

### Action Sequence

1. Check resource thresholds
2. Verify it's not protected
3. Send SIGKILL (-9)
4. Log with timestamp and details
5. Display alert for 4 seconds

## Development Guide

### Code Style

- **Indentation**: 4 spaces
- **Variables**: camelCase for arrays, CAPS for constants
- **Functions**: Lowercase with underscores
- **Comments**: Descriptive, above code blocks

### Adding Features

#### Example: Add Memory-Only View

```bash
# 1. Add to global variables
MEMONLY=0

# 2. Add to input()
[mM]) (( MEMONLY ^= 1 )); SORTBY="mem" ;;

# 3. Modify render() keybind display
# Add: ${cG}[M]${R}em-Only

# 4. Modify fetch() to filter if needed
```

#### Example: Add Process-Specific Thresholds

```bash
# 1. Create config file: ~/.autokillsys.conf
# format: processname:cputhreshold:memthreshold

# 2. Parse config in initialize
# 3. Use in auto-kill loop:
if [[ -v PROC_THRESH[$name] ]]; then
    read cpu mem <<< "${PROC_THRESH[$name]}"
    (( c > cpu || m > mem )) && kill ...
fi
```

### Testing

#### Test Terminal Size Detection
```bash
# Terminal too small
# Should show error message
export LINES=20; export COLUMNS=60
./AutoKillSYS.sh
```

#### Test Log Parsing
```bash
# Verify log format and readability
tail -20 /tmp/autokillsys.log
./AutoKillSYS.sh  # Press 'L' to view
```

#### Test Auto-Kill Safeguards
```bash
# Start a low-CPU bash shell
bash -c 'while true; do :; done' &
# Set threshold to 5%
# Verify bash is NOT killed
```

### Performance Considerations

1. **ps Command**: Called every REFRESH seconds
2. **Array Operations**: O(n) where n = processes shown
3. **String Processing**: Uses native Bash (not external tools)
4. **Terminal I/O**: Atomic writes to prevent flicker
5. **Memory**: Arrays limited to 500 processes

### Known Limitations

1. **Terminal Size**: Minimum 70×24 characters required
2. **Color Support**: Requires 256-color terminal
3. **Performance**: Slower on systems with thousands of processes
4. **Permissions**: Needs root to kill other user's processes
5. **Platform**: Linux/Unix only (uses `/proc/stat`, `ps`)

### Future Enhancements

1. Configuration file support
2. Process filtering/search
3. Historical graphs
4. Network/IO monitoring
5. Process grouping by user
6. Custom keybindings
7. Mouse support
8. Output export to CSV

## Debugging

### Enable Debugging Mode

```bash
# Add to top of script
set -x  # Trace execution
```

### Check System Info

```bash
ps --version
bash --version
tput colors  # Should be 256
```

### Log Analysis

```bash
# Show all kills in last hour
grep -i "KILLED\|AUTO-KILLED" /tmp/autokillsys.log
```

---

For more information, see the [README.md](README.md)
