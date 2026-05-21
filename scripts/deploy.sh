#!/bin/bash
echo "===== DEPLOY NUTRESA - $(date) ====="

cd /datos/compose

echo "Deteniendo servicios..."
docker compose down

echo "Actualizando imágenes..."
docker compose pull

echo "Levantando servicios..."
docker compose up -d --build

echo "Estado final:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo "===== DEPLOY COMPLETADO ====="