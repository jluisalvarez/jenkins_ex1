# Jenkins Example 1. FreeStyle Job

Contenerizando app y subirla a Docker hub con Jenkins

## Requisitos

- Instalar Java

```
alvarez@jenkins:~$ java --version

Command 'java' not found, but can be installed with:

apt install openjdk-11-jre-headless  # version 11.0.20.1+1-0ubuntu1~20.04, or
apt install default-jre              # version 2:1.11-72
apt install openjdk-16-jre-headless  # version 16.0.1+9-1~20.04
apt install openjdk-17-jre-headless  # version 17.0.8.1+1~us1-0ubuntu1~20.04
apt install openjdk-8-jre-headless   # version 8u382-ga-1~20.04.1
apt install openjdk-13-jre-headless  # version 13.0.7+5-0ubuntu1~20.04

Ask your administrator to install one of them.
```

```
alvarez@jenkins:~$ sudo apt update

...

alvarez@jenkins:~$ sudo apt install -y openjdk-17-jre-headless

...

alvarez@jenkins:~$ java --version
openjdk 17.0.10 2024-01-16
OpenJDK Runtime Environment (build 17.0.10+7-Ubuntu-120.04.1)
OpenJDK 64-Bit Server VM (build 17.0.10+7-Ubuntu-120.04.1, mixed mode, sharing)
```

- Instalar Docker


```
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

```
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

```
sudo groupadd docker

sudo usermod -aG docker $USER

sudo su - $USER
```

```
docker version
Client: Docker Engine - Community
 Version:           26.1.3
 API version:       1.45
 Go version:        go1.21.10
 Git commit:        b72abbb
 Built:             Thu May 16 08:33:49 2024
 OS/Arch:           linux/amd64
 Context:           default

Server: Docker Engine - Community
 Engine:
  Version:          26.1.3
  API version:      1.45 (minimum version 1.24)
  Go version:       go1.21.10
  Git commit:       8e96db1
  Built:            Thu May 16 08:33:49 2024
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.6.31
  GitCommit:        e377cd56a71523140ca6ae87e30244719194a521
 runc:
  Version:          1.1.12
  GitCommit:        v1.1.12-0-g51d5e94
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```


## Instalar Jenkins

```shell
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
```

```shell
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
```

```shell
sudo apt update

...

sudo apt install -y jenkins
...
```

```
sudo systemctl enable jenkins
Synchronizing state of jenkins.service with SysV service script with /lib/systemd/systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable jenkins
```

```
sudo systemctl status jenkins
```


```
https://IP_SERVER:8080/
```

```
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
be1f2b1a5f78b6efde5faf8be12e7f0948d4e
```

- Instala los plugins sugeridos.

- Introduce los datos (username, password, nombre, email) del usuario administrador.

En la máquina virtual, incluye al usuario jenkins en el grupo docker y reinicia el servicio jenkins.

```
sudo usermod -aG docker jenkins

sudo systemctl restart jenkins

```

## Administrar Jenkins

- Nodos
- Plugins
- Seguridad
- Credenciales



## Crear Projecto (Tarea / Job) Freestyle

- Crea un Projecto de estilo libre:
Establece el nombre, pulsa sobre crear un projecto de estilo libre y OK.

Accederemos a la pantalla de configuración del proyecto, con un montón de opciones, dependiendo de los plugins que tengamos instalados.

Por ahora, pasaremos a la sección "Build Steps", pulsaremos sobre añadir un nuevo paso y seleccionamos Ejecutar linea de comandos (shell). En el cuadro de texto escribiremos el comando a ejecutar y pulsaremos sobre Guardar.

En la pantalla del proyecto, entre otras acciones, podemos ver su workspace (directorio de trabajo), ejecutarlo con "Construir ahora" o volver a configurarlo de nuevo en la opción "Configurar".

Si ejecutamos el proyecto, veremos en la sección "Historia de tarea" una nueva entrada a la que podemos acceder  para comprobar su resultado, con la opción "Console Output".

En el panel de control tendremos todos los proyectos organizados en Vistas y/o Carpetas.

### Reconfiguremos el proyecto

Ahora, modificaremos el proyecto para que cada vez que subamos una nueva versión a nuestro repositorio git remoto (Github), se ejecute la tarea, que creará la imagen y la subirá a Docker Hub.

Primero, vamos a crear las crendenciales para DockerHub: Panel de control - Administrar Jenkins - Credentials - Global - Add Credential - Tipo: Username with Password - Inserta Username y Password, en ID pon un nombre a las credenciales.

Ahora, volvemos al proyecto:

- Accedemos al Proyecto y pulsamos en Configurar

- En "Configurar el origen del código fuente": Marcamos Git y completamos los apartados: Repository URL y Branches to build. Si es un repositorio público no es necesario indicar credenciales.

- En "Disparadores de ejecuciones": marcamos GitHub hook trigger for GITScm polling.
NOTA: Es necesario añadir un WebHook a Github con la URL http://<jenkins_server>/github-webhook/ para las acciones push.

- En "Entorno de ejecución" marca "Use secret text(s) or file(s)", pulsa en Añadir y selecciona "Username and password (separated)", en Username Variable introducimos: DOCKER_USERNAME, en Password Variable: DOCKER_PASSWORD y seleccionamos en Credentials las credenciales de Dockerhub creadas anteriormenete.
NOTA: Requiere haber creado previamente las crendenciales para DockerHub.

- En "Build Steps", pulsamos en "Añadir nuevo paso" y seleccionamos "Ejecutar linea de comandos (shell)". En el cuadro de texto introducimos los siguientes comandos:
```
TAG=`date "+%d%m%Y-%H%M%S"`
docker build -t jluisalvarez/flask_hello:$TAG .
docker images
docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"
docker push jluisalvarez/flask_hello:$TAG
```
- Finalmente, pulsamos en guardar.

Ahora, cada vez que subamos una nueva versión a nuestro repositorio Github se ejecutará la tarea, creará una imagen y la súbirá a Docker Hub, etiquetada con la fecha y hora de creación. También, podemos iniciarla manualmente.
