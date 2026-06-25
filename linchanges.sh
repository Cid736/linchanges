#!/usr/bin/env bash
# linchanges.sh — Herramientas del sistema para Linux
# Uso: bash linchanges.sh   (algunas opciones requieren sudo)

# ── Colores ───────────────────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
C='\033[0;36m' W='\033[0;37m' D='\033[2m' RESET='\033[0m'

e()   { echo -e "$@"; }
sep() { e "${D}  $(printf '─%.0s' $(seq 1 56))${RESET}"; }
pause() { read -rp $'\n  Pulsa Enter para continuar...' _; }

is_root()   { [[ $EUID -eq 0 ]]; }
need_root() {
    if ! is_root; then
        e "\n${R}  [!] Esta opción requiere root. Ejecuta con sudo.${RESET}"
        pause; return 1
    fi
    return 0
}

on_off() {
    if [[ "$1" == "1" || "$1" == "true" || "$1" == "active" || "$1" == "yes" ]]; then
        printf "${G} [ON] ${RESET}"
    else
        printf "${R} [OFF]${RESET}"
    fi
}

# Devuelve 0 (bloqueado/saltar) o 1 (libre/proceder).
# Si bloqueado, pregunta al usuario que quiere hacer.
apt_locked() {
    local lock="/var/cache/apt/archives/lock"
    local lock2="/var/lib/dpkg/lock-frontend"
    local held=""

    if ! command -v fuser &>/dev/null; then
        # fuser no disponible: intentar detectar lock via lsof
        if command -v lsof &>/dev/null; then
            held=$(lsof "$lock2" 2>/dev/null | awk 'NR>1{print $2; exit}')
        fi
        [[ -z "$held" ]] && return 1
    else
        fuser "$lock"  >/dev/null 2>&1 && held=$(fuser "$lock"  2>/dev/null | tr -d ' ')
        fuser "$lock2" >/dev/null 2>&1 && held=$(fuser "$lock2" 2>/dev/null | tr -d ' ')
    fi

    [[ -z "$held" ]] && return 1  # libre, proceder

    local pname
    pname=$(ps -p "$held" -o comm= 2>/dev/null || echo "desconocido")
    e "\n${Y}  [!] apt bloqueado por proceso ${held} (${pname}).${RESET}"
    e ""
    e "  [K]  Matar el proceso y continuar"
    e "  [W]  Esperar a que termine (max 60s)"
    e "  [S]  Saltar esta operacion"
    printf "\n  ${C}> ${RESET}"; read -r _apt_choice

    case ${_apt_choice^^} in
        K)
            kill "$held" 2>/dev/null
            sleep 1
            kill -9 "$held" 2>/dev/null || true
            sleep 1
            e "  ${G}[OK] Proceso ${held} terminado.${RESET}"
            return 1  # libre ahora, proceder
            ;;
        W)
            local waited=0
            printf "  Esperando"
            while fuser "$lock2" >/dev/null 2>&1 || fuser "$lock" >/dev/null 2>&1; do
                if [[ $waited -ge 60 ]]; then
                    e "\n  ${Y}Tiempo agotado. Saltando.${RESET}"
                    return 0
                fi
                sleep 3; waited=$((waited+3))
                printf "."
            done
            e "\n  ${G}[OK] apt disponible.${RESET}"
            return 1  # libre, proceder
            ;;
        *)
            e "  ${D}Operacion saltada.${RESET}"
            return 0  # bloqueado, saltar
            ;;
    esac
}

detect_pkg() {
    command -v apt-get &>/dev/null  && echo "apt"    && return
    command -v dnf     &>/dev/null  && echo "dnf"    && return
    command -v pacman  &>/dev/null  && echo "pacman" && return
    command -v zypper  &>/dev/null  && echo "zypper" && return
    echo "unknown"
}
PKG=$(detect_pkg)

svc_active()  { systemctl is-active  "$1" 2>/dev/null || echo "inactive"; }
svc_enabled() { systemctl is-enabled "$1" 2>/dev/null || echo "disabled"; }
svc_exists()  { systemctl cat "${1}.service" &>/dev/null 2>&1; }

# ── Banner ────────────────────────────────────────────────────────────────────
banner() {
    clear
    e ""
    e "${C}  ┌────────────────────────────────────────────────────────┐${RESET}"
    e "${C}  │   L I N C H A N G E S  v1.0  —  Herramientas del sistema   │${RESET}"
    e "${C}  └────────────────────────────────────────────────────────┘${RESET}"
    if is_root; then
        e "${G}  [root] — acceso completo${RESET}"
    else
        e "${Y}  [usuario] — algunas opciones requieren sudo${RESET}"
    fi
    e ""
}

