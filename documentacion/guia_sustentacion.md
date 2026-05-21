# Guía de Sustentación — Infraestructura TI Nutresa

## Orden recomendado de demostración (30-40 min)

---

## 1. Diseño de Red (5 min)
**Mostrar:** Packet Tracer con la topología lógica

- Abrir `infra.pkt` y señalar los 5 switches y el Multilayer Switch0
- Explicar las 5 VLANs y sus rangos IP (tener el PDF de direccionamiento a mano)
- Señalar VLAN 100 (Servidores) como la que implementamos en la VM

**Puntos clave a mencionar:**
- Máscara /23 en VLAN 40 (Producción) → justificación de crecimiento
- Gateway .1 consistente en todas las VLANs
- Switch 3650 como núcleo de distribución (Multilayer)

---

## 2. VM y Sistema Base (3 min)
**Mostrar:** VirtualBox con los snapshots visibles

- Señalar la cadena de snapshots: `fase1` → `fase2` → `fase3` → `fase4`
- Abrir SSH desde PowerShell: `ssh nutresa@192.168.1.12`
- Ejecutar `uname -a` y `uptime`

---

## 3. RAID 1 + LVM (5 min)
**Mostrar en SSH:**
```bash
cat /proc/mdstat
sudo pvs && sudo vgs && sudo lvs
df -h /datos
lsblk
```
- Señalar `[UU]` en mdstat → ambos discos activos
- Mostrar `lv-docker` montado en `/datos`
- Explicar la pila: disco → RAID → LVM → /datos

---

## 4. Docker y Servicios (8 min)
**Mostrar:**
```bash
docker ps
cat /datos/compose/docker-compose.yml
```
- Señalar los 3 contenedores corriendo con sus puertos
- Abrir browser → `http://192.168.1.12` → mostrar formulario de login
- Hacer login con `admin / admin2026` → mostrar respuesta exitosa
- Hacer login fallido → mostrar mensaje de error
- Mostrar tablas de BD:
```bash
docker exec -it nutresa-db psql -U nutresa -d nutresadb -c "SELECT * FROM logs_acceso;"
```
- Verificar que el login quedó registrado en `logs_acceso`

---

## 5. Samba (3 min)
**Mostrar:**
```bash
systemctl status smbd
ls -la /datos/samba/share
```
- Desde Windows Explorer: `\\192.168.1.12\NutresaShare`
- Crear un archivo de prueba en el share

---

## 6. NTP (2 min)
```bash
chronyc tracking
```
- Señalar Reference ID, Stratum y offset mínimo

---

## 7. Firewall (2 min)
```bash
sudo ufw status
```
- Señalar cada puerto y su servicio asociado
- Explicar que ufw gestiona iptables internamente

---

## 8. Permisos Especiales (3 min)
```bash
ls -la /datos/samba/
ls -la /datos/nginx/
ls -la /datos/scripts/
```
- Señalar `t` en samba/share (sticky bit)
- Señalar `s` en nginx/html (SETGID)
- Señalar `s` en backup.sh (SETUID)

---

## 9. Scripts Bash (4 min)
```bash
bash /datos/scripts/monitoreo.sh
```
- Mostrar output completo: CPU, RAID, contenedores, Samba, logs DB
- Mostrar `ls /datos/backups/` con los archivos generados

---

## 10. Monitoreo (3 min)
```bash
htop
# salir con q
journalctl -u docker --since "1 hour ago" | tail -10
```

---

## 11. Alta Disponibilidad (2 min)
- Señalar `restart: always` en docker-compose.yml
- Mostrar que tras `sudo reboot` todo levanta solo (ya evidenciado)
- Mencionar la estrategia conceptual de balanceo de carga

---

## Preguntas frecuentes que puede hacer el profesor

| Pregunta | Respuesta clave |
|----------|----------------|
| ¿Por qué RAID 1 y no RAID 5? | Solo 2 discos disponibles; RAID 5 requiere mínimo 3 |
| ¿Para qué LVM sobre el RAID? | Flexibilidad para redimensionar volúmenes sin reformatear |
| ¿Por qué ufw y no iptables directo? | ufw es la herramienta recomendada en Ubuntu; gestiona iptables internamente |
| ¿Qué pasa si cae un contenedor? | `restart: always` lo levanta automáticamente |
| ¿Qué pasa si falla un disco? | RAID 1 continúa con el disco restante sin pérdida de datos |
| ¿Por qué Docker Compose y no Kubernetes? | Escala adecuada para el proyecto; Kubernetes es para microservicios en producción masiva |
| ¿Qué hace el sticky bit en Samba? | Evita que un usuario elimine archivos de otros en la carpeta compartida |
| ¿Por qué Node.js para el backend? | Liviano, rápido de implementar, integración nativa con pg para PostgreSQL |
