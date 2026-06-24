# LinChanges

TUI de administración del sistema Linux en Bash — sin dependencias externas, compatible con las principales distros.

## Características

- **7 secciones** interactivas en terminal
- Muestra información del sistema en tiempo real (SO, CPU, RAM, disco, GPU, red)
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

## Capturas

```
  ┌────────────────────────────────────────────────────────┐
  │   L I N T O Y S  v1.0  —  Herramientas del sistema   │
  └────────────────────────────────────────────────────────┘
  [root] — acceso completo

  [1]  Sistema          — Hardware, SO, RAM, disco
  [2]  Privacidad       — Telemetría, informes de fallos
  [3]  Rendimiento      — Swappiness, CPU governor, THP
  [4]  Limpieza         — Caché, temp, logs, paquetes
  [5]  Aplicaciones     — Actualizar, instalar, buscar
  [6]  Servicios        — Estado y toggle de servicios
  [7]  Red              — Info, ping, DNS, puertos

  [0]  Salir
```

## Licencia

MIT
