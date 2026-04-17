# Stock CLI

CLI en Bash para consultar cotizaciones bursátiles desde Finnhub.

Actualmente permite:
- consultar el precio actual de un símbolo con `quote`
- monitorizar una cotización en tiempo real con `watch`
- usar colores en terminal cuando la salida es interactiva
- instalar un comando local `stock`

## Requisitos

### Ejecución local

- `bash`
- `curl`
- `jq`
- una API key de Finnhub

### Ejecución con Docker

- `docker`
- `docker compose`

## Configuración

1. Copia el archivo de ejemplo:

```bash
cp .env.example .env
```

2. Edita `.env` y añade tu API key real:

```env
FINNHUB_API_KEY=tu_api_key_aqui
```

El script carga `.env` automáticamente si existe en la raíz del proyecto o en el directorio desde el que se ejecuta.

## Instalación del comando `stock`

La forma recomendada de usar el proyecto es instalar el comando local:

```bash
./install.sh
```

Por defecto se instala en `~/.local/bin/stock`.

Si `~/.local/bin` no está en tu `PATH`, añade esta línea a tu `~/.zshrc` o `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Después abre una terminal nueva y podrás ejecutar:

```bash
stock help
stock quote AAPL
stock watch TSLA 3
```

Para desinstalar el comando:

```bash
./uninstall.sh
```

## Uso local sin instalar

Desde la raíz del proyecto:

```bash
./app/stockcli.sh help
./app/stockcli.sh quote AAPL
./app/stockcli.sh watch TSLA 3
```

### Comandos disponibles con `stock`

- `stock help`
  Muestra la ayuda del CLI.

- `stock quote SYMBOL`
  Consulta la cotización actual de un símbolo.

- `stock watch SYMBOL [intervalo]`
  Refresca la cotización cada `N` segundos. Si no se indica intervalo, usa `5`.

### Comandos disponibles con ruta directa

- `./app/stockcli.sh help`
  Muestra la ayuda del CLI.

- `./app/stockcli.sh quote SYMBOL`
  Consulta la cotización actual de un símbolo.

- `./app/stockcli.sh watch SYMBOL [intervalo]`
  Refresca la cotización cada `N` segundos. Si no se indica intervalo, usa `5`.

## Uso con Docker

Construcción de la imagen:

```bash
docker compose build
```

Ejemplos:

```bash
docker compose run --rm stockcli help
docker compose run --rm stockcli quote AAPL
docker compose run --rm stockcli watch TSLA 3
```

## Variables de entorno

- `FINNHUB_API_KEY`
  Obligatoria. API key usada para autenticar las peticiones a Finnhub.

- `NO_COLOR`
  Opcional. Si existe, desactiva los colores del CLI.

Ejemplo:

```bash
NO_COLOR=1 ./app/stockcli.sh quote AAPL
```

## Estructura del proyecto

```text
.
├── app/
│   └── stockcli.sh
├── stock
├── install.sh
├── uninstall.sh
├── logs/
├── .env.example
├── docker-compose.yml
├── Dockerfile
└── README.md
```

## Problemas comunes

### `Error: falta FINNHUB_API_KEY.`

Revisa que exista un archivo `.env` con esta variable:

```env
FINNHUB_API_KEY=tu_api_key_aqui
```

### `Error: curl no está instalado.` o `Error: jq no está instalado.`

Instala las dependencias necesarias en tu sistema antes de ejecutar el script en local.

### `Cannot connect to the Docker daemon`

Docker está instalado pero el daemon no está levantado. Inicia Docker Desktop o el servicio de Docker y vuelve a ejecutar `docker compose`.

### `stock: command not found`

Ejecuta `./install.sh` y asegúrate de que `~/.local/bin` esté incluido en tu `PATH`.

## Notas

- El comando `watch` limpia la pantalla en cada iteración para redibujar la información.
- Los colores solo se muestran cuando la salida va a una terminal real.
- La salida depende de la respuesta que devuelva Finnhub para el símbolo consultado.
-Prueba para PR