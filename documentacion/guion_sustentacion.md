# Guión de Sustentación — Infraestructura TI Nutresa

---

## Introducción (1 min)

> "Buenos días. El proyecto que vamos a presentar consiste en el diseño e implementación de la infraestructura TI para el Grupo Nutresa, una empresa del sector alimentario colombiano. El objetivo fue construir una infraestructura funcional, segura y escalable, aplicando los estándares que se esperan en un entorno de producción real."

---

## 1. Diseño de Red

> "Comenzamos con el diseño de red. En Cisco Packet Tracer implementamos una topología estrella con un Switch Multicapa 3650 como núcleo de distribución, conectado a cinco switches de acceso, uno por cada área funcional de Nutresa."

> "Segmentamos la red en cinco VLANs: Social, Económica, Ambiental, Producción y Servidores. Cada VLAN tiene su propia subred en el rango 172.16.0.0, con un gateway en la dirección .1 para mantener consistencia."

> "Para la VLAN de Producción usamos una máscara /23 en lugar de /24, porque es el área con mayor cantidad de dispositivos y necesitábamos prever el crecimiento. Esto nos da 510 hosts disponibles en lugar de 254."

> "La VLAN 100, Servidores, es donde vive nuestro servidor: IP 172.16.100.10 al .13 para DNS, Archivos, Base de Datos y Web respectivamente."

---

## 2. Virtualización y Sistema Base

> "Para la implementación práctica, desplegamos Ubuntu Server 26.04 LTS en una máquina virtual VirtualBox llamada Servidor-Nutresa-Prod, sobre un host Windows 11. La VM tiene 2 cores, 4GB de RAM y tres discos: uno de 20GB para el sistema operativo y dos de 10GB para el almacenamiento redundante."

> "El acceso remoto se gestiona mediante SSH. Aquí podemos ver la conexión activa desde Windows PowerShell."

---

## 3. RAID 1 + LVM

> "Para garantizar la redundancia de datos implementamos RAID 1 por software usando mdadm. Los dos discos de 10GB forman un arreglo en espejo: si uno falla, el sistema continúa operando desde el otro sin pérdida de datos."

*(ejecutar `cat /proc/mdstat`)*

> "Como pueden ver, el arreglo muestra [UU], lo que indica que ambos discos están activos y sincronizados."

> "Sobre el RAID implementamos LVM, que nos da flexibilidad para gestionar el almacenamiento de forma dinámica. El volumen lógico lv-docker de 8GB está montado en /datos y es donde viven todos los servicios."

*(ejecutar `df -h /datos` y `lsblk`)*

---

## 4. Docker y Servicios

> "Los servicios se despliegan como contenedores Docker orquestados con Docker Compose. Tenemos tres contenedores: Nginx como servidor web, PostgreSQL como base de datos, y un backend propio en Node.js que conecta ambos."

*(ejecutar `docker ps`)*

> "Todos los volúmenes de persistencia están en /datos, sobre el RAID. Esto significa que si un contenedor se destruye y recrea, los datos no se pierden."

> "Vamos a la demostración en vivo. Abrimos el navegador en http://192.168.1.12..."

*(abrir browser, mostrar formulario)*

> "Este formulario fue desarrollado por nosotros. Al ingresar credenciales válidas, el frontend hace un POST al backend en el puerto 3000, que consulta la tabla de usuarios en PostgreSQL."

*(login con admin / admin2026)*

> "Login exitoso. Y si revisamos la base de datos, podemos ver que el acceso quedó registrado en la tabla logs_acceso."

*(ejecutar query en psql)*

---

## 5. Samba

> "Para el servicio de archivos compartidos implementamos Samba, que permite compartir directorios en red usando el protocolo SMB, compatible con Windows, Linux y macOS."

*(ejecutar `systemctl status smbd`)*

> "El share NutresaShare en /datos/samba/share está disponible para cualquier equipo de la red local."

---

## 6. NTP

> "La sincronización de tiempo es crítica en infraestructuras con múltiples servicios. Usamos chrony como cliente NTP, sincronizado con los servidores de Canonical."

*(ejecutar `chronyc tracking`)*

> "Stratum 3, offset de milisegundos — el servidor tiene tiempo preciso y consistente."

---

## 7. Firewall y Seguridad

> "Para la seguridad perimetral configuramos ufw, que es la herramienta de firewall recomendada en Ubuntu. Solo están abiertos los puertos estrictamente necesarios para cada servicio."

*(ejecutar `sudo ufw status`)*

> "En cuanto a permisos especiales del sistema de archivos, aplicamos los tres bits especiales de Linux:"

*(ejecutar `ls -la /datos/samba/` y `ls -la /datos/scripts/`)*

> "Sticky bit en la carpeta Samba para evitar que usuarios eliminen archivos ajenos. SETGID en los directorios de Nginx y PostgreSQL para herencia de grupo. Y SETUID en el script de backup para que se ejecute con los privilegios necesarios."

---

## 8. Scripts Bash y Automatización

> "Automatizamos las tareas operativas con tres scripts Bash."

*(ejecutar `bash /datos/scripts/monitoreo.sh`)*

> "El script de monitoreo nos da en una sola ejecución el estado de CPU, memoria, disco, RAID, contenedores Docker, Samba y los últimos accesos a la base de datos."

> "El script de backup hace un dump de PostgreSQL y comprime los archivos de configuración. Los backups se guardan en /datos/backups con retención automática de 7 días."

> "Y el script de despliegue permite actualizar y relanzar todos los servicios con un solo comando."

---

## 9. Alta Disponibilidad

> "Finalmente, la alta disponibilidad está cubierta en varias capas. A nivel de almacenamiento, el RAID 1 garantiza continuidad ante fallo de disco. A nivel de servicios, Docker reinicia cualquier contenedor caído automáticamente gracias a restart: always. Y tenemos backups periódicos para recuperación ante pérdida de datos."

> "Como estrategia de escalabilidad futura, el diseño permite añadir un segundo servidor y un balanceador de carga HAProxy frente a ambos, con replicación streaming de PostgreSQL entre nodos."

---

## Cierre

> "En resumen, implementamos una infraestructura completa que cubre red segmentada por VLANs, almacenamiento redundante con RAID y LVM, servicios containerizados con Docker, seguridad con firewall y permisos especiales, automatización con Bash, y una estrategia de alta disponibilidad tanto práctica como conceptual. Quedamos atentos a sus preguntas."

---

## Frases de apoyo para preguntas difíciles

- *"Esa es una excelente observación. En este caso decidimos... porque..."*
- *"En un entorno de producción real, lo complementaríamos con... pero para el alcance del proyecto..."*
- *"Eso está documentado en el archivo [nombre].md del repositorio."*
- *"¿Prefiere que lo demostremos en vivo o lo explicamos conceptualmente?"*