# ════════════════════════════════════════════════════════════════════════════════
#  1. SISTEMA
# ════════════════════════════════════════════════════════════════════════════════
show_system() {
    banner
    e "  ${Y}── INFORMACIÓN DEL SISTEMA ──────────────────────────────${RESET}"
    e ""

    # SO
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        e "  ${D}SO           :${RESET} ${PRETTY_NAME:-$NAME}"
    fi
    e "  ${D}Kernel       :${RESET} $(uname -r)"
    e "  ${D}Arquitectura :${RESET} $(uname -m)"
    e "  ${D}Hostname     :${RESET} $(hostname)"
    e "  ${D}Usuario      :${RESET} $(whoami)"
    e "  ${D}Uptime       :${RESET} $(uptime -p 2>/dev/null || uptime)"

    sep

    # CPU
    local cpu cores
    cpu=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
    cores=$(grep -c '^processor' /proc/cpuinfo 2>/dev/null)
    [[ -n $cpu ]]   && e "  ${D}CPU          :${RESET} $cpu"
    [[ -n $cores ]] && e "  ${D}Cores        :${RESET} $cores"

    local load
    load=$(awk '{print $1" "$2" "$3}' /proc/loadavg 2>/dev/null)
    e "  ${D}Carga 1/5/15m:${RESET} $load"

    sep

    # RAM
    local mem_total mem_free mem_used swap_total swap_free
    mem_total=$(awk '/MemTotal/    {printf "%.1f", $2/1024/1024}' /proc/meminfo)
    mem_free=$(awk  '/MemAvailable/{printf "%.1f", $2/1024/1024}' /proc/meminfo)
    mem_used=$(awk  '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{printf "%.1f",(t-a)/1024/1024}' /proc/meminfo)
    swap_total=$(awk '/SwapTotal/{printf "%.1f",$2/1024/1024}' /proc/meminfo)
    swap_free=$(awk  '/SwapFree/ {printf "%.1f",$2/1024/1024}' /proc/meminfo)

    e "  ${D}RAM          :${RESET} ${mem_used} GB usados / ${mem_total} GB total (${mem_free} GB libres)"
    e "  ${D}Swap         :${RESET} ${swap_total} GB total / ${swap_free} GB libres"

    sep

    # Disco
    e "  ${D}Discos:${RESET}"
    df -h --output=target,size,used,avail,pcent 2>/dev/null \
        | grep -v -E 'tmpfs|udev|/snap|Filesystem' \
        | awk '{printf "    %-20s %5s  usados:%-6s  libres:%-6s  %s\n", $1,$2,$3,$4,$5}'

    sep

    # GPU (si está disponible)
    if command -v lspci &>/dev/null; then
        local gpu
        gpu=$(lspci 2>/dev/null | grep -iE 'VGA|3D|Display' | head -1 | sed 's/.*: //')
        [[ -n $gpu ]] && e "  ${D}GPU          :${RESET} $gpu"
    fi

    # Red
    sep
    e "  ${D}Red:${RESET}"
    ip -4 addr show 2>/dev/null \
        | awk '/^[0-9]+:/{iface=$2; gsub(/:$/,"",iface)} /inet /{printf "    %-12s %s\n",iface,$2}' \
        | grep -v '127.0'

    local gw
    gw=$(ip route show default 2>/dev/null | awk '/default/{print $3}' | head -1)
    [[ -n $gw ]] && e "  ${D}Gateway      :${RESET} $gw"

    e ""
    pause
}

