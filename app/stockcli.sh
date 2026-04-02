#!/usr/bin/env bash

# Activa un modo estricto básico: si se usa una variable no definida,
# el script termina en lugar de continuar con valores vacíos.
set -u

# Calcula la ruta del script para poder localizar el archivo .env
# aunque el comando se lance desde otro directorio.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Carga automáticamente variables desde .env si existe en el directorio
# actual o en la raíz del proyecto.
load_env_file() {
  local env_file

  for env_file in "${PWD}/.env" "${PROJECT_ROOT}/.env"; do
    if [[ -f "$env_file" ]]; then
      set -a
      # shellcheck disable=SC1090
      source "$env_file"
      set +a
      return 0
    fi
  done
}

load_env_file

# Lee la API key desde la variable de entorno y define la base
# de la API de Finnhub que usará todo el script.
# Se admite también FINHUB_API_KEY por compatibilidad con el typo previo.
API_KEY="${FINNHUB_API_KEY:-${FINHUB_API_KEY:-}}"
BASE_URL="https://finnhub.io/api/v1"
COMMAND_NAME="${STOCK_COMMAND_NAME:-./app/stockcli.sh}"

# Inicializa colores ANSI solo cuando la salida va a una terminal real
# y el usuario no ha desactivado el color mediante NO_COLOR.
setup_colors() {
  if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    YELLOW=$'\033[33m'
    BLUE=$'\033[34m'
    CYAN=$'\033[36m'
    BOLD=$'\033[1m'
    RESET=$'\033[0m'
  else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    CYAN=""
    BOLD=""
    RESET=""
  fi
}

setup_colors

# Helpers de salida para aplicar estilo de forma consistente y no repetir
# secuencias ANSI por todo el script.
print_error() {
  printf "%sError:%s %s\n" "${RED}${BOLD}" "$RESET" "$1" >&2
}

print_warning() {
  printf "%sAviso:%s %s\n" "${YELLOW}${BOLD}" "$RESET" "$1"
}

print_section() {
  printf "%s%s%s\n" "${BLUE}${BOLD}" "$1" "$RESET"
}

print_field() {
  local label="$1"
  local value="$2"

  printf "%s%-14s%s %s\n" "${CYAN}${BOLD}" "${label}:" "$RESET" "$value"
}

# Muestra la ayuda del CLI con comandos disponibles y ejemplos.
usage() {
  print_section "Uso"
  printf "  %s%s quote SYMBOL%s\n" "$BOLD" "$COMMAND_NAME" "$RESET"
  printf "  %s%s watch SYMBOL [intervalo]%s\n" "$BOLD" "$COMMAND_NAME" "$RESET"
  printf "  %s%s help%s\n" "$BOLD" "$COMMAND_NAME" "$RESET"
  printf "\n"
  print_section "Ejemplos"
  printf "  %s%s quote AAPL%s\n" "$BOLD" "$COMMAND_NAME" "$RESET"
  printf "  %s%s watch TSLA 3%s\n" "$BOLD" "$COMMAND_NAME" "$RESET"
}

# Comprueba que las dependencias externas necesarias estén instaladas
# antes de intentar hacer peticiones o procesar JSON.
check_dependencies() {
  command -v curl >/dev/null 2>&1 || {
    print_error "curl no está instalado."
    exit 1
  }

  command -v jq >/dev/null 2>&1 || {
    print_error "jq no está instalado."
    exit 1
  }
}

# Verifica que exista la API key requerida para autenticar las
# peticiones contra Finnhub.
check_api_key() {
  if [[ -z "$API_KEY" ]]; then
    print_error "falta FINNHUB_API_KEY."
    print_warning "Añádela en el archivo .env"
    exit 1
  fi
}

# Valida que el intervalo de watch sea un entero positivo expresado
# en segundos. Se acepta, por ejemplo, 5 o 05, pero no 0, texto libre
# ni valores negativos.
validate_interval() {
  local interval="$1"

  if [[ ! "$interval" =~ ^0*[1-9][0-9]*$ ]]; then
    print_error "El intervalo debe ser un numero entero positivo en segundos."
    print_warning "Ejemplo valido: ${COMMAND_NAME} watch AAPL 5"
    return 1
  fi
}

