# Justificación Técnica: RAID 1 + LVM

## 1. Contexto

El servidor `Servidor-Nutresa-Prod` requiere almacenamiento confiable para alojar servicios críticos (base de datos, web, archivos compartidos). Se implementó una pila de almacenamiento en dos capas: **RAID 1 por software** para redundancia y **LVM** para flexibilidad de gestión.

---

## 2. RAID 1 (Espejo por Software)

### ¿Qué es?
RAID 1 replica los datos de forma idéntica en dos discos simultáneamente. Si un disco falla, el otro continúa operando sin pérdida de datos ni interrupción del servicio.

### Implementación
| Parámetro | Valor |
|-----------|-------|
| Herramienta | `mdadm` (MD RAID — Linux software RAID) |
| Nivel | RAID 1 (espejo) |
| Discos | `/dev/sdb` + `/dev/sdc` (10 GB c/u) |
| Dispositivo resultante | `/dev/md0` |
| Capacidad efectiva | ~10 GB (50% de uso por espejo) |

### Justificación de la elección
- **Sin controladora hardware:** `mdadm` opera a nivel de kernel, sin dependencia de hardware propietario. Portable y auditable.
- **RAID 1 vs RAID 0:** RAID 0 aumenta velocidad pero sin redundancia — inaceptable para datos de producción. RAID 1 prioriza disponibilidad.
- **RAID 1 vs RAID 5:** RAID 5 requiere mínimo 3 discos. Con 2 discos disponibles, RAID 1 es la única opción con redundancia real.
- **Tolerancia a fallos:** Ante fallo de `sdb` o `sdc`, el sistema continúa operando. El disco puede reemplazarse en caliente y el arreglo se re-sincroniza automáticamente.

### Verificación
```bash
cat /proc/mdstat
# Resultado esperado: md0 : active raid1 sdc[1] sdb[0] [2/2] [UU]
```
`[UU]` = ambos discos activos y sincronizados.

---

## 3. LVM (Logical Volume Manager)

### ¿Qué es?
LVM es una capa de abstracción sobre los dispositivos de bloque que permite crear, redimensionar y gestionar volúmenes lógicos de forma dinámica, sin necesidad de reparticionar.

### Implementación
| Componente | Nombre | Detalles |
|-----------|--------|----------|
| Physical Volume | `/dev/md0` | RAID 1 como PV base |
| Volume Group | `vg-nutresa` | Agrupa el PV |
| Logical Volume | `lv-docker` | 8 GB — montado en `/datos` |
| Sistema de archivos | `ext4` | Formateo sobre el LV |
| Punto de montaje | `/datos` | Persistente vía `/etc/fstab` |

### Justificación de la elección
- **Flexibilidad:** El volumen lógico puede expandirse (`lvextend`) si el proyecto crece, sin reformatear ni migrar datos.
- **Separación del SO:** Los datos de servicios están completamente aislados del disco del sistema operativo (`/dev/sda`). Un fallo en `/datos` no afecta el SO y viceversa.
- **LVM sobre RAID:** Combinar ambas tecnologías es la práctica estándar en servidores Linux de producción: RAID provee redundancia física, LVM provee flexibilidad lógica.
- **Snapshots futuros:** LVM permite crear snapshots del volumen para backups consistentes sin detener los servicios.

---

## 4. Pila de Almacenamiento Completa

```
Capa Física:
  /dev/sdb (10GB, VirtualBox VDI)
  /dev/sdc (10GB, VirtualBox VDI)
        │
        ▼
Capa RAID (mdadm):
  /dev/md0 — RAID 1, ~10GB efectivos
        │
        ▼
Capa LVM:
  PV: /dev/md0
  VG: vg-nutresa
  LV: lv-docker (8GB)
        │
        ▼
Sistema de Archivos:
  ext4 → montado en /datos
        │
        ▼
Servicios Docker:
  /datos/nginx/       → nutresa-web (Nginx)
  /datos/postgres/    → nutresa-db (PostgreSQL)
  /datos/backend/     → nutresa-backend (Node.js)
  /datos/samba/       → smbd (Samba)
```

---

## 5. Persistencia y Arranque Automático

Se garantiza que el arreglo y el montaje sobrevivan reinicios mediante:

```bash
# /etc/mdadm/mdadm.conf — registro del arreglo RAID
ARRAY /dev/md0 metadata=1.2 UUID=<uuid>

# /etc/fstab — montaje automático del volumen lógico
/dev/vg-nutresa/lv-docker  /datos  ext4  defaults  0  2
```

Además se regeneró el `initramfs` para que el kernel reconozca el arreglo durante el boot:
```bash
sudo update-initramfs -u
```

---

## 6. Conclusión

La combinación RAID 1 + LVM sobre discos virtuales en VirtualBox simula fielmente una arquitectura de servidor Linux de producción. Provee:

| Atributo | Mecanismo |
|----------|-----------|
| Redundancia de datos | RAID 1 (espejo) |
| Flexibilidad de almacenamiento | LVM (redimensionamiento dinámico) |
| Aislamiento del SO | Disco dedicado `/dev/sda` para OS |
| Persistencia garantizada | `fstab` + `mdadm.conf` + `initramfs` |
| Escalabilidad futura | LVM permite agregar PVs y extender VGs |