# ════════════════════════════════════════════════════════════════════════════════
#  2. PRIVACIDAD
# ════════════════════════════════════════════════════════════════════════════════
show_privacy() {
    while true; do
        banner
        e "  ${Y}── PRIVACIDAD ────────────────────────────────────────────${RESET}"
        e ""

        # Apport (Ubuntu)
        local apport_en="0"
        if [[ -f /etc/default/apport ]]; then
            [[ "$(grep -m1 'enabled=' /etc/default/apport | cut -d= -f2)" == "1" ]] && apport_en="1"
        fi

        # Popularity contest
        local popcon_en="0"
        [[ -f /etc/popularity-contest.conf ]] && \
            grep -q 'PARTICIPATE=yes' /etc/popularity-contest.conf 2>/dev/null && popcon_en="1"

        # Core dumps
        local core_en="0"
        local climit
        climit=$(ulimit -c 2>/dev/null)
        [[ "$climit" != "0" && "$climit" != "" ]] && core_en="1"

        # systemd-coredump
        local coredump_en="0"
        if [[ -f /etc/systemd/coredump.conf ]]; then
            grep -q 'Storage=external' /etc/systemd/coredump.conf 2>/dev/null && coredump_en="1"
        fi

        printf "  [1]"; on_off "$apport_en";   e "  Informes de fallos Apport ${D}(Ubuntu/Debian)${RESET}"
        printf "  [2]"; on_off "$popcon_en";   e "  Estadísticas de paquetes popularity-contest"
        printf "  [3]"; on_off "$core_en";     e "  Core dumps (ulimit)"
        printf "  [4]"; on_off "$coredump_en"; e "  systemd-coredump (volcados del sistema)"
        e ""
        e "  [I]  Información sobre privacidad en Linux"
        e "  [A]  Desactivar todo"
        e "  [0]  Volver"
        e ""
        printf "  ${C}> ${RESET}"; read -r opt

        case $opt in
            1)
                need_root || continue
                if [[ $apport_en == "1" ]]; then
                    sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport 2>/dev/null
                    systemctl stop apport 2>/dev/null || true
                    e "\n${G}  [OK] Apport desactivado.${RESET}"
                else
                    [[ -f /etc/default/apport ]] && sed -i 's/^enabled=.*/enabled=1/' /etc/default/apport
                    systemctl start apport 2>/dev/null || true
                    e "\n${G}  [OK] Apport activado.${RESET}"
                fi
                pause ;;
            2)
                need_root || continue
                if [[ $popcon_en == "1" ]]; then
                    sed -i 's/^PARTICIPATE=yes/PARTICIPATE=no/' /etc/popularity-contest.conf 2>/dev/null
                    e "\n${G}  [OK] Popularity-contest desactivado.${RESET}"
                else
                    sed -i 's/^PARTICIPATE=no/PARTICIPATE=yes/' /etc/popularity-contest.conf 2>/dev/null || true
                    e "\n${G}  [OK] Popularity-contest activado.${RESET}"
                fi
                pause ;;
            3)
                need_root || continue
                if [[ $core_en == "1" ]]; then
                    grep -q 'core 0' /etc/security/limits.conf 2>/dev/null || \
                        printf '* hard core 0\n* soft core 0\n' >> /etc/security/limits.conf
                    e "\n${G}  [OK] Core dumps desactivados (efectivo en próxima sesión).${RESET}"
                else
                    sed -i '/core 0/d' /etc/security/limits.conf 2>/dev/null
                    e "\n${G}  [OK] Core dumps habilitados.${RESET}"
                fi
                pause ;;
            4)
                need_root || continue
                if [[ $coredump_en == "1" ]]; then
                    sed -i 's/^Storage=external/Storage=none/' /etc/systemd/coredump.conf 2>/dev/null || \
                        mkdir -p /etc/systemd && echo -e '[Coredump]\nStorage=none' > /etc/systemd/coredump.conf
                    e "\n${G}  [OK] systemd-coredump desactivado.${RESET}"
                else
                    sed -i 's/^Storage=none/Storage=external/' /etc/systemd/coredump.conf 2>/dev/null || true
                    e "\n${G}  [OK] systemd-coredump activado.${RESET}"
                fi
                pause ;;
            [Ii])
                banner
                e "  ${Y}── Privacidad en Linux ──────────────────────────────────${RESET}"
                e ""
                e "  Linux es mucho más privado que Windows por defecto."
                e "  Las principales fuentes de datos en distros comunes:"
                e ""
                e "  ${D}Apport${RESET}              — reporta crashes al desarrollador (Ubuntu)"
                e "  ${D}popularity-contest${RESET}  — envía estadísticas de paquetes usados"
                e "  ${D}systemd-coredump${RESET}    — guarda volcados de memoria del sistema"
                e ""
                e "  Arch Linux, Fedora (pura) y Debian no tienen telemetría."
                e "  Ubuntu desde 20.04 tiene ubuntu-report, desactivable:"
                e "  ${C}  ubuntu-report send no${RESET}"
                e ""
                pause ;;
            [Aa])
                need_root || continue
                [[ -f /etc/default/apport ]] && sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
                [[ -f /etc/popularity-contest.conf ]] && sed -i 's/^PARTICIPATE=yes/PARTICIPATE=no/' /etc/popularity-contest.conf
                grep -q 'core 0' /etc/security/limits.conf 2>/dev/null || \
                    printf '* hard core 0\n* soft core 0\n' >> /etc/security/limits.conf
                e "\n${G}  [OK] Privacidad máxima aplicada.${RESET}"
                pause ;;
            0) return ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════