# Hace la petición HTTP a Finnhub para obtener la cotización
# actual del símbolo indicado y devuelve el JSON en bruto.
fetch_quote() {
  local symbol="$1"

  curl -s "${BASE_URL}/quote?symbol=${symbol}&token=${API_KEY}"
}

# Convierte la respuesta JSON en datos legibles para consola.
# Primero extrae los campos relevantes, luego valida la respuesta
# y por último imprime la información con formato.
print_quote() {
  local symbol="$1"
  local data="$2"

  local current change percent high low open prev_close timestamp change_color

  # Extrae del JSON los campos de precio y variación que devuelve Finnhub.
  current=$(echo "$data" | jq -r '.c')
  change=$(echo "$data" | jq -r '.d')
  percent=$(echo "$data" | jq -r '.dp')
  high=$(echo "$data" | jq -r '.h')
  low=$(echo "$data" | jq -r '.l')
  open=$(echo "$data" | jq -r '.o')
  prev_close=$(echo "$data" | jq -r '.pc')
  timestamp=$(echo "$data" | jq -r '.t')

  # Si el precio actual no existe o llega como 0, trata la respuesta
  # como no válida y muestra el JSON para facilitar el diagnóstico.
  if [[ "$current" == "null" || "$current" == "0" ]]; then
    print_error "No se pudieron obtener datos válidos para ${symbol}"
    print_warning "Respuesta recibida: $data"
    return 1
  fi

  # Cambia el color del movimiento según sea positivo o negativo.
  change_color="$GREEN"
  if [[ "$change" == -* || "$percent" == -* ]]; then
    change_color="$RED"
  fi

  # Imprime la cotización en un bloque legible para uso interactivo.
  printf "%s========================================%s\n" "$BLUE" "$RESET"
  print_field "Símbolo" "$symbol"
  print_field "Precio actual" "$current"
  print_field "Cambio" "${change_color}${change}${RESET}"
  print_field "Cambio %" "${change_color}${percent}${RESET}"
  print_field "Máximo día" "$high"
  print_field "Mínimo día" "$low"
  print_field "Apertura" "$open"
  print_field "Cierre previo" "$prev_close"
  print_field "Timestamp" "$timestamp"
  printf "%s========================================%s\n" "$BLUE" "$RESET"
}

# Entra en un bucle infinito para refrescar la cotización cada cierto
# número de segundos, limpiando la pantalla en cada iteración.
watch_quote() {
  local symbol="$1"
  local interval="${2:-5}"

  while true; do
    # Redibuja la vista del monitor y muestra contexto temporal.
    clear
    print_section "Monitor en tiempo real"
    print_field "Símbolo" "$symbol"
    print_field "Intervalo" "${interval}s"
    print_field "Hora local" "$(date '+%Y-%m-%d %H:%M:%S')"
    printf "\n"

    # Obtiene la cotización actual y la muestra formateada.
    local data
    data=$(fetch_quote "$symbol")
    print_quote "$symbol" "$data"

    sleep "$interval"
  done
}

# Punto de entrada principal: valida requisitos, interpreta el comando
# recibido y delega en la función correspondiente.
main() {
  local command="${1:-help}"

  # Router sencillo de subcomandos del CLI.
  case "$command" in
    quote)
      check_dependencies
      check_api_key
      local symbol="${2:-}"
      [[ -z "$symbol" ]] && usage && exit 1
      local data
      data=$(fetch_quote "$symbol")
      print_quote "$symbol" "$data"
      ;;
    watch)
      check_dependencies
      check_api_key
      local symbol="${2:-}"
      local interval="${3:-5}"
      [[ -z "$symbol" ]] && usage && exit 1
      validate_interval "$interval" || exit 1
      watch_quote "$symbol" "$interval"
      ;;
    help|--help|-h)
      usage
      ;;
    *)
      print_error "Comando no válido: $command"
      usage
      exit 1
      ;;
  esac
}

main "$@"
