# Docker Swarm
Comandos útiles para Docker Swarm


El comando principal para inicializar un clúster es:
```
docker swarm init
```
Este comando convierte el nodo actual en un manager y genera un token que permite a otros nodos unirse al grupo.

## Gestión del Clúster (Swarm)

| Descripción | Comando     | 
| :-------- | :------- | 
| Ver token de unión | `docker swarm join-token worker` o (`manager`) para recuperar el código necesario para nuevos nodos|
| Unirse al clúster | `docker swarm join --token <TOKEN> <IP_MANAGER>:<PUERTO>` según el token se añade un worker o un manager |
| Promover un worker a manager | `docker swarm leave`|
| Abandonar el clúster | `docker node promote <HOSTNAME_WORKER>` |

Para que un cluster de Docker Swarm funcione correctamente entre nodos manager y worker, debes abrir 3 puertos principales entre todos los nodos del cluster.

| Puerto   | Protocolo | Uso                                   |
| -------- | --------- | ------------------------------------- |
| **2377** | TCP       | Gestión del cluster (manager ↔ nodos) |
| **7946** | TCP/UDP   | Comunicación entre nodos              |
| **4789** | UDP       | Red overlay (VXLAN para contenedores) |

```
nc -zv <IP_MANAGER> 2377
nc -zv <IP_MANAGER> 7946
nc -zvu <IP_MANAGER> 7946
nc -zvu <IP_MANAGER> 4789
```

Testear desde estos script:

```
sh check-swarm-ports.sh <IP_NODO>
sh check-swarm-ports.sh <IP_NODO>
```

Probar comunicación:

```
docker exec -it CONTAINER_ID sh
ping IP_OTRO_CONTENEDOR 
```



## Gestión de Nodos

| Descripción | Comando     | 
| :-------- | :------- | 
| Listar nodos | `docker node ls` (solo ejecutable desde un nodo manager) |
| Ver detalles de un nodo | `docker node inspect <ID_NODO>` |
| Promover/Degradar | `docker node promote <NODO>` o `docker node demote <NODO>` |

## Gestión de Servicios

| Descripción | Comando     | 
| :-------- | :------- | 
| Crear un servicio | `docker service create --name <NOMBRE> <IMAGEN>` |
| Listar servicios | `docker service ls` |
| Escalar un servicio | `docker service scale <NOMBRE>=<NUM_REPLICAS>` |
| Eliminar un servicio | `docker service rm <NOMBRE>` |

## Despliegue con Stack (Similar a Compose)

| Descripción | Comando     | 
| :-------- | :------- | 
| Desplegar una aplicación | `docker stack deploy -c docker-compose.yml <NOMBRE_STACK>` |
| Listar stacks | `docker stack ls` |
| Eliminar un stack | `docker stack rm <NOMBRE_STACK>` |
| Ver estado de los servicios | `docker stack services <NOMBRE_STACK>` |
| Ver en qué nodos están los contenedores | `docker stack ps <NOMBRE_STACK>` |

## Monitorización con logs
| Descripción | Comando     | 
| :-------- | :------- | 
| Ver logs de un servicio específico | `docker service logs <NOMBRE_SERVICIO_O_ID>` |
| Ver solo las últimas líneas | `docker service logs --tail 50 <NOMBRE_SERVICIO_O_ID>` |
| Ver logs con marcas de tiempo (Timestamps) | `docker service logs -t <NOMBRE_SERVICIO_O_ID>` |
| Filtrar por una réplica específica | Primero obtienes los IDs de las tareas: `docker service ps <NOMBRE_SERVICIO>`. Luego consultas el log de esa tarea: `docker service logs <ID_TAREA>` |
| Logs de Stack | `docker service logs <NOMBRE_STACK>` |

Para evitar que los logs consuman todo el espacio en disco, debes configurar el
Logging Driver (generalmente json-file). Tienes dos formas de hacerlo: para todo el clúster o específicamente en un servicio/stack.

**1. Configuración en un Stack**

Es la mejor opción porque queda documentado en tu infraestructura. Añade la sección logging a cada servicio:

```
services:
  api:
    image: mi-backend:latest
    logging:
      driver: "json-file"
      options:
        max-size: "10m"   # Tamaño máximo de cada archivo
        max-file: "3"     # Número de archivos de rotación antes de borrar el viejo
    deploy:
      replicas: 3
```

**2. Configuración global (En cada Nodo)**

Si quieres que todos los contenedores del nodo (incluso los que no son de Swarm) sigan esta regla, debes editar o crear el archivo /etc/docker/daemon.json:

```
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Reinicia Docker: `sudo systemctl restart docker`

**3. Limpiar logs manualmente (Emergencia)**

Si ya tienes el disco lleno, puedes vaciar el archivo de log actual de un contenedor específico sin borrar el contenedor:
```
# Ejecutar en el nodo donde vive el contenedor
truncate -s 0 $(docker inspect --format='{{.LogPath}}' <ID_CONTENEDOR>)
```

## Configuración de una red Overlay

La red **overlay** es fundamental en Docker Swarm porque crea una red virtual distribuida que permite que los contenedores en diferentes nodos se comuniquen de forma segura, como si estuvieran en la misma máquina.

**1. Crear la red overlay**

Ejecuta este comando en un nodo **Manager**:

```
docker network create --driver overlay mi_red_overlay
```

**2. Conectar servicios a la red**
   
Cuando creas un nuevo servicio, debes especificar que use esta red con el parámetro `--network`:

```
docker service create --name app_web \
  --network mi_red_overlay \
  --replicas 3 \
  nginx
```

**3. Conectar servicios existentes**

Si ya tienes un servicio funcionando y quieres añadirlo a la red overlay, usa:

```docker service update --network-add mi_red_overlay <NOMBRE_DEL_SERVICIO>```

**4. Verificar la comunicación**

Para comprobar que los contenedores están conectados correctamente:

**Listar redes:** `docker network ls` (Verás que el Scope es swarm).

**Inspeccionar detalles:** `docker network inspect mi_red_overlay` para ver qué contenedores e IPs están asignados en ese momento.

**Prueba de ping:** Puedes entrar en un contenedor y hacer ping a otro usando su nombre de servicio (DNS interno de Docker), por ejemplo: `ping app_web`.


**5. Redes adjuntables (attachable)**
   
Si necesitas que contenedores individuales (creados con `docker run`) también puedan unirse a esta red de Swarm, añade la bandera `--attachable` al crearla:
```
docker network create --driver overlay --attachable mi_red_mixta
``` 