#  3. RENDIMIENTO
# ════════════════════════════════════════════════════════════════════════════════
show_performance() {
    while true; do
        banner
        e "  ${Y}── RENDIMIENTO ───────────────────────────────────────────${RESET}"
        e ""

        local swappiness gov iosched thp
        swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "?")
        gov="N/A"
        [[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]] && \
            gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
        iosched="N/A"
        for dev in sda nvme0n1 vda mmcblk0; do
            [[ -f /sys/block/$dev/queue/scheduler ]] && \
                iosched=$(grep -o '\[.*\]' /sys/block/$dev/queue/scheduler | tr -d '[]') && break
        done
        thp="N/A"
        [[ -f /sys/kernel/mm/transparent_hugepage/enabled ]] && \
            thp=$(grep -o '\[.*\]' /sys/kernel/mm/transparent_hugepage/enabled | tr -d '[]')

        e "  ${D}Swappiness actual     :${RESET} ${C}${swappiness}${RESET}  ${D}(10 = escritorio, 1 = servidor)${RESET}"
        e "  ${D}Gobernador CPU        :${RESET} ${C}${gov}${RESET}"
        e "  ${D}Planificador I/O      :${RESET} ${C}${iosched}${RESET}"
        e "  ${D}Transparent HugePages :${RESET} ${C}${thp}${RESET}"
        e ""
        e "  [1]  Swappiness → 10  (escritorio, recomendado)"
        e "  [2]  Swappiness → 1   (servidor / base de datos)"
        e "  [3]  Swappiness → 60  (por defecto)"
        sep
        e "  [4]  CPU governor → performance"
        e "  [5]  CPU governor → powersave"
        e "  [6]  CPU governor → ondemand"
        sep
        e "  [7]  Transparent HugePages → madvise  (recomendado general)"
        e "  [8]  Transparent HugePages → never    (máx. rendimiento DB)"
        e "  [9]  Transparent HugePages → always"
        e ""
        e "  [0]  Volver"
        e ""
        printf "  ${C}> ${RESET}"; read -r opt

        if [[ $opt == "0" ]]; then return; fi
        need_root || continue

        case $opt in
            1) sysctl -w vm.swappiness=10  >/dev/null
               echo 'vm.swappiness=10'  > /etc/sysctl.d/99-lintoys.conf
               e "\n${G}  [OK] Swappiness = 10${RESET}"; pause ;;
            2) sysctl -w vm.swappiness=1   >/dev/null
               echo 'vm.swappiness=1'   > /etc/sysctl.d/99-lintoys.conf
               e "\n${G}  [OK] Swappiness = 1${RESET}"; pause ;;
            3) sysctl -w vm.swappiness=60  >/dev/null
               echo 'vm.swappiness=60'  > /etc/sysctl.d/99-lintoys.conf
               e "\n${G}  [OK] Swappiness = 60${RESET}"; pause ;;
            4) for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                   echo performance > "$f" 2>/dev/null || true
               done
               e "\n${G}  [OK] Governor → performance${RESET}"; pause ;;
            5) for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                   echo powersave > "$f" 2>/dev/null || true
               done
               e "\n${G}  [OK] Governor → powersave${RESET}"; pause ;;
            6) for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
                   echo ondemand > "$f" 2>/dev/null || true
               done
               e "\n${G}  [OK] Governor → ondemand${RESET}"; pause ;;
            7) echo madvise > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
               e "\n${G}  [OK] THP → madvise${RESET}"; pause ;;
            8) echo never   > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
               e "\n${G}  [OK] THP → never${RESET}"; pause ;;
            9) echo always  > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
               e "\n${G}  [OK] THP → always${RESET}"; pause ;;
            0) return ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════
#  4. LIMPIEZA
# ════════════════════════════════════════════════════════════════════════════════
dir_size() { du -sh "$1" 2>/dev/null | cut -f1 || echo "?"; }

