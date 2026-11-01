# Shared helpers for every make script. Sourced, never executed.
# shellcheck shell=bash
# Variables below are used by the scripts that source this file.
# shellcheck disable=SC2034

ENV_FILE=".env"             # versioned: project identity
LOCAL_ENV_FILE=".env.local" # never versioned: environment and secrets
NETWORK="proxy"
SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Prints an error and exits.
#
# @param string $* Message
die () { printf '%s\n' "$*" >&2; exit 1; }

# Prints an indented message.
#
# @param string $* Message
info () { printf '  %s\n' "$*"; }

# Prints a command, then runs it.
#
# @param string $@ Command and arguments
run () {
  local arg shown=()
  for arg in "$@"; do
    case $arg in *[[:space:]]*) shown+=("\"$arg\"") ;; *) shown+=("$arg") ;; esac
  done
  printf '  \033[2m%s\033[0m\n' "${shown[*]}"
  "$@"
}

# Reads a KEY=value file into the environment, without executing it.
# A variable already set (command line, or a file read before) is kept.
#
# @param string $1 File (skipped if missing)
read_env_file () {
  local key value
  [ -f "$1" ] || return 0
  while IFS='=' read -r key value || [ -n "$key" ]; do
    key="${key%$'\r'}"; value="${value%$'\r'}"
    [[ $key =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || continue
    value="${value#\"}"; value="${value%\"}"
    [ -n "${!key:-}" ] || export "$key=$value"
  done < "$1"
}

# Resolves the settings: command-line parameters, then .env.local, then .env.
# APP_ENV defaults to local.
#
# @param string $1 Command name, for error messages
load_env () {
  read_env_file "$LOCAL_ENV_FILE"
  read_env_file "$ENV_FILE"

  export APP_ENV="${APP_ENV:-local}"

  case "$APP_ENV" in
    local|demo|prod) ;;
    *) die "$1 : APP_ENV doit valoir local, demo ou prod (actuellement « $APP_ENV »)" ;;
  esac
}

# Exits unless APP_ENV matches.
#
# @param string $1 Command name, for error messages
# @param string $2 Required environment (local|demo|prod)
require_app_env () {
  [ "$APP_ENV" = "$2" ] \
    || die "$1 : commande réservée à l'environnement $2 (APP_ENV=$APP_ENV)"
}

# Sets KEY=value in an env file, replacing the existing line.
#
# @param string $1 File
# @param string $2 Key
# @param string $3 Value
set_env_value () {
  awk -v k="$2" -v v="$3" 'index($0, k "=") == 1 { $0 = k "=" v } { print }' \
    "$1" > "$1.tmp"
  mv "$1.tmp" "$1"
}

# Runs docker compose with both env files, the base file and the APP_ENV overlay if any.
#
# @param string $@ docker compose arguments
compose () {
  local args=(--env-file "$ENV_FILE")
  if [ -f "$LOCAL_ENV_FILE" ]; then args+=(--env-file "$LOCAL_ENV_FILE"); fi
  args+=(-f compose.yaml)
  if [ -f "compose.$APP_ENV.yaml" ]; then args+=(-f "compose.$APP_ENV.yaml"); fi
  run docker compose "${args[@]}" "$@"
}

# @return 0 if the reverse proxy's shared network exists
network_exists () { docker network inspect "$NETWORK" >/dev/null 2>&1; }

# Generates a random secret: hexadecimal only, safe inside URLs.
secret () { openssl rand -hex 24; }

# Path of a tool: the project's pinned copy in .tools/bin/, else the system one.
#
# @param string $1 Tool name
# @return 1 if the tool is not found
tool () {
  if [ -x ".tools/bin/$1.exe" ]; then
    echo ".tools/bin/$1.exe"
  elif [ -x ".tools/bin/$1" ]; then
    echo ".tools/bin/$1"
  elif command -v "$1" >/dev/null; then
    echo "$1"
  else
    return 1
  fi
}