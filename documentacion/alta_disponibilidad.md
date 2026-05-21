# Alta Disponibilidad y Recuperación ante Fallos

## 1. Estrategia General

La infraestructura Nutresa implementa alta disponibilidad en múltiples capas, combinando mecanismos prácticos desplegados en la VM con estrategias conceptuales para escenarios de mayor escala.

---

## 2. Implementaciones Prácticas (Activas en la VM)

### 2.1 Redundancia de Almacenamiento — RAID 1

```
/dev/sdb ──┐
            ├── /dev/md0 (espejo activo) ── /datos
/dev/sdc ──┘
```

**Escenario de fallo:** Si `/dev/sdb` falla físicamente, el sistema continúa operando desde `/dev/sdc` sin pérdida de datos ni interrupción de servicios.

**Recuperación:**
```bash
# Verificar estado del arreglo
cat /proc/mdstat

# Reemplazar disco fallido
sudo mdadm /dev/md0 --remove /dev/sdb
sudo mdadm /dev/md0 --add /dev/sdb_nuevo
# El RAID re-sincroniza automáticamente [UU]
```

**Tiempo de recuperación estimado:** ~10 minutos (re-sincronización automática).

---

### 2.2 Recuperación Automática de Contenedores — `restart: always`

Todos los contenedores tienen política `restart: always` en Docker Compose:

| Contenedor | Comportamiento ante fallo |
|-----------|--------------------------|
| `nutresa-web` | Reinicia automáticamente en <5s |
| `nutresa-db` | Reinicia automáticamente en <5s |
| `nutresa-backend` | Reinicia automáticamente en <5s |

**Escenario de fallo:** Si un contenedor cae por error de aplicación, OOM killer, o reinicio del sistema, Docker lo levanta sin intervención manual.

**Verificación:**
```bash
# Simular fallo
docker stop nutresa-web
# El contenedor se reinicia solo en segundos
docker ps  # STATUS: Up X seconds (restarting)
```

---

### 2.3 Persistencia de Datos — Volúmenes en LVM

Los datos de PostgreSQL y Nginx están en `/datos` (fuera del contenedor). Si un contenedor se destruye y recrea, los datos persisten.

```bash
# Recrear contenedor sin perder datos
docker compose down
docker compose up -d
# Los datos de nutresadb siguen intactos en /datos/postgres/data
```

---

### 2.4 Backup Automatizado

Script `backup.sh` genera copias de seguridad de:
- Base de datos PostgreSQL (pg_dump → `.sql`)
- Archivos Samba (tar.gz)
- Configuración Nginx (tar.gz)

**Retención:** 7 días. **Ubicación:** `/datos/backups/`

**RPO (Recovery Point Objective):** Máximo 24h de pérdida de datos si se ejecuta diariamente.
**RTO (Recovery Time Objective):** ~5 minutos para restaurar desde backup.

---

### 2.5 Redespliegue Automatizado — `deploy.sh`

Ante fallo total del entorno Docker:
```bash
bash /datos/scripts/deploy.sh
# Resultado: todos los servicios operativos en <2 minutos
```

---

## 3. Estrategia Conceptual (Escalabilidad Futura)

### 3.1 Balanceo de Carga (No implementado — propuesta)

En un entorno de producción real, se añadiría un segundo servidor con la misma pila y un balanceador de carga frente a ambos:

```
Internet
    │
[Load Balancer — Nginx/HAProxy]
    ├── Servidor-Nutresa-Prod  (192.168.1.12)
    └── Servidor-Nutresa-Replica (192.168.1.13)
         └── Ambos conectados a PostgreSQL compartido con replicación
```

**Tecnologías sugeridas:** HAProxy, Nginx upstream, o AWS ALB en nube.

### 3.2 Replicación de Base de Datos (Propuesta)

```sql
-- PostgreSQL soporta replicación streaming nativa
-- Primary: nutresa-db (escritura)
-- Replica: nutresa-db-replica (lectura)
```

### 3.3 Snapshots de LVM para Backups Consistentes

```bash
# Sin detener servicios, crear snapshot del volumen lógico
sudo lvcreate -L1G -s -n lv-docker-snap /dev/vg-nutresa/lv-docker
# Montar y respaldar desde el snapshot
sudo mount /dev/vg-nutresa/lv-docker-snap /mnt/snap
```

---

## 4. Resumen de Cobertura

| Riesgo | Mecanismo | Estado |
|--------|-----------|--------|
| Fallo de disco | RAID 1 (mdadm) | ✅ Implementado |
| Caída de contenedor | `restart: always` | ✅ Implementado |
| Pérdida de datos | Backups + volúmenes LVM | ✅ Implementado |
| Fallo total de servicios | `deploy.sh` | ✅ Implementado |
| Sobrecarga de tráfico | Balanceo de carga | 📋 Conceptual |
| Fallo del servidor completo | Servidor réplica | 📋 Conceptual |
| Corrupción de BD | Replicación PostgreSQL | 📋 Conceptual |