show_cleanup() {
    # Detecta home del usuario real aunque se ejecute con sudo
    local REAL_HOME
    if [[ -n "${SUDO_USER:-}" ]]; then
        REAL_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    else
        REAL_HOME="$HOME"
    fi

    while true; do
        banner
        e "  ${Y}── LIMPIEZA ──────────────────────────────────────────────${RESET}"
        e "  Calculando tamanos..."

        local tmp_sz home_cache thumb_sz log_sz journal_sz pkg_cache
        tmp_sz=$(dir_size /tmp)
        home_cache=$(dir_size "$REAL_HOME/.cache")
        thumb_sz=$(dir_size "$REAL_HOME/.cache/thumbnails" 2>/dev/null || echo "0")
        log_sz=$(dir_size /var/log)
        journal_sz=$(journalctl --disk-usage 2>/dev/null | grep -oP '\d+(\.\d+)?\s*\w+' | tail -1 || echo "?")

        case $PKG in
            apt)    pkg_cache=$(dir_size /var/cache/apt/archives) ;;
            dnf)    pkg_cache=$(dir_size /var/cache/dnf) ;;
            pacman) pkg_cache=$(dir_size /var/cache/pacman/pkg) ;;
            *)      pkg_cache="N/A" ;;
        esac

        e ""
        e "  [1]  /tmp                      : ${Y}${tmp_sz}${RESET}"
        e "  [2]  ~/.cache                  : ${Y}${home_cache}${RESET}  ${D}($REAL_HOME/.cache)${RESET}"
        e "  [3]  ~/.cache/thumbnails       : ${Y}${thumb_sz}${RESET}"
        e "  [4]  /var/log (logs sistema)   : ${Y}${log_sz}${RESET}"
        e "  [5]  Diarios systemd (journald): ${Y}${journal_sz}${RESET}"
        e "  [6]  Cache paquetes ($PKG)     : ${Y}${pkg_cache}${RESET}"
        e "  [7]  Paquetes huerfanos / obsoletos"
        e "  [8]  Kernels antiguos ${D}(solo apt/dnf)${RESET}"
        e ""
        e "  ${Y}[A]  Limpiar TODO (seguro)${RESET}"
        e "  [0]  Volver"
        e ""
        printf "  ${C}> ${RESET}"; read -r opt

        case $opt in
            1)
                need_root || continue
                find /tmp -mindepth 1 -delete 2>/dev/null || true
                e "\n${G}  [OK] /tmp limpiado.${RESET}"; pause ;;
            2)
                rm -rf "$REAL_HOME/.cache/"* 2>/dev/null || true
                e "\n${G}  [OK] ~/.cache limpiado.${RESET}"; pause ;;
            3)
                rm -rf "$REAL_HOME/.cache/thumbnails/"* 2>/dev/null || true
                e "\n${G}  [OK] Miniaturas limpiadas.${RESET}"; pause ;;
            4)
                need_root || continue
                find /var/log -type f -name "*.gz"  -delete 2>/dev/null || true
                find /var/log -type f -name "*.1"   -delete 2>/dev/null || true
                find /var/log -type f -name "*.old" -delete 2>/dev/null || true
                e "\n${G}  [OK] Logs comprimidos y rotativos eliminados.${RESET}"; pause ;;
            5)
                need_root || continue
                journalctl --vacuum-size=100M 2>/dev/null || true
                journalctl --vacuum-time=14d  2>/dev/null || true
                e "\n${G}  [OK] Diarios systemd reducidos (100 MB / 14 dias).${RESET}"; pause ;;
            6)
                need_root || continue
                case $PKG in
                    apt)
                        if ! apt_locked; then
                            apt-get clean -y 2>/dev/null
                            e "\n${G}  [OK] Cache apt limpiado.${RESET}"
                        fi ;;
                    dnf)    dnf clean all && e "\n${G}  [OK] Cache dnf limpiado.${RESET}" ;;
                    pacman) pacman -Sc --noconfirm && e "\n${G}  [OK] Cache pacman limpiado.${RESET}" ;;
                    zypper) zypper clean -a && e "\n${G}  [OK] Cache zypper limpiado.${RESET}" ;;
                    *)      e "  ${Y}Gestor de paquetes no soportado.${RESET}" ;;
                esac
                pause ;;
            7)
                need_root || continue
                case $PKG in
                    apt)
                        if apt_locked; then :
                        elif apt-get autoremove --purge -y 2>/dev/null; then
                            e "\n${G}  [OK] Paquetes huerfanos eliminados.${RESET}"
                        else
                            e "\n${Y}  [!] Error al ejecutar apt.${RESET}"
                        fi ;;
                    dnf)    dnf autoremove -y && e "\n${G}  [OK] Hecho.${RESET}" ;;
                    pacman)
                        local orphans
                        orphans=$(pacman -Qdtq 2>/dev/null)
                        if [[ -n "$orphans" ]]; then
                            # word-split intencionado: cada linea es un paquete
                            # shellcheck disable=SC2086
                            pacman -Rns --noconfirm $orphans 2>/dev/null
                            e "\n${G}  [OK] Huerfanos eliminados.${RESET}"
                        else
                            e "  ${D}No hay paquetes huerfanos.${RESET}"
                        fi ;;
                    *)  e "  ${Y}No disponible para $PKG.${RESET}" ;;
                esac
                pause ;;
            8)
                need_root || continue
                case $PKG in
                    apt)
                        if apt_locked; then :
                        elif apt-get autoremove --purge -y 2>/dev/null; then
                            e "\n${G}  [OK] Kernels y paquetes obsoletos eliminados.${RESET}"
                        else
                            e "\n${Y}  [!] Error al ejecutar apt.${RESET}"
                        fi ;;
                    dnf)
                        local old_kernels
                        old_kernels=$(dnf repoquery --installonly --latest-limit=-2 -q 2>/dev/null)
                        if [[ -n "$old_kernels" ]]; then
                            echo "$old_kernels" | xargs dnf remove -y 2>/dev/null
                            e "\n${G}  [OK] Kernels antiguos eliminados.${RESET}"
                        else
                            e "  ${D}No hay kernels antiguos que eliminar.${RESET}"
                        fi ;;
                    *)  e "  ${Y}Solo disponible para apt/dnf.${RESET}" ;;
                esac
                pause ;;
            [Aa])
                need_root || continue
                e ""
                find /tmp -mindepth 1 -delete 2>/dev/null && e "  [OK] /tmp" || true
                rm -rf "$REAL_HOME/.cache/"* 2>/dev/null && e "  [OK] ~/.cache" || true
                find /var/log -type f \( -name "*.gz" -o -name "*.1" -o -name "*.old" \) -delete 2>/dev/null && e "  [OK] logs rotativos" || true
                journalctl --vacuum-size=100M 2>/dev/null || true
                journalctl --vacuum-time=14d  2>/dev/null || true
                e "  [OK] journald"
                case $PKG in
                    apt)
                        if ! apt_locked; then
                            apt-get clean -y 2>/dev/null && e "  [OK] cache apt" || true
                            apt-get autoremove --purge -y 2>/dev/null && e "  [OK] huerfanos apt" || true
                        fi ;;
                    dnf)    dnf clean all 2>/dev/null && e "  [OK] cache dnf" || true ;;
                    pacman) pacman -Sc --noconfirm 2>/dev/null && e "  [OK] cache pacman" || true ;;
                esac
                e "\n${G}  Limpieza completa.${RESET}"; pause ;;
            0) return ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════
