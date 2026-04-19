#!/usr/bin/env bash
# ============================================================
#  AutoKillSYS — Process Management & Auto-Kill System
# ============================================================
export TERM=xterm-256color

#Colors
R="\033[0m"; B="\033[1m"
cR="\033[38;5;196m"  # red
cO="\033[38;5;208m"  # orange
cY="\033[38;5;226m"  # yellow
cG="\033[38;5;82m"   # green
cC="\033[38;5;87m"   # cyan
cW="\033[38;5;255m"  # white
cGr="\033[38;5;240m" # dark gray
cLg="\033[38;5;247m" # light gray
cP="\033[38;5;213m"  # pink
cBd="\033[38;5;238m" # border
cHd="\033[38;5;208m" # header
cSB="\033[48;5;234m" # selected bg

#State
SEL=0; AUTO=0; ACPU=80; AMEM=80
REFRESH=3; LOG="/tmp/autokillsys.log"
SHOWALL=0; SORTBY="cpu"
AMSG=""; ATIME=0
declare -a PIDS CPU MEM NAMES STATS

#Helpers
hide_cur() { printf '\033[?25l'; }
show_cur() { printf '\033[?25h'; }
goto()     { printf "\033[%d;%dH" "$1" "$2"; }
clr()      { printf '\033[2J'; goto 1 1; }
ROWS()     { tput lines 2>/dev/null || echo 40; }
COLS()     { tput cols  2>/dev/null || echo 120; }

cleanup() {
    show_cur; tput rmcup 2>/dev/null; printf "${R}\n"
    echo -e "${cR}${B}[AutoKillSYS]${R} Exited. Log: $LOG"
}
trap cleanup EXIT INT TERM
log() { echo "[$(date '+%F %T')] $*" >> "$LOG"; }

#Bar (returns string, no trailing newline)
bar() {
    local v=$1 w=$2; [[ $v -gt 100 ]] && v=100; [[ $v -lt 0 ]] && v=0
    local f=$(( v * w / 100 )) e=$(( w - v * w / 100 ))
    local col; (( v>=85 )) && col=$cR || (( v>=60 )) && col=$cO || (( v>=35 )) && col=$cY || col=$cG
    local s=""; local i
    for (( i=0; i<f; i++ )); do s+="█"; done
    for (( i=0; i<e; i++ )); do s+="░"; done
    printf "${col}%s${R}" "$s"
}

#Pad a line to exactly $1 visible chars (handles escape codes) ─

pad_line() {
    # $1 = target width, $2 = content string (with escapes)
    # We calculate visible length by stripping escape sequences
    local width=$1 content=$2
    local visible; visible=$(printf "%b" "$content" | sed 's/\x1b\[[0-9;]*m//g' | wc -m)
    local pad=$(( width - visible ))
    [[ $pad -lt 0 ]] && pad=0
    printf "%b%*s" "$content" "$pad" ""
}

#Fetch processes
fetch() {
    PIDS=(); CPU=(); MEM=(); NAMES=(); STATS=()
    local sk=3
    case "$SORTBY" in mem) sk=4;; pid) sk=1;; name) sk=5;; esac
    local lim=15; [[ $SHOWALL -eq 1 ]] && lim=500
    while read -r pid cpu mem stat name; do
        [[ -z "$pid" ]] && continue
        PIDS+=("$pid"); CPU+=("${cpu%.*}"); MEM+=("${mem%.*}")
        STATS+=("$stat"); NAMES+=("$name")
    done < <(ps ax -o pid,%cpu,%mem,stat,comm --no-headers 2>/dev/null \
             | sort -k${sk} -rn | head -n "$lim")
}

