# Arquitectura de Contenedores Docker

## 1. Contexto

Los servicios de la infraestructura Nutresa se despliegan como contenedores Docker orquestados mediante **Docker Compose**, con volúmenes persistentes almacenados en `/datos` (LVM sobre RAID 1).

---

## 2. Servicios Desplegados

| Contenedor | Imagen | Puerto | Función |
|-----------|--------|--------|---------|
| `nutresa-web` | `nginx:latest` | `80:80` | Servidor web — sirve la página de login |
| `nutresa-db` | `postgres:16` | `5432:5432` | Motor de base de datos PostgreSQL |
| `nutresa-backend` | `compose-backend` (build local) | `3000:3000` | API REST Node.js/Express — autenticación |

> Samba (`smbd`) corre como servicio del sistema operativo host, no como contenedor.

---

## 3. Diagrama de Arquitectura

```
                        RED LOCAL (192.168.1.0/24)
                               │
                    Cliente Browser / PowerShell
                               │
              ┌────────────────┼────────────────┐
              │ HTTP :80       │ SSH :22         │ SMB :445
              ▼                ▼                 ▼
     ┌─────────────────┐  ┌─────────┐  ┌──────────────┐
     │  nutresa-web    │  │  sshd   │  │     smbd     │
     │  (Nginx)        │  │  (host) │  │  (Samba/host)│
     └────────┬────────┘  └─────────┘  └──────┬───────┘
              │ fetch POST :3000/login          │
              ▼                                 │
     ┌─────────────────┐               /datos/samba/share
     │ nutresa-backend │
     │ (Node.js/Express│
     └────────┬────────┘
              │ pg query :5432
              ▼
     ┌─────────────────┐
     │   nutresa-db    │
     │ (PostgreSQL 16) │
     └────────┬────────┘
              │
    ┌─────────┴──────────────────────────────┐
    │         VOLÚMENES EN /datos            │
    │  /datos/nginx/html  → contenido web    │
    │  /datos/nginx/conf  → config Nginx     │
    │  /datos/postgres/data → datos PG       │
    │  /datos/backend/    → código fuente    │
    └────────────────────────────────────────┘
              │
    ┌─────────┴──────────┐
    │   LVM lv-docker    │
    │   (8GB, ext4)      │
    └─────────┬──────────┘
              │
    ┌─────────┴──────────┐
    │   /dev/md0 RAID 1  │
    │   sdb + sdc        │
    └────────────────────┘
```

---

## 4. Flujo de Autenticación

```
1. Usuario accede a http://192.168.1.12
2. Nginx sirve index.html (formulario de login)
3. Usuario ingresa credenciales → POST http://192.168.1.12:3000/login
4. nutresa-backend consulta: SELECT * FROM usuarios WHERE username=$1 AND password=$2
5. Si válido → INSERT en logs_acceso + respuesta JSON con rol
6. Nginx muestra mensaje de bienvenida o error
```

---

## 5. Docker Compose

```yaml
services:
  nginx:
    image: nginx:latest
    container_name: nutresa-web
    ports:
      - "80:80"
    volumes:
      - /datos/nginx/html:/usr/share/nginx/html
      - /datos/nginx/conf:/etc/nginx/conf.d
    restart: always

  postgres:
    image: postgres:16
    container_name: nutresa-db
    environment:
      POSTGRES_DB: nutresadb
      POSTGRES_USER: nutresa
      POSTGRES_PASSWORD: Nutresa2026
    volumes:
      - /datos/postgres/data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: always

  backend:
    build: /datos/backend
    container_name: nutresa-backend
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    restart: always
```

---

## 6. Base de Datos

### Esquema

```sql
-- Tabla de usuarios del sistema
CREATE TABLE usuarios (
    id         SERIAL PRIMARY KEY,
    username   VARCHAR(50) UNIQUE NOT NULL,
    password   VARCHAR(100) NOT NULL,
    rol        VARCHAR(20) DEFAULT 'user',
    creado_en  TIMESTAMP DEFAULT NOW()
);

-- Auditoría de accesos
CREATE TABLE logs_acceso (
    id         SERIAL PRIMARY KEY,
    usuario_id INT REFERENCES usuarios(id),
    fecha      TIMESTAMP DEFAULT NOW(),
    accion     VARCHAR(100)
);
```

### Datos de prueba

| username | password | rol |
|----------|----------|-----|
| admin | admin2026 | admin |
| juan.perez | pass123 | user |
| maria.lopez | pass456 | user |

---

## 7. Persistencia y Alta Disponibilidad

| Mecanismo | Detalle |
|-----------|---------|
| `restart: always` | Contenedores reinician automáticamente ante fallo o reboot |
| Volúmenes en `/datos` | Datos fuera del contenedor — sobreviven `docker compose down` |
| RAID 1 bajo `/datos` | Redundancia física ante fallo de disco |
| `depends_on: postgres` | Backend espera a que la DB esté lista antes de iniciar |

---

## 8. Comandos de Operación

```bash
# Ver estado de contenedores
docker ps

# Levantar todos los servicios
cd /datos/compose && docker compose up -d

# Ver logs de un servicio
docker logs nutresa-backend

# Reiniciar un servicio
docker compose restart nginx

# Acceder a la base de datos
docker exec -it nutresa-db psql -U nutresa -d nutresadb

# Detener todo
docker compose down
```
