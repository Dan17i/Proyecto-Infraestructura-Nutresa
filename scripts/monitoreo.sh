#!/bin/bash
echo "===== MONITOREO NUTRESA - $(date) ====="

echo ""
echo "--- CPU y Memoria ---"
top -bn1 | grep -E "Cpu|MiB Mem"

echo ""
echo "--- Disco /datos ---"
df -h /datos

echo ""
echo "--- RAID ---"
cat /proc/mdstat | grep -E "md0|blocks"

echo ""
echo "--- Contenedores Docker ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "--- Samba ---"
systemctl is-active smbd

echo ""
echo "--- Últimos 5 accesos DB ---"
docker exec nutresa-db psql -U nutresa -d nutresadb -c \
  "SELECT u.username, l.accion, l.fecha FROM logs_acceso l JOIN usuarios u ON l.usuario_id=u.id ORDER BY l.fecha DESC LIMIT 5;"