#MAIN RENDER
render() {
    fetch
    local cols; cols=$(COLS)
    local rows; rows=$(ROWS)
    local cnt=${#PIDS[@]}
    [[ $SEL -ge $cnt && $cnt -gt 0 ]] && SEL=$(( cnt - 1 ))
    # Inner width (between the │ borders)
    local iw=$(( cols - 2 ))
    # Dynamic bar width based on screen
    local BW=$(( (iw - 50) / 2 ))
    (( BW < 8 )) && BW=8
    (( BW > 20 )) && BW=20
    # How many process rows we can show
    # Header=11 lines, footer=4 lines, borders
    local avail=$(( rows - 18 )); [[ $avail -lt 1 ]] && avail=1

    #Helper: full-width bordered line
    # top/mid/bot rules
    local TOP="${cBd}╔$(printf '═%.0s' $(seq 1 $iw))╗${R}"
    local MID="${cBd}╠$(printf '═%.0s' $(seq 1 $iw))╣${R}"
    local BOT="${cBd}╚$(printf '═%.0s' $(seq 1 $iw))╝${R}"

    # Bordered content line: pads to exactly cols wide
    bline() {
        # $1 = content (with escape codes)
        local vis; vis=$(printf "%b" "$1" | sed 's/\x1b\[[0-9;]*m//g' | wc -m)
        local pad=$(( iw - vis )); [[ $pad -lt 0 ]] && pad=0
        printf "${cBd}║${R}%b%*s${cBd}║${R}\n" "$1" "$pad" ""
    }

    #BUILD FRAME
    local -a FRAME
    FRAME+=("$TOP")

    #LOGO
    local lw=52
    local lp=$(( (iw - lw) / 2 )); [[ $lp -lt 0 ]] && lp=0
    local LP; LP=$(printf '%*s' "$lp" '')

    FRAME+=("$(bline "${LP}${cR}${B}  █████  ██   ██ ████████  █████  ██   ██ ██ ██     ██ ")")
    FRAME+=("$(bline "${LP}${cR}${B} ██   ██ ██   ██    ██    ██   ██ ██  ██  ██ ██     ██ ")")
    FRAME+=("$(bline "${LP}${cO}${B} ███████ ██   ██    ██    ██   ██ █████   ██ ██     ██ ")")
    FRAME+=("$(bline "${LP}${cO}${B} ██   ██ ██   ██    ██    ██   ██ ██  ██  ██ ██     ██ ")")
    FRAME+=("$(bline "${LP}${cY}${B} ██   ██  █████     ██     █████  ██   ██ ██ ██████ ██████ ")")

    local sub="★  Process Management & Auto-Kill System  ★"
    local sp2=$(( (iw - ${#sub}) / 2 )); [[ $sp2 -lt 0 ]] && sp2=0
    FRAME+=("$(bline "$(printf '%*s' "$sp2" '')${cLg}${B}${sub}${R}")")

    FRAME+=("$MID")

    #Status bar
    local ts; ts=$(date '+%I:%M:%S %p')
    local up; up=$(uptime -p 2>/dev/null | sed 's/up //' | cut -c1-25)
    local aks
    if [[ $AUTO -eq 1 ]]; then aks="${cR}${B}● AUTO-KILL ON${R} ${cGr}CPU>${ACPU}% MEM>${AMEM}%${R}"
    else aks="${cGr}○ AUTO-KILL OFF${R}"; fi
    local vws; [[ $SHOWALL -eq 1 ]] && vws="${cG}ALL${R}" || vws="${cGr}TOP15${R}"
    FRAME+=("$(bline "  ${cLg}⏰ ${ts}  ⬆ ${up}${R}   ${aks}   ${cC}SORT:${SORTBY^^}${R}   ${vws}")")

    FRAME+=("$MID")

    #Column headers
    local ch="  ${cHd}${B}PID     CPU%  $(printf "%-${BW}s" 'CPU')  MEM%  $(printf "%-${BW}s" 'MEM')  STAT   PROCESS${R}"
    FRAME+=("$(bline "$ch")")
    FRAME+=("$MID")

    #Process rows 
    local scroll=0
    (( SEL >= avail )) && scroll=$(( SEL - avail + 1 ))

    local disp=0 i
    for (( i=scroll; i<cnt && disp<avail; i++ )); do
        local pid="${PIDS[$i]}" nm="${NAMES[$i]}" st="${STATS[$i]}"
        local cp="${CPU[$i]}"; [[ -z $cp ]] && cp=0
        local mp="${MEM[$i]}"; [[ -z $mp ]] && mp=0
        [[ $cp -gt 100 ]] && cp=100; [[ $mp -gt 100 ]] && mp=100

        local sc
        case "${st:0:1}" in R) sc=$cY;; D) sc=$cO;; Z) sc=$cR;; T) sc=$cGr;; *) sc=$cG;; esac

        # Max name length to fit line
        local mn=$(( iw - 62 )); [[ $mn -lt 8 ]] && mn=8; [[ $mn -gt 40 ]] && mn=40

        local cb; cb=$(bar "$cp" "$BW")
        local mb; mb=$(bar "$mp" "$BW")

        local row
        if [[ $i -eq $SEL ]]; then
            row="${cSB}${cR}${B} ▶${R}${cSB} ${cC}$(printf '%-6s' "$pid")${R}${cSB} ${cY}$(printf '%4s' "$cp")%%${R}${cSB}  ${cb}${cSB}  ${cP}$(printf '%4s' "$mp")%%${R}${cSB}  ${mb}${cSB}  ${sc}$(printf '%-5s' "$st")${R}${cSB}  ${cW}$(printf "%-${mn}s" "${nm:0:$mn}")${R}"
        else
            row="   ${cC}$(printf '%-6s' "$pid")${R} ${cY}$(printf '%4s' "$cp")%%${R}  ${cb}  ${cP}$(printf '%4s' "$mp")%%${R}  ${mb}  ${sc}$(printf '%-5s' "$st")${R}  ${cLg}$(printf "%-${mn}s" "${nm:0:$mn}")${R}"
        fi
        FRAME+=("$(bline "$row")")
        (( disp++ ))
    done

    # Empty rows to fill space
    for (( j=disp; j<avail; j++ )); do
        FRAME+=("$(bline "")")
    done

    FRAME+=("$MID")

    #System summary
    local cs; cs=$(awk '/^cpu /{u=$2+$4;t=$2+$3+$4+$5;print int(u/t*100)}' /proc/stat 2>/dev/null || echo 0)
    local mi; mi=$(free -m 2>/dev/null | awk '/Mem:/{printf "%dMB/%dMB (%.0f%%)",$3,$2,$3/$2*100}')
    local pc; pc=$(ps --no-headers ax 2>/dev/null | wc -l)
    local csb; csb=$(bar "${cs:-0}" 14)
    FRAME+=("$(bline "  ${cLg}SYS CPU:${R} ${csb} ${cY}${cs:-0}%%${R}   ${cLg}RAM: ${cP}${mi}${R}   ${cLg}PROCS: ${cC}${pc}${R}   ${cLg}LOG: ${cGr}${LOG}${R}")")

    #Alert 
    local now; now=$(date +%s)
    if [[ -n "$AMSG" && $(( now - ATIME )) -lt 4 ]]; then
        FRAME+=("$MID")
        FRAME+=("$(bline "  ${cR}${B}⚡ ${AMSG}${R}")")
    fi

    FRAME+=("$MID")

    #Keybinds
    local kb="  ${cR}[K]${R}ill  ${cY}[A]${R}uto-Kill  ${cG}[↑↓]${R}Navigate  ${cC}[S]${R}ort  ${cO}[T]${R}hreshold  ${cP}[L]${R}og  ${cLg}[V]${R}iew-All  ${cW}[R]${R}efresh  ${cGr}[Q]${R}uit"
    FRAME+=("$(bline "$kb")")
    FRAME+=("$BOT")

    #ATOMIC PRINT
    {
        goto 1 1
        for line in "${FRAME[@]}"; do
            printf "%b\n" "$line"
        done
        # Clear any leftover lines below our frame
        printf '\033[J'
    }

    #Auto-kill engine
    if [[ $AUTO -eq 1 ]]; then
        for (( i=0; i<cnt; i++ )); do
            local c=${CPU[$i]} m=${MEM[$i]}
            (( c > ACPU || m > AMEM )) || continue
            local n=${NAMES[$i]} p=${PIDS[$i]}
            case "$n" in systemd|init|bash|sshd|AutoKillSYS*|ps|awk) continue;; esac
            kill -9 "$p" 2>/dev/null && {
                log "AUTO-KILLED pid=$p name=$n cpu=${c}% mem=${m}%"
                AMSG="AUTO-KILLED: $n (PID $p) CPU:${c}% MEM:${m}%"
                ATIME=$(date +%s)
            }
        done
    fi
}