#  5. APLICACIONES
# ════════════════════════════════════════════════════════════════════════════════
show_apps() {
    while true; do
        banner
        e "  ${Y}── APLICACIONES ────────────────────────────────────────${RESET}"
        e ""
        e "  Gestor detectado: ${C}${PKG}${RESET}"
        e ""
        e "  [1]  Actualizar todos los paquetes del sistema"
        e "  [2]  Listar paquetes instalados manualmente (top 50)"
        e "  [3]  Buscar paquete en repositorios"
        e "  [4]  Instalar paquete"
        e "  [5]  Eliminar paquete"
        e "  [6]  Listar los 20 paquetes más grandes"
        e "  [7]  Ver historial de instalaciones"
        e ""
        e "  [0]  Volver"
        e ""
        printf "  ${C}> ${RESET}"; read -r opt

        case $opt in
            1)
                need_root || continue
                e ""
                case $PKG in
                    apt)
                        if apt_locked; then : ; else
                            apt-get update && apt-get upgrade -y
                        fi ;;
                    dnf)    dnf upgrade -y ;;
                    pacman) pacman -Syu --noconfirm ;;
                    zypper) zypper update -y ;;
                    *)      e "  ${Y}Gestor no soportado.${RESET}" ;;
                esac
                pause ;;
            2)
                e ""
                case $PKG in
                    apt)    apt-mark showmanual 2>/dev/null | head -50 ;;
                    dnf)    dnf history userinstalled 2>/dev/null | head -50 ;;
                    pacman) pacman -Qe 2>/dev/null | head -50 ;;
                    *)      e "  ${Y}No disponible.${RESET}" ;;
                esac
                pause ;;
            3)
                printf "\n  ${C}Término de búsqueda: ${RESET}"; read -r term
                [[ -z "$term" ]] && continue
                e ""
                case $PKG in
                    apt)    apt-cache search "$term" 2>/dev/null | head -20 ;;
                    dnf)    dnf search "$term" 2>/dev/null | head -20 ;;
                    pacman) pacman -Ss "$term" 2>/dev/null | head -20 ;;
                    *)      e "  ${Y}No disponible.${RESET}" ;;
                esac
                pause ;;
            4)
                need_root || continue
                printf "\n  ${C}Nombre del paquete: ${RESET}"; read -r pkg_name
                [[ -z "$pkg_name" ]] && continue
                if ! [[ "$pkg_name" =~ ^[a-zA-Z0-9_.+\-]+$ ]]; then
                    e "\n${Y}  [!] Nombre de paquete inválido.${RESET}"; pause; continue
                fi
                e ""
                case $PKG in
                    apt)    apt_locked || apt-get install -y "$pkg_name" ;;
                    dnf)    dnf install -y "$pkg_name" ;;
                    pacman) pacman -S --noconfirm "$pkg_name" ;;
                    zypper) zypper install -y "$pkg_name" ;;
                    *)      e "  ${Y}No disponible.${RESET}" ;;
                esac
                pause ;;
            5)
                need_root || continue
                printf "\n  ${C}Nombre del paquete a eliminar: ${RESET}"; read -r pkg_name
                [[ -z "$pkg_name" ]] && continue
                if ! [[ "$pkg_name" =~ ^[a-zA-Z0-9_.+\-]+$ ]]; then
                    e "\n${Y}  [!] Nombre de paquete inválido.${RESET}"; pause; continue
                fi
                e ""
                case $PKG in
                    apt)    apt_locked || apt-get remove --purge -y "$pkg_name" ;;
                    dnf)    dnf remove -y "$pkg_name" ;;
                    pacman) pacman -Rns --noconfirm "$pkg_name" ;;
                    zypper) zypper remove -y "$pkg_name" ;;
                    *)      e "  ${Y}No disponible.${RESET}" ;;
                esac
                pause ;;
            6)
                e ""
                case $PKG in
                    apt)
                        dpkg-query -W --showformat='${Installed-Size}\t${Package}\n' 2>/dev/null \
                            | sort -rn | head -20 \
                            | awk '{printf "  %8d KB  %s\n", $1, $2}' ;;
                    dnf)
                        rpm -qa --queryformat '%{SIZE} %{NAME}\n' 2>/dev/null \
                            | sort -rn | head -20 \
                            | awk '{printf "  %8.1f MB  %s\n", $1/1024/1024, $2}' ;;
                    pacman)
                        expac -s "%-30n %m" 2>/dev/null | sort -rhk 2 | head -20 ;;
                    *)  e "  ${Y}No disponible.${RESET}" ;;
                esac
                pause ;;
            7)
                e ""
                case $PKG in
                    apt)    grep -i 'install\|upgrade' /var/log/dpkg.log 2>/dev/null | tail -30 ;;
                    dnf)    dnf history list 2>/dev/null | head -20 ;;
                    pacman) grep 'installed\|upgraded' /var/log/pacman.log 2>/dev/null | tail -30 ;;
                    *)      e "  ${Y}No disponible.${RESET}" ;;
                esac
                pause ;;
            0) return ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════
