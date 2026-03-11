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
| Unirse al clúster | `docker swarm join --token <TOKEN> <IP_MANAGER>:<PUERTO>` |
| Ver token de unión | `docker swarm join-token worker` o (`manager`) para recuperar el código necesario para nuevos nodos|
| Abandonar el clúster | `docker swarm leave`|

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


