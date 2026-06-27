<p align="center">
  <a href="#english">🇬🇧 English</a> &nbsp;·&nbsp; <a href="#español">🇪🇸 Español</a>
</p>

---

<a name="english"></a>

# LinChanges

Linux system management TUI in Bash — no external dependencies, compatible with major distros.

## Features

- **7 interactive sections** in the terminal
- Real-time system info (OS, CPU, RAM, disk, GPU, network)
- Privacy controls: Apport, popularity-contest, core dumps, systemd-coredump
- Performance tuning: swappiness, CPU governor, I/O scheduler, Transparent HugePages
- Cleanup: `/tmp`, `~/.cache`, system logs, journald journals, package cache
- Package management: update, install, remove, search, orphans, old kernels
- systemd service control with active/stopped toggle
- Network tools: ping, traceroute, DNS flush, traffic statistics
- Automatic package manager detection: `apt`, `dnf`, `pacman`, `zypper`
- Smart apt lock handling: kill / wait / skip if apt is busy

## Usage

```bash
# Without root (read-only sections available)
bash linchanges.sh

# With full root access
sudo bash linchanges.sh
```

## Sections

| # | Section | Requires root |
|---|---------|---------------|
| 1 | System — hardware info, OS, uptime, network | No |
| 2 | Privacy — Apport, popcon, core dumps | Yes (toggle) |
| 3 | Performance — swappiness, CPU governor, THP | Yes (changes) |
| 4 | Cleanup — cache, temp, logs, packages | Partial |
| 5 | Apps — update, install, search | Yes (changes) |
| 6 | Services — systemd status and toggle | Yes (changes) |
| 7 | Network — info, ping, DNS, ports | Partial |

## Requirements

- Bash 4.0+
- `systemd` (for the services section)
- `iproute2` (`ip`, `ss`) — included in most distros
- `fuser` (`psmisc` package) or `lsof` — for apt lock detection
- Package manager: `apt-get`, `dnf`, `pacman` or `zypper`

## Compatibility

| Distro | Status |
|--------|--------|
| Ubuntu / Debian | ✓ Full |
| Fedora / RHEL | ✓ Full |
| Arch Linux | ✓ Full |
| openSUSE | ✓ Full |
| Alpine / Busybox | Partial (no systemd) |

## Preview

```
  ┌────────────────────────────────────────────────────────┐
  │   L I N C H A N G E S  v1.0  —  System tools         │
  └────────────────────────────────────────────────────────┘
  [root] — full access

  [1]  System          — Hardware, OS, RAM, disk
  [2]  Privacy         — Telemetry, crash reports
  [3]  Performance     — Swappiness, CPU governor, THP
  [4]  Cleanup         — Cache, temp, logs, packages
  [5]  Apps            — Update, install, search
  [6]  Services        — Status and toggle
  [7]  Network         — Info, ping, DNS, ports

  [0]  Exit
```

## License

MIT

## Security

Automated security reviews are powered by [Claude](https://claude.ai) (Anthropic AI) and run on every significant change to detect vulnerabilities, insecure patterns and dependency risks. Findings are tracked in [`BUGLOG.md`](BUGLOG.md).

**Last review:** 2026-06-28 (rev 3) — No new issues found. Full audit passed: no command injection, no eval usage, package name and network interface inputs protected by allowlist/existence checks.

Found a vulnerability? Open an issue or contact directly.

---

<a name="español"></a>

# LinChanges

TUI de administración del sistema Linux en Bash — sin dependencias externas, compatible con las principales distros.

## Características

- **7 secciones** interactivas en terminal
- Información del sistema en tiempo real (SO, CPU, RAM, disco, GPU, red)
- Control de privacidad: Apport, popularity-contest, core dumps, systemd-coredump
- Ajuste de rendimiento: swappiness, CPU governor, planificador I/O, Transparent HugePages
- Limpieza: `/tmp`, `~/.cache`, logs del sistema, diarios journald, caché de paquetes
- Gestión de paquetes: actualizar, instalar, eliminar, buscar, huérfanos, kernels antiguos
- Control de servicios systemd con toggle activo/parado
- Herramientas de red: ping, traceroute, flush DNS, estadísticas de tráfico
- Detección automática de gestor de paquetes: `apt`, `dnf`, `pacman`, `zypper`
- Gestión inteligente de bloqueos apt: kill / esperar / saltar si apt está ocupado

## Uso

```bash
# Sin root (secciones de solo lectura disponibles)
bash linchanges.sh

# Con root completo
sudo bash linchanges.sh
```

## Secciones

| # | Sección | Requiere root |
|---|---------|---------------|
| 1 | Sistema — info hardware, SO, uptime, red | No |
| 2 | Privacidad — Apport, popcon, core dumps | Sí (toggle) |
| 3 | Rendimiento — swappiness, CPU governor, THP | Sí (cambios) |
| 4 | Limpieza — caché, temp, logs, paquetes | Parcial |
| 5 | Aplicaciones — actualizar, instalar, buscar | Sí (cambios) |
| 6 | Servicios — estado y toggle systemd | Sí (cambios) |
| 7 | Red — info, ping, DNS, puertos | Parcial |

## Requisitos

- Bash 4.0+
- `systemd` (para la sección de servicios)
- `iproute2` (`ip`, `ss`) — incluido en la mayoría de distros
- `fuser` (paquete `psmisc`) o `lsof` — para detección de bloqueos apt
- Gestor de paquetes: `apt-get`, `dnf`, `pacman` o `zypper`

## Compatibilidad

| Distro | Estado |
|--------|--------|
| Ubuntu / Debian | ✓ Completo |
| Fedora / RHEL | ✓ Completo |
| Arch Linux | ✓ Completo |
| openSUSE | ✓ Completo |
| Alpine / Busybox | Parcial (sin systemd) |

## Seguridad

Las revisiones de seguridad automatizadas utilizan [Claude](https://claude.ai) (Anthropic AI) y se ejecutan en cada cambio significativo para detectar vulnerabilidades, patrones inseguros y riesgos en dependencias. Los hallazgos se registran en [`BUGLOG.md`](BUGLOG.md).

**Última revisión:** 2026-06-28 (rev 3) — Sin nuevos problemas. Auditoría completa superada: sin command injection, sin uso de eval, inputs de nombre de paquete e interfaz de red protegidos por allowlist y comprobación de existencia.

¿Encontraste una vulnerabilidad? Abre un issue o contacta directamente.
## Licencia

MIT