#  6. SERVICIOS
# ════════════════════════════════════════════════════════════════════════════════
SVCS=("ssh" "cron" "docker" "nginx" "apache2" "mysql" "mariadb" "postgresql" "ufw" "fail2ban" "bluetooth" "cups" "avahi-daemon" "NetworkManager" "firewalld")
LBLS=("SSH Server" "Cron (tareas programadas)" "Docker" "Nginx" "Apache2" "MySQL" "MariaDB" "PostgreSQL" "Firewall UFW" "Fail2ban" "Bluetooth" "Impresión CUPS" "Avahi mDNS" "NetworkManager" "FirewallD")

show_services() {
    while true; do
        banner
        e "  ${Y}── SERVICIOS (systemd) ──────────────────────────────────${RESET}"
        e ""

        local i
        for i in "${!SVCS[@]}"; do
            local svc="${SVCS[$i]}" label="${LBLS[$i]}"
            local num=$((i+1))
            printf "  [%02d]" $num
            if svc_exists "$svc"; then
                local active
                active=$(svc_active "$svc")
                if [[ $active == "active" ]]; then
                    printf " ${G}[activo] ${RESET}"
                else
                    printf " ${R}[parado] ${RESET}"
                fi
                e " $label"
            else
                printf " ${D}[N/A]    ${RESET}"
                e " $label"
            fi
        done

        e ""
        e "  [L]  Listar todos los servicios activos"
        e "  [0]  Volver"
        e ""
        printf "  ${C}Número o L/0: ${RESET}"; read -r opt

        case $opt in
            [Ll])
                e ""
                systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null | head -30
                pause ;;
            0) return ;;
            *)
                if [[ "$opt" =~ ^[0-9]+$ ]] && [[ $opt -ge 1 ]] && [[ $opt -le ${#SVCS[@]} ]]; then
                    need_root || continue
                    local idx=$((opt-1))
                    local svc="${SVCS[$idx]}"
                    if svc_exists "$svc"; then
                        local active
                        active=$(svc_active "$svc")
                        if [[ $active == "active" ]]; then
                            systemctl stop    "$svc" 2>/dev/null || true
                            systemctl disable "$svc" 2>/dev/null || true
                            e "\n${G}  [OK] $svc detenido y desactivado.${RESET}"
                        else
                            systemctl enable "$svc" 2>/dev/null || true
                            systemctl start  "$svc" 2>/dev/null || true
                            e "\n${G}  [OK] $svc habilitado e iniciado.${RESET}"
                        fi
                        pause
                    else
                        e "\n${Y}  Servicio no instalado en este sistema.${RESET}"
                        pause
                    fi
                fi ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════
#  7. RED
# ════════════════════════════════════════════════════════════════════════════════
show_network() {
    while true; do
        banner
        e "  ${Y}── RED ───────────────────────────────────────────────────${RESET}"
        e ""

        # Interfaces activas
        ip -4 addr show 2>/dev/null \
            | awk '/^[0-9]+:/{iface=$2; gsub(/:$/,"",iface)} /inet /{printf "  %-14s %s\n", iface, $2}' \
            | grep -v '127.0'

        local gw dns
        gw=$(ip route show default 2>/dev/null | awk '/default/{print $3}' | head -1)
        dns=$(grep '^nameserver' /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' '  ')
        [[ -n $gw  ]] && e "  ${D}Gateway :${RESET} $gw"
        [[ -n $dns ]] && e "  ${D}DNS     :${RESET} $dns"

        e ""
        e "  [1]  Conexiones activas (ss -tunp)"
        e "  [2]  Puertos en escucha"
        e "  [3]  Ping a 8.8.8.8"
        e "  [4]  Traceroute a 8.8.8.8"
        e "  [5]  Flush caché DNS (systemd-resolved)"
        e "  [6]  Mostrar tabla de rutas"
        e "  [7]  Reiniciar interfaz de red"
        e "  [8]  Estadísticas de tráfico por interfaz"
        e ""
        e "  [0]  Volver"
        e ""
        printf "  ${C}> ${RESET}"; read -r opt

        case $opt in
            1) e ""; ss -tunp 2>/dev/null | head -35; pause ;;
            2) e ""; ss -tlnp 2>/dev/null | grep LISTEN | sort; pause ;;
            3) e ""; ping -c 4 8.8.8.8; pause ;;
            4) e ""; (traceroute 8.8.8.8 2>/dev/null || tracepath 8.8.8.8 2>/dev/null); pause ;;
            5)
                need_root || continue
                if systemctl is-active systemd-resolved &>/dev/null; then
                    resolvectl flush-caches 2>/dev/null || systemd-resolve --flush-caches 2>/dev/null
                    e "\n${G}  [OK] Caché DNS vaciado.${RESET}"
                else
                    e "\n${Y}  systemd-resolved no está activo en este sistema.${RESET}"
                fi
                pause ;;
            6) e ""; ip route show; pause ;;
            7)
                need_root || continue
                printf "\n  ${C}Interfaz (ej: eth0, ens3, wlan0): ${RESET}"; read -r iface
                if [[ -n $iface ]]; then
                    if [[ ! -e "/sys/class/net/$iface" ]]; then
                        e "\n${Y}  [!] Interfaz '$iface' no encontrada.${RESET}"; pause; continue
                    fi
                    ip link set "$iface" down 2>/dev/null
                    ip link set "$iface" up   2>/dev/null
                    dhclient "$iface" 2>/dev/null || dhcpcd "$iface" 2>/dev/null || true
                    e "\n${G}  [OK] Interfaz $iface reiniciada.${RESET}"
                fi
                pause ;;
            8)
                e ""
                cat /proc/net/dev 2>/dev/null \
                    | awk 'NR>2 {
                        gsub(/:/, "", $1)
                        rx=$2/1024/1024; tx=$10/1024/1024
                        if ($1 != "lo") printf "  %-14s RX: %8.2f MB   TX: %8.2f MB\n", $1, rx, tx
                    }'
                pause ;;
            0) return ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════════════════════════
