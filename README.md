# Proyecto de Infraestructura TI - Caso Nutresa 

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Infrastructure: Docker](https://img.shields.io/badge/Infrastructure-Docker-blue?logo=docker)](https://www.docker.com/)

Este proyecto consiste en el diseño, implementación y documentación de una infraestructura de red y servidores para la organización **Nutresa**. El objetivo es garantizar una operación funcional, segura y escalable bajo estándares profesionales.

##  Arquitectura de Red
La red está diseñada en **Cisco Packet Tracer** con un enfoque de segmentación por VLANs para mejorar la seguridad y el rendimiento:

*   **VLAN 10 (Social):** Gestión administrativa. 
*   **VLAN 20 (Económica):** Operaciones financieras. 
*   **VLAN 30 (Ambiental):** Monitoreo de sostenibilidad. 
*   **VLAN 40 (Producción):** Control de planta y procesos. 
*   **VLAN 100 (Servidores):** Centro de datos principal (DMZ). 🖥

## 🛠️ Stack Tecnológico
- **SO:** Linux (Ubuntu Server sugerido) 
- **Contenedores:** Docker & Docker Compose 
- **Almacenamiento:** Gestión de volúmenes con **RAID 1** y **LVM** para tolerancia a fallos. 💾
- **Servicios:**
    - Web (Nginx/Apache) 
    - Base de Datos (MySQL/PostgreSQL) 
    - Archivos (Samba) 
    - Acceso Remoto (SSH) 
    - Sincronización (NTP) 

##  Estructura del Proyecto
```text
.
├── diseno_red/         # Diagramas de Packet Tracer y plan de direccionamiento.
├── documentacion/      # Bitácora de avances, documento técnico y manuales.
├── infraestructura/    # Dockerfiles y archivos docker-compose.yml.
├── scripts/            # Automatización en Bash (Backup, Monitoreo, Deploy).
└── seguridad/          # Reglas de Firewall (UFW) y políticas de permisos.