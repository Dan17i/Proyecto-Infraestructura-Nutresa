#!/bin/bash
FECHA=$(date +%Y-%m-%d_%H-%M)
DESTINO="/datos/backups"
mkdir -p "$DESTINO"

echo "[$FECHA] Iniciando backup..."

# Backup base de datos
docker exec nutresa-db pg_dump -U nutresa nutresadb > "$DESTINO/db_$FECHA.sql"

# Backup archivos Samba
tar -czf "$DESTINO/samba_$FECHA.tar.gz" /datos/samba/share

# Backup configuración Nginx
tar -czf "$DESTINO/nginx_$FECHA.tar.gz" /datos/nginx/conf /datos/nginx/html

echo "[$FECHA] Backup completado en $DESTINO"

# Eliminar backups de más de 7 días
find "$DESTINO" -type f -mtime +7 -delete
echo "[$FECHA] Backups antiguos eliminados"