#  MENÚ PRINCIPAL
# ════════════════════════════════════════════════════════════════════════════════
while true; do
    banner
    e "  ${D}┌────────────────────────────────────────────────────────┐${RESET}"
    e "  ${D}│  Selecciona una categoría:                            │${RESET}"
    e "  ${D}└────────────────────────────────────────────────────────┘${RESET}"
    e ""
    e "  [1]  Sistema          — Hardware, SO, RAM, disco"
    e "  [2]  Privacidad       — Telemetría, informes de fallos"
    e "  [3]  Rendimiento      — Swappiness, CPU governor, THP"
    e "  [4]  Limpieza         — Caché, temp, logs, paquetes"
    e "  [5]  Aplicaciones     — Actualizar, instalar, buscar"
    e "  [6]  Servicios        — Estado y toggle de servicios"
    e "  [7]  Red              — Info, ping, DNS, puertos"
    e ""
    e "  [0]  Salir"
    e ""
    printf "  ${C}> ${RESET}"; read -r opt

    case $opt in
        1) show_system ;;
        2) show_privacy ;;
        3) show_performance ;;
        4) show_cleanup ;;
        5) show_apps ;;
        6) show_services ;;
        7) show_network ;;
        0) e "\n  Hasta luego.\n"; exit 0 ;;
    esac
done
