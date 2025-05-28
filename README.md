# Setup ROS2 Humble con Docker

## 📁 Copia della cartella

Clonare la repo dove vi torna più comodo accedervi.

## 🔧 Setup iniziale

Entrare nella sotto cartella `docker_setup` e lanciare:

```bash
./setup.sh <path_relativo>
```

con il path relativo per la directory del vostro sistema che volete mappare ai workspace impostati nella docker.

Ad esempio, per avere:

```
ros2_basic_docker_setup
├── docker_setup
└── workspaces
```

si esegue da dentro `docker_setup`:

```bash
./setup.sh ../workspaces
```

> Il nome `workspaces` è chiaramente arbitrario.

## 🐳 Creazione dell'immagine Docker

`setup.sh` procederà a caricare la docker image con ROS2 Humble Desktop pre-installato e a scaricare altre librerie che possono tornarci utili, per poi creare il nostro container dall'immagine docker.

## 🚀 Avvio del container

Per avviare il container appena creato si esegue lo script che termina in  `_run.sh` che trovate nella sotto-cartella `ws` presente nella vostra directory per i `workspaces`:
per esempio, se non si cambia il nome del container, si lancia questo comando da docker_setup:
```bash
./ws/ros2_humble_run.sh
```

Questo script:
- avvia un container dall'immagine appena impostata
- avvia il setup del vostro workspace minimale con i pacchetti tutorial di ROS2 Humble

## 🔁 Uscire e rientrare nel container

Per uscire dal container una volta entrati:
- premere `Ctrl-D` oppure
- eseguire `exit` dal terminale della Docker

Per rientrare nel container:

```bash
docker start ros2_humble
docker attach ros2_humble
```
Per aprire nuovi terminali della docker:

```bash
docker exec -ti ros2_humble bash

```

oppure usare tmux.

## 📦 Pacchetti e strumenti preinstallati

Nella Docker troverete pre-installati:

- `git`
- `ranger`
- `tmux`
- `gedit`

La lista completa dei pacchetti preinstallati si trova nello script:

```
/docker_setup/components/base.sh
```

Se volete aggiungere o togliere pacchetti al vostro Docker potete modificare questo script e ripetere tutte le istruzioni per ricrearvi una nuova immagine Docker.
