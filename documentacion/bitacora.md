# Bitácora de Proyecto: Infraestructura TI - Nutresa

## [2026-04-28] - Fase de Diseño y Documentación
**Estado:** Finalización de esquema lógico y preparación de entorno.

### Actividades Realizadas:
- Definición de 5 VLANs según requerimientos de áreas (Social, Económica, Ambiental, Producción, Servidores).
- Cálculo de direccionamiento IP utilizando la red base 172.16.0.0.
- Creación de la estructura de repositorio Git para control de versiones.
- Diseño de la topología en Cisco Packet Tracer (`infra.pkt`).

### Decisiones Técnicas:
- Se optó por una máscara /23 para la VLAN de Producción para prever el crecimiento de clientes/dispositivos en planta.
- Uso de Gateway .1 en todas las subredes para mantener consistencia en la configuración de los SVI (Switch Virtual Interfaces).

### Próximos Pasos:
1. Exportar y subir diagramas finales a `diseno_red/`.
2. Instalación de Ubuntu Server en Máquina Virtual.
3. **Hito Técnico:** Configuración de redundancia de datos mediante RAID 1 + LVM.