#Kill selected 
kill_selected() {
    local pid="${PIDS[$SEL]}" nm="${NAMES[$SEL]}"
    [[ -z "$pid" ]] && return
    local r; r=$(ROWS); local c; c=$(COLS)
    goto $(( r - 1 )) 2
    printf "${cR}${B}KILL PID ${pid} (${nm})? [y/N]: ${R}"
    show_cur; read -r -s -n1 ans; hide_cur
    if [[ "$ans" =~ ^[Yy]$ ]]; then
        kill -9 "$pid" 2>/dev/null
        log "KILLED pid=$pid name=$nm"
        AMSG="KILLED: $nm (PID $pid)"; ATIME=$(date +%s)
    fi
}

#Set thresholds
set_thresh() {
    local r; r=$(ROWS)
    goto $(( r - 1 )) 2
    printf "${cY}CPU%% threshold [now:${ACPU}]: ${R}"
    show_cur; read -r -t 15 v; hide_cur
    [[ "$v" =~ ^[0-9]+$ && $v -le 100 ]] && ACPU=$v
    goto $(( r - 1 )) 2; printf '%*s' 60 ''   # clear line
    goto $(( r - 1 )) 2
    printf "${cP}MEM%% threshold [now:${AMEM}]: ${R}"
    show_cur; read -r -t 15 v; hide_cur
    [[ "$v" =~ ^[0-9]+$ && $v -le 100 ]] && AMEM=$v
    log "Thresholds: CPU>${ACPU}% MEM>${AMEM}%"
}

#View log
view_log() {
    show_cur; tput rmcup 2>/dev/null
    echo -e "\n${cBd}══════════ AutoKillSYS Log ══════════${R}"
    if [[ -f "$LOG" ]]; then
        tail -40 "$LOG" | while IFS= read -r l; do echo -e "  ${cLg}${l}${R}"; done
    else echo -e "  ${cGr}No log entries yet.${R}"; fi
    echo -e "\n${cR}  Press any key to return...${R}"; read -r -s -n1
    hide_cur; tput smcup 2>/dev/null; clr
}

#Splash 
splash() {
    local r; r=$(ROWS); local c; c=$(COLS); clr
    goto $(( r/2 - 1 )) 1
    local t="AutoKillSYS — Process Management & Auto-Kill System"
    local p=$(( (c - ${#t}) / 2 ))
    printf "%*s${cR}${B}%s${R}\n" "$p" '' "$t"
    printf "%*s${cLg}Initializing...${R}\n\n" $(( p+4 )) ''
    printf "%*s${cBd}[${R}" "$p" ''
    local i; for (( i=0; i<32; i++ )); do printf "${cR}█${R}"; sleep 0.02; done
    printf "${cBd}]${R}\n"; sleep 0.2; clr
}

#Input 
input() {
    local key cnt=${#PIDS[@]}
    IFS= read -r -s -t 0.15 -n3 key 2>/dev/null
    case "$key" in
        $'\e[A') (( SEL > 0 )) && (( SEL-- )) ;;
        $'\e[B') (( SEL < cnt-1 )) && (( SEL++ )) ;;
        [kK]) kill_selected ;;
        [aA]) (( AUTO ^= 1 )); log "Auto-kill toggled: $AUTO" ;;
        [sS]) case "$SORTBY" in cpu) SORTBY=mem;; mem) SORTBY=pid;; pid) SORTBY=name;; *) SORTBY=cpu;; esac ;;
        [tT]) set_thresh ;;
        [lL]) view_log ;;
        [vV]) (( SHOWALL ^= 1 )); SEL=0 ;;
        [rR]) : ;;
        [qQ]) exit 0 ;;
    esac
}

#Main
main() {
    local r; r=$(ROWS); local c; c=$(COLS)
    if (( r < 24 || c < 70 )); then
        echo "Terminal too small: need 90×26 minimum, got ${c}×${r}."
        echo "Please maximize your terminal window and retry."
        exit 1
    fi
    echo "# AutoKillSYS started $(date)" >> "$LOG"
    tput smcup 2>/dev/null
    hide_cur; clr; splash
    local last=0
    while true; do
        local now; now=$(date +%s)
        (( now - last >= REFRESH )) && { render; last=$now; }
        input
    done
}

main "$@"
